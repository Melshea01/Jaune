import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/journey_data.dart';

/// Décor d'ambiance discret du monde courant, peint dans le tiers supérieur
/// de l'écran (là où le dégradé du monde est le plus présent) : feuilles,
/// vagues, montagnes, gratte-ciels, étoiles. Très basse opacité → ne gêne
/// jamais la lisibilité de l'UI. À poser en fond (IgnorePointer).
class WorldAmbiance extends StatelessWidget {
  final int level;
  const WorldAmbiance({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _WorldAmbiancePainter(
          chapterId: chapterOfLevel(level).id,
          color: chapterColorOf(level),
        ),
      ),
    );
  }
}

class _WorldAmbiancePainter extends CustomPainter {
  final int chapterId;
  final Color color;

  _WorldAmbiancePainter({required this.chapterId, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (chapterId) {
      case 1:
        _orchard(canvas, size);
      case 2:
        _coast(canvas, size);
      case 3:
        _peaks(canvas, size);
      case 4:
        _city(canvas, size);
      default:
        _stars(canvas, size);
    }
  }

  // --- Ch.1 Le Verger : feuilles flottantes ---
  void _orchard(Canvas canvas, Size size) {
    final p = Paint()..color = color.withValues(alpha: 0.12);
    const leaves = [
      [0.14, 0.10, 10.0],
      [0.82, 0.08, 13.0],
      [0.30, 0.20, 8.0],
      [0.66, 0.17, 11.0],
      [0.48, 0.06, 9.0],
      [0.90, 0.22, 7.0],
    ];
    for (final l in leaves) {
      final c = Offset(size.width * l[0], size.height * l[1]);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(l[0] * math.pi);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: l[2] * 2, height: l[2]),
        p,
      );
      canvas.restore();
    }
  }

  // --- Ch.2 La Côte : vagues ---
  void _coast(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.13);
    for (int line = 0; line < 3; line++) {
      final y = size.height * (0.10 + line * 0.055);
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += size.width / 16) {
        path.relativeQuadraticBezierTo(
          size.width / 32, line.isEven ? -7 : 7,
          size.width / 16, 0,
        );
      }
      canvas.drawPath(path, p);
    }
  }

  // --- Ch.3 Les Sommets : silhouette de montagnes ---
  void _peaks(Canvas canvas, Size size) {
    final base = size.height * 0.30;
    final path = Path()..moveTo(0, base);
    final peaks = [0.12, 0.30, 0.52, 0.74, 0.93];
    final heights = [0.16, 0.22, 0.12, 0.26, 0.15];
    for (int i = 0; i < peaks.length; i++) {
      path.lineTo(size.width * peaks[i], base - size.height * heights[i]);
      final nextX =
          i + 1 < peaks.length ? (peaks[i] + peaks[i + 1]) / 2 : 1.0;
      path.lineTo(size.width * nextX, base);
    }
    path
      ..lineTo(size.width, base)
      ..lineTo(size.width, base + 4)
      ..lineTo(0, base + 4)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.10));
  }

  // --- Ch.4 La Ville : skyline ---
  void _city(Canvas canvas, Size size) {
    final base = size.height * 0.30;
    final p = Paint()..color = color.withValues(alpha: 0.11);
    const towers = [
      [0.04, 0.12],
      [0.16, 0.20],
      [0.27, 0.10],
      [0.40, 0.24],
      [0.54, 0.15],
      [0.66, 0.22],
      [0.80, 0.12],
      [0.90, 0.18],
    ];
    for (final t in towers) {
      final w = size.width * 0.085;
      final h = size.height * t[1];
      canvas.drawRect(
        Rect.fromLTWH(size.width * t[0], base - h, w, h + 4),
        p,
      );
    }
  }

  // --- Ch.5 Les Étoiles : étoiles + croissant de lune ---
  void _stars(Canvas canvas, Size size) {
    final p = Paint()..color = color.withValues(alpha: 0.22);
    const stars = [
      [0.10, 0.08, 2.5],
      [0.22, 0.16, 1.8],
      [0.35, 0.06, 2.2],
      [0.47, 0.13, 1.6],
      [0.58, 0.05, 2.8],
      [0.68, 0.18, 1.7],
      [0.78, 0.09, 2.3],
      [0.88, 0.15, 2.0],
      [0.16, 0.24, 1.5],
      [0.52, 0.22, 1.9],
      [0.92, 0.26, 1.6],
      [0.40, 0.27, 1.4],
    ];
    for (final s in stars) {
      canvas.drawCircle(
        Offset(size.width * s[0], size.height * s[1]),
        s[2],
        p,
      );
    }
    // Croissant de lune : différence de deux cercles.
    final moonC = Offset(size.width * 0.84, size.height * 0.07);
    const r = 13.0;
    final full = Path()..addOval(Rect.fromCircle(center: moonC, radius: r));
    final cut = Path()
      ..addOval(Rect.fromCircle(center: moonC.translate(5, -3), radius: r));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, cut),
      Paint()..color = color.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(_WorldAmbiancePainter old) =>
      old.chapterId != chapterId || old.color != color;
}
