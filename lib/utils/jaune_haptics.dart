import 'dart:async';

import 'package:flutter/services.dart';

/// Patterns haptiques séquencés réutilisables — un seul langage tactile.
/// Règle : un impact isolé pour les actions, une séquence décroissante
/// pour les célébrations (l'écho physique du moment qui retombe).
abstract class JauneHaptics {
  /// Level-up, gros moments : heavy → medium → light en cascade
  static void celebrate() {
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    Timer(const Duration(milliseconds: 200), HapticFeedback.lightImpact);
  }

  /// Palier de streak, badge : double tap medium
  static void milestone() {
    HapticFeedback.mediumImpact();
    Timer(const Duration(milliseconds: 90), HapticFeedback.lightImpact);
  }

  /// Micro-feedback (équiper un skin, sélection) : un seul clic
  static void tick() {
    HapticFeedback.selectionClick();
  }
}
