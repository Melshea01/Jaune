import 'package:flutter/foundation.dart';

import '../l10n/gen/app_localizations.dart';
import 'character_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

/// Notifications de rétention au-delà du rappel apéro : paliers de streak
/// et teaser de level-up. Philosophie du scheduler déterministe existant :
/// chaque évaluation annule puis re-planifie — idempotent, jamais d'état
/// incohérent si l'utilisateur boit après coup (le palier saute, la notif
/// aussi).
abstract class MilestoneScheduler {
  static const List<int> streakMilestones = [3, 7, 30, 100];

  /// Palier atteint DEMAIN matin si la journée reste sobre : le streak est
  /// dérivé d'hier, donc demain il vaudra `currentStreak + 1` ssi
  /// aujourd'hui finit à 0 verre.
  @visibleForTesting
  static int? upcomingStreakMilestone({
    required int currentStreak,
    required int todayDrinks,
  }) {
    if (todayDrinks > 0) return null;
    final int tomorrow = currentStreak + 1;
    return streakMilestones.contains(tomorrow) ? tomorrow : null;
  }

  /// Teaser de level-up : assez proche pour qu'une journée sobre suffise
  @visibleForTesting
  static bool shouldTeaseLevelUp(double levelProgress) => levelProgress >= 0.8;

  /// Série « en jeu » : à partir de 2 jours, une série méritée vaut la peine
  /// d'un rappel doux le soir tant que la journée est encore sobre. Levier de
  /// rétention #1 (peur de perdre sa série) — ton encourageant, jamais culpa-
  /// bilisant. Ne se déclenche que si l'on est avant l'heure du rappel.
  static const int kStreakRiskThreshold = 2;

  /// Heure du rappel « série en jeu » : ce soir 21h.
  @visibleForTesting
  static DateTime streakRiskNotificationTime(DateTime now) =>
      DateTime(now.year, now.month, now.day, 21);

  @visibleForTesting
  static bool shouldRemindStreakRisk({
    required int currentStreak,
    required int todayDrinks,
    required DateTime now,
  }) {
    if (todayDrinks > 0) return false;
    if (currentStreak < kStreakRiskThreshold) return false;
    // Avant 21h seulement : sinon le rappel du soir serait déjà passé.
    return now.isBefore(streakRiskNotificationTime(now));
  }

  /// Heure de la notification de palier : demain 10h (le streak est alors
  /// acquis — il se calcule sur les journées closes)
  @visibleForTesting
  static DateTime streakNotificationTime(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1, 10);

  /// Teaser de niveau : demain midi, après le rappel du matin
  @visibleForTesting
  static DateTime teaserNotificationTime(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1, 12);

  /// À appeler après chaque recalcul de santé et à l'ouverture de l'app.
  static Future<void> evaluate({
    required CharacterService character,
    required int todayDrinks,
  }) async {
    try {
      // Idempotence : on repart toujours d'une ardoise vide
      await NotificationService.cancelNotification(kStreakNotifId);
      await NotificationService.cancelNotification(kLevelTeaserNotifId);
      await NotificationService.cancelNotification(kStreakRiskNotifId);

      if (!SettingsService.instance.notificationsEnabled.value) return;

      final l10n = lookupAppLocalizations(
        SettingsService.instance.effectiveLocale,
      );
      final now = DateTime.now();

      final int? milestone = upcomingStreakMilestone(
        currentStreak: character.soberStreakDays,
        todayDrinks: todayDrinks,
      );
      if (milestone != null) {
        await NotificationService.scheduleNotification(
          id: kStreakNotifId,
          scheduledTime: streakNotificationTime(now),
          title: l10n.notifStreakTitle(milestone),
          body: l10n.notifStreakBody,
        );
      }

      // Rappel « série en jeu » ce soir (n'entre pas en conflit avec le palier
      // de demain matin : c'est le même streak vu sous deux angles temporels).
      if (shouldRemindStreakRisk(
        currentStreak: character.soberStreakDays,
        todayDrinks: todayDrinks,
        now: now,
      )) {
        await NotificationService.scheduleNotification(
          id: kStreakRiskNotifId,
          scheduledTime: streakRiskNotificationTime(now),
          title: l10n.notifStreakRiskTitle(character.soberStreakDays),
          body: l10n.notifStreakRiskBody,
        );
      }

      if (shouldTeaseLevelUp(character.levelProgress)) {
        final int xpRemaining =
            character.xpToNextLevel - character.profile.xp;
        await NotificationService.scheduleNotification(
          id: kLevelTeaserNotifId,
          scheduledTime: teaserNotificationTime(now),
          title: l10n.notifLevelTeaserTitle(character.level + 1),
          body: l10n.notifLevelTeaserBody(xpRemaining),
        );
      }
    } catch (e) {
      debugPrint('Error evaluating milestone notifications: $e');
    }
  }
}
