# Widget d'écran d'accueil Jaune

Le côté Flutter est déjà branché : `HomeWidgetService.sync()` pousse
humeur / santé / streak / niveau / heure d'apéro dans l'App Group
`group.com.jaune.app` à chaque recalcul de santé, et demande le refresh
du widget. Sans extension installée, ces appels sont silencieux.

## Branchement (≈10 min, nécessite un compte Apple Developer)

1. **Créer le target** — Xcode → `Runner.xcworkspace` → File → New →
   Target… → **Widget Extension** → Product Name : `JauneWidget`
   (décocher "Include Configuration App Intent"). Ne pas activer
   le scheme proposé si demandé pour la Live Activity.
2. **Remplacer le code généré** — supprimer les fichiers Swift créés par
   le template et glisser `JauneWidget.swift` (ce dossier) dans le
   target `JauneWidget`.
3. **App Group** — pour les DEUX targets (`Runner` et `JauneWidget`) :
   Signing & Capabilities → + Capability → App Groups →
   `group.com.jaune.app`.
4. **Déploiement** — iOS Deployment Target du widget ≥ 17.0
   (containerBackground). Build sur device ou simulateur, ajouter le
   widget depuis l'écran d'accueil.

## Visuels

Le widget rend l'humeur en emoji pour l'instant. Pour la v2 : exporter
5 PNGs du citron (un par humeur : superHappy/happy/neutral/tired/sick)
et les ajouter à l'asset catalog de l'extension, puis remplacer
`Text(entry.moodEmoji)` par `Image(entry.mood)`.

## Étape suivante : Live Activity (Dynamic Island)

Compte à rebours BeJaune pendant la fenêtre apéro (17h-20h) :
- package Flutter `live_activities` + extension ActivityKit (iOS 16.1+),
- démarrée à l'ouverture de la fenêtre (heure déterministe du
  `DeterministicNotificationScheduler`), terminée au post ou à 20h,
- test uniquement sur device réel, entitlement Push/ActivityKit requis.
À faire une fois le signing en place — très différenciant pour le buzz.
