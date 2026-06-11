import 'dart:math' as math;

import 'spring_value.dart';

/// Oscillateur sinusoïdal à PHASE INTÉGRÉE — le cœur de l'anti-saccade.
///
/// L'ancien moteur calculait `sin(temps_absolu × vitesse)` : tout changement
/// de vitesse faisait sauter l'argument du sinus de milliers de radians
/// (t ≈ horloge Unix), d'où le tremblement à chaque transition. Ici la phase
/// est accumulée (`phase += 2π·freq·dt`) : la fréquence et l'amplitude
/// peuvent changer librement (lissées par springs), la POSITION de
/// l'oscillation est continue par construction.
class Oscillator {
  final SpringValue _freq; // Hz
  final SpringValue _amp;
  double _phase; // radians, borné à [0, 2π)

  Oscillator({
    double frequency = 1.0,
    double amplitude = 0.0,
    double omega = 8.0,
    double initialPhase = 0.0,
  }) : _freq = SpringValue(frequency, omega: omega),
       _amp = SpringValue(amplitude, omega: omega),
       _phase = initialPhase % (2 * math.pi);

  double get phase => _phase;
  double get amplitude => _amp.value;
  double get frequency => _freq.value;

  void setFrequencyTarget(double hz) => _freq.setTarget(hz);
  void setAmplitudeTarget(double amp) => _amp.setTarget(amp);

  void snapTo({required double frequency, required double amplitude}) {
    _freq.snapTo(frequency);
    _amp.snapTo(amplitude);
  }

  void update(double dt) {
    _freq.update(dt);
    _amp.update(dt);
    _phase = (_phase + 2 * math.pi * _freq.value * dt) % (2 * math.pi);
  }

  /// Onde signée : sin(φ)·amp
  double get sine => math.sin(_phase) * _amp.value;

  /// Onde rectifiée |sin(φ)|·amp — motif de rebond (hop)
  double get absSine => math.sin(_phase).abs() * _amp.value;

  /// sin(φ) brut (sans amplitude) — pour les jambes qui se partagent
  /// la phase mais l'exploitent asymétriquement
  double get raw => math.sin(_phase);

  /// |cos(φ)| — vitesse normalisée de l'onde, maximale au passage au sol :
  /// sert à dériver le squash d'impact physiquement juste
  double get speedNorm => math.cos(_phase).abs();
}
