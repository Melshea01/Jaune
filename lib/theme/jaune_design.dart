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
