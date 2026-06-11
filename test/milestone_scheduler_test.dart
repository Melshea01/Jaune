import 'package:flutter_test/flutter_test.dart';

import 'package:jaune/services/milestone_scheduler.dart';

void main() {
  group('upcomingStreakMilestone', () {
    test('palier 3 atteint demain si streak=2 et journée sobre', () {
      expect(
        MilestoneScheduler.upcomingStreakMilestone(
          currentStreak: 2,
          todayDrinks: 0,
        ),
        3,
      );
    });

    test('palier 7 atteint demain si streak=6 et journée sobre', () {
      expect(
        MilestoneScheduler.upcomingStreakMilestone(
          currentStreak: 6,
          todayDrinks: 0,
        ),
        7,
      );
    });

    test('pas de notification si un verre a été bu aujourd\'hui', () {
      expect(
        MilestoneScheduler.upcomingStreakMilestone(
          currentStreak: 6,
          todayDrinks: 1,
        ),
        isNull,
      );
    });

    test('pas de notification hors palier', () {
      expect(
        MilestoneScheduler.upcomingStreakMilestone(
          currentStreak: 4,
          todayDrinks: 0,
        ),
        isNull,
      );
      expect(
        MilestoneScheduler.upcomingStreakMilestone(
          currentStreak: 0,
          todayDrinks: 0,
        ),
        isNull,
      );
    });
  });

  group('shouldTeaseLevelUp', () {
    test('teaser à partir de 80% de progression', () {
      expect(MilestoneScheduler.shouldTeaseLevelUp(0.8), isTrue);
      expect(MilestoneScheduler.shouldTeaseLevelUp(0.95), isTrue);
      expect(MilestoneScheduler.shouldTeaseLevelUp(0.79), isFalse);
      expect(MilestoneScheduler.shouldTeaseLevelUp(0.0), isFalse);
    });
  });

  group('horaires de notification', () {
    test('palier de streak : demain 10h', () {
      final now = DateTime(2026, 6, 11, 21, 30);
      final when = MilestoneScheduler.streakNotificationTime(now);
      expect(when, DateTime(2026, 6, 12, 10));
    });

    test('teaser de niveau : demain 12h, gère la fin de mois', () {
      final now = DateTime(2026, 6, 30, 23, 0);
      final when = MilestoneScheduler.teaserNotificationTime(now);
      expect(when, DateTime(2026, 7, 1, 12));
    });
  });
}
