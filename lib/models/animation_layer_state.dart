/// Animation state configuration for character animation layers
/// Each parameter controls a specific aspect of motion and appearance
class AnimationLayerState {
  final double hopAmp;
  final double hopSpeed;
  final double slump;
  final double swayAmp;
  final double swaySpeed;
  final double breathAmp;
  final double breathSpeed;
  final double lean;
  final double baseScaleY;
  final double baseScaleX;
  final double ampY;
  final double scaleAmp;
  final double speed;
  final double baseD;
  final double baseG;
  final double gravFollow;
  final double amp;
  final double base;
  final double scaleY;
  final double offsetY;
  final double drift;
  final double blinkInterval;
  final double blinkDuration;
  final double rotation;
  final double opacity;

  const AnimationLayerState({
    this.hopAmp = 0,
    this.hopSpeed = 1,
    this.slump = 0,
    this.swayAmp = 0,
    this.swaySpeed = 1,
    this.breathAmp = 0,
    this.breathSpeed = 1,
    this.lean = 0,
    this.baseScaleY = 1,
    this.baseScaleX = 1,
    this.ampY = 0,
    this.scaleAmp = 0,
    this.speed = 1,
    this.baseD = 0,
    this.baseG = 0,
    this.gravFollow = 0,
    this.amp = 0,
    this.base = 0,
    this.scaleY = 1,
    this.offsetY = 0,
    this.drift = 0,
    this.blinkInterval = 4,
    this.blinkDuration = 0.12,
    this.rotation = 0,
    this.opacity = 1,
  });

  /// Smooth linear interpolation between two states
  factory AnimationLayerState.lerp(
    AnimationLayerState a,
    AnimationLayerState b,
    double t,
  ) {
    return AnimationLayerState(
      hopAmp: _lerpDouble(a.hopAmp, b.hopAmp, t),
      hopSpeed: _lerpDouble(a.hopSpeed, b.hopSpeed, t),
      slump: _lerpDouble(a.slump, b.slump, t),
      swayAmp: _lerpDouble(a.swayAmp, b.swayAmp, t),
      swaySpeed: _lerpDouble(a.swaySpeed, b.swaySpeed, t),
      breathAmp: _lerpDouble(a.breathAmp, b.breathAmp, t),
      breathSpeed: _lerpDouble(a.breathSpeed, b.breathSpeed, t),
      lean: _lerpDouble(a.lean, b.lean, t),
      baseScaleY: _lerpDouble(a.baseScaleY, b.baseScaleY, t),
      baseScaleX: _lerpDouble(a.baseScaleX, b.baseScaleX, t),
      ampY: _lerpDouble(a.ampY, b.ampY, t),
      scaleAmp: _lerpDouble(a.scaleAmp, b.scaleAmp, t),
      speed: _lerpDouble(a.speed, b.speed, t),
      baseD: _lerpDouble(a.baseD, b.baseD, t),
      baseG: _lerpDouble(a.baseG, b.baseG, t),
      gravFollow: _lerpDouble(a.gravFollow, b.gravFollow, t),
      amp: _lerpDouble(a.amp, b.amp, t),
      base: _lerpDouble(a.base, b.base, t),
      scaleY: _lerpDouble(a.scaleY, b.scaleY, t),
      offsetY: _lerpDouble(a.offsetY, b.offsetY, t),
      drift: _lerpDouble(a.drift, b.drift, t),
      blinkInterval: _lerpDouble(a.blinkInterval, b.blinkInterval, t),
      blinkDuration: _lerpDouble(a.blinkDuration, b.blinkDuration, t),
      rotation: _lerpDouble(a.rotation, b.rotation, t),
      opacity: _lerpDouble(a.opacity, b.opacity, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// Complete animation states dictionary for all 9 layers
/// Contains 80+ animation states with full parametrization
final Map<String, Map<String, AnimationLayerState>> layerStates = {
  'global': {
    // Idle apaisé : 3.5px à vitesse 2.1 — un balancement de respiration,
    // pas un sautillement nerveux (l'utilisateur regarde cet état des heures)
    'idle': const AnimationLayerState(hopAmp: 3.5, hopSpeed: 2.1),
    'floating_soft': const AnimationLayerState(hopAmp: 2, hopSpeed: 4.0),
    'bounce_light': const AnimationLayerState(hopAmp: 10, hopSpeed: 1.0),
    'pulse': const AnimationLayerState(hopAmp: 0, hopSpeed: 1.0),
    'pendulum': const AnimationLayerState(hopAmp: 0, hopSpeed: 1.0),
    'bored': const AnimationLayerState(hopAmp: 0, hopSpeed: 6.5, slump: 8),
    'digest': const AnimationLayerState(hopAmp: 0, hopSpeed: 8.0),
    'dance': const AnimationLayerState(hopAmp: 30, hopSpeed: 1.2),
    'crushed': const AnimationLayerState(hopAmp: 0, hopSpeed: 10, slump: 55),
    'struggle_up': const AnimationLayerState(
      hopAmp: 8,
      hopSpeed: 2.5,
      slump: 10,
    ),
    'levitate': const AnimationLayerState(
      hopAmp: 15,
      hopSpeed: 6.0,
      slump: -10,
    ),
    'grounded': const AnimationLayerState(hopAmp: 0, hopSpeed: 10, slump: 30),
    'walk_slow': const AnimationLayerState(hopAmp: 5, hopSpeed: 0.75),
    'walk_normal': const AnimationLayerState(hopAmp: 8, hopSpeed: 1.05),
    'walk_fast': const AnimationLayerState(hopAmp: 10, hopSpeed: 1.55),
    'run': const AnimationLayerState(hopAmp: 14, hopSpeed: 3.6),
    'joy_bounce': const AnimationLayerState(hopAmp: 14, hopSpeed: 1.45),
    'sway_tipsy': const AnimationLayerState(hopAmp: 0, hopSpeed: 1.1),
    'sway_drunk': const AnimationLayerState(hopAmp: 0, hopSpeed: 1.4, slump: 4),
    'sway_wasted': const AnimationLayerState(
      hopAmp: 0,
      hopSpeed: 1.75,
      slump: 10,
    ),
    'tremble': const AnimationLayerState(hopAmp: 0, hopSpeed: 2.8),
    'sick': const AnimationLayerState(hopAmp: 0, hopSpeed: 4.0, slump: 8),
    'critical': const AnimationLayerState(hopAmp: 0, hopSpeed: 5.0, slump: 14),
    'dead': const AnimationLayerState(hopAmp: 0, hopSpeed: 12, slump: 80),
  },
  'milieu': {
    'idle': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 3.0,
      breathAmp: 0.02,
      breathSpeed: 3.0,
      lean: 0,
      baseScaleY: 1,
      baseScaleX: 1,
    ),
    'breathe_deep': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 3.5,
      breathAmp: 0.08,
      breathSpeed: 3.5,
    ),
    'breathe_fast': const AnimationLayerState(
      swayAmp: 6,
      swaySpeed: 4.4,
      breathAmp: 0.10,
      breathSpeed: 4.4,
    ),
    'sway_tipsy': const AnimationLayerState(
      swayAmp: 5,
      swaySpeed: 1.25,
      breathAmp: 0.04,
      breathSpeed: 1.25,
    ),
    'pulse': const AnimationLayerState(
      swayAmp: 6,
      swaySpeed: 0.8,
      breathAmp: 0.28,
      breathSpeed: 0.35,
    ),
    'pendulum': const AnimationLayerState(
      swayAmp: 25,
      swaySpeed: 1.5,
      breathAmp: 0.02,
      breathSpeed: 1.5,
    ),
    'bored': const AnimationLayerState(
      swayAmp: 2,
      swaySpeed: 6.0,
      breathAmp: 0.01,
      breathSpeed: 6.0,
      lean: 25,
    ),
    'slump': const AnimationLayerState(
      swayAmp: 4,
      swaySpeed: 6.5,
      breathAmp: 0.05,
      breathSpeed: 6.5,
      lean: 50,
    ),
    // Fatigué mais attachant : léger affaissement et respiration lourde,
    // sans basculer à 50° comme 'slump' (réservé aux états extrêmes)
    'weary': const AnimationLayerState(
      swayAmp: 2,
      swaySpeed: 5.5,
      breathAmp: 0.07,
      breathSpeed: 5.5,
      lean: 10,
      baseScaleY: 0.97,
      baseScaleX: 1.02,
    ),
    'digest': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 8.0,
      breathAmp: 0.15,
      breathSpeed: 8.0,
      baseScaleY: 1.15,
      baseScaleX: 1.15,
    ),
    'dance': const AnimationLayerState(
      swayAmp: 35,
      swaySpeed: 1.2,
      breathAmp: 0.08,
      breathSpeed: 1.2,
    ),
    'sway_drunk': const AnimationLayerState(
      swayAmp: 25,
      swaySpeed: 1.75,
      breathAmp: 0.08,
      breathSpeed: 1.5,
    ),
    'sided': const AnimationLayerState(
      swayAmp: 2,
      swaySpeed: 4.0,
      breathAmp: 0.25,
      breathSpeed: 5.0,
      lean: 85,
    ),
    'crushed_tremble': const AnimationLayerState(
      swayAmp: 2.5,
      swaySpeed: 3.0,
      breathAmp: 0.01,
      breathSpeed: 3.0,
      baseScaleY: 0.75,
      baseScaleX: 1.15,
    ),
    'struggle': const AnimationLayerState(
      swayAmp: 6,
      swaySpeed: 2.5,
      breathAmp: 0.08,
      breathSpeed: 2.5,
      lean: 10,
    ),
    'panting': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 1.0,
      breathAmp: 0.02,
      breathSpeed: 0.3,
      baseScaleY: 0.9,
      baseScaleX: 0.9,
    ),
    'zen': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 6.0,
      breathAmp: 0.03,
      breathSpeed: 6.0,
    ),
    'sleep': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 4.0,
      breathAmp: 0.05,
      breathSpeed: 4.0,
      lean: 90,
    ),
    'walk_slow': const AnimationLayerState(
      swayAmp: 4,
      swaySpeed: 1.4,
      breathAmp: 0.03,
      breathSpeed: 1.4,
      lean: 2,
    ),
    'walk_normal': const AnimationLayerState(
      swayAmp: 6,
      swaySpeed: 1.0,
      breathAmp: 0.04,
      breathSpeed: 1.0,
      lean: 3,
    ),
    'walk_fast': const AnimationLayerState(
      swayAmp: 8,
      swaySpeed: 0.6,
      breathAmp: 0.05,
      breathSpeed: 0.6,
      lean: 5,
    ),
    'run': const AnimationLayerState(
      swayAmp: 10,
      swaySpeed: 0.4,
      breathAmp: 0.06,
      breathSpeed: 0.4,
      lean: 8,
    ),
    'joy_bounce': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 0.5,
      breathAmp: 0.10,
      breathSpeed: 0.5,
    ),
    'sway_wasted': const AnimationLayerState(
      swayAmp: 30,
      swaySpeed: 3.5,
      breathAmp: 0.14,
      breathSpeed: 2.5,
      lean: 8,
    ),
    'tremble': const AnimationLayerState(
      swayAmp: 6,
      swaySpeed: 2.8,
      breathAmp: 0.04,
      breathSpeed: 3.0,
    ),
    'sick': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 4.0,
      breathAmp: 0.08,
      breathSpeed: 4.0,
      lean: 16,
    ),
    'critical': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 5.0,
      breathAmp: 0.14,
      breathSpeed: 5.0,
      lean: 24,
    ),
    'dead': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 12,
      breathAmp: 0.01,
      breathSpeed: 12,
      lean: 95,
    ),
    'sprint': const AnimationLayerState(
      swayAmp: 3,
      swaySpeed: 5.0,
      breathAmp: 0.08,
      breathSpeed: 5.0,
      lean: -2,
    ),
    'strain': const AnimationLayerState(
      swayAmp: 0,
      swaySpeed: 8.0,
      breathAmp: 0.05,
      breathSpeed: 8.0,
      baseScaleY: 0.95,
      baseScaleX: 1.05,
    ),
  },
  'jambes': {
    // Synchronisé avec le hop global apaisé (2.1)
    'idle': const AnimationLayerState(
      ampY: 3.0,
      scaleAmp: 0.035,
      speed: 2.1,
      gravFollow: 0.4,
    ),
    'floating': const AnimationLayerState(
      ampY: 0,
      scaleAmp: 0,
      speed: 4.0,
      gravFollow: 0,
    ),
    'floating_soft': const AnimationLayerState(
      ampY: 2.5,
      scaleAmp: 0.03,
      speed: 4.0,
      gravFollow: 0.05,
    ),
    'dance': const AnimationLayerState(
      ampY: 25,
      scaleAmp: 0.15,
      speed: 0.3,
      gravFollow: 0.1,
    ),
    'bounce': const AnimationLayerState(
      ampY: 4,
      scaleAmp: 0.04,
      speed: 1.2,
      gravFollow: 0.2,
    ),
    'bounce_light': const AnimationLayerState(
      ampY: 7.0,
      scaleAmp: 0.08,
      speed: 1.2,
      gravFollow: 0.25,
    ),
    'walk_slow': const AnimationLayerState(
      ampY: 8,
      scaleAmp: 0.06,
      speed: 1.4,
      gravFollow: 0.2,
    ),
    'walk_normal': const AnimationLayerState(
      ampY: 12,
      scaleAmp: 0.08,
      speed: 1.0,
      gravFollow: 0.15,
    ),
    'walk_fast': const AnimationLayerState(
      ampY: 16,
      scaleAmp: 0.10,
      speed: 0.6,
      gravFollow: 0.1,
    ),
    'run': const AnimationLayerState(
      ampY: 22,
      scaleAmp: 0.13,
      speed: 3.4,
      gravFollow: 0.18,
    ),
    'drunk': const AnimationLayerState(
      ampY: 5,
      scaleAmp: 0.03,
      speed: 3.5,
      gravFollow: 0.4,
    ),
    'bent': const AnimationLayerState(
      ampY: 0,
      scaleAmp: 0,
      speed: 3.0,
      baseD: 6,
      baseG: 6,
      gravFollow: 0,
    ),
    'spread': const AnimationLayerState(
      ampY: 0,
      scaleAmp: 0,
      speed: 3.0,
      gravFollow: 0.7,
    ),
    'sick': const AnimationLayerState(
      ampY: 3,
      scaleAmp: 0.02,
      speed: 4.0,
      gravFollow: 0.1,
    ),
    'grounded': const AnimationLayerState(
      ampY: 0,
      scaleAmp: 0,
      speed: 0,
      gravFollow: 0,
    ),
    'dead': const AnimationLayerState(
      ampY: 0,
      scaleAmp: 0,
      speed: 10,
      gravFollow: 0,
    ),
  },
  'bras_D': {
    // Synchronisé avec le hop global apaisé (2.1)
    'idle': const AnimationLayerState(amp: 0.06, speed: 2.1),
    // Joyeux sans être frénétique : bras semi-levé qui ondule doucement
    // (le double 'wave' permanent était épuisant à regarder)
    'cheer': const AnimationLayerState(
      amp: 0.22,
      speed: 1.6,
      base: -0.7,
      gravFollow: 0.2,
    ),
    'soft': const AnimationLayerState(
      amp: 0.02,
      speed: 4.0,
      base: 0.1,
      gravFollow: 0.2,
    ),
    'active': const AnimationLayerState(
      amp: 0.15,
      speed: 1.2,
      base: 0.2,
      gravFollow: 0.25,
    ),
    'dance': const AnimationLayerState(amp: 0.60, speed: 1.2, base: -1.5),
    'wave': const AnimationLayerState(amp: 0.90, speed: 1.35, base: -0.6),
    'raised': const AnimationLayerState(amp: 0.12, speed: 1.8, base: -1.1),
    'ballant': const AnimationLayerState(amp: 0.12, speed: 3.5),
    'trembling': const AnimationLayerState(amp: 0.08, speed: 2.6),
    'walk_slow': const AnimationLayerState(amp: 0.15, speed: 0.75),
    'walk_normal': const AnimationLayerState(amp: 0.20, speed: 1.05),
    'walk_fast': const AnimationLayerState(amp: 0.26, speed: 1.55),
    'run': const AnimationLayerState(
      amp: 0.32,
      speed: 2.6,
      base: 0.1,
      gravFollow: 0.15,
    ),
    'panic': const AnimationLayerState(amp: 0.80, speed: 2.8, base: -1.5),
    'sick': const AnimationLayerState(amp: 0.03, speed: 4.0, base: 0.6),
    'dead': const AnimationLayerState(amp: 0, speed: 10, base: 0.85),
    'crossed': const AnimationLayerState(amp: 0, speed: 5.0, base: -1.2),
  },
  'bras_G': {
    // Synchronisé avec le hop global apaisé (2.1)
    'idle': const AnimationLayerState(amp: 0.06, speed: 2.1),
    // Pendant gauche de 'cheer' (déphasé naturellement par le moteur)
    'cheer': const AnimationLayerState(
      amp: 0.22,
      speed: 1.6,
      base: 0.7,
      gravFollow: 0.2,
    ),
    'soft': const AnimationLayerState(
      amp: 0.02,
      speed: 4.0,
      base: -0.1,
      gravFollow: 0.2,
    ),
    'active': const AnimationLayerState(
      amp: 0.15,
      speed: 1.2,
      base: -0.2,
      gravFollow: 0.25,
    ),
    'dance': const AnimationLayerState(amp: 0.60, speed: 1.2, base: 1.5),
    'wave': const AnimationLayerState(amp: 0.90, speed: 1.35, base: 0.6),
    'raised': const AnimationLayerState(amp: 0.12, speed: 1.8, base: 1.1),
    'ballant': const AnimationLayerState(amp: 0.12, speed: 3.5),
    'trembling': const AnimationLayerState(amp: 0.08, speed: 2.6),
    'walk_slow': const AnimationLayerState(amp: 0.15, speed: 0.75),
    'walk_normal': const AnimationLayerState(amp: 0.20, speed: 1.05),
    'walk_fast': const AnimationLayerState(amp: 0.26, speed: 1.55),
    'run': const AnimationLayerState(
      amp: 0.32,
      speed: 2.6,
      base: -0.1,
      gravFollow: 0.15,
    ),
    'panic': const AnimationLayerState(amp: 0.80, speed: 2.8, base: 1.5),
    'sick': const AnimationLayerState(amp: 0.03, speed: 4.0, base: 0.6),
    'dead': const AnimationLayerState(amp: 0, speed: 10, base: 0.85),
    'crossed': const AnimationLayerState(amp: 0, speed: 5.0, base: 1.2),
  },
  'plante': {
    'idle': const AnimationLayerState(amp: 0.02, speed: 1.9),
    'active': const AnimationLayerState(amp: 0.08, speed: 0.9, base: 0.1),
    'breeze_soft': const AnimationLayerState(amp: 0.03, speed: 2.8),
    'breeze_fast': const AnimationLayerState(amp: 0.06, speed: 0.9),
    'dance': const AnimationLayerState(amp: 0.12, speed: 1.1),
    'breeze': const AnimationLayerState(amp: 0.04, speed: 1.2),
    'wind': const AnimationLayerState(amp: 0.10, speed: 0.6),
    'curl': const AnimationLayerState(amp: 0.01, speed: 3.5, base: 0.2),
    'startle': const AnimationLayerState(amp: 0.15, speed: 0.2),
    'drunk': const AnimationLayerState(amp: 0.07, speed: 2.0),
    'wasted': const AnimationLayerState(amp: 0.09, speed: 2.4),
    'grounded': const AnimationLayerState(amp: 0, speed: 0, base: 2.0),
    'dead': const AnimationLayerState(amp: 0, speed: 10, base: 1.5),
  },
  'yeux': {
    'open': const AnimationLayerState(
      scaleY: 1.10,
      offsetY: 0,
      drift: 0,
      blinkInterval: 4.0,
      blinkDuration: 0.12,
    ),
    'half_closed': const AnimationLayerState(
      scaleY: 0.25,
      offsetY: 5,
      drift: 0,
      blinkInterval: 99,
      blinkDuration: 0.15,
    ),
    'closed': const AnimationLayerState(
      scaleY: 0.01,
      offsetY: 7,
      drift: 0,
      blinkInterval: 99,
      blinkDuration: 99,
    ),
    'wide': const AnimationLayerState(
      scaleY: 1.60,
      offsetY: -4,
      drift: 0,
      blinkInterval: 8.0,
      blinkDuration: 0.08,
    ),
    'shock': const AnimationLayerState(
      scaleY: 1.50,
      offsetY: -4,
      drift: 0,
      blinkInterval: 99,
      blinkDuration: 99,
    ),
    'squint': const AnimationLayerState(
      scaleY: 0.25,
      offsetY: 4,
      drift: 0,
      blinkInterval: 99,
      blinkDuration: 0.10,
    ),
    'drunk': const AnimationLayerState(
      scaleY: 0.40,
      offsetY: 5,
      drift: 4,
      blinkInterval: 6.0,
      blinkDuration: 0.20,
    ),
    'zen': const AnimationLayerState(
      scaleY: 0.15,
      offsetY: 2,
      drift: 0,
      blinkInterval: 99,
      blinkDuration: 99,
    ),
    'panting': const AnimationLayerState(
      scaleY: 0.60,
      offsetY: 2,
      drift: 0,
      blinkInterval: 2.0,
      blinkDuration: 0.15,
    ),
    // Yeux lourds de fatigue : mi-clos avec clignements lents et fréquents
    // (plus expressif que 'half_closed' qui fige le regard)
    'sleepy': const AnimationLayerState(
      scaleY: 0.50,
      offsetY: 4,
      drift: 0,
      blinkInterval: 2.5,
      blinkDuration: 0.30,
    ),
    'dead': const AnimationLayerState(
      scaleY: 0.01,
      offsetY: 14,
      drift: 0,
      blinkInterval: 99,
      blinkDuration: 99,
    ),
  },
  'bouche': {
    'smile': const AnimationLayerState(scaleY: 1.00, rotation: 0),
    'open': const AnimationLayerState(scaleY: 1.40, rotation: 0),
    'neutral': const AnimationLayerState(scaleY: 0.70, rotation: 0),
    'sad': const AnimationLayerState(scaleY: 1.20, rotation: 180, offsetY: 14),
    'sick': const AnimationLayerState(scaleY: 0.60, rotation: 180),
    'exhausted': const AnimationLayerState(scaleY: 1.20, rotation: 10),
    'big_smile': const AnimationLayerState(scaleY: 2.10, rotation: 0),
    'drunk_smile': const AnimationLayerState(scaleY: 1.20, rotation: -12),
  },
  'joues': {
    'visible': const AnimationLayerState(opacity: 0.7),
    'flushed': const AnimationLayerState(opacity: 1.0),
    'hidden': const AnimationLayerState(opacity: 0.0),
    'blinking': const AnimationLayerState(opacity: 0.5),
  },
};
