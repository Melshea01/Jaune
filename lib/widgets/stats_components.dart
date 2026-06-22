import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/citron_animation_controller.dart';
import '../services/stats_service.dart';
import '../theme/jaune_design.dart';
import 'citron_character.dart';

/// Couleur d'un jour/bucket selon le nombre de verres — mêmes paliers que le
/// calendrier, pour que l'app raconte partout la même histoire.
Color jauneStatColor(int count) {
  if (count <= 0) return const Color(0xFF43E97B); // sobre = vert vibrant
  if (count <= 2) return const Color(0xFF56AB2F);
  if (count <= 4) return const Color(0xFFE0A800);
  if (count <= 5) return const Color(0xFFFF7043);
  return const Color(0xFFE53935);
}

// =====================================================================
// Animations utilitaires
// =====================================================================

/// Nombre qui « compte » de 0 vers sa valeur à l'apparition.
class CountUpInt extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;

  const CountUpInt(
    this.value, {
    super.key,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: JauneMotion.smooth,
      builder: (context, v, _) => Text('$prefix${v.round()}$suffix', style: style),
    );
  }
}

/// Apparition en cascade : fondu + glissement vers le haut, déclenché après un
/// délai (typiquement index × pas) pour révéler les sections une à une.
class StaggeredReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const StaggeredReveal({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: JauneMotion.standard,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: JauneMotion.smooth);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

// =====================================================================
// Carte conteneur (DA Revolut : coins arrondis, ombre douce)
// =====================================================================

class StatCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const StatCard({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: JauneColors.ink,
                letterSpacing: 0.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: JauneColors.inkSoft,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

// =====================================================================
// Header héros (DA Revolut : carte sombre, gros chiffre)
// =====================================================================

class StatHeroHeader extends StatelessWidget {
  final int streakDays;
  final double healthPercent;
  final String streakLabel;
  final String hpLabel;
  final CitronAnimationController citron;
  final String skin;

  const StatHeroHeader({
    super.key,
    required this.streakDays,
    required this.healthPercent,
    required this.streakLabel,
    required this.hpLabel,
    required this.citron,
    this.skin = '',
  });

  @override
  Widget build(BuildContext context) {
    final hpColor = JauneColors.healthGradient(healthPercent).first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 8, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(JauneRadii.card + 4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2B45), Color(0xFF1C1C2E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            offset: const Offset(0, 8),
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 34)),
                    const SizedBox(width: 6),
                    CountUpInt(
                      streakDays,
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  streakLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 14),
                // PV : pastille colorée + valeur
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: hpColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(JauneRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: hpColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CountUpInt(
                        (healthPercent * 100).round(),
                        suffix: ' $hpLabel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: hpColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Le CitronCharacter a un layout fixe de 420×420 (seul le rendu est
          // scalé). Un FittedBox contient l'ensemble du personnage — tige
          // comprise — dans la vignette, sans détacher ni rogner.
          SizedBox(
            width: 116,
            height: 116,
            child: IgnorePointer(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 420,
                  height: 420,
                  child: CitronCharacter(controller: citron, skin: skin),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Sélecteur de période (segmented control animé)
// =====================================================================

class StatPeriodSelector extends StatelessWidget {
  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;
  final Map<StatsPeriod, String> labels;

  const StatPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    const periods = StatsPeriod.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final segW = w / periods.length;
        final index = periods.indexOf(selected);
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEFF4),
            borderRadius: BorderRadius.circular(JauneRadii.pill),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: JauneMotion.quick,
                curve: JauneMotion.smooth,
                alignment: Alignment(
                  periods.length == 1 ? 0 : (index / (periods.length - 1)) * 2 - 1,
                  0,
                ),
                child: Container(
                  width: segW - 6,
                  height: 34,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(JauneRadii.pill),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final p in periods)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(p),
                        child: Center(
                          child: Text(
                            labels[p] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: p == selected
                                  ? JauneColors.ink
                                  : JauneColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// =====================================================================
// Carte insight (phrase marquante)
// =====================================================================

class StatInsightCard extends StatelessWidget {
  final String emoji;
  final String text;

  const StatInsightCard({super.key, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(JauneRadii.card),
        gradient: LinearGradient(
          colors: [
            JauneColors.lemon.withValues(alpha: 0.30),
            JauneColors.lemonDeep.withValues(alpha: 0.20),
          ],
        ),
        border: Border.all(color: JauneColors.lemonDeep.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: JauneColors.ink,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Graphe en barres (générique période) — cascade animée
// =====================================================================

class StatBarDatum {
  final String label;
  final int value;
  const StatBarDatum(this.label, this.value);
}

class StatBarChart extends StatefulWidget {
  final List<StatBarDatum> data;
  final double height;
  final bool showLabels;

  const StatBarChart({
    super.key,
    required this.data,
    this.height = 150,
    this.showLabels = true,
  });

  @override
  State<StatBarChart> createState() => _StatBarChartState();
}

class _StatBarChartState extends State<StatBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: JauneMotion.emphasized,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final maxValue = data.fold<int>(1, (m, d) => d.value > m ? d.value : m);
    final n = data.length;
    final thin = n > 12;
    final showValue = n <= 12;

    // La zone des barres est un Expanded : valeur (haut) et label (bas) ont
    // une hauteur fixe, donc le total ne dépasse jamais [height] (zéro
    // overflow, quelle que soit la valeur max).
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < n; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: thin ? 1 : 3),
                    child: _bar(data[i], maxValue, i, n, thin, showValue),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(
    StatBarDatum d,
    int maxValue,
    int i,
    int n,
    bool thin,
    bool showValue,
  ) {
    // Cascade : chaque barre démarre légèrement après la précédente.
    final start = n <= 1 ? 0.0 : (i / n) * 0.35;
    final t = ((_c.value - start) / (1 - 0.35)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    final frac = (d.value <= 0 ? 0.0 : d.value / maxValue) * eased;
    final color = d.value <= 0 ? Colors.grey.shade200 : jauneStatColor(d.value);
    final radius = BorderRadius.circular(thin ? 2 : 6);

    return Column(
      children: [
        if (showValue)
          SizedBox(
            height: 16,
            child: d.value > 0
                ? Center(
                    child: Text(
                      '${d.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: JauneColors.inkSoft,
                      ),
                    ),
                  )
                : null,
          ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: d.value <= 0
                ? Container(
                    height: 3,
                    decoration: BoxDecoration(color: color, borderRadius: radius),
                  )
                : FractionallySizedBox(
                    heightFactor: frac.clamp(0.02, 1.0),
                    widthFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(color: color, borderRadius: radius),
                    ),
                  ),
          ),
        ),
        if (widget.showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              d.label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }
}

// =====================================================================
// Badge de tendance (période vs précédente)
// =====================================================================

class StatTrendBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatTrendBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

// =====================================================================
// Anneau de progression vers le prochain palier de série
// =====================================================================

/// Anneau « jours sobres » (style anneau d'activité Apple) : proportion de
/// jours sans verre sur la période, avec gros pourcentage au centre.
class SoberRing extends StatefulWidget {
  final double progress; // 0..1
  final String bigLabel; // ex: "72%"
  final String smallLabel; // ex: "5 / 7 jours sobres"
  final List<Color> gradient;

  const SoberRing({
    super.key,
    required this.progress,
    required this.bigLabel,
    required this.smallLabel,
    this.gradient = const [Color(0xFF43E97B), Color(0xFF38F9D7)],
  });

  @override
  State<SoberRing> createState() => _SoberRingState();
}

class _SoberRingState extends State<SoberRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: JauneMotion.emphasized,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _RingPainter(
                widget.progress.clamp(0.0, 1.0) * _c.value,
                widget.gradient,
              ),
              child: Center(
                child: Text(
                  widget.bigLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: JauneColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            widget.smallLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: JauneColors.ink,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final List<Color> gradient;
  _RingPainter(this.progress, this.gradient);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 7;
    const stroke = 12.0;

    final bg = Paint()
      ..color = const Color(0xFFEDEFF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final fg = Paint()
      ..shader = SweepGradient(
        colors: [...gradient, gradient.first],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Parcours d'objectifs (style chemin Duolingo) : les paliers de série sobre
/// (3, 7, 30, 100) sous forme de jalons reliés, remplis jusqu'à la série en
/// cours. Beaucoup plus parlant qu'un simple anneau « 3/7 ».
class MilestoneTrack extends StatelessWidget {
  final int currentStreak;
  final List<int> milestones;

  const MilestoneTrack({
    super.key,
    required this.currentStreak,
    required this.milestones,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    int prev = 0;
    for (int k = 0; k < milestones.length; k++) {
      final m = milestones[k];
      final fill = ((currentStreak - prev) / (m - prev)).clamp(0.0, 1.0);
      final reached = currentStreak >= m;
      final isNext = !reached &&
          (k == 0 || currentStreak >= milestones[k - 1]);
      children.add(Expanded(child: _segment(fill)));
      children.add(_node(m, reached, isNext));
      prev = m;
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }

  Widget _segment(double fill) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEFF4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: fill,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [JauneColors.lemon, JauneColors.flame],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _node(int milestone, bool reached, bool isNext) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: reached
            ? const LinearGradient(colors: [JauneColors.lemon, JauneColors.flame])
            : null,
        color: reached ? null : Colors.white,
        border: Border.all(
          color: isNext
              ? JauneColors.flame
              : reached
                  ? Colors.transparent
                  : const Color(0xFFD9DCE3),
          width: isNext ? 2.5 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$milestone',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: reached ? Colors.white : JauneColors.inkSoft,
        ),
      ),
    );
  }
}

/// Légende de la heatmap : du sobre (vert) au chargé (rouge).
class StatHeatmapLegend extends StatelessWidget {
  final String lessLabel;
  final String moreLabel;
  const StatHeatmapLegend({
    super.key,
    required this.lessLabel,
    required this.moreLabel,
  });

  @override
  Widget build(BuildContext context) {
    const swatches = [0, 2, 4, 5, 6];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          lessLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        for (final c in swatches)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: jauneStatColor(c).withValues(alpha: c == 0 ? 0.35 : 1.0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          moreLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Patterns par jour de la semaine (7 barres, pire jour mis en avant)
// =====================================================================

class WeekdayChart extends StatelessWidget {
  final List<double> averages; // 0 = lundi … 6 = dimanche
  final List<String> labels; // initiales localisées (L M M J V S D)

  const WeekdayChart({super.key, required this.averages, required this.labels});

  @override
  Widget build(BuildContext context) {
    final maxV = averages.fold<double>(0.001, (m, v) => v > m ? v : m);
    int worst = 0;
    for (int i = 1; i < averages.length; i++) {
      if (averages[i] > averages[worst]) worst = i;
    }
    const chartH = 90.0;
    return SizedBox(
      height: chartH + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: averages[i] <= 0 ? 3 : chartH * averages[i] / maxV,
                      ),
                      duration: JauneMotion.emphasized,
                      curve: JauneMotion.smooth,
                      builder: (context, h, _) => Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: i == worst && averages[i] > 0
                              ? JauneColors.flame
                              : JauneColors.lemonDeep.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels.length > i ? labels[i] : '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == worst ? FontWeight.w900 : FontWeight.w700,
                        color: i == worst ? JauneColors.flame : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
// Heatmap (grille type contributions GitHub) — colonnes = semaines
// =====================================================================

class StatHeatmap extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final Map<String, int> dailyMap;
  final DateTime today;
  final String firstUseDate;
  final String Function(DateTime day) keyOf;
  final List<String> weekdayLabels; // L M M J V S D (lundi→dimanche)

  const StatHeatmap({
    super.key,
    required this.start,
    required this.end,
    required this.dailyMap,
    required this.today,
    required this.firstUseDate,
    required this.keyOf,
    required this.weekdayLabels,
  });

  @override
  Widget build(BuildContext context) {
    // On commence le lundi de la semaine de [start] pour aligner les colonnes.
    DateTime cursor = StatsService.mondayOf(start);
    final last = DateTime(end.year, end.month, end.day);
    final d0 = DateTime(today.year, today.month, today.day);
    final first = DateTime.tryParse(firstUseDate);

    final columns = <Widget>[];
    while (!cursor.isAfter(last)) {
      final cells = <Widget>[];
      for (int wd = 0; wd < 7; wd++) {
        final day = cursor.add(Duration(days: wd));
        cells.add(_cell(day, last, d0, first));
      }
      columns.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Column(children: cells),
        ),
      );
      cursor = cursor.add(const Duration(days: 7));
    }

    // Colonne fixe des initiales de jours, alignée sur les lignes (cellules
    // de 14 px + 4 px de marge basse).
    final labelColumn = Column(
      children: [
        for (int i = 0; i < 7; i++)
          SizedBox(
            height: 18,
            child: Center(
              child: Text(
                weekdayLabels.length > i ? weekdayLabels[i] : '',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: labelColumn,
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // dernières semaines visibles d'abord
            child: Row(children: columns),
          ),
        ),
      ],
    );
  }

  Widget _cell(DateTime day, DateTime last, DateTime d0, DateTime? first) {
    const size = 14.0;
    final inRange = !day.isBefore(StatsService.mondayOf(start)) && !day.isAfter(last);
    final isFuture = day.isAfter(d0);
    final beforeFirst = first != null &&
        day.isBefore(DateTime(first.year, first.month, first.day));

    Color color;
    if (!inRange || isFuture || beforeFirst) {
      color = const Color(0xFFEDEFF4);
    } else {
      final count = dailyMap[keyOf(day)] ?? 0;
      color = jauneStatColor(count).withValues(alpha: count == 0 ? 0.35 : 1.0);
    }

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// =====================================================================
// Ligne de record (avec mise en valeur si record battu)
// =====================================================================

class StatRecordRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool highlight;

  const StatRecordRow({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? JauneColors.lemon.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: highlight
            ? Border.all(color: JauneColors.lemonDeep.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
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
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: JauneColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
