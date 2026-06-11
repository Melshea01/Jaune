import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'deterministic_scheduler.dart';

/// Pousse l'état du citron vers le widget d'écran d'accueil iOS via
/// l'App Group. Sans extension installée (ou sans App Group configuré),
/// chaque appel échoue silencieusement : zéro impact sur l'app.
///
/// L'extension Swift vit dans ios/JauneWidget/ — voir le README de ce
/// dossier pour le branchement Xcode (target + App Group).
abstract class HomeWidgetService {
  static const String appGroupId = 'group.com.jaune.app';
  static const String iosWidgetName = 'JauneWidget';

  static bool _initialized = false;

  /// Humeur sérialisée pour SwiftUI — mêmes seuils que les presets
  /// d'animation (la couleur et l'émotion changent ensemble partout)
  static String moodFor(double healthPercent) {
    if (healthPercent >= 0.90) return 'superHappy';
    if (healthPercent >= 0.75) return 'happy';
    if (healthPercent >= 0.50) return 'neutral';
    if (healthPercent >= 0.25) return 'tired';
    if (healthPercent > 0) return 'sick';
    return 'dead';
  }

  static Future<void> sync({
    required double healthPercent,
    required int streakDays,
    required int level,
  }) async {
    try {
      if (!_initialized) {
        await HomeWidget.setAppGroupId(appGroupId);
        _initialized = true;
      }

      final aperoTime =
          DeterministicNotificationScheduler.getNextNotificationTime();

      await HomeWidget.saveWidgetData<String>(
        'mood',
        moodFor(healthPercent),
      );
      await HomeWidget.saveWidgetData<int>(
        'health',
        (healthPercent * 100).round(),
      );
      await HomeWidget.saveWidgetData<int>('streak', streakDays);
      await HomeWidget.saveWidgetData<int>('level', level);
      await HomeWidget.saveWidgetData<String>(
        'aperoTime',
        '${aperoTime.hour.toString().padLeft(2, '0')}:'
        '${aperoTime.minute.toString().padLeft(2, '0')}',
      );

      await HomeWidget.updateWidget(iOSName: iosWidgetName);
    } catch (e) {
      // Extension absente / App Group non configuré : dégradation propre
      debugPrint('Home widget sync skipped: $e');
    }
  }
}
