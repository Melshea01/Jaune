import 'dart:math' as math;

import '../utils/date_keys.dart';
import 'jaune_health_model.dart';

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

  /// Trajectoire des PV « santé de fond » via [JauneHealthModel], pour la
  /// courbe d'évolution. Du plus ancien à aujourd'hui, au plus [days] points.
  ///
  /// La simulation démarre à la première utilisation (et non au début de la
  /// fenêtre affichée) : l'équilibre est ainsi déjà convergé sur le segment
  /// montré, et on n'invente jamais de santé pour la période d'avant l'app.
  /// Un utilisateur récent obtient donc une courbe plus courte (honnête), qui
  /// s'allonge jusqu'à [days] points à mesure que l'historique grandit.
  static List<double> hpTrajectory(
    Map<String, int> dailyMap,
    String firstUseDate,
    DateTime today, {
    int days = 30,
  }) {
    final DateTime day0 = DateTime(today.year, today.month, today.day);

    // Départ de la simulation : première utilisation si connue, sinon le
    // début de la fenêtre affichée.
    final DateTime windowStart = day0.subtract(Duration(days: days - 1));
    DateTime start = windowStart;
    final DateTime? first = DateTime.tryParse(firstUseDate);
    if (first != null) {
      start = DateTime(first.year, first.month, first.day);
    }
    if (start.isAfter(day0)) return const [];

    final int total = day0.difference(start).inDays + 1;
    final history = List<int>.generate(total, (i) {
      return dailyMap[dateKey(start.add(Duration(days: i)))] ?? 0;
    });

    final trajectory =
        JauneHealthModel.simulate(history).map((d) => d.hp).toList();

    // Ne garder que les [days] derniers points (la fenêtre affichée).
    if (trajectory.length <= days) return trajectory;
    return trajectory.sublist(trajectory.length - days);
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

  // =====================================================================
  // Période sélectionnable (semaine / mois / année / tout)
  // =====================================================================

  static DateTime _lastOfMonth(int year, int month) =>
      DateTime(year, month + 1, 0);

  /// Bornes [start, end] (inclusives, à minuit) de la période sélectionnée.
  static ({DateTime start, DateTime end}) periodRange(
    StatsPeriod period,
    DateTime today,
    String firstUseDate,
  ) {
    final d0 = DateTime(today.year, today.month, today.day);
    switch (period) {
      case StatsPeriod.week:
        final mon = mondayOf(d0);
        return (start: mon, end: mon.add(const Duration(days: 6)));
      case StatsPeriod.month:
        return (
          start: DateTime(d0.year, d0.month, 1),
          end: _lastOfMonth(d0.year, d0.month),
        );
      case StatsPeriod.year:
        return (start: DateTime(d0.year, 1, 1), end: DateTime(d0.year, 12, 31));
      case StatsPeriod.all:
        final first = DateTime.tryParse(firstUseDate);
        final start =
            first != null
                ? DateTime(first.year, first.month, first.day)
                : d0;
        return (start: start, end: d0);
    }
  }

  /// Total de verres entre [start] et [end] inclus.
  static int totalInRange(
    Map<String, int> dailyMap,
    DateTime start,
    DateTime end,
  ) {
    int t = 0;
    DateTime d = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(last)) {
      t += dailyMap[dateKey(d)] ?? 0;
      d = d.add(const Duration(days: 1));
    }
    return t;
  }

  /// Jours sobres (0 verre) dans [start, end], en ne comptant que les jours
  /// déjà écoulés (≤ aujourd'hui) et suivis (≥ première utilisation).
  static int soberDaysInRange(
    Map<String, int> dailyMap,
    DateTime start,
    DateTime end,
    DateTime today,
    String firstUseDate,
  ) {
    final d0 = DateTime(today.year, today.month, today.day);
    final first = DateTime.tryParse(firstUseDate);
    DateTime lo = DateTime(start.year, start.month, start.day);
    if (first != null) {
      final f = DateTime(first.year, first.month, first.day);
      if (f.isAfter(lo)) lo = f;
    }
    DateTime hi = DateTime(end.year, end.month, end.day);
    if (hi.isAfter(d0)) hi = d0;
    int sober = 0;
    DateTime cur = lo;
    while (!cur.isAfter(hi)) {
      if ((dailyMap[dateKey(cur)] ?? 0) == 0) sober++;
      cur = cur.add(const Duration(days: 1));
    }
    return sober;
  }

  /// Nombre de jours suivis (écoulés) dans [start, end].
  static int trackedDaysInRange(
    DateTime start,
    DateTime end,
    DateTime today,
    String firstUseDate,
  ) {
    final d0 = DateTime(today.year, today.month, today.day);
    final first = DateTime.tryParse(firstUseDate);
    DateTime lo = DateTime(start.year, start.month, start.day);
    if (first != null) {
      final f = DateTime(first.year, first.month, first.day);
      if (f.isAfter(lo)) lo = f;
    }
    DateTime hi = DateTime(end.year, end.month, end.day);
    if (hi.isAfter(d0)) hi = d0;
    if (hi.isBefore(lo)) return 0;
    return hi.difference(lo).inDays + 1;
  }

  /// Barres du graphe selon la période : jour par jour (semaine/mois) ou mois
  /// par mois (année/tout).
  static ({StatGranularity gran, List<StatBar> bars}) periodBars(
    Map<String, int> dailyMap,
    StatsPeriod period,
    DateTime today,
    String firstUseDate,
  ) {
    final d0 = DateTime(today.year, today.month, today.day);
    switch (period) {
      case StatsPeriod.week:
        final mon = mondayOf(d0);
        return (
          gran: StatGranularity.day,
          bars: List.generate(7, (i) {
            final d = mon.add(Duration(days: i));
            return StatBar(d, dailyMap[dateKey(d)] ?? 0);
          }),
        );
      case StatsPeriod.month:
        final first = DateTime(d0.year, d0.month, 1);
        final n = _lastOfMonth(d0.year, d0.month).day;
        return (
          gran: StatGranularity.day,
          bars: List.generate(n, (i) {
            final d = first.add(Duration(days: i));
            return StatBar(d, dailyMap[dateKey(d)] ?? 0);
          }),
        );
      case StatsPeriod.year:
        // Mois ÉCOULÉS uniquement (jan → mois courant) : pas de mois futurs
        // vides qui donneraient l'illusion de plus de données que « Tout ».
        return (
          gran: StatGranularity.month,
          bars: List.generate(d0.month, (i) {
            final m = DateTime(d0.year, i + 1, 1);
            return StatBar(m, totalInRange(dailyMap, m, _lastOfMonth(m.year, m.month)));
          }),
        );
      case StatsPeriod.all:
        final first = DateTime.tryParse(firstUseDate);
        final startM =
            first != null
                ? DateTime(first.year, first.month, 1)
                : DateTime(d0.year, d0.month, 1);
        final lastM = DateTime(d0.year, d0.month, 1);
        final monthsSpan =
            (lastM.year - startM.year) * 12 + (lastM.month - startM.month) + 1;
        // Historique court (≤ 1 mois) : on détaille au jour, sinon « Tout »
        // n'aurait qu'une seule barre. Au-delà : agrégation mensuelle.
        if (monthsSpan <= 1) {
          final start = first != null
              ? DateTime(first.year, first.month, first.day)
              : DateTime(d0.year, d0.month, 1);
          final n = d0.difference(start).inDays + 1;
          return (
            gran: StatGranularity.day,
            bars: List.generate(n, (i) {
              final d = start.add(Duration(days: i));
              return StatBar(d, dailyMap[dateKey(d)] ?? 0);
            }),
          );
        }
        final bars = <StatBar>[];
        DateTime m = startM;
        while (!m.isAfter(lastM)) {
          bars.add(StatBar(m, totalInRange(dailyMap, m, _lastOfMonth(m.year, m.month))));
          m = DateTime(m.year, m.month + 1, 1);
        }
        return (gran: StatGranularity.month, bars: bars);
    }
  }

  /// Comparaison période courante vs période précédente de même longueur.
  /// null pour [StatsPeriod.all] (pas de période précédente pertinente).
  static ({int current, int previous})? periodComparison(
    Map<String, int> dailyMap,
    StatsPeriod period,
    DateTime today,
  ) {
    final d0 = DateTime(today.year, today.month, today.day);
    switch (period) {
      case StatsPeriod.week:
        final mon = mondayOf(d0);
        return (
          current: weekTotal(dailyMap, mon),
          previous: weekTotal(dailyMap, mon.subtract(const Duration(days: 7))),
        );
      case StatsPeriod.month:
        final cur = DateTime(d0.year, d0.month, 1);
        final prev = DateTime(d0.year, d0.month - 1, 1);
        return (
          current: totalInRange(dailyMap, cur, _lastOfMonth(cur.year, cur.month)),
          previous:
              totalInRange(dailyMap, prev, _lastOfMonth(prev.year, prev.month)),
        );
      case StatsPeriod.year:
        return (
          current: totalInRange(
            dailyMap,
            DateTime(d0.year, 1, 1),
            DateTime(d0.year, 12, 31),
          ),
          previous: totalInRange(
            dailyMap,
            DateTime(d0.year - 1, 1, 1),
            DateTime(d0.year - 1, 12, 31),
          ),
        );
      case StatsPeriod.all:
        return null;
    }
  }

  /// Moyenne de verres par jour de la semaine (0 = lundi … 6 = dimanche), sur
  /// toutes les journées closes depuis la première utilisation.
  static List<double> weekdayAverages(
    Map<String, int> dailyMap,
    String firstUseDate,
    DateTime today,
  ) {
    final first = DateTime.tryParse(firstUseDate);
    if (first == null) return List<double>.filled(7, 0);
    final sums = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    final d0 = DateTime(today.year, today.month, today.day);
    DateTime d = DateTime(first.year, first.month, first.day);
    while (d.isBefore(d0)) {
      final wd = d.weekday - 1; // 0 = lundi
      sums[wd] += dailyMap[dateKey(d)] ?? 0;
      counts[wd]++;
      d = d.add(const Duration(days: 1));
    }
    return List<double>.generate(7, (i) => counts[i] == 0 ? 0 : sums[i] / counts[i]);
  }

  /// Répartition des verres par heure (0–23) sur [start, end] inclus, à partir
  /// des horodatages des verres. Sert au cadran 24h.
  static List<int> hourCounts(
    List<DateTime> times,
    DateTime start,
    DateTime end,
  ) {
    final counts = List<int>.filled(24, 0);
    final lo = DateTime(start.year, start.month, start.day);
    final hi = DateTime(end.year, end.month, end.day, 23, 59, 59);
    for (final t in times) {
      if (!t.isBefore(lo) && !t.isAfter(hi)) counts[t.hour]++;
    }
    return counts;
  }

  /// Total de jours sobres depuis la première utilisation (journées closes).
  static int totalSoberDays(
    Map<String, int> dailyMap,
    String firstUseDate,
    DateTime today,
  ) {
    final first = DateTime.tryParse(firstUseDate);
    if (first == null) return 0;
    final d0 = DateTime(today.year, today.month, today.day);
    int sober = 0;
    DateTime d = DateTime(first.year, first.month, first.day);
    while (d.isBefore(d0)) {
      if ((dailyMap[dateKey(d)] ?? 0) == 0) sober++;
      d = d.add(const Duration(days: 1));
    }
    return sober;
  }

  /// Choisit l'insight le plus marquant à mettre en avant. La présentation
  /// (texte localisé) se fait côté UI à partir du [StatInsightKind] + valeur.
  static StatInsight computeInsight({
    required Map<String, int> dailyMap,
    required String firstUseDate,
    required DateTime today,
    required StatsPeriod period,
    required int currentStreak,
  }) {
    final cmp = periodComparison(dailyMap, period, today);
    if (cmp != null && cmp.previous > 0 && cmp.current < cmp.previous) {
      final pct = ((cmp.previous - cmp.current) * 100 / cmp.previous).round();
      if (pct >= 10) return StatInsight(StatInsightKind.trendDown, pct);
    }
    final longest = longestSoberStreak(dailyMap, firstUseDate, today);
    if (currentStreak >= 3 && currentStreak >= longest) {
      return StatInsight(StatInsightKind.bestStreak, currentStreak);
    }
    final range = periodRange(period, today, firstUseDate);
    final tracked =
        trackedDaysInRange(range.start, range.end, today, firstUseDate);
    if (tracked >= 3) {
      final sober = soberDaysInRange(
        dailyMap,
        range.start,
        range.end,
        today,
        firstUseDate,
      );
      final rate = (sober * 100 / tracked).round();
      if (rate >= 50) return StatInsight(StatInsightKind.soberRate, rate);
    }
    if (cmp != null && cmp.previous > 0 && cmp.current > cmp.previous) {
      final pct = ((cmp.current - cmp.previous) * 100 / cmp.previous).round();
      return StatInsight(StatInsightKind.trendUp, pct);
    }
    final wk = weekdayAverages(dailyMap, firstUseDate, today);
    double maxV = -1;
    int maxI = 0;
    for (int i = 0; i < 7; i++) {
      if (wk[i] > maxV) {
        maxV = wk[i];
        maxI = i;
      }
    }
    if (maxV > 0) return StatInsight(StatInsightKind.worstWeekday, maxI);
    return const StatInsight(StatInsightKind.gettingStarted, 0);
  }
}

/// Période d'analyse sélectionnable dans l'écran de statistiques.
enum StatsPeriod { week, month, year, all }

/// Granularité des barres du graphe principal selon la période.
enum StatGranularity { day, month }

/// Une barre du graphe : la date de début du bucket et sa valeur (verres).
class StatBar {
  final DateTime date;
  final int value;
  const StatBar(this.date, this.value);
}

/// Type d'insight mis en avant dans la carte du haut des statistiques.
enum StatInsightKind {
  trendDown,
  trendUp,
  bestStreak,
  soberRate,
  worstWeekday,
  gettingStarted,
}

/// Insight calculé : un [StatInsightKind] et une valeur associée (pourcentage,
/// nombre de jours, ou index de jour de la semaine selon le kind).
class StatInsight {
  final StatInsightKind kind;
  final int value;
  const StatInsight(this.kind, this.value);
}
