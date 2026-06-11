import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences utilisateur persistées (langue, notifications, sons).
/// Singleton chargé dans main() avant runApp.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const String _kLocaleKey = 'locale_override';
  static const String _kNotificationsKey = 'notifications_enabled';
  static const String _kSoundKey = 'sound_enabled';

  /// null = suivre la langue du système
  final ValueNotifier<ui.Locale?> localeOverride = ValueNotifier<ui.Locale?>(
    null,
  );
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> soundEnabled = ValueNotifier<bool>(true);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? code = prefs.getString(_kLocaleKey);
      localeOverride.value = code == null ? null : ui.Locale(code);
      notificationsEnabled.value = prefs.getBool(_kNotificationsKey) ?? true;
      soundEnabled.value = prefs.getBool(_kSoundKey) ?? true;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setLocaleOverride(ui.Locale? locale) async {
    localeOverride.value = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_kLocaleKey);
      } else {
        await prefs.setString(_kLocaleKey, locale.languageCode);
      }
    } catch (e) {
      debugPrint('Error saving locale override: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled.value = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kNotificationsKey, enabled);
    } catch (e) {
      debugPrint('Error saving notifications setting: $e');
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled.value = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSoundKey, enabled);
    } catch (e) {
      debugPrint('Error saving sound setting: $e');
    }
  }

  /// Locale effective de l'app, résolue contre les langues supportées —
  /// utilisée hors arbre de widgets (notifications planifiées, messages
  /// du citron chargés avant le premier build).
  ui.Locale get effectiveLocale {
    final override = localeOverride.value;
    if (override != null) return override;
    final system = ui.PlatformDispatcher.instance.locale;
    return system.languageCode == 'fr'
        ? const ui.Locale('fr')
        : const ui.Locale('en');
  }
}
