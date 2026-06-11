import 'package:flutter/material.dart';

/// Halo lumineux doré derrière le citron — la récompense visuelle de la
/// pleine forme. Le rayon pulse avec la respiration du personnage, et
/// l'intensité (spring du moteur) peut dépasser 1.0 lors d'un flash
/// (level-up via kickGlow).
class CitronAuraPainter extends CustomPainter {
  /// 0..1.6 — intensité de l'aura (0 = invisible)
  final double glow;

  /// Valeur de respiration courante du moteur (module le rayon)
  final double breathValue;

  CitronAuraPainter({required this.glow, required this.breathValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (glow <= 0.01) return;

    final center = Offset(size.width / 2, size.height * 0.52);
    final radius =
        size.width * 0.42 * (1 + 0.06 * breathValue) * (0.85 + 0.15 * glow);

    final opacity = (0.38 * glow).clamp(0.0, 0.6);
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE066).withValues(alpha: opacity),
              const Color(0xFFFFD23F).withValues(alpha: opacity * 0.45),
              const Color(0xFFFFE066).withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CitronAuraPainter oldDelegate) =>
      oldDelegate.glow != glow || oldDelegate.breathValue != breathValue;
}
