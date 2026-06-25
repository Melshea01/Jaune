import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/citron_animation_controller.dart';
import '../services/stats_service.dart';
import '../theme/jaune_design.dart';
import 'citron_character.dart';

/// Couleur d'un jour/bucket selon le nombre de verres — mêmes paliers que le
/// calendrier, pour que l'app raconte partout la même histoire.
Color jauneStatColor(int count) {
  if (count <= 0) return const Color(0xFF22C55E); // sobre = vert net
  if (count <= 2) return const Color(0xFF84CC16); // léger = lime
  if (count <= 4) return const Color(0xFFF59E0B); // attention = ambre
  if (count <= 5) return const Color(0xFFF97316); // limite = orange
  return const Color(0xFFEF4444); // binge = rouge
}

/// Accents de couleur cohérents pour les tuiles et anneaux des statistiques.
abstract class StatPalette {
  static const Color sober = Color(0xFF22C55E); // vert
  static const Color drinks = Color(0xFFF59E0B); // ambre
  static const Color streak = Color(0xFFFB7185); // corail (série)
  static const Color light = Color(0xFF38BDF8); // bleu ciel
  static const Color lemon = Color(0xFFEAB308); // citron profond
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
  // Couleur unique des barres (plus sobre/on-brand). Si null, palier par valeur.
  final Color? barColor;

  const StatBarChart({
    super.key,
    required this.data,
    this.height = 150,
    this.showLabels = true,
    this.barColor,
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
    final hasData = data.any((d) => d.value > 0);
    // Sur les vues denses (mois, tout au jour), un libellé sur N pour garder
    // un axe lisible.
    final step = n <= 12 ? 1 : (n / 6).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Échelle verticale : le pic de verres, toujours visible (donne le
        // « nombre de verres » même quand les barres n'ont pas d'étiquette).
        if (hasData)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'max $maxValue',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < n; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: thin ? 1 : 3),
                        child: _bar(data[i], maxValue, i, n, thin, showValue, step),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bar(
    StatBarDatum d,
    int maxValue,
    int i,
    int n,
    bool thin,
    bool showValue,
    int step,
  ) {
    // Cascade : chaque barre démarre légèrement après la précédente.
    final start = n <= 1 ? 0.0 : (i / n) * 0.35;
    final t = ((_c.value - start) / (1 - 0.35)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    final frac = (d.value <= 0 ? 0.0 : d.value / maxValue) * eased;
    final color = d.value <= 0
        ? Colors.grey.shade200
        : (widget.barColor ?? jauneStatColor(d.value));
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
            child: ConstrainedBox(
              // Largeur plafonnée quand il y a peu de barres (ex. « Tout » sur
              // un historique court) : pas de barre pleine largeur disgracieuse.
              constraints: BoxConstraints(maxWidth: thin ? double.infinity : 46),
              child: d.value <= 0
                  ? Container(
                      height: 3,
                      decoration:
                          BoxDecoration(color: color, borderRadius: radius),
                    )
                  : FractionallySizedBox(
                      heightFactor: frac.clamp(0.02, 1.0),
                      widthFactor: 1,
                      child: Container(
                        decoration:
                            BoxDecoration(color: color, borderRadius: radius),
                      ),
                    ),
            ),
          ),
        ),
        if (widget.showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              i % step == 0 ? d.label : '',
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

/// Tuile compacte (demi-largeur) : un grand chiffre animé + libellé, et au
/// choix un emoji ou un mini-anneau de progression. Pensée pour s'afficher
/// deux par deux dans une grille (DA dashboard Revolut / apps santé).
class StatTile extends StatelessWidget {
  final String emoji;
  final int value;
  final String suffix;
  final String label;
  final Color accent;
  final double? ring; // 0..1 → mini-anneau au lieu de l'emoji

  const StatTile({
    super.key,
    this.emoji = '',
    required this.value,
    this.suffix = '',
    required this.label,
    this.accent = JauneColors.lemonDeep,
    this.ring,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: ring != null
          ? Column(
              // Style « anneau d'activité » : la valeur vit au centre de
              // l'anneau, le libellé dessous.
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: _MiniRing(
                    progress: ring!,
                    color: accent,
                    child: CountUpInt(
                      value,
                      suffix: suffix,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _label(),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 12),
                CountUpInt(
                  value,
                  suffix: suffix,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _label(),
                ],
              ],
            ),
    );
  }

  Widget _label() => Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: JauneColors.inkSoft,
          height: 1.25,
        ),
      );
}

/// Petit anneau de progression animé (pour les tuiles), avec contenu central
/// optionnel (ex. la valeur au centre, façon anneau d'activité).
class _MiniRing extends StatefulWidget {
  final double progress;
  final Color color;
  final Widget? child;
  const _MiniRing({required this.progress, required this.color, this.child});

  @override
  State<_MiniRing> createState() => _MiniRingState();
}

class _MiniRingState extends State<_MiniRing>
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _RingPainter(
          widget.progress.clamp(0.0, 1.0) * _c.value,
          [widget.color, widget.color],
          stroke: 6,
        ),
        child: widget.child == null
            ? null
            : Center(child: widget.child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final List<Color> gradient;
  final double stroke;
  _RingPainter(this.progress, this.gradient, {this.stroke = 12.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2 - 1;

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

// =====================================================================
// Patterns par jour de la semaine (7 barres, pire jour mis en avant)
// =====================================================================

class WeekdayChart extends StatelessWidget {
  final List<double> averages; // 0 = lundi … 6 = dimanche
  final List<String> labels; // initiales localisées (L M M J V S D)

  const WeekdayChart({super.key, required this.averages, required this.labels});

  @override
  Widget build(BuildContext context) {
    final maxV = averages.fold<double>(0.0, (m, v) => v > m ? v : m);
    final hasData = maxV > 0;
    int worst = 0;
    for (int i = 1; i < averages.length; i++) {
      if (averages[i] > averages[worst]) worst = i;
    }

    // Zone de barre en Expanded : valeur + label à hauteur fixe → jamais
    // d'overflow, quelle que soit la moyenne.
    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    // Moyenne au-dessus de la barre : l'échelle devient
                    // explicite (sinon plusieurs jours « au max » se ressemblent).
                    SizedBox(
                      height: 15,
                      child: averages[i] > 0
                          ? Center(
                              child: Text(
                                _fmtAvg(averages[i]),
                                style: const TextStyle(
                                  fontSize: 10,
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
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: hasData ? (averages[i] / maxV) : 0.0,
                          ),
                          duration: JauneMotion.emphasized,
                          curve: JauneMotion.smooth,
                          builder: (context, f, _) => FractionallySizedBox(
                            heightFactor: averages[i] <= 0 ? null : f.clamp(0.03, 1.0),
                            widthFactor: 1,
                            child: Container(
                              height: averages[i] <= 0 ? 3 : null,
                              decoration: BoxDecoration(
                                color: hasData && i == worst
                                    ? JauneColors.flame
                                    : JauneColors.lemonDeep.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels.length > i ? labels[i] : '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            hasData && i == worst ? FontWeight.w900 : FontWeight.w700,
                        color: hasData && i == worst
                            ? JauneColors.flame
                            : Colors.grey.shade600,
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

  /// Format compact d'une moyenne : entier si rond, sinon 1 décimale.
  static String _fmtAvg(double a) =>
      a == a.roundToDouble() ? a.round().toString() : a.toStringAsFixed(1);
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

// =====================================================================
// Cadran 24h : répartition des verres par heure (style horloge radiale)
// =====================================================================

class StatClock extends StatefulWidget {
  final List<int> hourCounts; // longueur 24
  final Color color;
  final String centerTop; // ex: "21 h"
  final String centerBottom; // ex: "heure de pointe"

  const StatClock({
    super.key,
    required this.hourCounts,
    required this.centerTop,
    required this.centerBottom,
    this.color = StatPalette.drinks,
  });

  @override
  State<StatClock> createState() => _StatClockState();
}

class _StatClockState extends State<StatClock>
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
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _ClockPainter(widget.hourCounts, _c.value, widget.color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.centerTop,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: widget.color,
                    ),
                  ),
                  Text(
                    widget.centerBottom,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: JauneColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final List<int> hours;
  final double progress;
  final Color color;
  _ClockPainter(this.hours, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    final innerR = r * 0.42;
    final maxLen = r - innerR - 4;
    final maxCount = hours.fold<int>(1, (m, v) => v > m ? v : m);

    // Cercle de base discret.
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..color = const Color(0xFFEDEFF4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (int h = 0; h < 24; h++) {
      final angle = -math.pi / 2 + (h / 24) * 2 * math.pi;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final count = hours[h];
      final len = (count <= 0 ? 0.0 : maxLen * count / maxCount) * progress;
      final start = center + dir * innerR;
      final end = center + dir * (innerR + math.max(len, count > 0 ? 3 : 0));
      final paint = Paint()
        ..color = count <= 0
            ? const Color(0xFFEDEFF4)
            : color.withValues(alpha: 0.45 + 0.55 * count / maxCount)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      if (count > 0) canvas.drawLine(start, end, paint);
    }

    // Repères cardinaux : 0h (haut), 6h (droite), 12h (bas), 18h (gauche).
    const labels = {0: '0h', 6: '6h', 12: '12h', 18: '18h'};
    labels.forEach((h, text) {
      final angle = -math.pi / 2 + (h / 24) * 2 * math.pi;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final pos = center + dir * (r - 8);
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.progress != progress || old.hours != hours;
}

// =====================================================================
// Carte « Repères à moindre risque » (Santé publique France)
// =====================================================================

class GuidelineRow extends StatelessWidget {
  final String label;
  final String value;
  final double? gaugeFraction; // si non nul : barre de jauge
  final bool ok;

  const GuidelineRow({
    super.key,
    required this.label,
    required this.value,
    required this.ok,
    this.gaugeFraction,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? StatPalette.sober : StatPalette.drinks;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: JauneColors.ink,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          if (gaugeFraction != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 7, color: const Color(0xFFEDEFF4)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: gaugeFraction!.clamp(0.0, 1.0)),
                    duration: JauneMotion.emphasized,
                    curve: JauneMotion.smooth,
                    builder: (context, f, _) => FractionallySizedBox(
                      widthFactor: f,
                      child: Container(height: 7, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
