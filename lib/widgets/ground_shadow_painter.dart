import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

/// A custom painter that renders a soft, animated ground shadow.
/// It uses multiple blurred ovals to create a realistic ambient occlusion effect.
class GroundShadowPainter extends CustomPainter {
  final Color color;
  final double blurSigma;
  final double coreFactor; // Proportion of the core shadow (e.g., 0.6)

  // Animation parameters
  final double t; // Phase from 0.0 to 1.0
  final double squashAmp; // Amplitude of the squash/stretch effect
  final double shiftAmp; // Amplitude of the horizontal shift

  /// 0..1 : hauteur de saut du personnage. Plus il est haut, plus l'ombre
  /// rétrécit, s'éclaircit et se floute — vend le poids et la hauteur.
  final double jumpFactor;

  GroundShadowPainter({
    required this.color,
    this.blurSigma = 28.0,
    this.coreFactor = 0.6,
    this.t = 0.0,
    this.squashAmp = 0.06,
    this.shiftAmp = 6.0,
    this.jumpFactor = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Offset.zero & size;

    // Gentle oscillations for a breathing effect
    final double twoPi = math.pi * 2.0;
    final double sinT = math.sin(twoPi * t);
    final double cosT = math.cos(twoPi * t);

    // Couplage au saut : ombre plus petite, plus claire, plus diffuse
    final double j = jumpFactor.clamp(0.0, 1.0);
    final double jumpScale = 1.0 - 0.45 * j;

    // Calculate animation transformations
    final double scaleX = (1.0 + squashAmp * sinT) * jumpScale;
    final double scaleY =
        (1.0 - squashAmp * sinT * 0.5) * jumpScale; // Squash less vertically
    final double dx = shiftAmp * math.sin(twoPi * t + math.pi / 3);

    // Subtle variation in blur to sync with the breathing
    final double dynamicBlurFactor = 0.5 + 0.5 * (1.0 - cosT.abs());
    final double extraBlur = 4.0 * dynamicBlurFactor + 10.0 * j;

    canvas.save();

    // Apply transformations relative to the center
    canvas.translate(fullRect.center.dx, fullRect.center.dy);
    canvas.translate(dx, 0); // Apply horizontal shift
    canvas.scale(scaleX, scaleY);
    canvas.translate(-fullRect.center.dx, -fullRect.center.dy);

    // L'ombre s'éclaircit avec la hauteur du saut
    final double jumpFade = 1.0 - 0.5 * j;

    // Layer 1: Wide, soft halo for ambient shadow
    final haloPaint =
        Paint()
          ..color = color.withValues(alpha: 0.26 * jumpFade)
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            blurSigma + extraBlur,
          );
    canvas.drawOval(fullRect, haloPaint);

    // Layer 2: Darker core for contact shadow
    final double coreDeflate = size.height * (1.0 - coreFactor);
    final Rect coreRect = fullRect.deflate(coreDeflate);
    final corePaint =
        Paint()
          ..color = color.withValues(alpha: 0.42 * jumpFade)
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            (blurSigma * 0.6) + (extraBlur * 0.5),
          );
    canvas.drawOval(coreRect, corePaint);

    // Layer 3: Asymmetrical tail for a more natural look
    final Rect tailRect = fullRect
        .inflate(size.height * 0.08)
        .shift(const Offset(0, 2));
    final tailPaint =
        Paint()
          ..color = color.withValues(alpha: 0.16 * jumpFade)
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            (blurSigma * 1.2) + (extraBlur * 0.3),
          );
    canvas.drawOval(tailRect, tailPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GroundShadowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.blurSigma != blurSigma ||
        oldDelegate.coreFactor != coreFactor ||
        oldDelegate.t != t ||
        oldDelegate.squashAmp != squashAmp ||
        oldDelegate.shiftAmp != shiftAmp ||
        oldDelegate.jumpFactor != jumpFactor;
  }
}
