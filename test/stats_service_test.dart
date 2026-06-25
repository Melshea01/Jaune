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

  group('hpTrajectory', () {
    test('historique >30j : fenêtre plafonnée à [days] points, bornés [0,100]', () {
      final map = mapOf({
        DateTime(2026, 6, 6): 8, // un binge isolé
        DateTime(2026, 6, 10): 3,
      });
      // Première utilisation bien antérieure à la fenêtre de 30 jours.
      final traj = StatsService.hpTrajectory(map, '2026-04-01', today, days: 30);
      expect(traj.length, 30);
      for (final v in traj) {
        expect(v, inInclusiveRange(0.0, 100.0));
      }
    });

    test('fenêtre plus longue que l\'historique : tronquée aux jours dispo', () {
      // Première utilisation seulement 5 jours avant aujourd'hui.
      final map = mapOf({today: 2});
      final firstUse = dateKey(today.subtract(const Duration(days: 4)));
      final traj = StatsService.hpTrajectory(map, firstUse, today, days: 30);
      expect(traj.length, 5); // J-4 → aujourd'hui inclus
      expect(traj.every((v) => v >= 0 && v <= 100), isTrue);
    });

    test('abstinence totale → courbe plate à 100', () {
      final traj = StatsService.hpTrajectory(const {}, '2026-05-01', today, days: 14);
      expect(traj.every((v) => v == 100.0), isTrue);
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

  group('periodComparison', () {
    test('semaine : courante vs précédente', () {
      final map = mapOf({
        DateTime(2026, 6, 8): 1,
        DateTime(2026, 6, 10): 2,
        DateTime(2026, 6, 1): 4,
        DateTime(2026, 6, 7): 3,
      });
      final c = StatsService.periodComparison(map, StatsPeriod.week, today)!;
      expect(c.current, 3);
      expect(c.previous, 7);
    });

    test('mois : juin vs mai', () {
      final map = mapOf({
        DateTime(2026, 6, 5): 2,
        DateTime(2026, 6, 9): 3,
        DateTime(2026, 5, 20): 10,
      });
      final c = StatsService.periodComparison(map, StatsPeriod.month, today)!;
      expect(c.current, 5);
      expect(c.previous, 10);
    });

    test('tout : pas de comparaison', () {
      expect(
        StatsService.periodComparison(const {}, StatsPeriod.all, today),
        isNull,
      );
    });
  });

  group('periodBars', () {
    test('semaine : 7 barres lundi→dimanche, granularité jour', () {
      final map = mapOf({
        DateTime(2026, 6, 8): 1, // lundi
        DateTime(2026, 6, 11): 2, // jeudi (aujourd'hui)
      });
      final r = StatsService.periodBars(map, StatsPeriod.week, today, '');
      expect(r.gran, StatGranularity.day);
      expect(r.bars.length, 7);
      expect(r.bars.first.value, 1);
      expect(r.bars[3].value, 2);
    });

    test('année : mois écoulés uniquement (jan → mois courant)', () {
      final map = mapOf({DateTime(2026, 3, 4): 6});
      final r = StatsService.periodBars(map, StatsPeriod.year, today, '');
      expect(r.gran, StatGranularity.month);
      expect(r.bars.length, 6); // janvier → juin (today = 11 juin)
      expect(r.bars[2].value, 6); // mars
    });
  });

  group('weekdayAverages', () {
    test('moyenne par jour de la semaine depuis la première utilisation', () {
      // Deux mardis (2 et 9 juin) : 4 et 2 verres → moyenne 3 (index 1).
      final map = mapOf({
        DateTime(2026, 6, 2): 4,
        DateTime(2026, 6, 9): 2,
      });
      final avgs = StatsService.weekdayAverages(map, '2026-06-01', today);
      expect(avgs[1], closeTo(3.0, 0.001)); // mardi
    });
  });

  group('totalSoberDays', () {
    test('compte les journées closes sans verre', () {
      // Du 8 au 10 juin suivis ; le 9 a un verre → 2 jours sobres (8 et 10).
      final map = mapOf({DateTime(2026, 6, 9): 3});
      expect(StatsService.totalSoberDays(map, '2026-06-08', today), 2);
    });
  });

  group('hourCounts', () {
    test('répartit les verres par heure sur la plage', () {
      final times = [
        DateTime(2026, 6, 10, 21, 30),
        DateTime(2026, 6, 10, 21, 45),
        DateTime(2026, 6, 11, 9, 0),
        DateTime(2026, 6, 1, 23, 0), // hors plage
      ];
      final h = StatsService.hourCounts(
        times,
        DateTime(2026, 6, 8),
        DateTime(2026, 6, 11),
      );
      expect(h.length, 24);
      expect(h[21], 2);
      expect(h[9], 1);
      expect(h[23], 0); // le 1er juin est hors plage
    });
  });

  group('periodBars all', () {
    test('historique court (<= 1 mois) : granularité jour', () {
      final map = mapOf({DateTime(2026, 6, 9): 3});
      final r = StatsService.periodBars(
        map,
        StatsPeriod.all,
        today,
        '2026-06-08',
      );
      expect(r.gran, StatGranularity.day);
      expect(r.bars.length, 4); // 8, 9, 10, 11
      expect(r.bars[1].value, 3); // le 9
    });
  });

  group('computeInsight', () {
    test('met en avant le record de série en cours', () {
      // Première utilisation = aujourd'hui → aucun jour clos, donc le record
      // historique vaut 0 et la série en cours (12) devient le record.
      final insight = StatsService.computeInsight(
        dailyMap: const {},
        firstUseDate: '2026-06-11',
        today: today,
        period: StatsPeriod.week,
        currentStreak: 12,
      );
      expect(insight.kind, StatInsightKind.bestStreak);
      expect(insight.value, 12);
    });
  });
}
