import 'dart:async';

import 'package:flutter/services.dart';

import '../services/settings_service.dart';

/// Patterns haptiques séquencés réutilisables — un seul langage tactile.
/// Règle : un impact isolé pour les actions, une séquence décroissante
/// pour les célébrations (l'écho physique du moment qui retombe).
///
/// **Point de passage unique** de tout l'haptique : chaque méthode respecte
/// le réglage `hapticsEnabled` (toggle « Vibrations » des réglages). Ne PAS
/// appeler `HapticFeedback.*` directement ailleurs — passer par ici, sinon la
/// vibration échappe au réglage.
abstract class JauneHaptics {
  static bool get _on => SettingsService.instance.hapticsEnabled.value;

  // --- Impacts simples (gated) ---
  static void light() {
    if (_on) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_on) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_on) HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (_on) HapticFeedback.selectionClick();
  }

  // --- Patterns séquencés (gated) ---

  /// Level-up, gros moments : heavy → medium → light en cascade
  static void celebrate() {
    if (!_on) return;
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    Timer(const Duration(milliseconds: 200), HapticFeedback.lightImpact);
  }

  /// Palier de streak, badge : double tap medium
  static void milestone() {
    if (!_on) return;
    HapticFeedback.mediumImpact();
    Timer(const Duration(milliseconds: 90), HapticFeedback.lightImpact);
  }

  /// Micro-feedback (équiper un skin, sélection) : un seul clic
  static void tick() {
    if (_on) HapticFeedback.selectionClick();
  }
}
