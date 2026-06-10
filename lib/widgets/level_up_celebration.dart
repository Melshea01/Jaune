import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/character_service.dart';

/// Overlay plein écran de célébration de passage de niveau :
/// confettis, titre élastique, rang, et liste des déblocables gagnés.
class LevelUpCelebration {
  /// Retourne un Future qui se résout à la fermeture — permet d'enchaîner
  /// une réaction du personnage (ex : mega_jump du citron).
  static Future<void> show({
    required BuildContext context,
    required int newLevel,
    required List<LevelUnlock> unlocks,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (context, _, __) =>
              _CelebrationView(newLevel: newLevel, unlocks: unlocks),
    );
  }
}

class _CelebrationView extends StatefulWidget {
  final int newLevel;
  final List<LevelUnlock> unlocks;

  const _CelebrationView({required this.newLevel, required this.unlocks});

  @override
  State<_CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<_CelebrationView>
    with TickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final AnimationController _contentController;
  late final List<_ConfettiParticle> _particles;

  String get _rankTitle => switch (widget.newLevel) {
    <= 5 => 'Apprenti 🌱',
    <= 15 => 'Explorateur 🗺️',
    <= 30 => 'Maître 🏆',
    _ => 'Légende ⭐',
  };

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..forward();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    final rng = math.Random();
    _particles = List.generate(80, (_) => _ConfettiParticle.random(rng));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleIn = CurvedAnimation(
      parent: _contentController,
      curve: Curves.elasticOut,
    );
    final fadeIn = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
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

        // Confettis
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
                        const Text('🎉', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 12),
                        Text(
                          'NIVEAU ${widget.newLevel}',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF7D83F),
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _rankTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
                          const Text(
                            '✨ DÉBLOQUÉ ✨',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.unlocks.map(_buildUnlockCard),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockCard(LevelUnlock unlock) {
    final icon = switch (unlock.type) {
      UnlockType.citronState => '🎨',
      UnlockType.feature => '⭐',
      UnlockType.badge => '🏅',
      UnlockType.message => '💬',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF7D83F).withValues(alpha: 0.6),
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
                  unlock.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unlock.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF7D83F), Color(0xFFF6B73F)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF7D83F).withValues(alpha: 0.5),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: const Text(
          'Continuer',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confettis
// ---------------------------------------------------------------------------

class _ConfettiParticle {
  final double startX; // 0..1 fraction de la largeur
  final double horizontalDrift; // dérive latérale
  final double fallSpeed; // multiplicateur de vitesse de chute
  final double rotationSpeed;
  final double size;
  final Color color;
  final double delay; // 0..0.5 départ décalé
  final bool isCircle;

  _ConfettiParticle({
    required this.startX,
    required this.horizontalDrift,
    required this.fallSpeed,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.delay,
    required this.isCircle,
  });

  static const List<Color> _palette = [
    Color(0xFFF7D83F),
    Color(0xFFF6B73F),
    Color(0xFF43e97b),
    Color(0xFF95C6F4),
    Color(0xFFf857a6),
    Colors.white,
  ];

  factory _ConfettiParticle.random(math.Random rng) {
    return _ConfettiParticle(
      startX: rng.nextDouble(),
      horizontalDrift: (rng.nextDouble() - 0.5) * 120,
      fallSpeed: 0.6 + rng.nextDouble() * 0.8,
      rotationSpeed: (rng.nextDouble() - 0.5) * 12,
      size: 6 + rng.nextDouble() * 8,
      color: _palette[rng.nextInt(_palette.length)],
      delay: rng.nextDouble() * 0.4,
      isCircle: rng.nextBool(),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = p.startX * size.width + p.horizontalDrift * t;
      final y = -20 + (size.height + 40) * t * p.fallSpeed;
      if (y > size.height + 20) continue;

      final opacity = t > 0.8 ? (1 - t) / 0.2 : 1.0;
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
