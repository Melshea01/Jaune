// Widget d'écran d'accueil Jaune — citron du jour, streak et heure d'apéro.
// Lit l'état publié par l'app Flutter via l'App Group (HomeWidgetService).
//
// Branchement : voir README.md dans ce dossier.

import WidgetKit
import SwiftUI

private let appGroupId = "group.com.jaune.app"

// MARK: - Données

struct CitronEntry: TimelineEntry {
    let date: Date
    let mood: String
    let health: Int
    let streak: Int
    let level: Int
    let aperoTime: String

    static let placeholder = CitronEntry(
        date: Date(), mood: "happy", health: 86, streak: 3,
        level: 4, aperoTime: "18:30"
    )

    var moodEmoji: String {
        switch mood {
        case "superHappy": return "🤩"
        case "happy": return "😄"
        case "neutral": return "🙂"
        case "tired": return "🥱"
        case "sick": return "🤢"
        default: return "💀"
        }
    }

    var healthColor: Color {
        switch health {
        case 90...: return Color(red: 0.26, green: 0.91, blue: 0.48)
        case 75..<90: return Color(red: 0.66, green: 0.88, blue: 0.39)
        case 50..<75: return Color(red: 1.0, green: 0.82, blue: 0.0)
        case 25..<50: return Color(red: 1.0, green: 0.55, blue: 0.26)
        default: return Color(red: 0.97, green: 0.34, blue: 0.34)
        }
    }
}

struct CitronProvider: TimelineProvider {
    func placeholder(in context: Context) -> CitronEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (CitronEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CitronEntry>) -> Void) {
        // L'app pousse les mises à jour via WidgetCenter à chaque recalcul ;
        // le refresh horaire n'est qu'un filet de sécurité.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [load()], policy: .after(next)))
    }

    private func load() -> CitronEntry {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return .placeholder
        }
        return CitronEntry(
            date: Date(),
            mood: defaults.string(forKey: "mood") ?? "happy",
            health: defaults.integer(forKey: "health"),
            streak: defaults.integer(forKey: "streak"),
            level: defaults.integer(forKey: "level"),
            aperoTime: defaults.string(forKey: "aperoTime") ?? "—"
        )
    }
}

// MARK: - Vues

struct JauneWidgetView: View {
    var entry: CitronEntry
    @Environment(\.widgetFamily) var family

    private let sky = Color(red: 0.584, green: 0.776, blue: 0.957)
    private let skyLight = Color(red: 0.788, green: 0.886, blue: 0.980)

    var body: some View {
        content
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [sky, skyLight],
                    startPoint: .top, endPoint: .bottom
                )
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(spacing: 4) {
            Text(entry.moodEmoji).font(.system(size: 40))
            healthBar
            if entry.streak > 0 {
                Text("🔥 \(entry.streak)")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            Text(entry.moodEmoji).font(.system(size: 56))
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("JAUNE")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white.opacity(0.9))
                    if entry.streak > 0 {
                        Text("🔥 \(entry.streak)")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
                healthBar
                Text("🍋 Apéro à \(entry.aperoTime)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }

    private var healthBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.35))
                Capsule()
                    .fill(entry.healthColor)
                    .frame(width: geo.size.width * CGFloat(entry.health) / 100)
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Widget

struct JauneWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "JauneWidget", provider: CitronProvider()) {
            JauneWidgetView(entry: $0)
        }
        .configurationDisplayName("Jaune")
        .description("Ton citron, ta série sobre et l'heure de l'apéro.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct JauneWidgetBundle: WidgetBundle {
    var body: some Widget {
        JauneWidget()
    }
}
