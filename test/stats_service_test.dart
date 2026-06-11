import 'package:flutter_test/flutter_test.dart';

import 'package:jaune/services/stats_service.dart';
import 'package:jaune/utils/date_keys.dart';

void main() {
  // Mercredi 11 juin 2026
  final today = DateTime(2026, 6, 11);

  Map<String, int> mapOf(Map<DateTime, int> entries) =>
      entries.map((d, v) => MapEntry(dateKey(d), v));

  group('last7Days', () {
    test('retourne les 7 derniers jours, zéros par défaut', () {
      final map = mapOf({
        DateTime(2026, 6, 11): 2,
        DateTime(2026, 6, 9): 5,
        DateTime(2026, 6, 4): 99, // hors fenêtre (J-7)
      });
      expect(StatsService.last7Days(map, today), [0, 0, 0, 0, 5, 0, 2]);
    });
  });

  group('weekComparison', () {
    test('compare la semaine en cours (lun 8 juin) à la précédente', () {
      final map = mapOf({
        DateTime(2026, 6, 8): 1, // lundi semaine en cours
        DateTime(2026, 6, 10): 2,
        DateTime(2026, 6, 1): 4, // lundi semaine précédente
        DateTime(2026, 6, 7): 3, // dimanche semaine précédente
      });
      final c = StatsService.weekComparison(map, today);
      expect(c.thisWeek, 3);
      expect(c.lastWeek, 7);
    });
  });

  group('longestSoberStreak', () {
    test('trouve la plus longue série close', () {
      // Première utilisation le 1er juin ; verres les 3 et 8 juin.
      // Séries sobres closes : 1-2 (2 j), 4-7 (4 j), 9-10 (2 j).
      final map = mapOf({
        DateTime(2026, 6, 3): 2,
        DateTime(2026, 6, 8): 1,
      });
      expect(StatsService.longestSoberStreak(map, '2026-06-01', today), 4);
    });

    test('zéro sans date de première utilisation', () {
      expect(StatsService.longestSoberStreak({}, '', today), 0);
    });
  });

  group('lightestFullWeekTotal', () {
    test('null sans semaine complète couverte', () {
      expect(
        StatsService.lightestFullWeekTotal({}, '2026-06-09', today),
        isNull,
      );
    });

    test('prend la semaine complète la plus légère', () {
      // Première utilisation lundi 18 mai → semaines complètes closes :
      // 18-24 mai (3 verres), 25-31 mai (1), 1-7 juin (6)
      final map = mapOf({
        DateTime(2026, 5, 20): 3,
        DateTime(2026, 5, 28): 1,
        DateTime(2026, 6, 2): 6,
      });
      expect(
        StatsService.lightestFullWeekTotal(map, '2026-05-18', today),
        1,
      );
    });
  });

  group('drinksAvoided', () {
    test('null avant 5 semaines de recul', () {
      expect(StatsService.drinksAvoided({}, '2026-05-20', today), isNull);
    });

    test('écart positif vs la baseline des 4 premières semaines', () {
      // Première utilisation le 1er avril. Baseline (1-28 avril) :
      // 28 verres → 1/jour. Depuis le 29 avril (43 jours au 11 juin) :
      // 13 verres réels → 43 - 13 = 30 évités.
      final map = <String, int>{};
      for (int i = 0; i < 28; i++) {
        map[dateKey(DateTime(2026, 4, 1).add(Duration(days: i)))] = 1;
      }
      for (int i = 0; i < 13; i++) {
        map[dateKey(DateTime(2026, 4, 29).add(Duration(days: i)))] = 1;
      }
      expect(StatsService.drinksAvoided(map, '2026-04-01', today), 30);
    });

    test('jamais négatif', () {
      // Baseline sobre puis grosse dérive : clampé à 0
      final map = <String, int>{
        dateKey(DateTime(2026, 6, 1)): 50,
      };
      expect(StatsService.drinksAvoided(map, '2026-04-01', today), 0);
    });
  });
}
