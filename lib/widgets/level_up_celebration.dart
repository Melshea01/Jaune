import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/l10n_helpers.dart' as l10n_helpers;
import '../services/audio_service.dart';
import '../services/character_service.dart';
import '../theme/jaune_design.dart';
import '../utils/jaune_haptics.dart';
import 'pressable.dart';
import 'share_card.dart';

/// Overlay plein écran de célébration de passage de niveau :
/// burst de confettis, titre élastique avec shimmer, rang, et liste
/// des déblocables gagnés en cascade.
class LevelUpCelebration {
  /// Retourne un Future qui se résout à la fermeture — permet d'enchaîner
  /// une réaction du personnage (ex : mega_jump du citron).
  /// [skin] : le citron de la carte de partage porte le skin équipé.
  static Future<void> show({
    required BuildContext context,
    required int newLevel,
    required List<LevelUnlock> unlocks,
    int? fromLevel,
    String skin = '',
  }) {
    JauneHaptics.celebrate();
    AudioService.instance.playLevelUpSound();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (context, _, __) => Material(
            type: MaterialType.transparency,
            child: _CelebrationView(
              newLevel: newLevel,
              fromLevel: fromLevel ?? newLevel - 1,
              unlocks: unlocks,
              skin: skin,
            ),
          ),
    );
  }
}

class _CelebrationView extends StatefulWidget {
  final int newLevel;
  final int fromLevel;
  final List<LevelUnlock> unlocks;
  final String skin;

  const _CelebrationView({
    required this.newLevel,
    required this.fromLevel,
    required this.unlocks,
    this.skin = '',
  });

  @override
  State<_CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<_CelebrationView>
    with TickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final AnimationController _contentController;
  late final AnimationController _shimmerController;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..forward();

    // Allongé pour laisser respirer la cascade des cartes d'unlock
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    final rng = math.Random();
    _particles = List.generate(90, (_) => _ConfettiParticle.random(rng));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _contentController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  /// Vrai quand ce level-up fait entrer dans un nouveau monde (arène).
  bool get _isNewWorld =>
      widget.fromLevel >= 1 &&
      chapterOfLevel(widget.newLevel).id != chapterOfLevel(widget.fromLevel).id;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) _shimmerController.stop();

    final scaleIn = CurvedAnimation(
      parent: _contentController,
      // Le pop ne consomme que le début du controller (rallongé pour les
      // cartes) : même tempo élastique qu'avant
      curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
    );
    final fadeIn = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );

    return Stack(
      children: [
        // Fond flouté sombre
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),

        // Confettis : burst radial puis chute balistique
        if (!reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
                    ),
                  );
                },
              ),
            ),
          ),

        // Contenu
        Positioned.fill(
          child: SafeArea(
            child: FadeTransition(
              opacity: fadeIn,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: scaleIn,
                    child: Column(
                      children: [
                        _LevelClimb(
                          fromLevel: widget.fromLevel,
                          toLevel: widget.newLevel,
                          color: chapterColorOf(widget.newLevel),
                        ),
                        const SizedBox(height: 12),
                        if (_isNewWorld)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _NewWorldBanner(
                              color: chapterColorOf(widget.newLevel),
                            ),
                          ),
                        _buildShimmeringTitle(reduceMotion),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final fr =
                                Localizations.localeOf(context).languageCode ==
                                'fr';
                            final chapter = chapterOfLevel(widget.newLevel);
                            return Text(
                              '${chapter.emoji}  ${chapter.name(fr)}',
                              style: TextStyle(
                                fontSize: _isNewWorld ? 24 : 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (widget.unlocks.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          // Coffre qui s'ouvre : motif de récompense des jalons
                          const _ChestReveal(),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context).unlockedBanner,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Cascade : chaque carte arrive avec un léger décalage
                          ...widget.unlocks.indexed.map(
                            (entry) => _StaggeredReveal(
                              controller: _contentController,
                              index: entry.$1,
                              child: _buildUnlockCard(entry.$2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  _buildContinueButton(),
                  const SizedBox(height: 12),
                  _buildShareButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "NIVEAU {n}" doré avec balayage de reflet — même technique que le
  /// CTA BeJaune de la home (_buildShineEffect), portée sur du texte
  Widget _buildShimmeringTitle(bool reduceMotion) {
    final title = Text(
      AppLocalizations.of(context).levelUpTitle(widget.newLevel),
      style: const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        color: JauneColors.lemon,
        letterSpacing: 2,
        shadows: [
          Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 8),
        ],
      ),
    );
    if (reduceMotion) return title;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        // Balayage pendant 40% du cycle puis repos (cf. _buildShineEffect)
        final sweep = Curves.easeInOut.transform(
          (_shimmerController.value / 0.4).clamp(0.0, 1.0),
        );
        return ShaderMask(
          shaderCallback: (bounds) {
            final dx = bounds.width * (sweep * 2 - 0.5);
            return LinearGradient(
              colors: const [
                JauneColors.lemon,
                Colors.white,
                JauneColors.lemon,
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: GradientTranslation(dx, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: title,
    );
  }

  Widget _buildUnlockCard(LevelUnlock unlock) {
    final bool fr = Localizations.localeOf(context).languageCode == 'fr';
    final icon = unlock.icon;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(
          color: JauneColors.lemon.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n_helpers.unlockTitle(unlock, fr),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n_helpers.unlockDescription(unlock, fr),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Partage une carte brandée du level-up — le moment de fierté devient
  /// le vecteur viral de l'app
  Widget _buildShareButton() {
    final label = AppLocalizations.of(context).shareAction;
    return PressableScale(
      semanticLabel: label,
      onTap:
          () => ShareCard.shareLevel(
            context,
            level: widget.newLevel,
            skin: widget.skin,
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ios_share, size: 17, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return PressableScale(
      semanticLabel: AppLocalizations.of(context).continueLabel,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
      },
      haptic: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [JauneColors.lemon, JauneColors.lemonDeep],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: JauneColors.lemon.withValues(alpha: 0.5),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Text(
          AppLocalizations.of(context).continueLabel,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Translation pure pour le shader du shimmer
class GradientTranslation extends GradientTransform {
  final double dx;
  final double dy;
  const GradientTranslation(this.dx, this.dy);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, dy, 0);
}

/// Révèle [child] en fondu + glissement vers le haut, décalé selon [index]
/// sur la fin du [controller] — l'effet cascade des cartes d'unlock.
class _StaggeredReveal extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggeredReveal({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double start = (0.35 + index * 0.12).clamp(0.0, 0.85);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start,
        (start + 0.3).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder:
          (context, _) => Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - animation.value)),
              child: child,
            ),
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confettis — burst radial depuis le titre, puis chute balistique
// ---------------------------------------------------------------------------

class _ConfettiParticle {
  final double angle; // direction initiale du burst
  final double speed; // norme de la vélocité initiale (fraction écran/s)
  final double rotationSpeed;
  final double size;
  final Color color;
  final double delay; // 0..0.25 départ décalé
  final bool isCircle;

  _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.delay,
    required this.isCircle,
  });

  static const List<Color> _palette = [
    JauneColors.lemon,
    JauneColors.lemonDeep,
    Color(0xFF43E97B),
    JauneColors.sky,
    Color(0xFFF857A6),
    Colors.white,
  ];

  factory _ConfettiParticle.random(math.Random rng) {
    // Biais vers le haut : l'explosion part du titre et retombe en pluie
    final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi * 1.6;
    return _ConfettiParticle(
      angle: angle,
      speed: 0.35 + rng.nextDouble() * 0.55,
      rotationSpeed: (rng.nextDouble() - 0.5) * 14,
      size: 6 + rng.nextDouble() * 8,
      color: _palette[rng.nextInt(_palette.length)],
      delay: rng.nextDouble() * 0.18,
      isCircle: rng.nextBool(),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  /// Durée réelle de l'animation — convertit progress en secondes
  static const double _totalSeconds = 3.5;

  /// Gravité en fractions de hauteur d'écran / s²
  static const double _gravity = 0.55;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Origine du burst : centre horizontal, à hauteur du titre "NIVEAU n"
    final origin = Offset(size.width / 2, size.height * 0.38);

    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final seconds = t * _totalSeconds;
      // Balistique : p(t) = p₀ + v₀·t + ½·g·t²
      final x =
          origin.dx + math.cos(p.angle) * p.speed * size.width * 0.6 * seconds;
      final y =
          origin.dy +
          math.sin(p.angle) * p.speed * size.height * 0.5 * seconds +
          0.5 * _gravity * size.height * seconds * seconds;
      if (y > size.height + 20) continue;

      final opacity = t > 0.75 ? (1 - t) / 0.25 : 1.0;
      paint.color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * t);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Bannière « nouveau monde » : pastille pulsante affichée quand le level-up
/// fait franchir une frontière de chapitre (entrée dans une nouvelle arène).
class _NewWorldBanner extends StatefulWidget {
  final Color color;
  const _NewWorldBanner({required this.color});

  @override
  State<_NewWorldBanner> createState() => _NewWorldBannerState();
}

class _NewWorldBannerState extends State<_NewWorldBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final label = AppLocalizations.of(context).newWorldBanner;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = reduce ? 0.0 : Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(scale: 1 + 0.04 * t, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(JauneRadii.pill),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 16,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Le citron grimpe physiquement du nœud précédent au nouveau niveau : il
/// saute le long du segment qui se remplit, et atterrit avec un rebond.
/// C'est le « moment du level-up » rendu concret.
class _LevelClimb extends StatefulWidget {
  final int fromLevel;
  final int toLevel;
  final Color color;

  const _LevelClimb({
    required this.fromLevel,
    required this.toLevel,
    required this.color,
  });

  @override
  State<_LevelClimb> createState() => _LevelClimbState();
}

class _LevelClimbState extends State<_LevelClimb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );

  static const double _w = 120;
  static const double _h = 150;
  static const double _cx = 60;
  static const double _yTop = 28;
  static const double _yBot = 126;

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 770), () {
      if (mounted) JauneHaptics.tick();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // reduce-motion : lu ici (safe), on saute à la frame finale.
    final reduce = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      width: _w,
      height: _h,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = reduce ? 1.0 : _c.value;
          final climb = ((t - 0.12) / 0.6).clamp(0.0, 1.0);
          final eased = Curves.easeInOutCubic.transform(climb);
          final ly = ui.lerpDouble(_yBot, _yTop, eased)!;
          final lx = _cx + math.sin(climb * math.pi) * 16;
          final landT = ((t - 0.72) / 0.28).clamp(0.0, 1.0);
          final landScale =
              t < 0.72
                  ? 1.0
                  : 1.0 +
                      0.20 * Curves.easeOut.transform(landT) * (1 - landT) * 2;
          final landed = t > 0.74;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ClimbPainter(
                    ly: ly,
                    color: widget.color,
                    landed: landed,
                  ),
                ),
              ),
              // Niveau de départ (acquis)
              Positioned(
                left: 0,
                right: 0,
                top: _yBot - 9,
                child: Center(
                  child: Text(
                    '${widget.fromLevel}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Nouveau niveau (révélé à l'atterrissage, sous le citron)
              if (landed)
                Positioned(
                  left: 0,
                  right: 0,
                  top: _yTop - 9,
                  child: Center(
                    child: Text(
                      '${widget.toLevel}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Le citron qui grimpe
              Positioned(
                left: lx - 16,
                top: ly - 17,
                child: Transform.scale(
                  scale: landScale,
                  child: const Text('🍋', style: TextStyle(fontSize: 32)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClimbPainter extends CustomPainter {
  final double ly;
  final Color color;
  final bool landed;

  _ClimbPainter({required this.ly, required this.color, required this.landed});

  static const double _cx = 60;
  static const double _yTop = 28;
  static const double _yBot = 126;
  static const double _r = 19;

  @override
  void paint(Canvas canvas, Size size) {
    // Segment gris (à parcourir)
    final grey =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(_cx, _yBot), const Offset(_cx, _yTop), grey);

    // Segment rempli jusqu'au citron
    final fill =
        Paint()
          ..color = color
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(_cx, _yBot), Offset(_cx, ly), fill);

    // Nœud de départ (acquis)
    canvas.drawCircle(const Offset(_cx, _yBot), _r, Paint()..color = color);
    canvas.drawCircle(
      const Offset(_cx, _yBot),
      _r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.5),
    );

    // Nœud d'arrivée
    canvas.drawCircle(
      const Offset(_cx, _yTop),
      _r,
      Paint()..color = landed ? color : Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      const Offset(_cx, _yTop),
      _r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: landed ? 0.6 : 0.3),
    );
  }

  @override
  bool shouldRepaint(_ClimbPainter old) =>
      old.ly != ly || old.landed != landed || old.color != color;
}

/// Coffre qui tremble puis s'ouvre dans un éclat — motif de récompense des
/// jalons. Auto-joué une fois à l'apparition.
class _ChestReveal extends StatefulWidget {
  const _ChestReveal();

  @override
  State<_ChestReveal> createState() => _ChestRevealState();
}

class _ChestRevealState extends State<_ChestReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    // Petit « clac » d'ouverture
    Future.delayed(const Duration(milliseconds: 720), () {
      if (mounted) JauneHaptics.tick();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = reduce ? 1.0 : _c.value;
        double rot = 0;
        double scale = 1;
        final bool opened = t > 0.55;

        if (t < 0.55) {
          // Tremblement qui s'amplifie avant l'ouverture
          final ramp = t / 0.55;
          rot = math.sin(t * 22 * math.pi) * 0.16 * ramp;
          scale = 1 + 0.06 * ramp;
        } else {
          // Pop d'ouverture puis retour
          final p = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
          scale = 1 + 0.55 * Curves.easeOut.transform(p) * (1 - p);
        }

        return SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (opened)
                Opacity(
                  opacity: (1 - ((t - 0.55) / 0.45)).clamp(0.0, 1.0),
                  child: const Text('✨', style: TextStyle(fontSize: 52)),
                ),
              Transform.rotate(
                angle: rot,
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    opened ? '🎉' : '🎁',
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
