import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/citron_animation_controller.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/audio_service.dart';
import '../services/character_service.dart';
import '../services/milestone_scheduler.dart';
import '../services/stats_service.dart';
import '../theme/jaune_design.dart';
import '../utils/date_keys.dart';
import 'draggable_sheet.dart';
import 'share_card.dart';
import 'stats_components.dart';

/// Bottom sheet de statistiques : un tableau de bord vivant et ludique.
/// Header héros (série + PV + citron), sélecteur de période, insight, graphe,
/// tendance, courbe de santé, anneau de palier, patterns par jour, heatmap et
/// records — le tout animé, avec célébration quand un record tombe.
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

class _StatsSheetContent extends StatefulWidget {
  final Map<String, int> dailyMap;
  final CharacterService character;

  const _StatsSheetContent({required this.dailyMap, required this.character});

  @override
  State<_StatsSheetContent> createState() => _StatsSheetContentState();
}

class _StatsSheetContentState extends State<_StatsSheetContent> {
  StatsPeriod _period = StatsPeriod.week;
  late final CitronAnimationController _citron;
  final DateTime _now = DateTime.now();

  Map<String, int> get _map => widget.dailyMap;
  String get _firstUse => widget.character.profile.firstUseDate;

  @override
  void initState() {
    super.initState();
    final hp = widget.character.healthPercent;
    _citron = CitronAnimationController()
      ..updateHealth((hp * 100).round())
      ..idleMood = hp >= 0.5 ? 'happy' : 'sad';
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate());
  }

  @override
  void dispose() {
    _citron.dispose();
    super.dispose();
  }

  /// Célèbre (une seule fois) quand la série en cours atteint/égale le record.
  Future<void> _maybeCelebrate() async {
    final streak = widget.character.soberStreakDays;
    final longest = StatsService.longestSoberStreak(_map, _firstUse, _now);
    if (streak < 3 || streak < longest) return;
    final prefs = await SharedPreferences.getInstance();
    const key = 'last_celebrated_streak';
    if (streak <= (prefs.getInt(key) ?? 0)) return;
    await prefs.setInt(key, streak);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    AudioService.instance.playStreakChime();
    _RecordConfetti.show(context);
  }

  void _setPeriod(StatsPeriod p) {
    if (p == _period) return;
    HapticFeedback.selectionClick();
    setState(() => _period = p);
  }

  Future<void> _share() async {
    HapticFeedback.selectionClick();
    final l10n = AppLocalizations.of(context);
    final soberTotal = StatsService.totalSoberDays(_map, _firstUse, _now);
    await ShareCard.shareStats(
      context,
      streakDays: widget.character.soberStreakDays,
      soberDays: soberTotal,
      caption: l10n.statsShareCaption(soberTotal),
      skin: widget.character.profile.equippedSkin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final streak = widget.character.soberStreakDays;

    // Sections révélées en cascade.
    final sections = <Widget>[
      _titleRow(l10n),
      StatHeroHeader(
        streakDays: streak,
        healthPercent: widget.character.healthPercent,
        streakLabel: l10n.statsHeroStreak,
        hpLabel: l10n.statsHpUnit,
        citron: _citron,
        skin: widget.character.profile.equippedSkin,
      ),
      StatPeriodSelector(
        selected: _period,
        onChanged: _setPeriod,
        labels: {
          StatsPeriod.week: l10n.statsPeriodWeek,
          StatsPeriod.month: l10n.statsPeriodMonth,
          StatsPeriod.year: l10n.statsPeriodYear,
          StatsPeriod.all: l10n.statsPeriodAll,
        },
      ),
      _insightCard(l10n, locale, streak),
      _consumptionCard(l10n, locale),
      _healthCard(l10n),
      _milestoneCard(l10n, streak),
      _weekdayCard(l10n, locale),
      _heatmapCard(l10n),
      _recordsCard(l10n, streak),
    ];

    return DraggableSheet(
      children: [
        for (int i = 0; i < sections.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: StaggeredReveal(
              delay: Duration(milliseconds: 60 * i),
              child: sections[i],
            ),
          ),
      ],
    );
  }

  Widget _titleRow(AppLocalizations l10n) {
    return Row(
      children: [
        Text(
          l10n.statsTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: JauneColors.ink,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _share,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: JauneColors.lemon.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(JauneRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.ios_share, size: 16, color: JauneColors.ink),
                const SizedBox(width: 6),
                Text(
                  l10n.statsShare,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: JauneColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _insightCard(AppLocalizations l10n, String locale, int streak) {
    final insight = StatsService.computeInsight(
      dailyMap: _map,
      firstUseDate: _firstUse,
      today: _now,
      period: _period,
      currentStreak: streak,
    );
    final (emoji, text) = switch (insight.kind) {
      StatInsightKind.trendDown => ('📉', l10n.statsInsightTrendDown(insight.value)),
      StatInsightKind.trendUp => ('📈', l10n.statsInsightTrendUp(insight.value)),
      StatInsightKind.bestStreak => ('🔥', l10n.statsInsightBestStreak(insight.value)),
      StatInsightKind.soberRate => ('💧', l10n.statsInsightSoberRate(insight.value)),
      StatInsightKind.worstWeekday => (
        '📅',
        l10n.statsInsightWorstWeekday(_weekdayName(locale, insight.value)),
      ),
      StatInsightKind.gettingStarted => ('🍋', l10n.statsInsightGettingStarted),
    };
    return StatInsightCard(emoji: emoji, text: text);
  }

  Widget _consumptionCard(AppLocalizations l10n, String locale) {
    final pb = StatsService.periodBars(_map, _period, _now, _firstUse);
    final List<StatBarDatum> data;
    final bool showLabels;
    switch (_period) {
      case StatsPeriod.week:
        data = [
          for (final b in pb.bars)
            StatBarDatum(_initial(DateFormat.E(locale).format(b.date)), b.value),
        ];
        showLabels = true;
      case StatsPeriod.month:
        data = [for (final b in pb.bars) StatBarDatum('', b.value)];
        showLabels = false;
      case StatsPeriod.year:
        data = [
          for (final b in pb.bars)
            StatBarDatum(_initial(DateFormat.MMM(locale).format(b.date)), b.value),
        ];
        showLabels = true;
      case StatsPeriod.all:
        final few = pb.bars.length <= 12;
        data = [
          for (final b in pb.bars)
            StatBarDatum(
              few ? _initial(DateFormat.MMM(locale).format(b.date)) : '',
              b.value,
            ),
        ];
        showLabels = few;
    }

    final cmp = StatsService.periodComparison(_map, _period, _now);
    return StatCard(
      title: l10n.statsConsumptionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cmp != null) ...[
            _trendRow(l10n, cmp.current, cmp.previous),
            const SizedBox(height: 12),
          ],
          StatBarChart(
            key: ValueKey('bars-${_period.name}'),
            data: data,
            showLabels: showLabels,
          ),
        ],
      ),
    );
  }

  Widget _trendRow(AppLocalizations l10n, int current, int previous) {
    final String text;
    final Color color;
    if (previous == 0 || current == previous) {
      text = l10n.statsTrendFlat;
      color = JauneColors.inkSoft;
    } else if (current < previous) {
      text = l10n.statsTrendDown(((previous - current) * 100 / previous).round());
      color = const Color(0xFF34C759);
    } else {
      text = l10n.statsTrendUp(((current - previous) * 100 / previous).round());
      color = JauneColors.flame;
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.statsDrinksCount(current),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: JauneColors.ink,
            ),
          ),
        ),
        StatTrendBadge(text: text, color: color),
      ],
    );
  }

  Widget _healthCard(AppLocalizations l10n) {
    final days = switch (_period) {
      StatsPeriod.week => 7,
      StatsPeriod.month => 31,
      StatsPeriod.year => 365,
      StatsPeriod.all => 365 * 3,
    };
    final values = StatsService.hpTrajectory(_map, _firstUse, _now, days: days);
    return StatCard(
      title: l10n.statsHealthTrend,
      child: _HealthCurve(values: values, hpUnit: l10n.statsHpUnit),
    );
  }

  Widget _milestoneCard(AppLocalizations l10n, int streak) {
    final milestones = MilestoneScheduler.streakMilestones;
    int target = milestones.last;
    for (final m in milestones) {
      if (streak < m) {
        target = m;
        break;
      }
    }
    final reached = streak >= milestones.last;
    final remaining = math.max(0, target - streak);
    return StatCard(
      title: l10n.statsMilestoneTitle,
      child: MilestoneRing(
        key: ValueKey('ring-$streak'),
        currentStreak: streak,
        target: target,
        centerLabel: reached ? '$streak 🔥' : '$streak/$target',
        caption: reached
            ? l10n.statsMilestoneReached
            : l10n.statsMilestoneCaption(remaining, target),
      ),
    );
  }

  Widget _weekdayCard(AppLocalizations l10n, String locale) {
    final avgs = StatsService.weekdayAverages(_map, _firstUse, _now);
    // Initiales lundi→dimanche.
    final monday = StatsService.mondayOf(_now);
    final labels = [
      for (int i = 0; i < 7; i++)
        _initial(DateFormat.E(locale).format(monday.add(Duration(days: i)))),
    ];
    return StatCard(
      title: l10n.statsWeekdayTitle,
      child: WeekdayChart(averages: avgs, labels: labels),
    );
  }

  Widget _heatmapCard(AppLocalizations l10n) {
    final range = StatsService.periodRange(_period, _now, _firstUse);
    return StatCard(
      title: l10n.statsHeatmapTitle,
      child: StatHeatmap(
        start: range.start,
        end: range.end,
        dailyMap: _map,
        today: _now,
        firstUseDate: _firstUse,
        keyOf: dateKey,
      ),
    );
  }

  Widget _recordsCard(AppLocalizations l10n, int streak) {
    final longest = StatsService.longestSoberStreak(_map, _firstUse, _now);
    final lightest = StatsService.lightestFullWeekTotal(_map, _firstUse, _now);
    final soberTotal = StatsService.totalSoberDays(_map, _firstUse, _now);
    final avoided = StatsService.drinksAvoided(_map, _firstUse, _now);
    return StatCard(
      title: l10n.statsRecords,
      child: Column(
        children: [
          StatRecordRow(
            emoji: '🔥',
            label: l10n.statsLongestStreak,
            value: l10n.daysCount(math.max(longest, streak)),
            highlight: streak >= 3 && streak >= longest,
          ),
          StatRecordRow(
            emoji: '🌿',
            label: l10n.statsTotalSoberDays,
            value: l10n.daysCount(soberTotal),
          ),
          if (lightest != null)
            StatRecordRow(
              emoji: '🪶',
              label: l10n.statsLightestWeek,
              value: l10n.statsDrinksCount(lightest),
            ),
          if (avoided != null)
            StatRecordRow(
              emoji: '🍋',
              label: l10n.statsDrinksAvoided,
              value: l10n.statsDrinksCount(avoided),
            ),
        ],
      ),
    );
  }

  String _initial(String s) =>
      s.isEmpty ? '' : s.characters.first.toUpperCase();

  String _weekdayName(String locale, int index0) {
    final monday = StatsService.mondayOf(_now);
    return DateFormat.EEEE(locale).format(monday.add(Duration(days: index0)));
  }
}

// =====================================================================
// Courbe de santé (PV) — conservée de la version précédente
// =====================================================================

class _HealthCurve extends StatelessWidget {
  final List<double> values;
  final String hpUnit;
  const _HealthCurve({required this.values, required this.hpUnit});

  @override
  Widget build(BuildContext context) {
    final double current = values.isNotEmpty ? values.last : 100.0;
    final List<Color> pill = JauneColors.healthGradient(current / 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            CountUpInt(
              current.round(),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: pill.last,
              ),
            ),
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                hpUnit,
                style: const TextStyle(
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

    final gridPaint = Paint()
      ..color = JauneColors.inkSoft.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final double yFull = yAt(100);
    canvas.drawLine(Offset(0, yFull), Offset(size.width, yFull), gridPaint);

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

    final shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF43E97B),
        Color(0xFFA8E063),
        Color(0xFFFFD200),
        Color(0xFFFF8C42),
        Color(0xFFF85757),
      ],
      stops: [0.0, 0.18, 0.45, 0.72, 1.0],
    ).createShader(Offset.zero & size);

    final metric = path.computeMetrics().fold<Path>(
      Path(),
      (acc, m) => acc..addPath(m.extractPath(0, m.length * progress), Offset.zero),
    );

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

    canvas.drawPath(
      metric,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

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

// =====================================================================
// Confettis de record — overlay léger, auto-effacé
// =====================================================================

class _RecordConfetti {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiLayer(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _ConfettiLayer extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiLayer({required this.onDone});

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const colors = [
      JauneColors.lemon,
      JauneColors.lemonDeep,
      JauneColors.flame,
      Color(0xFF43E97B),
      Color(0xFF5E9FD5),
    ];
    _particles = List.generate(80, (_) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi;
      final speed = 380 + rnd.nextDouble() * 420;
      return _Particle(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: colors[rnd.nextInt(colors.length)],
        size: 6 + rnd.nextDouble() * 8,
        rot: rnd.nextDouble() * math.pi,
        rotSpeed: (rnd.nextDouble() - 0.5) * 8,
        square: rnd.nextBool(),
      );
    });
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _c.value),
        ),
      ),
    );
  }
}

class _Particle {
  final double vx, vy, size, rot, rotSpeed;
  final Color color;
  final bool square;
  const _Particle({
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rot,
    required this.rotSpeed,
    required this.square,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.32);
    const g = 900.0; // gravité
    final fade = (1 - t).clamp(0.0, 1.0);
    for (final p in particles) {
      final x = origin.dx + p.vx * t;
      final y = origin.dy + p.vy * t + 0.5 * g * t * t;
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + p.rotSpeed * t);
      if (p.square) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
