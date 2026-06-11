import 'dart:math' as math;

/// Spring scalaire critiquement amorti.
///
/// Remplace les lerps à durée fixe de l'ancien moteur : on fixe une cible
/// ([setTarget]) et la valeur converge naturellement, sans rebond ni durée.
/// Propriété clé : re-cibler EN COURS DE ROUTE est continu en position ET en
/// vitesse — c'est ce qui élimine les à-coups quand une transition est
/// interrompue par une autre (cas permanent dans l'app : conso → recompute
/// santé → réaction).
///
/// Intégration par la forme exacte de la solution critiquement amortie
/// x(t) = (x₀ + (v₀ + ω·x₀)·t)·e^(−ωt) — stable quel que soit dt.
class SpringValue {
  /// Pulsation (rad/s) : la "raideur". Temps de réponse ≈ 4/omega secondes.
  /// Tronc lent ≈ 8, visage vif ≈ 14, membres ≈ 10, feuille traînante ≈ 5.
  final double omega;

  double _value;
  double _velocity = 0;
  double _target;

  SpringValue(double initialValue, {required this.omega})
    : _value = initialValue,
      _target = initialValue;

  double get value => _value;
  double get velocity => _velocity;
  double get target => _target;

  /// Fixe une nouvelle cible — la convergence reprend depuis l'état courant.
  void setTarget(double target) => _target = target;

  /// Téléporte instantanément (initialisation uniquement).
  void snapTo(double value) {
    _value = value;
    _target = value;
    _velocity = 0;
  }

  /// Impulsion de vélocité : la valeur part brièvement au-delà de sa cible
  /// puis y revient naturellement (amortissement critique). Utilisé pour
  /// les « flashs » (ex : burst d'aura au level-up).
  void kick(double impulse) => _velocity += impulse;

  /// Avance la simulation de [dt] secondes et retourne la nouvelle valeur.
  double update(double dt) {
    if (dt <= 0) return _value;
    final x = _value - _target;
    final c = _velocity + omega * x;
    final e = math.exp(-omega * dt);
    _value = _target + (x + c * dt) * e;
    _velocity = (_velocity - omega * c * dt) * e;
    return _value;
  }
}
