import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class GroundShadowPainter extends CustomPainter {
  final Color color;
  final double blurSigma;
  final double coreFactor; // proportion du cœur (0.5..0.7)

  // Paramètres animés
  final double t; // 0..1 (phase)
  final double squashAmp; // amplitude de squash/scale
  final double shiftAmp; // amplitude du déplacement horizontal

  GroundShadowPainter({
    required this.color,
    this.blurSigma = 28,
    this.coreFactor = 0.6,
    this.t = 0.0,
    this.squashAmp = 0.06,
    this.shiftAmp = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect full = Offset.zero & size;

    // Oscillations douces
    final double twoPi = math.pi * 2.0;
    final double s = math.sin(twoPi * t);
    final double c = math.cos(twoPi * t);

    // Légère respiration + décalage
    final double scaleX = 1.0 + squashAmp * s;
    final double scaleY = 1.0 - squashAmp * s * 0.5;
    final double dx = shiftAmp * math.sin(twoPi * t + math.pi / 3);

    // Variation subtile du flou
    final double extraBlur = 4.0 * (0.5 + 0.5 * (1.0 - c.abs()));

    canvas.save();

    // Translation légère
    canvas.translate(dx, 0);

    // Scale par rapport au centre
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-size.width / 2, -size.height / 2);

    // Halo large (très doux)
    final Paint halo = Paint()
      ..color = color.withOpacity(0.26)
      ..maskFilter = ui.MaskFilter.blur(
        ui.BlurStyle.normal,
        blurSigma + extraBlur,
      );
    canvas.drawOval(full, halo);

    // Cœur de contact (plus sombre, un peu plus petit)
    final double deflateDy = size.height * (1 - coreFactor);
    final Rect core = full.deflate(deflateDy);
    final Paint corePaint = Paint()
      ..color = color.withOpacity(0.42)
      ..maskFilter = ui.MaskFilter.blur(
        ui.BlurStyle.normal,
        (blurSigma * 0.6) + (extraBlur * 0.5),
      );
    canvas.drawOval(core, corePaint);

    // Traîne asymétrique pour naturel
    final Rect tail = full
        .inflate(size.height * 0.08)
        .shift(const Offset(0, 2));
    final Paint tailPaint = Paint()
      ..color = color.withOpacity(0.16)
      ..maskFilter = ui.MaskFilter.blur(
        ui.BlurStyle.normal,
        (blurSigma * 1.2) + (extraBlur * 0.3),
      );
    canvas.drawOval(tail, tailPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GroundShadowPainter old) {
    return old.color != color ||
        old.blurSigma != blurSigma ||
        old.coreFactor != coreFactor ||
        old.t != t ||
        old.squashAmp != squashAmp ||
        old.shiftAmp != shiftAmp;
  }
}