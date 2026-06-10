import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class DeterministicNotificationScheduler {
  /// Génère une heure déterministe (17h-20h) basée sur la date du jour
  /// Utilise SHA-256 pour un hash déterministe synchronisé entre appareils
  static DateTime _getNotificationTimeForDate(DateTime date) {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final bytes = utf8.encode(dateString);
    final digest = sha256.convert(bytes);

    // Utilise les 4 premiers octets pour l'heure et les 4 suivants pour la minute
    // pour une meilleure distribution.
    final hourData = Uint8List.fromList(digest.bytes.sublist(0, 4));
    final minuteData = Uint8List.fromList(digest.bytes.sublist(4, 8));

    final hourHash = hourData.buffer.asByteData().getUint32(0);
    final minuteHash = minuteData.buffer.asByteData().getUint32(0);

    // Génère l'heure : 17h + (hash % 4 heures), minute 0..59
    final hour = 17 + (hourHash % 4); // 17, 18, 19, 20
    final minute = minuteHash % 60;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime getNotificationTime() {
    return _getNotificationTimeForDate(DateTime.now());
  }

  static DateTime getNextNotificationTime() {
    final now = DateTime.now();
    final todayNotification = getNotificationTime();

    if (todayNotification.isAfter(now)) {
      return todayNotification;
    }

    // Si l'heure d'aujourd'hui est passée, calculer pour demain
    final tomorrow = now.add(const Duration(days: 1));
    return _getNotificationTimeForDate(tomorrow);
  }

  /// Vérifie si c'est l'heure de notifier maintenant (dans la même minute)
  static bool shouldNotifyNow() {
    final scheduledTime = getNotificationTime();
    final now = DateTime.now();

    return now.hour == scheduledTime.hour && now.minute == scheduledTime.minute;
  }

  /// Retourne le temps jusqu'à la prochaine notification
  static Duration timeUntilNotification() {
    final scheduledTime = getNextNotificationTime();
    final now = DateTime.now();

    final diff = scheduledTime.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Vérifie si la notification a déjà été envoyée aujourd'hui
  static bool isNotificationSentToday(DateTime? lastSent) {
    if (lastSent == null) return false;

    final today = DateTime.now();
    final lastSentDate = DateTime(lastSent.year, lastSent.month, lastSent.day);

    return lastSentDate.isAtSameMomentAs(
      DateTime(today.year, today.month, today.day),
    );
  }

  /// Vérifie si on est dans la fenetre "apero" du jour
  static bool isWithinAperoWindow({
    Duration window = const Duration(hours: 2),
  }) {
    final now = DateTime.now();
    final start = getNotificationTime();
    final end = start.add(window);
    return !now.isBefore(start) && !now.isAfter(end);
  }
}
