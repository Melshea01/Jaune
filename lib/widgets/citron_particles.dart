import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Système de particules d'ambiance du citron — étincelles (pleine forme),
/// bulles (éméché), gouttes de sueur (panique/surchauffe).
///
/// Léger par design : 24 particules max, un seul CustomPainter, simulation
/// tickée par le même dt que le moteur d'animation. Quand le mode passe à
/// 'none', l'émission s'arrête mais les particules vivantes finissent leur
/// vie — pas de coupure sèche.
class CitronParticleSystem {
  static const int _maxParticles = 24;

  final math.Random _rng = math.Random();
  final List<_Particle> _particles = [];
  double _spawnAccumulator = 0;

  bool get isEmpty => _particles.isEmpty;

  /// Avance la simulation. [mode] : 'none' | 'sparkles' | 'bubbles' | 'sweat'
  void update(double dt, String mode) {
    // Émission
    final rate = switch (mode) {
      'sparkles' => 3.0, // par seconde
      'bubbles' => 2.2,
      'sweat' => 1.6,
      _ => 0.0,
    };
    if (rate > 0 && _particles.length < _maxParticles) {
      _spawnAccumulator += rate * dt;
      while (_spawnAccumulator >= 1) {
        _spawnAccumulator -= 1;
        _particles.add(_Particle.spawn(mode, _rng));
      }
    } else if (rate == 0) {
      _spawnAccumulator = 0;
    }

    // Vie des particules
    for (final p in _particles) {
      p.age += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += p.gravity * dt;
      p.wobblePhase += p.wobbleFreq * dt * 2 * math.pi;
    }
    _particles.removeWhere((p) => p.age >= p.lifetime);
  }

  void paintInto(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in _particles) {
      final progress = (p.age / p.lifetime).clamp(0.0, 1.0);
      // Fondu d'entrée rapide, fondu de sortie doux
      final fade =
          progress < 0.15 ? progress / 0.15 : 1 - (progress - 0.15) / 0.85;
      final wobbleX = math.sin(p.wobblePhase) * p.wobbleAmp;
      final cx = p.x * size.width + wobbleX;
      final cy = p.y * size.height;

      switch (p.kind) {
        case 'sparkles':
          // Étincelle : losange scintillant (l'opacité vacille)
          final twinkle = 0.6 + 0.4 * math.sin(p.wobblePhase * 3);
          paint.color = p.color.withValues(
            alpha: (fade * twinkle).clamp(0.0, 1.0),
          );
          final r = p.size * (0.8 + 0.2 * twinkle);
          final path =
              Path()
                ..moveTo(cx, cy - r)
                ..lineTo(cx + r * 0.4, cy)
                ..lineTo(cx, cy + r)
                ..lineTo(cx - r * 0.4, cy)
                ..close();
          canvas.drawPath(path, paint);
        case 'bubbles':
          // Bulle : cercle translucide avec reflet
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = p.color.withValues(alpha: fade * 0.7);
          canvas.drawCircle(Offset(cx, cy), p.size, paint);
          paint
            ..style = PaintingStyle.fill
            ..color = Colors.white.withValues(alpha: fade * 0.5);
          canvas.drawCircle(
            Offset(cx - p.size * 0.3, cy - p.size * 0.3),
            p.size * 0.22,
            paint,
          );
          paint.style = PaintingStyle.fill;
        case 'sweat':
          // Goutte : ovale bleuté
          paint.color = p.color.withValues(alpha: fade * 0.85);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: p.size * 1.1,
              height: p.size * 1.6,
            ),
            paint,
          );
      }
    }
  }
}

class _Particle {
  final String kind;
  double x; // fraction de la largeur (0..1)
  double y; // fraction de la hauteur (0..1)
  double vx; // fraction/s
  double vy;
  final double gravity;
  final double size;
  final double lifetime;
  final Color color;
  final double wobbleAmp; // px
  final double wobbleFreq; // Hz
  double wobblePhase;
  double age = 0;

  _Particle({
    required this.kind,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.size,
    required this.lifetime,
    required this.color,
    required this.wobbleAmp,
    required this.wobbleFreq,
    required this.wobblePhase,
  });

  factory _Particle.spawn(String kind, math.Random rng) {
    switch (kind) {
      case 'sparkles':
        // Autour du haut du corps, dérive vers le haut
        return _Particle(
          kind: kind,
          x: 0.30 + rng.nextDouble() * 0.40,
          y: 0.25 + rng.nextDouble() * 0.30,
          vx: (rng.nextDouble() - 0.5) * 0.03,
          vy: -0.04 - rng.nextDouble() * 0.04,
          gravity: 0,
          size: 4 + rng.nextDouble() * 5,
          lifetime: 1.4 + rng.nextDouble() * 0.8,
          color: const Color(0xFFFFE066),
          wobbleAmp: 3,
          wobbleFreq: 1.5 + rng.nextDouble(),
          wobblePhase: rng.nextDouble() * 2 * math.pi,
        );
      case 'bubbles':
        // Près de la bouche, montent en zigzag
        return _Particle(
          kind: kind,
          x: 0.40 + rng.nextDouble() * 0.20,
          y: 0.50 + rng.nextDouble() * 0.10,
          vx: (rng.nextDouble() - 0.5) * 0.02,
          vy: -0.06 - rng.nextDouble() * 0.05,
          gravity: 0,
          size: 3.5 + rng.nextDouble() * 4.5,
          lifetime: 1.8 + rng.nextDouble() * 1.0,
          color: const Color(0xFFBFE3FF),
          wobbleAmp: 6,
          wobbleFreq: 0.8 + rng.nextDouble() * 0.6,
          wobblePhase: rng.nextDouble() * 2 * math.pi,
        );
      default: // sweat
        // Aux tempes, glissent vers l'extérieur puis tombent
        final side = rng.nextBool() ? 1.0 : -1.0;
        return _Particle(
          kind: 'sweat',
          x: 0.5 + side * (0.16 + rng.nextDouble() * 0.06),
          y: 0.32 + rng.nextDouble() * 0.08,
          vx: side * (0.02 + rng.nextDouble() * 0.02),
          vy: 0.01,
          gravity: 0.25,
          size: 3.5 + rng.nextDouble() * 2.5,
          lifetime: 0.9 + rng.nextDouble() * 0.5,
          color: const Color(0xFF8FC7F0),
          wobbleAmp: 0,
          wobbleFreq: 0,
          wobblePhase: 0,
        );
    }
  }
}

/// Painter branché sur le système de particules
class CitronParticlesPainter extends CustomPainter {
  final CitronParticleSystem system;

  /// Compteur de frame : force le repaint à chaque tick
  final int tick;

  CitronParticlesPainter({required this.system, required this.tick});

  @override
  void paint(Canvas canvas, Size size) => system.paintInto(canvas, size);

  @override
  bool shouldRepaint(CitronParticlesPainter oldDelegate) =>
      oldDelegate.tick != tick;
}
