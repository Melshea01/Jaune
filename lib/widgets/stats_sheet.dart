import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/audio_service.dart';
import '../services/character_service.dart';
import '../services/stats_service.dart';
import '../theme/jaune_design.dart';

/// Bottom sheet de statistiques : graphe des 7 derniers jours, tendance
/// semaine vs semaine, records et verres évités. Tout est calculé par
/// StatsService (fonctions pures) à partir de la map des consommations.
class StatsSheet {
  static void show(
    BuildContext context, {
    required Map<String, int> dailyMap,
    required CharacterService character,
  }) {
    HapticFeedback.selectionClick();
    AudioService.instance.playUiPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _StatsSheetContent(dailyMap: dailyMap, character: character),
    );
  }
}

class _StatsSheetContent extends StatelessWidget {
  final Map<String, int> dailyMap;
  final CharacterService character;

  const _StatsSheetContent({required this.dailyMap, required this.character});

  /// Mêmes paliers de couleur que le calendrier : ≤2 modéré, ≤4 attention,
  /// ≤5 limite, ≥6 binge — l'app raconte partout la même histoire
  static Color _barColor(int count) {
    if (count == 0) return JauneColors.healthVibrant.first;
    if (count <= 2) return Colors.green.shade600;
    if (count <= 4) return Colors.yellow.shade700;
    if (count <= 5) return Colors.deepOrange.shade600;
    return Colors.redAccent.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();

    final List<int> week = StatsService.last7Days(dailyMap, now);
    final List<double> healthTrend = StatsService.hpTrajectory(
      dailyMap,
      character.profile.firstUseDate,
      now,
    );
    final comparison = StatsService.weekComparison(dailyMap, now);
    final int longestStreak = StatsService.longestSoberStreak(
      dailyMap,
      character.profile.firstUseDate,
      now,
    );
    final int? lightestWeek = StatsService.lightestFullWeekTotal(
      dailyMap,
      character.profile.firstUseDate,
      now,
    );
    final int? avoided = StatsService.drinksAvoided(
      dailyMap,
      character.profile.firstUseDate,
      now,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(JauneRadii.sheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      l10n.statsTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: JauneColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Graphe 7 jours ---
                  _SectionTitle(l10n.statsLast7Days),
                  const SizedBox(height: 12),
                  _WeekChart(
                    values: week,
                    locale: locale,
                    now: now,
                    barColor: _barColor,
                  ),
                  const SizedBox(height: 24),

                  // --- Courbe de santé de fond (PV) ---
                  _SectionTitle(l10n.statsHealthTrend),
                  const SizedBox(height: 4),
                  Text(
                    l10n.statsHealthTrendHint,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: JauneColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _HealthCurve(values: healthTrend),
                  const SizedBox(height: 24),

                  // --- Tendance semaine vs semaine ---
                  _TrendCard(
                    l10n: l10n,
                    thisWeek: comparison.thisWeek,
                    lastWeek: comparison.lastWeek,
                  ),

                  // --- Records ---
                  const SizedBox(height: 24),
                  _SectionTitle(l10n.statsRecords),
                  const SizedBox(height: 10),
                  _RecordRow(
                    emoji: '🔥',
                    label: l10n.statsLongestStreak,
                    value: l10n.daysCount(longestStreak),
                  ),
                  if (lightestWeek != null) ...[
                    const SizedBox(height: 10),
                    _RecordRow(
                      emoji: '🪶',
                      label: l10n.statsLightestWeek,
                      value: l10n.statsDrinksCount(lightestWeek),
                    ),
                  ],

                  // --- Verres évités ---
                  if (avoided != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            JauneColors.lemon.withValues(alpha: 0.25),
                            JauneColors.lemonDeep.withValues(alpha: 0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(JauneRadii.card),
                        border: Border.all(
                          color: JauneColors.lemonDeep.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🍋 $avoided',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: JauneColors.ink,
                            ),
                          ),
                          Text(
                            l10n.statsDrinksAvoided,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: JauneColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.statsAvoidedHint,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: JauneColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: JauneColors.ink,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Graphe en barres des 7 derniers jours — les hauteurs s'animent à
/// l'ouverture, les couleurs suivent les paliers du calendrier
class _WeekChart extends StatelessWidget {
  final List<int> values;
  final String locale;
  final DateTime now;
  final Color Function(int) barColor;

  const _WeekChart({
    required this.values,
    required this.locale,
    required this.now,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final int maxValue = values.fold(1, (m, v) => v > m ? v : m);
    const double chartHeight = 110;

    return SizedBox(
      height: chartHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final int v = values[i];
          final DateTime day = now.subtract(Duration(days: 6 - i));
          final String label =
              DateFormat.E(locale).format(day).characters.first.toUpperCase();
          final double h = v == 0 ? 6 : chartHeight * v / maxValue;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (v > 0)
                    Text(
                      '$v',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: JauneColors.inkSoft,
                      ),
                    ),
                  //const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: h),
                    duration: JauneMotion.emphasized,
                    curve: JauneMotion.smooth,
                    builder:
                        (context, height, _) => Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: v == 0 ? Colors.grey.shade200 : barColor(v),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final AppLocalizations l10n;
  final int thisWeek;
  final int lastWeek;

  const _TrendCard({
    required this.l10n,
    required this.thisWeek,
    required this.lastWeek,
  });

  @override
  Widget build(BuildContext context) {
    final String trend;
    final Color color;
    if (lastWeek == 0 || thisWeek == lastWeek) {
      trend = l10n.statsTrendFlat;
      color = JauneColors.inkSoft;
    } else if (thisWeek < lastWeek) {
      trend = l10n.statsTrendDown(
        ((lastWeek - thisWeek) * 100 / lastWeek).round(),
      );
      color = const Color(0xFF34C759);
    } else {
      trend = l10n.statsTrendUp(
        ((thisWeek - lastWeek) * 100 / lastWeek).round(),
      );
      color = JauneColors.flame;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.statsThisWeek} · ${l10n.statsDrinksCount(thisWeek)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: JauneColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.statsLastWeek} · ${l10n.statsDrinksCount(lastWeek)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JauneColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trend,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Courbe de la santé de fond (PV 0–100) sur les 30 derniers jours.
///
/// La couleur encode l'altitude : un dégradé vertical vert (haut, plein de
/// vie) → rouge (bas) — exactement les paliers de [JauneColors.healthGradient].
/// Le tracé se dessine à l'ouverture et la pastille affiche le PV courant.
class _HealthCurve extends StatelessWidget {
  final List<double> values;
  const _HealthCurve({required this.values});

  @override
  Widget build(BuildContext context) {
    final double current = values.isNotEmpty ? values.last : 100.0;
    final List<Color> pill = JauneColors.healthGradient(current / 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PV courant, gros, dans la couleur de sa zone.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${current.round()}',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: pill.last,
              ),
            ),
            const SizedBox(width: 3),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'PV',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: JauneColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: JauneMotion.emphasized,
            curve: JauneMotion.smooth,
            builder: (context, progress, _) => CustomPaint(
              painter: _HealthCurvePainter(values: values, progress: progress),
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthCurvePainter extends CustomPainter {
  final List<double> values;
  final double progress;

  _HealthCurvePainter({required this.values, required this.progress});

  // Marges verticales : laisse respirer le 100 et le 0.
  static const double _padTop = 10;
  static const double _padBottom = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double usableH = size.height - _padTop - _padBottom;
    double xAt(int i) => values.length == 1
        ? size.width / 2
        : size.width * i / (values.length - 1);
    double yAt(double hp) =>
        _padTop + usableH * (1 - (hp.clamp(0.0, 100.0) / 100.0));

    // Ligne de base discrète à 100 PV (objectif santé pleine).
    final gridPaint = Paint()
      ..color = JauneColors.inkSoft.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final double yFull = yAt(100);
    canvas.drawLine(Offset(0, yFull), Offset(size.width, yFull), gridPaint);

    // Construit le chemin lissé (béziers quadratiques via les milieux).
    final points = [
      for (int i = 0; i < values.length; i++) Offset(xAt(i), yAt(values[i])),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      path.lineTo(points.first.dx, points.first.dy);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      path.lineTo(points.last.dx, points.last.dy);
    }

    // Dégradé vertical vert (haut) → rouge (bas) = paliers de santé.
    final shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF43E97B), // ≥90 vibrant
        Color(0xFFA8E063), // ≥75 high
        Color(0xFFFFD200), // ≥50 mid
        Color(0xFFFF8C42), // ≥25 warm
        Color(0xFFF85757), // <25 low
      ],
      stops: [0.0, 0.18, 0.45, 0.72, 1.0],
    ).createShader(Offset.zero & size);

    // Anime le tracé : on n'extrait que la fraction [progress] du chemin.
    final metric = path.computeMetrics().fold<Path>(
      Path(),
      (acc, m) => acc..addPath(m.extractPath(0, m.length * progress), Offset.zero),
    );

    // Aire sous la courbe : même dégradé mais translucide (l'alpha est dans
    // les couleurs, car un shader ignore Paint.color).
    final fillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF43E97B).withValues(alpha: 0.22),
        const Color(0xFFFFD200).withValues(alpha: 0.12),
        const Color(0xFFF85757).withValues(alpha: 0.04),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Offset.zero & size);

    final lastDrawn = _pointAt(path, progress);
    if (lastDrawn != null) {
      final fill = Path.from(metric)
        ..lineTo(lastDrawn.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = fillShader
          ..style = PaintingStyle.fill,
      );
    }

    // La ligne elle-même.
    canvas.drawPath(
      metric,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Pastille sur le point courant.
    if (lastDrawn != null) {
      canvas.drawCircle(lastDrawn, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        lastDrawn,
        5,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  /// Position du point situé à la fraction [t] de la longueur du chemin.
  Offset? _pointAt(Path path, double t) {
    for (final m in path.computeMetrics()) {
      final tan = m.getTangentForOffset(m.length * t.clamp(0.0, 1.0));
      if (tan != null) return tan.position;
    }
    return null;
  }

  @override
  bool shouldRepaint(_HealthCurvePainter old) =>
      old.progress != progress || old.values != values;
}

class _RecordRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _RecordRow({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: JauneColors.lemon.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: JauneColors.ink,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: JauneColors.ink,
          ),
        ),
      ],
    );
  }
}
