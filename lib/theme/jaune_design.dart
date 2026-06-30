import 'package:flutter/material.dart';

/// Système de design Jaune — source unique de vérité pour les couleurs,
/// le mouvement et les rayons. Toute nouvelle UI doit piocher ici.
abstract class JauneColors {
  // Ciel (fond de l'app)
  static const sky = Color(0xFF95C6F4);
  static const skyLight = Color(0xFFC9E2FA);
  static const skyDeep = Color(0xFF5E9FD5);

  // Citron (identité de marque)
  static const lemon = Color(0xFFF7D83F);
  static const lemonDeep = Color(0xFFF6B73F);

  // Flamme (streak)
  static const flame = Color(0xFFFF6B35);
  static const flameLight = Color(0xFFFF9D42);

  // Santé — 5 paliers alignés sur les émotions du citron
  // (superHappy ≥90, happy ≥75, neutral ≥50, tired ≥25, sick <25)
  static const healthVibrant = [Color(0xFF43E97B), Color(0xFF38F9D7)];
  static const healthHigh = [Color(0xFFA8E063), Color(0xFF56AB2F)];
  static const healthMid = [Color(0xFFFFD200), Color(0xFFF7971E)];
  static const healthWarm = [Color(0xFFFF8C42), Color(0xFFFF5E3A)];
  static const healthLow = [Color(0xFFF85757), Color(0xFFF857A6)];

  // Texte
  static const ink = Color(0xFF22223A);
  static const inkSoft = Color(0xFF6E6E85);

  /// Dégradé de santé selon le pourcentage — source unique pour la barre
  /// de PV, l'image partagée et tout futur indicateur. Les seuils sont
  /// CEUX des presets d'animation : la couleur et l'émotion changent
  /// ensemble.
  static List<Color> healthGradient(double percent) {
    if (percent >= 0.90) return healthVibrant;
    if (percent >= 0.75) return healthHigh;
    if (percent >= 0.50) return healthMid;
    if (percent >= 0.25) return healthWarm;
    return healthLow;
  }

  /// Bleu « sobriété » — la journée sans alcool est l'objectif, on la
  /// valorise (rappel de l'eau, cf. 💧) plutôt que de la rendre terne.
  static const sober = Color(0xFF2F7CC2);
  static const soberTint = Color(0xFFE3F1FB);

  /// Couleur d'une journée selon le nombre de verres — barème UNIQUE
  /// (aligné OMS / formule PV) partagé par les cellules du calendrier et
  /// le texte de détail. Réservé à count >= 1 (la sobriété a son propre
  /// traitement, cf. [sober]). Toutes ces teintes passent l'AA avec du
  /// texte blanc.
  /// 1-2 modéré · 3-5 ça monte · >=6 grosse soirée.
  static Color consumptionColor(int count) {
    if (count <= 2) return const Color(0xFF56AB2F); // modéré — vert
    if (count <= 5) return const Color(0xFFE8821E); // ça monte — ambre
    return const Color(0xFFE5484D); // grosse soirée — rouge
  }

  /// Couleurs de phase de progression
  static Color phaseColor(String phase) => switch (phase) {
    'discovery' => const Color(0xFF34C759),
    'engagement' => const Color(0xFFAF52DE),
    _ => const Color(0xFFFF9F0A),
  };

  /// Or du chapitre « Légende » (niv. 31+) — 4e couleur de chapitre.
  static const chapterLegend = Color(0xFFFFB300);

  /// Couleur du chapitre d'un niveau donné — source unique pour le parcours.
  /// Aligne les 4 chapitres sur les 4 rangs (cf. rankTitle).
  static Color chapterColor(int level) {
    if (level <= 5) return phaseColor('discovery');
    if (level <= 15) return phaseColor('engagement');
    if (level <= 30) return phaseColor('mastery');
    return chapterLegend;
  }
}

/// Durées et courbes standardisées — un seul langage de mouvement.
/// Règle : interactions directes = rapides (tap), changements d'état = moyens,
/// célébrations = lentes et expressives.
abstract class JauneMotion {
  /// Feedback de pression d'un bouton
  static const tap = Duration(milliseconds: 120);

  /// Apparitions/disparitions légères (toasts, détails)
  static const quick = Duration(milliseconds: 250);

  /// Transitions d'écran et de dialogues
  static const standard = Duration(milliseconds: 420);

  /// Changements de données visibles (barre de vie, jauges)
  static const emphasized = Duration(milliseconds: 700);

  /// Entrées avec léger rebond (éléments joyeux)
  static const springy = Curves.easeOutBack;

  /// Sorties et déplacements (lisse, naturel)
  static const smooth = Curves.easeOutCubic;

  /// Entrées très expressives (célébrations)
  static const playful = Curves.elasticOut;
}

abstract class JauneRadii {
  static const card = 16.0;
  static const sheet = 28.0;
  static const pill = 24.0;
}

/// Échelle typographique Jaune — un seul rythme de tailles/graisses pour
/// toute l'app. On reste sur la police système (SF Pro sur iOS, Roboto sur
/// Android), mais on cadre les tailles, graisses, interlignes et tracking
/// pour un rendu cohérent et premium. Toute nouvelle UI doit piocher ici
/// plutôt que de recoder des `fontSize:` à la main.
///
/// Convention de graisse : titres en `w900` (ton joyeux/affirmé de la marque),
/// corps en `w500/w600`, libellés de bouton en `w800`.
abstract class JauneType {
  /// Très gros chiffres/héros (célébrations, gros compteurs).
  static const display = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    color: JauneColors.ink,
    height: 1.05,
    letterSpacing: -0.5,
  );

  /// Titre d'écran plein page / onboarding.
  static const title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: JauneColors.ink,
    height: 1.15,
    letterSpacing: -0.3,
  );

  /// Titre de section (en-tête de carte, titre de sheet).
  static const heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: JauneColors.ink,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// Sous-titre / titre de ligne mis en avant.
  static const subhead = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: JauneColors.ink,
    height: 1.25,
  );

  /// Corps de texte courant.
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: JauneColors.inkSoft,
    height: 1.45,
  );

  /// Libellé de bouton principal.
  static const button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: 0.2,
  );

  /// Petit libellé / légende / métadonnée.
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: JauneColors.inkSoft,
    height: 1.35,
  );
}

/// Espacements standard (multiples de 4) — un seul rythme vertical/horizontal.
abstract class JauneSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Ombres standard — au lieu de recoder des `BoxShadow` à la main partout.
abstract class JauneShadows {
  /// Ombre douce pour cartes/pastilles posées sur fond clair.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 3),
      blurRadius: 8,
    ),
  ];

  /// Ombre teintée pour un élément coloré qui « flotte » (CTA citron/ciel).
  static List<BoxShadow> tinted(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.45),
      offset: const Offset(0, 6),
      blurRadius: 16,
    ),
  ];
}
