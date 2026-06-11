import 'dart:math' as math;

import '../utils/date_keys.dart';

/// Calculs de statistiques — fonctions pures sur la map { date → verres },
/// testables sans plateforme. La présentation vit dans stats_sheet.dart.
abstract class StatsService {
  /// Consommations des 7 derniers jours, du plus ancien à aujourd'hui
  static List<int> last7Days(Map<String, int> dailyMap, DateTime today) {
    final DateTime day0 = DateTime(today.year, today.month, today.day);
    return List.generate(7, (i) {
      final d = day0.subtract(Duration(days: 6 - i));
      return dailyMap[dateKey(d)] ?? 0;
    });
  }

  static DateTime mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  /// Total d'une semaine commençant le [monday]
  static int weekTotal(Map<String, int> dailyMap, DateTime monday) {
    int total = 0;
    for (int i = 0; i < 7; i++) {
      total += dailyMap[dateKey(monday.add(Duration(days: i)))] ?? 0;
    }
    return total;
  }

  /// Semaine en cours vs semaine précédente (totaux)
  static ({int thisWeek, int lastWeek}) weekComparison(
    Map<String, int> dailyMap,
    DateTime today,
  ) {
    final monday = mondayOf(today);
    return (
      thisWeek: weekTotal(dailyMap, monday),
      lastWeek: weekTotal(dailyMap, monday.subtract(const Duration(days: 7))),
    );
  }

  /// Plus longue série de jours sobres consécutifs depuis la première
  /// utilisation (journées closes uniquement : aujourd'hui non compté)
  static int longestSoberStreak(
    Map<String, int> dailyMap,
    String firstUseDate,
    DateTime today,
  ) {
    if (firstUseDate.isEmpty) return 0;
    final DateTime? first = DateTime.tryParse(firstUseDate);
    if (first == null) return 0;

    final DateTime day0 = DateTime(today.year, today.month, today.day);
    int best = 0;
    int current = 0;
    DateTime d = DateTime(first.year, first.month, first.day);
    while (d.isBefore(day0)) {
      if ((dailyMap[dateKey(d)] ?? 0) == 0) {
        current++;
        best = math.max(best, current);
      } else {
        current = 0;
      }
      d = d.add(const Duration(days: 1));
    }
    return best;
  }

  /// Total de la semaine complète (lundi → dimanche close) la plus légère.
  /// null si aucune semaine complète n'est couverte par les données.
  static int? lightestFullWeekTotal(
    Map<String, int> dailyMap,
    String firstUseDate,
    DateTime today,
  ) {
    if (firstUseDate.isEmpty) return null;
    final DateTime? first = DateTime.tryParse(firstUseDate);
    if (first == null) return null;

    // Première semaine entièrement couverte : le lundi suivant (ou égal à)
    // la première utilisation
    DateTime monday = mondayOf(first);
    if (monday.isBefore(DateTime(first.year, first.month, first.day))) {
      monday = monday.add(const Duration(days: 7));
    }
    final DateTime currentMonday = mondayOf(today);

    int? best;
    while (monday.isBefore(currentMonday)) {
      final int total = weekTotal(dailyMap, monday);
      if (best == null || total < best) best = total;
      monday = monday.add(const Duration(days: 7));
    }
    return best;
  }

  /// Verres « évités » : écart entre le rythme des 4 premières semaines
  /// (la baseline de l'utilisateur) et sa consommation réelle depuis.
  /// null tant que la baseline n'est pas établie (< 5 semaines de recul).
  static int? drinksAvoided(
    Map<String, int> dailyMap,
    String firstUseDate,
    DateTime today,
  ) {
    if (firstUseDate.isEmpty) return null;
    final DateTime? first = DateTime.tryParse(firstUseDate);
    if (first == null) return null;

    final DateTime firstDay = DateTime(first.year, first.month, first.day);
    final DateTime day0 = DateTime(today.year, today.month, today.day);
    final int daysSinceStart = day0.difference(firstDay).inDays;
    if (daysSinceStart < 35) return null;

    int baselineTotal = 0;
    for (int i = 0; i < 28; i++) {
      baselineTotal += dailyMap[dateKey(firstDay.add(Duration(days: i)))] ?? 0;
    }
    final double baselinePerDay = baselineTotal / 28.0;

    final DateTime afterBaseline = firstDay.add(const Duration(days: 28));
    final int daysSince = day0.difference(afterBaseline).inDays;
    int actual = 0;
    for (int i = 0; i < daysSince; i++) {
      actual += dailyMap[dateKey(afterBaseline.add(Duration(days: i)))] ?? 0;
    }

    final int avoided = (baselinePerDay * daysSince - actual).round();
    return math.max(0, avoided);
  }
}
