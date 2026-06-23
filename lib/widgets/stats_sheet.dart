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
    required List<DateTime> drinkTimes,
    required CharacterService character,
  }) {
    HapticFeedback.selectionClick();
    AudioService.instance.playUiPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatsSheetContent(
        dailyMap: dailyMap,
        drinkTimes: drinkTimes,
        character: character,
      ),
    );
  }
}

class _StatsSheetContent extends StatefulWidget {
  final Map<String, int> dailyMap;
  final List<DateTime> drinkTimes;
  final CharacterService character;

  const _StatsSheetContent({
    required this.dailyMap,
    required this.drinkTimes,
    required this.character,
  });

  @override
  State<_StatsSheetContent> createState() => _StatsSheetContentState();
}

class _StatsSheetContentState extends State<_StatsSheetContent> {
  StatsPeriod _period = StatsPeriod.week;
  late final CitronAnimationController _citron;
  final DateTime _now = DateTime.now();

  Map<String, int> get _map => widget.dailyMap;

  /// Première utilisation EFFECTIVE : la date du profil si connue, sinon la
  /// plus ancienne donnée enregistrée. Sans ça, « Tout » démarrait à
  /// aujourd'hui (firstUseDate vide) et affichait moins que « Année ».
  late final String _firstUse = _computeFirstUse();

  String _computeFirstUse() {
    final profileDate = widget.character.profile.firstUseDate;
    if (DateTime.tryParse(profileDate) != null) return profileDate;
    DateTime? earliest;
    for (final k in _map.keys) {
      final d = DateTime.tryParse(k);
      if (d != null && (earliest == null || d.isBefore(earliest))) earliest = d;
    }
    return earliest != null ? dateKey(earliest) : dateKey(_now);
  }

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

    // Sections révélées en cascade. En haut : ce qui décrit l'instant (héros +
    // objectifs de série, indépendants de la période). Puis le sélecteur, qui
    // gouverne les cartes juste en dessous (KPI, insight, conso, santé). Enfin
    // le profil global (habitudes par jour, records).
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
      _milestoneCard(l10n, streak),
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
      _kpiRow(l10n),
      _insightCard(l10n, locale, streak),
      _consumptionCard(l10n, locale),
      _healthCard(l10n),
      _clockCard(l10n),
      _sectionLabel(l10n.statsAllTimeSection),
      _weekdayCard(l10n, locale),
      _recordsGrid(l10n, streak),
      _guidelineCard(l10n),
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
        // Numéro du jour : le graphe affichera un libellé espacé (axe lisible).
        data = [
          for (final b in pb.bars) StatBarDatum('${b.date.day}', b.value),
        ];
        showLabels = true;
      case StatsPeriod.year:
        data = [
          for (final b in pb.bars)
            StatBarDatum(_initial(DateFormat.MMM(locale).format(b.date)), b.value),
        ];
        showLabels = true;
      case StatsPeriod.all:
        final monthly = pb.gran == StatGranularity.month;
        data = [
          for (final b in pb.bars)
            StatBarDatum(
              monthly
                  ? _initial(DateFormat.MMM(locale).format(b.date))
                  : '${b.date.day}',
              b.value,
            ),
        ];
        showLabels = true;
    }

    final cmp = StatsService.periodComparison(_map, _period, _now);
    final perMonth = _period == StatsPeriod.year || _period == StatsPeriod.all;
    return StatCard(
      title: l10n.statsConsumptionTitle,
      subtitle: perMonth ? l10n.statsUnitPerMonth : l10n.statsUnitPerDay,
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
            barColor: StatPalette.drinks,
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
      subtitle: l10n.statsHealthScrubHint,
      child: _HealthCurve(
        key: ValueKey('curve-${_period.name}'),
        values: values,
        hpUnit: l10n.statsHpUnit,
        now: _now,
        locale: Localizations.localeOf(context).toString(),
      ),
    );
  }

  /// Deux tuiles côte à côte, gouvernées par la période : taux de jours sobres
  /// (mini-anneau) et total de verres.
  Widget _kpiRow(AppLocalizations l10n) {
    final range = StatsService.periodRange(_period, _now, _firstUse);
    final tracked = StatsService.trackedDaysInRange(
      range.start,
      range.end,
      _now,
      _firstUse,
    );
    final sober = StatsService.soberDaysInRange(
      _map,
      range.start,
      range.end,
      _now,
      _firstUse,
    );
    final pct = tracked == 0 ? 0 : (sober * 100 / tracked).round();
    final total = StatsService.totalInRange(_map, range.start, range.end);
    return _grid([
      StatTile(
        key: ValueKey('sober-${_period.name}'),
        ring: tracked == 0 ? 0 : sober / tracked,
        value: pct,
        suffix: '%',
        label: '', // anneau seul, pas de texte redondant en dessous
        accent: StatPalette.sober,
      ),
      StatTile(
        key: ValueKey('drinks-${_period.name}'),
        emoji: '🍺',
        value: total,
        label: l10n.statsDrinksLabel,
        accent: StatPalette.drinks,
      ),
    ]);
  }

  /// Carte « Repères à moindre risque » (Santé publique France), toujours
  /// calculée sur la SEMAINE en cours (les repères sont hebdomadaires).
  Widget _guidelineCard(AppLocalizations l10n) {
    final monday = StatsService.mondayOf(_now);
    final weekly = StatsService.weekTotal(_map, monday);
    int maxDay = 0;
    int soberDays = 0;
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      if (d.isAfter(_now)) break;
      final c = _map[dateKey(d)] ?? 0;
      if (c > maxDay) maxDay = c;
      if (c == 0) soberDays++;
    }
    return StatCard(
      title: l10n.statsGuidelineTitle,
      subtitle: l10n.statsGuidelineSubtitle,
      child: Column(
        children: [
          GuidelineRow(
            label: l10n.statsGuidelineWeekly,
            value: '$weekly / 10',
            ok: weekly <= 10,
            gaugeFraction: weekly / 10,
          ),
          GuidelineRow(
            label: l10n.statsGuidelinePerDay,
            value: '$maxDay',
            ok: maxDay <= 2,
          ),
          GuidelineRow(
            label: l10n.statsGuidelineSoberDays,
            value: '$soberDays',
            ok: soberDays >= 1,
          ),
        ],
      ),
    );
  }

  /// Cadran 24h : à quelle heure tu bois (à partir des horodatages).
  Widget _clockCard(AppLocalizations l10n) {
    final range = StatsService.periodRange(_period, _now, _firstUse);
    final hours = StatsService.hourCounts(widget.drinkTimes, range.start, range.end);
    final total = hours.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return StatCard(
        title: l10n.statsClockTitle,
        subtitle: l10n.statsClockEmpty,
        child: const SizedBox.shrink(),
      );
    }
    int peak = 0;
    for (int h = 1; h < 24; h++) {
      if (hours[h] > hours[peak]) peak = h;
    }
    final afterCount =
        hours[21] + hours[22] + hours[23] + hours[0] + hours[1];
    final pctAfter = (afterCount * 100 / total).round();
    return StatCard(
      title: l10n.statsClockTitle,
      subtitle: pctAfter >= 25
          ? l10n.statsClockInsight(pctAfter)
          : l10n.statsClockSubtitle,
      child: StatClock(
        key: ValueKey('clock-${_period.name}'),
        hourCounts: hours,
        centerTop: '${peak}h',
        centerBottom: l10n.statsClockPeak,
      ),
    );
  }

  /// Petit intertitre gris pour séparer la zone « depuis le début ».
  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 4, left: 4, bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: JauneColors.inkSoft,
            letterSpacing: 0.3,
          ),
        ),
      );

  /// Dispose des tuiles deux par deux (demi-largeur), hauteurs égalisées.
  Widget _grid(List<Widget> tiles) {
    final rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
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
      subtitle: reached
          ? l10n.statsMilestoneReached
          : l10n.statsMilestoneCaption(remaining, target),
      child: MilestoneTrack(currentStreak: streak, milestones: milestones),
    );
  }

  Widget _weekdayCard(AppLocalizations l10n, String locale) {
    final avgs = StatsService.weekdayAverages(_map, _firstUse, _now);
    return StatCard(
      title: l10n.statsWeekdayTitle,
      subtitle: l10n.statsWeekdaySubtitle,
      child: WeekdayChart(averages: avgs, labels: _weekdayInitials(locale)),
    );
  }

  List<String> _weekdayInitials(String locale) {
    final monday = StatsService.mondayOf(_now);
    return [
      for (int i = 0; i < 7; i++)
        _initial(DateFormat.E(locale).format(monday.add(Duration(days: i)))),
    ];
  }

  Widget _recordsGrid(AppLocalizations l10n, int streak) {
    final longest = StatsService.longestSoberStreak(_map, _firstUse, _now);
    final lightest = StatsService.lightestFullWeekTotal(_map, _firstUse, _now);
    final soberTotal = StatsService.totalSoberDays(_map, _firstUse, _now);
    final avoided = StatsService.drinksAvoided(_map, _firstUse, _now);
    return _grid([
      StatTile(
        emoji: '🔥',
        value: math.max(longest, streak),
        label: l10n.statsLongestStreak,
        accent: StatPalette.streak,
      ),
      StatTile(
        emoji: '🌿',
        value: soberTotal,
        label: l10n.statsTotalSoberDays,
        accent: StatPalette.sober,
      ),
      if (lightest != null)
        StatTile(
          emoji: '🪶',
          value: lightest,
          label: l10n.statsLightestWeek,
          accent: StatPalette.light,
        ),
      if (avoided != null)
        StatTile(
          emoji: '🍋',
          value: avoided,
          label: l10n.statsDrinksAvoided,
          accent: StatPalette.lemon,
        ),
    ]);
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

class _HealthCurve extends StatefulWidget {
  final List<double> values;
  final String hpUnit;
  final DateTime now;
  final String locale;

  const _HealthCurve({
    super.key,
    required this.values,
    required this.hpUnit,
    required this.now,
    required this.locale,
  });

  @override
  State<_HealthCurve> createState() => _HealthCurveState();
}

class _HealthCurveState extends State<_HealthCurve> {
  // Index sélectionné par le doigt (null = pas de scrub, on montre le dernier).
  int? _selected;

  static const double _chartH = 130;

  void _updateFromX(double dx, double width) {
    final values = widget.values;
    if (values.length < 2) return;
    final frac = (dx / width).clamp(0.0, 1.0);
    final idx = (frac * (values.length - 1)).round();
    if (idx != _selected) {
      HapticFeedback.selectionClick();
      setState(() => _selected = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final int shownIndex = _selected ?? (values.length - 1);
    final double shown =
        values.isNotEmpty ? values[shownIndex.clamp(0, values.length - 1)] : 100.0;
    final List<Color> pill = JauneColors.healthGradient(shown / 100.0);

    // Date du point affiché : le dernier point = aujourd'hui.
    String dateLabel = '';
    if (values.isNotEmpty) {
      final daysFromEnd = (values.length - 1) - shownIndex;
      final date = DateTime(widget.now.year, widget.now.month, widget.now.day)
          .subtract(Duration(days: daysFromEnd));
      final raw = DateFormat.MMMEd(widget.locale).format(date);
      dateLabel = raw.isEmpty ? '' : raw[0].toUpperCase() + raw.substring(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Le chiffre suit le doigt (pas de count-up pendant le scrub).
            Text(
              '${shown.round()}',
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
                widget.hpUnit,
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
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final len = values.length;
            final bubbleX = len < 2
                ? 0.0
                : ((shownIndex / (len - 1)) * width - 36)
                    .clamp(0.0, math.max(0.0, width - 72))
                    .toDouble();
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _updateFromX(d.localPosition.dx, width),
              onHorizontalDragStart: (d) =>
                  _updateFromX(d.localPosition.dx, width),
              onHorizontalDragUpdate: (d) =>
                  _updateFromX(d.localPosition.dx, width),
              onHorizontalDragEnd: (_) => setState(() => _selected = null),
              onTapUp: (_) => setState(() => _selected = null),
              onTapCancel: () => setState(() => _selected = null),
              child: SizedBox(
                height: _chartH,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: JauneMotion.emphasized,
                        curve: JauneMotion.smooth,
                        builder: (context, progress, _) => CustomPaint(
                          painter: _HealthCurvePainter(
                            values: values,
                            progress: progress,
                            color: pill.last,
                            selected: _selected,
                          ),
                        ),
                      ),
                    ),
                    // Bulle qui suit le doigt pendant le scrub.
                    if (_selected != null && len >= 2)
                      Positioned(
                        top: 0,
                        left: bubbleX,
                        child: _scrubBubble(shown.round(), dateLabel, pill.last),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _scrubBubble(int value, String date, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: JauneColors.ink,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$value ${widget.hpUnit}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCurvePainter extends CustomPainter {
  final List<double> values;
  final double progress;
  final int? selected;
  final Color color;

  _HealthCurvePainter({
    required this.values,
    required this.progress,
    required this.color,
    this.selected,
  });

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

    final metric = path.computeMetrics().fold<Path>(
      Path(),
      (acc, m) => acc..addPath(m.extractPath(0, m.length * progress), Offset.zero),
    );

    // Teinte unique = couleur de la santé courante : calme et on-brand, plus
    // d'arc-en-ciel vert→rouge.
    final fillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.24),
        color.withValues(alpha: 0.02),
      ],
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
        ..color = color
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
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Marqueur de scrub : ligne verticale + point sur le jour sélectionné.
    final sel = selected;
    if (sel != null && sel >= 0 && sel < points.length && progress >= 0.999) {
      final p = points[sel];
      final line = Paint()
        ..color = JauneColors.ink.withValues(alpha: 0.18)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), line);
      canvas.drawCircle(p, 6, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
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
      old.progress != progress ||
      old.values != values ||
      old.selected != selected ||
      old.color != color;
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
