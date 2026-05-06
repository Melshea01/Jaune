import 'dart:convert';
import 'package:crypto/crypto.dart';

class DeterministicNotificationScheduler {
  /// Génère une heure déterministe (17h-20h) basée sur la date du jour
  /// Utilise SHA-256 pour un hash déterministe synchronisé entre appareils
  static DateTime _getNotificationTimeForDate(DateTime date) {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Hash SHA-256 de la date
    final hash = sha256.convert(utf8.encode(dateString));
    final hashValue = hash.bytes.fold<int>(0, (a, b) => a ^ b);

    // Génère l'heure : 17h + (hashValue % 3 heures), minute 0..59
    final hour = 17 + (hashValue.abs() % 3);
    final minute = (hashValue.abs() ~/ 3) % 60;

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

    return lastSentDate.isAtSameMomentAs(DateTime(today.year, today.month, today.day));
  }
}