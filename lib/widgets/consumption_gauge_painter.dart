import 'package:flutter/material.dart';
import 'dart:math' as math;

// Painter pour dessiner les demi-cercles de la jauge autour du bouton
class ConsumptionGaugePainter extends CustomPainter {
  final double
  segments; // nombre de demi-cercles à afficher (peut être fractionnel pour animation)

  ConsumptionGaugePainter(this.segments);

  // Retourne la couleur interpolée pour un segment.
  // Si l'index dépasse la palette, on reste sur la couleur rouge finale.
  Color _colorForIndex(int i, double t) {
    final List<Color> gradientColors = [
      const Color(0xFF43e97b),
      const Color(0xFF38f9d7),
      const Color(0xFFc6e66b),
      const Color(0xFFffd200),
      const Color(0xFFf6a564),
      const Color(0xFFfb8c00),
      const Color(0xFFe53935),
      const Color(0xFFbf1b1b),
      const Color(0xFFff5252),
      const Color(0xFFFF0000),
    ];

    if (i >= gradientColors.length - 1) {
      // Si on dépasse la palette, rester sur le rouge final
      return gradientColors.last;
    }

    final int colorIndexStart = i;
    final int colorIndexEnd = (colorIndexStart + 1).clamp(
      0,
      gradientColors.length - 1,
    );

    return Color.lerp(
      gradientColors[colorIndexStart],
      gradientColors[colorIndexEnd],
      t,
    )!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseStroke = 8.0;
    final baseRadius =
        math.min(size.width, size.height) / 2 - baseStroke / 2 - 2;

    // anneau de fond glass (visible même si segments == 0)
    final Paint bg =
        Paint()
          ..color = Colors.white.withAlpha((0.12 * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;
    final rectBg = Rect.fromCircle(center: center, radius: baseRadius);
    canvas.drawArc(rectBg, 0, 2 * math.pi, false, bg);

    if (segments <= 0) return;

    final int totalToDraw = segments.ceil();
    int lastVisible = totalToDraw - 1;
    double lastCompleted = (segments - lastVisible).clamp(0.0, 1.0);
    if (lastCompleted == 0.0) {
      lastVisible -= 1;
      lastCompleted = 1.0;
    }

    for (int i = 0; i < totalToDraw; i++) {
      final startAngle = -math.pi / 2 + i * math.pi;
      final sweep = math.pi; // demi-tour
      final completed = (segments - i).clamp(0.0, 1.0);
      if (completed <= 0) break;

      final rect = Rect.fromCircle(center: center, radius: baseRadius);
      // Découpage en petits arcs pour un dégradé parfait
      const int subdivisions = 32;
      final int maxSub = (subdivisions * completed).ceil();
      for (int s = 0; s < maxSub; s++) {
        final double t0 = s / subdivisions;
        final double t1 = (s + 1) / subdivisions;
        if (t1 > completed) break;
        final double angle0 = startAngle + sweep * t0;
        final double angle1 = startAngle + sweep * t1;
        final path =
            Path()
              ..moveTo(
                center.dx + baseRadius * math.cos(angle0),
                center.dy + baseRadius * math.sin(angle0),
              )
              ..arcTo(rect, angle0, angle1 - angle0, false);

        final color = _colorForIndex(i, t0);

        // Ajout d'un halo lumineux autour de la jauge
        final haloPaint =
            Paint()
              ..color = color.withAlpha((0.2 * 255).round())
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = baseStroke * 1.5;
        canvas.drawPath(path, haloPaint);

        final paint =
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..isAntiAlias = true
              ..strokeWidth = baseStroke;
        canvas.drawPath(path, paint);
      }
    }

    // Ajouter une ombre au dernier segment visible
    if (lastVisible >= 0) {
      final double startAngle = -math.pi / 2 + lastVisible * math.pi;
      final double sweep = math.pi * lastCompleted;
      final rect = Rect.fromCircle(center: center, radius: baseRadius);

      // Découpage en petits arcs pour un dégradé d'ombre
      const int subdivisions = 32;
      for (int s = 0; s < subdivisions; s++) {
        final double t0 = s / subdivisions;
        final double t1 = (s + 1) / subdivisions;
        if (t1 > lastCompleted) break;

        final double angle0 = startAngle + sweep * t0;
        final double angle1 = startAngle + sweep * t1;
        final path =
            Path()
              ..moveTo(
                center.dx + baseRadius * math.cos(angle0),
                center.dy + baseRadius * math.sin(angle0),
              )
              ..arcTo(rect, angle0, angle1 - angle0, false);

        final shadowOpacity = t1; // Opacité progressive
        final shadowPaint =
            Paint()
              ..color = Colors.black.withAlpha(
                (0.05 * shadowOpacity * 255).round(),
              )
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = baseStroke;
        canvas.drawPath(path, shadowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
