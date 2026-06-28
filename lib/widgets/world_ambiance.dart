import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/journey_data.dart';

/// Décor d'ambiance **animé** du monde courant, peint dans le tiers supérieur
/// de l'écran : feuilles qui flottent, vagues qui ondulent, nuages qui
/// dérivent, fenêtres/étoiles qui scintillent, étoile filante. Très basse
/// opacité → ne gêne jamais l'UI. À poser en fond (déjà en IgnorePointer).
class WorldAmbiance extends StatefulWidget {
  final int level;
  const WorldAmbiance({super.key, required this.level});

  @override
  State<WorldAmbiance> createState() => _WorldAmbianceState();
}

class _WorldAmbianceState extends State<WorldAmbiance>
    with SingleTickerProviderStateMixin {
  // Boucle longue : la « phase » t ∈ [0,1] alimente toutes les oscillations
  // (toutes en cycles entiers → raccord sans saut à la boucle).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _WorldAmbiancePainter(
            chapterId: chapterOfLevel(widget.level).id,
            color: chapterColorOf(widget.level),
            t: reduce ? 0.0 : _c.value,
          ),
        ),
      ),
    );
  }
}

class _WorldAmbiancePainter extends CustomPainter {
  final int chapterId;
  final Color color;
  final double t; // phase ∈ [0,1]

  _WorldAmbiancePainter({
    required this.chapterId,
    required this.color,
    required this.t,
  });

  static const double _tau = math.pi * 2;

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

  // --- Ch.1 Le Verger : feuilles qui flottent et tournoient ---
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
    for (int i = 0; i < leaves.length; i++) {
      final l = leaves[i];
      final phase = i / leaves.length;
      final dy = math.sin(_tau * (t + phase)) * size.height * 0.018;
      final dx = math.sin(_tau * (t + phase * 1.7)) * size.width * 0.012;
      final cx = size.width * l[0] + dx;
      final cy = size.height * l[1] + dy;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(l[0] * math.pi + math.sin(_tau * (t + phase)) * 0.4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: l[2] * 2, height: l[2]),
        p,
      );
      canvas.restore();
    }
  }

  // --- Ch.2 La Côte : vagues qui défilent ---
  void _coast(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.13);
    const wavelength = 1 / 2.5; // en fraction de largeur
    for (int line = 0; line < 3; line++) {
      final y = size.height * (0.10 + line * 0.055);
      final amp = 6.0 + line * 1.5;
      final dir = line.isEven ? 1 : -1;
      final path = Path();
      for (double fx = 0; fx <= 1.0001; fx += 0.02) {
        final x = size.width * fx;
        final yy = y +
            amp *
                math.sin(_tau * (fx / wavelength - dir * t));
        if (fx == 0) {
          path.moveTo(x, yy);
        } else {
          path.lineTo(x, yy);
        }
      }
      canvas.drawPath(path, p);
    }
  }

  // --- Ch.3 Les Sommets : montagnes fixes + nuages qui dérivent ---
  void _peaks(Canvas canvas, Size size) {
    // Nuages (derrière les montagnes)
    final cloud = Paint()..color = color.withValues(alpha: 0.08);
    const clouds = [
      [0.0, 0.09, 34.0],
      [0.0, 0.15, 26.0],
      [0.0, 0.06, 30.0],
    ];
    for (int i = 0; i < clouds.length; i++) {
      final c = clouds[i];
      final speed = 0.12 + i * 0.05;
      final fx = ((c[0] + t * speed + i * 0.4) % 1.2) - 0.1; // dérive + wrap
      final cx = size.width * fx;
      final cy = size.height * c[1];
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: c[2] * 2, height: c[2]),
        cloud,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + c[2] * 0.7, cy + 3),
            width: c[2] * 1.4,
            height: c[2] * 0.8),
        cloud,
      );
    }

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

  // --- Ch.4 La Ville : skyline + fenêtres qui scintillent ---
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
    for (final tw in towers) {
      final w = size.width * 0.085;
      final h = size.height * tw[1];
      canvas.drawRect(Rect.fromLTWH(size.width * tw[0], base - h, w, h + 4), p);
    }
    // Fenêtres scintillantes
    const windows = [
      [0.07, 0.22],
      [0.19, 0.16],
      [0.21, 0.24],
      [0.43, 0.12],
      [0.45, 0.20],
      [0.57, 0.22],
      [0.69, 0.14],
      [0.83, 0.24],
      [0.92, 0.20],
    ];
    for (int i = 0; i < windows.length; i++) {
      final wv = windows[i];
      final phase = i / windows.length;
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(_tau * (2 * t + phase)));
      final wp = Paint()..color = color.withValues(alpha: 0.10 + 0.18 * tw);
      canvas.drawRect(
        Rect.fromLTWH(size.width * wv[0], size.height * wv[1], 4, 4),
        wp,
      );
    }
  }

  // --- Ch.5 Les Étoiles : scintillement + étoile filante + lune ---
  void _stars(Canvas canvas, Size size) {
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
    for (int i = 0; i < stars.length; i++) {
      final s = stars[i];
      final phase = i / stars.length;
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(_tau * (2 * t + phase)));
      canvas.drawCircle(
        Offset(size.width * s[0], size.height * s[1]),
        s[2],
        Paint()..color = color.withValues(alpha: 0.10 + 0.18 * tw),
      );
    }

    // Étoile filante : traverse rapidement au début de chaque boucle.
    if (t < 0.18) {
      final st = t / 0.18; // 0→1
      final sx = size.width * (0.15 + 0.7 * st);
      final sy = size.height * (0.05 + 0.12 * st);
      final tail = Offset(sx - 26, sy - 12);
      final fade = math.sin(st * math.pi); // apparaît puis s'efface
      final p = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.45 * fade);
      canvas.drawLine(tail, Offset(sx, sy), p);
      canvas.drawCircle(
        Offset(sx, sy),
        2.2,
        Paint()..color = color.withValues(alpha: 0.6 * fade),
      );
    }

    // Croissant de lune (légère pulsation de halo).
    final moonC = Offset(size.width * 0.84, size.height * 0.07);
    const r = 13.0;
    final glow = 0.5 + 0.5 * math.sin(_tau * t);
    canvas.drawCircle(
      moonC,
      r + 3 + 2 * glow,
      Paint()..color = color.withValues(alpha: 0.06 * glow),
    );
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
      old.t != t || old.chapterId != chapterId || old.color != color;
}
