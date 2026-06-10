import 'package:flutter/material.dart';
import 'dart:math' as math;

// Painter pour dessiner les demi-cercles de la jauge autour du bouton
class ConsumptionGaugePainter extends CustomPainter {
  final double segments;

  ConsumptionGaugePainter(this.segments);

  static const List<Color> _gradientColors = [
    Color(0xFF43e97b),
    Color(0xFF38f9d7),
    Color(0xFFc6e66b),
    Color(0xFFffd200),
    Color(0xFFf6a564),
    Color(0xFFfb8c00),
    Color(0xFFe53935),
    Color(0xFFbf1b1b),
    Color(0xFFff5252),
    Color(0xFFFF0000),
  ];

  // Retourne la couleur interpolée pour un segment.
  Color _colorForIndex(int i, double t) {
    if (i >= _gradientColors.length - 1) {
      return _gradientColors.last;
    }
    return Color.lerp(_gradientColors[i], _gradientColors[i + 1], t)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const baseStroke = 8.0;
    final baseRadius =
        math.min(size.width, size.height) / 2 - baseStroke / 2 - 2;

    // Anneau de fond glass (visible même si segments == 0)
    final bgPaint =
        Paint()
          ..color = Colors.white.withAlpha(30) // 0.12 * 255
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, baseRadius, bgPaint);

    if (segments <= 0) return;

    final int totalSegmentsToDraw = segments.ceil();

    for (int i = 0; i < totalSegmentsToDraw; i++) {
      final double completedRatio = (segments - i).clamp(0.0, 1.0);
      if (completedRatio <= 0) break;

      final startAngle = -math.pi / 2 + i * math.pi;
      final sweepAngle = math.pi * completedRatio;

      // Utilisation d'un Shader pour le dégradé, plus performant
      final segmentRect = Rect.fromCircle(center: center, radius: baseRadius);
      final segmentPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = baseStroke
            ..shader = SweepGradient(
              colors: [_colorForIndex(i, 0.0), _colorForIndex(i, 1.0)],
              startAngle: startAngle,
              endAngle: startAngle + math.pi,
            ).createShader(segmentRect);

      canvas.drawArc(segmentRect, startAngle, sweepAngle, false, segmentPaint);

      // Ajout d'un halo lumineux
      final haloPaint =
          Paint()
            ..color = _colorForIndex(i, 0.5).withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = baseStroke * 1.5;
      canvas.drawArc(segmentRect, startAngle, sweepAngle, false, haloPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConsumptionGaugePainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
