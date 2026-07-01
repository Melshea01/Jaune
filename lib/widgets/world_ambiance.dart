import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/journey_data.dart';

/// Décor d'ambiance **animé et en profondeur** du monde courant : un halo de
/// lumière qui dérive, des particules en 3 plans de profondeur (parallax), et
/// les motifs du monde sur plusieurs couches (chaîne/skyline lointaine derrière
/// la couche proche) — pour un rendu « 3D » dynamique. Très basse opacité →
/// ne gêne jamais l'UI. À poser en fond (déjà en IgnorePointer).
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
    duration: const Duration(seconds: 18),
  )..repeat();

  // Parallax gyroscope : inclinaison cible (depuis le capteur) + valeur lissée
  // (suivie à chaque frame). 0 si pas de capteur (simulateur) → dégradation
  // propre, aucun effet.
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _targetX = 0, _targetY = 0;
  double _tiltX = 0, _tiltY = 0;

  @override
  void initState() {
    super.initState();
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (e) {
          // Portrait quasi droit : roulis ≈ x, tangage ≈ z (≈0 au repos).
          _targetX = (e.x / 9.8).clamp(-1.0, 1.0);
          _targetY = (e.z / 9.8).clamp(-1.0, 1.0);
        },
        onError: (_) {}, // capteur indisponible → on reste à 0
        cancelOnError: true,
      );
    } catch (_) {
      // sensors_plus indisponible : pas de parallax, le reste fonctionne.
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // Lissage de l'inclinaison (low-pass) à chaque frame.
          if (reduce) {
            _tiltX = _tiltY = 0;
          } else {
            _tiltX += (_targetX - _tiltX) * 0.08;
            _tiltY += (_targetY - _tiltY) * 0.08;
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _WorldAmbiancePainter(
              chapterId: chapterOfLevel(widget.level).id,
              color: chapterColorOf(widget.level),
              t: reduce ? 0.0 : _c.value,
              tiltX: _tiltX,
              tiltY: _tiltY,
            ),
          );
        },
      ),
    );
  }
}

class _WorldAmbiancePainter extends CustomPainter {
  final int chapterId;
  final Color color;
  final double t; // phase ∈ [0,1]
  final double tiltX; // inclinaison gyroscope ∈ [-1,1]
  final double tiltY;

  _WorldAmbiancePainter({
    required this.chapterId,
    required this.color,
    required this.t,
    this.tiltX = 0,
    this.tiltY = 0,
  });

  static const double _tau = math.pi * 2;
  static const double _shift = 24; // amplitude max du parallax (px)

  /// Décalage de parallax pour une couche de profondeur donnée
  /// (0 = lointain/immobile, 1 = premier plan/maximum).
  Offset _par(double depth) =>
      Offset(-tiltX * _shift * depth, -tiltY * _shift * depth);

  /// Fraction pseudo-aléatoire déterministe (pas de Random par frame).
  double _frac(int i, double mul) {
    final v = (i * mul + 0.137).remainder(1.0);
    return v < 0 ? v + 1 : v;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Lumière de fond — couche lointaine (parallax faible).
    canvas.save();
    canvas.translate(_par(0.25).dx, _par(0.25).dy);
    _atmosphere(canvas, size);
    canvas.restore();

    // Motifs du monde — couche médiane.
    canvas.save();
    canvas.translate(_par(0.6).dx, _par(0.6).dy);
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
    canvas.restore();

    // Poussière lumineuse — premier plan (parallax max, par bande).
    _depthParticles(canvas, size);
  }

  // --- Lumière d'ambiance : halo radial qui dérive en haut ---
  void _atmosphere(Canvas canvas, Size size) {
    final gx = size.width * (0.25 + 0.5 * (0.5 + 0.5 * math.sin(_tau * t)));
    final center = Offset(gx, -size.height * 0.04);
    final radius = size.width * 0.75;
    final shader = RadialGradient(
      colors: [
        color.withValues(alpha: 0.16),
        color.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  // --- Particules « bokeh » en 3 plans de profondeur (parallax) ---
  void _depthParticles(Canvas canvas, Size size) {
    _band(canvas, size,
        count: 11, seed: 1, rMin: 1, rMax: 2, a: 0.06, sp: 0.08, depth: 0.35);
    _band(canvas, size,
        count: 7, seed: 2, rMin: 2, rMax: 3.5, a: 0.09, sp: 0.16, depth: 0.7);
    _band(canvas, size,
        count: 4, seed: 3, rMin: 4, rMax: 6.5, a: 0.11, sp: 0.28, depth: 1.2);
  }

  void _band(
    Canvas canvas,
    Size size, {
    required int count,
    required int seed,
    required double rMin,
    required double rMax,
    required double a,
    required double sp,
    required double depth,
  }) {
    final par = _par(depth);
    final p = Paint()..color = color.withValues(alpha: a);
    for (int i = 0; i < count; i++) {
      final key = i * 3 + seed * 53;
      final fx = _frac(key, 0.61803);
      final baseY = _frac(key + 11, 0.75487);
      double fy = (baseY - t * sp) % 1.0; // flotte vers le haut + wrap
      if (fy < 0) fy += 1;
      final sway = math.sin(_tau * (t + fx)) * size.width * 0.02;
      final r = rMin + (rMax - rMin) * _frac(key + 7, 0.91137);
      final center =
          Offset(fx * size.width + sway + par.dx, fy * size.height + par.dy);
      final rot = _tau * (t + fx) + key; // rotation lente, variée
      _drawParticle(canvas, center, r, p, rot);
    }
  }

  /// Dessine une particule flottante à la forme du monde courant : feuille
  /// (Verger), petite lumière carrée (Ville), sinon point lumineux (bulle /
  /// flocon / étincelle / étoile selon le monde).
  void _drawParticle(Canvas canvas, Offset c, double r, Paint p, double rot) {
    switch (chapterId) {
      case 1: // feuille
        // Grossie + minimum lisible : même les particules lointaines doivent
        // se lire comme des feuilles, pas comme des points.
        final lr = r * 1.7 + 2.2;
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(rot);
        final path = Path()
          ..moveTo(0, -lr * 1.4)
          ..quadraticBezierTo(lr, -lr * 0.1, 0, lr * 1.4)
          ..quadraticBezierTo(-lr, -lr * 0.1, 0, -lr * 1.4)
          ..close();
        canvas.drawPath(path, p);
        // nervure centrale
        canvas.drawLine(
          Offset(0, -lr * 1.2),
          Offset(0, lr * 1.2),
          Paint()
            ..color = p.color.withValues(alpha: p.color.a * 0.6)
            ..strokeWidth = math.max(0.7, lr * 0.12),
        );
        canvas.restore();
      case 4: // petite lumière de ville
        canvas.drawRect(
          Rect.fromCenter(center: c, width: r * 1.5, height: r * 1.5),
          p,
        );
      default: // bulle / flocon / étincelle
        canvas.drawCircle(c, r, p);
    }
  }

  // --- Ch.1 Le Verger : feuilles qui flottent et tournoient (2 profondeurs) ---
  void _orchard(Canvas canvas, Size size) {
    const leaves = [
      [0.14, 0.10, 10.0, 1.0],
      [0.82, 0.08, 13.0, 1.0],
      [0.30, 0.20, 8.0, 0.6], // plus loin
      [0.66, 0.17, 11.0, 1.0],
      [0.48, 0.06, 9.0, 0.6],
      [0.90, 0.22, 7.0, 0.6],
    ];
    for (int i = 0; i < leaves.length; i++) {
      final l = leaves[i];
      final depth = l[3]; // 1 = proche, 0.6 = loin
      final phase = i / leaves.length;
      final dy = math.sin(_tau * (t + phase)) * size.height * 0.018 * depth;
      final dx = math.sin(_tau * (t + phase * 1.7)) * size.width * 0.012 * depth;
      final cx = size.width * l[0] + dx;
      final cy = size.height * l[1] + dy;
      final p = Paint()..color = color.withValues(alpha: 0.07 + 0.07 * depth);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(l[0] * math.pi + math.sin(_tau * (t + phase)) * 0.4);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: l[2] * 2 * depth, height: l[2] * depth),
        p,
      );
      canvas.restore();
    }
  }

  // --- Ch.2 La Côte : vagues qui défilent à plusieurs profondeurs ---
  void _coast(Canvas canvas, Size size) {
    const wavelength = 1 / 2.5;
    for (int line = 0; line < 3; line++) {
      final depth = 1 - line * 0.28; // 1ère ligne proche, dernière loin
      final y = size.height * (0.10 + line * 0.055);
      final amp = (6.0 + line * 1.5) * depth;
      final dir = line.isEven ? 1 : -1;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * depth
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.08 + 0.07 * depth);
      final path = Path();
      for (double fx = 0; fx <= 1.0001; fx += 0.02) {
        final x = size.width * fx;
        final yy = y + amp * math.sin(_tau * (fx / wavelength - dir * t));
        fx == 0 ? path.moveTo(x, yy) : path.lineTo(x, yy);
      }
      canvas.drawPath(path, p);
    }
  }

  // --- Ch.3 Les Sommets : chaîne lointaine + chaîne proche + nuages ---
  void _peaks(Canvas canvas, Size size) {
    // Nuages qui dérivent (profondeur de fond)
    final cloud = Paint()..color = color.withValues(alpha: 0.07);
    const clouds = [
      [0.0, 0.09, 34.0],
      [0.0, 0.15, 26.0],
      [0.0, 0.06, 30.0],
    ];
    for (int i = 0; i < clouds.length; i++) {
      final c = clouds[i];
      final fx = ((c[0] + t * (0.12 + i * 0.05) + i * 0.4) % 1.2) - 0.1;
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

    // Chaîne LOINTAINE (plus haute, plus claire) — profondeur
    _range(canvas, size,
        baseFrac: 0.255,
        peaks: const [0.08, 0.26, 0.46, 0.68, 0.88, 1.0],
        heights: const [0.10, 0.14, 0.08, 0.16, 0.10, 0.06],
        alpha: 0.06);
    // Chaîne PROCHE
    _range(canvas, size,
        baseFrac: 0.30,
        peaks: const [0.12, 0.30, 0.52, 0.74, 0.93],
        heights: const [0.16, 0.22, 0.12, 0.26, 0.15],
        alpha: 0.11);
  }

  void _range(
    Canvas canvas,
    Size size, {
    required double baseFrac,
    required List<double> peaks,
    required List<double> heights,
    required double alpha,
  }) {
    final base = size.height * baseFrac;
    final path = Path()..moveTo(0, base);
    for (int i = 0; i < peaks.length; i++) {
      path.lineTo(size.width * peaks[i], base - size.height * heights[i]);
      final nextX = i + 1 < peaks.length ? (peaks[i] + peaks[i + 1]) / 2 : 1.0;
      path.lineTo(size.width * nextX, base);
    }
    path
      ..lineTo(size.width, base)
      ..lineTo(size.width, base + 4)
      ..lineTo(0, base + 4)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
  }

  // --- Ch.4 La Ville : skyline lointaine + proche + fenêtres scintillantes ---
  void _city(Canvas canvas, Size size) {
    // Skyline LOINTAINE (plus basse, plus claire)
    const farTowers = [
      [0.0, 0.09],
      [0.11, 0.13],
      [0.22, 0.08],
      [0.34, 0.12],
      [0.48, 0.10],
      [0.61, 0.14],
      [0.73, 0.09],
      [0.86, 0.12],
      [0.95, 0.08],
    ];
    final farBase = size.height * 0.27;
    final farP = Paint()..color = color.withValues(alpha: 0.06);
    for (final tw in farTowers) {
      final w = size.width * 0.07;
      final h = size.height * tw[1];
      canvas.drawRect(Rect.fromLTWH(size.width * tw[0], farBase - h, w, h), farP);
    }

    // Skyline PROCHE
    final base = size.height * 0.30;
    final p = Paint()..color = color.withValues(alpha: 0.12);
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
      canvas.drawRect(
        Rect.fromLTWH(size.width * wv[0], size.height * wv[1], 4, 4),
        Paint()..color = color.withValues(alpha: 0.10 + 0.18 * tw),
      );
    }
  }

  // --- Ch.5 Les Étoiles : étoiles en profondeur + filante + lune ---
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
      // Parallax léger : les grosses étoiles (proches) dérivent un peu plus.
      final depth = s[2] / 2.8;
      final drift = math.sin(_tau * (t + phase)) * size.width * 0.01 * depth;
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(_tau * (2 * t + phase)));
      canvas.drawCircle(
        Offset(size.width * s[0] + drift, size.height * s[1]),
        s[2],
        Paint()..color = color.withValues(alpha: 0.10 + 0.20 * tw),
      );
    }

    // Étoile filante : traverse au début de chaque boucle.
    if (t < 0.18) {
      final st = t / 0.18;
      final sx = size.width * (0.15 + 0.7 * st);
      final sy = size.height * (0.05 + 0.12 * st);
      final fade = math.sin(st * math.pi);
      canvas.drawLine(
        Offset(sx - 26, sy - 12),
        Offset(sx, sy),
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.45 * fade),
      );
      canvas.drawCircle(Offset(sx, sy), 2.2,
          Paint()..color = color.withValues(alpha: 0.6 * fade));
    }

    // Croissant de lune + halo qui pulse.
    final moonC = Offset(size.width * 0.84, size.height * 0.07);
    const r = 13.0;
    final glow = 0.5 + 0.5 * math.sin(_tau * t);
    canvas.drawCircle(moonC, r + 3 + 2 * glow,
        Paint()..color = color.withValues(alpha: 0.06 * glow));
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
