import 'citron_pose.dart';

/// Catalogue des poses nommées par couche — conversion 1:1 des ~80 états
/// historiques (mêmes valeurs perçues : les fréquences sont les anciennes
/// vitesses × 0.5, l'ancien speedFactor étant intégré).
class PoseCatalog {
  static const Map<String, GlobalPose> global = {
    // Idle apaisé : un balancement de respiration, pas un sautillement
    'idle': GlobalPose(hopAmp: 3.5, hopFreq: 1.05),
    'floating_soft': GlobalPose(hopAmp: 2, hopFreq: 2.0),
    'bounce_light': GlobalPose(hopAmp: 10, hopFreq: 0.5),
    'pulse': GlobalPose(hopFreq: 0.5),
    'pendulum': GlobalPose(hopFreq: 0.5),
    'bored': GlobalPose(hopFreq: 3.25, slump: 8),
    'digest': GlobalPose(hopFreq: 4.0),
    'dance': GlobalPose(hopAmp: 30, hopFreq: 0.6),
    'crushed': GlobalPose(hopFreq: 5.0, slump: 55),
    'struggle_up': GlobalPose(hopAmp: 8, hopFreq: 1.25, slump: 10),
    'levitate': GlobalPose(hopAmp: 15, hopFreq: 3.0, slump: -10),
    'grounded': GlobalPose(hopFreq: 5.0, slump: 30),
    'walk_slow': GlobalPose(hopAmp: 5, hopFreq: 0.375),
    'walk_normal': GlobalPose(hopAmp: 8, hopFreq: 0.525),
    'walk_fast': GlobalPose(hopAmp: 10, hopFreq: 0.775),
    'run': GlobalPose(hopAmp: 14, hopFreq: 1.8),
    'joy_bounce': GlobalPose(hopAmp: 14, hopFreq: 0.725),
    'sway_tipsy': GlobalPose(hopFreq: 0.55),
    'sway_drunk': GlobalPose(hopFreq: 0.7, slump: 4),
    'sway_wasted': GlobalPose(hopFreq: 0.875, slump: 10),
    'tremble': GlobalPose(hopFreq: 1.4),
    'sick': GlobalPose(hopFreq: 2.0, slump: 8),
    'critical': GlobalPose(hopFreq: 2.5, slump: 14),
    'dead': GlobalPose(hopFreq: 6.0, slump: 80),
  };

  static const Map<String, TorsoPose> torso = {
    'idle': TorsoPose(swayFreq: 1.5, breathAmp: 0.02, breathFreq: 1.5),
    'breathe_deep': TorsoPose(swayFreq: 1.75, breathAmp: 0.08, breathFreq: 1.75),
    'breathe_fast': TorsoPose(
      swayAmpDeg: 6,
      swayFreq: 2.2,
      breathAmp: 0.10,
      breathFreq: 2.2,
    ),
    'sway_tipsy': TorsoPose(
      swayAmpDeg: 5,
      swayFreq: 0.625,
      breathAmp: 0.04,
      breathFreq: 0.625,
    ),
    'pulse': TorsoPose(
      swayAmpDeg: 6,
      swayFreq: 0.4,
      breathAmp: 0.28,
      breathFreq: 0.175,
    ),
    'pendulum': TorsoPose(
      swayAmpDeg: 25,
      swayFreq: 0.75,
      breathAmp: 0.02,
      breathFreq: 0.75,
    ),
    'bored': TorsoPose(
      swayAmpDeg: 2,
      swayFreq: 3.0,
      breathAmp: 0.01,
      breathFreq: 3.0,
      leanDeg: 25,
    ),
    'slump': TorsoPose(
      swayAmpDeg: 4,
      swayFreq: 3.25,
      breathAmp: 0.05,
      breathFreq: 3.25,
      leanDeg: 50,
    ),
    // Fatigué mais attachant : léger affaissement, respiration lourde
    'weary': TorsoPose(
      swayAmpDeg: 2,
      swayFreq: 2.75,
      breathAmp: 0.07,
      breathFreq: 2.75,
      leanDeg: 10,
      scaleY: 0.97,
      scaleX: 1.02,
    ),
    'digest': TorsoPose(
      swayFreq: 4.0,
      breathAmp: 0.15,
      breathFreq: 4.0,
      scaleY: 1.15,
      scaleX: 1.15,
    ),
    'dance': TorsoPose(
      swayAmpDeg: 35,
      swayFreq: 0.6,
      breathAmp: 0.08,
      breathFreq: 0.6,
    ),
    'sway_drunk': TorsoPose(
      swayAmpDeg: 25,
      swayFreq: 0.875,
      breathAmp: 0.08,
      breathFreq: 0.75,
    ),
    'sided': TorsoPose(
      swayAmpDeg: 2,
      swayFreq: 2.0,
      breathAmp: 0.25,
      breathFreq: 2.5,
      leanDeg: 85,
    ),
    'crushed_tremble': TorsoPose(
      swayAmpDeg: 2.5,
      swayFreq: 1.5,
      breathAmp: 0.01,
      breathFreq: 1.5,
      scaleY: 0.75,
      scaleX: 1.15,
    ),
    'struggle': TorsoPose(
      swayAmpDeg: 6,
      swayFreq: 1.25,
      breathAmp: 0.08,
      breathFreq: 1.25,
      leanDeg: 10,
    ),
    'panting': TorsoPose(
      swayFreq: 0.5,
      breathAmp: 0.02,
      breathFreq: 0.15,
      scaleY: 0.9,
      scaleX: 0.9,
    ),
    'zen': TorsoPose(swayFreq: 3.0, breathAmp: 0.03, breathFreq: 3.0),
    'sleep': TorsoPose(
      swayFreq: 2.0,
      breathAmp: 0.05,
      breathFreq: 2.0,
      leanDeg: 90,
    ),
    'walk_slow': TorsoPose(
      swayAmpDeg: 4,
      swayFreq: 0.7,
      breathAmp: 0.03,
      breathFreq: 0.7,
      leanDeg: 2,
    ),
    'walk_normal': TorsoPose(
      swayAmpDeg: 6,
      swayFreq: 0.5,
      breathAmp: 0.04,
      breathFreq: 0.5,
      leanDeg: 3,
    ),
    'walk_fast': TorsoPose(
      swayAmpDeg: 8,
      swayFreq: 0.3,
      breathAmp: 0.05,
      breathFreq: 0.3,
      leanDeg: 5,
    ),
    'run': TorsoPose(
      swayAmpDeg: 10,
      swayFreq: 0.2,
      breathAmp: 0.06,
      breathFreq: 0.2,
      leanDeg: 8,
    ),
    'joy_bounce': TorsoPose(swayFreq: 0.25, breathAmp: 0.10, breathFreq: 0.25),
    'sway_wasted': TorsoPose(
      swayAmpDeg: 30,
      swayFreq: 1.75,
      breathAmp: 0.14,
      breathFreq: 1.25,
      leanDeg: 8,
    ),
    'tremble': TorsoPose(
      swayAmpDeg: 6,
      swayFreq: 1.4,
      breathAmp: 0.04,
      breathFreq: 1.5,
    ),
    'sick': TorsoPose(
      swayFreq: 2.0,
      breathAmp: 0.08,
      breathFreq: 2.0,
      leanDeg: 16,
    ),
    'critical': TorsoPose(
      swayFreq: 2.5,
      breathAmp: 0.14,
      breathFreq: 2.5,
      leanDeg: 24,
    ),
    'dead': TorsoPose(
      swayFreq: 6.0,
      breathAmp: 0.01,
      breathFreq: 6.0,
      leanDeg: 95,
    ),
    'sprint': TorsoPose(
      swayAmpDeg: 3,
      swayFreq: 2.5,
      breathAmp: 0.08,
      breathFreq: 2.5,
      leanDeg: -2,
    ),
    'strain': TorsoPose(
      swayFreq: 4.0,
      breathAmp: 0.05,
      breathFreq: 4.0,
      scaleY: 0.95,
      scaleX: 1.05,
    ),
  };

  static const Map<String, LegsPose> legs = {
    'idle': LegsPose(
      bounceAmp: 3.0,
      squashAmp: 0.035,
      freq: 1.05,
      gravFollow: 0.4,
    ),
    'floating': LegsPose(freq: 2.0),
    'floating_soft': LegsPose(
      bounceAmp: 2.5,
      squashAmp: 0.03,
      freq: 2.0,
      gravFollow: 0.05,
    ),
    'dance': LegsPose(
      bounceAmp: 25,
      squashAmp: 0.15,
      freq: 0.15,
      gravFollow: 0.1,
    ),
    'bounce': LegsPose(
      bounceAmp: 4,
      squashAmp: 0.04,
      freq: 0.6,
      gravFollow: 0.2,
    ),
    'bounce_light': LegsPose(
      bounceAmp: 7.0,
      squashAmp: 0.08,
      freq: 0.6,
      gravFollow: 0.25,
    ),
    'walk_slow': LegsPose(
      bounceAmp: 8,
      squashAmp: 0.06,
      freq: 0.7,
      gravFollow: 0.2,
    ),
    'walk_normal': LegsPose(
      bounceAmp: 12,
      squashAmp: 0.08,
      freq: 0.5,
      gravFollow: 0.15,
    ),
    'walk_fast': LegsPose(
      bounceAmp: 16,
      squashAmp: 0.10,
      freq: 0.3,
      gravFollow: 0.1,
    ),
    'run': LegsPose(
      bounceAmp: 22,
      squashAmp: 0.13,
      freq: 1.7,
      gravFollow: 0.18,
    ),
    'drunk': LegsPose(
      bounceAmp: 5,
      squashAmp: 0.03,
      freq: 1.75,
      gravFollow: 0.4,
    ),
    'bent': LegsPose(freq: 1.5, baseLiftD: 6, baseLiftG: 6),
    'spread': LegsPose(freq: 1.5, gravFollow: 0.7),
    'sick': LegsPose(
      bounceAmp: 3,
      squashAmp: 0.02,
      freq: 2.0,
      gravFollow: 0.1,
    ),
    'grounded': LegsPose(freq: 0),
    'dead': LegsPose(freq: 5.0),
  };

  static const Map<String, ArmPose> armD = {
    'idle': ArmPose(swingAmp: 0.06, freq: 1.05),
    // Joyeux sans être frénétique : bras semi-levé, ondulation douce
    'cheer': ArmPose(swingAmp: 0.22, freq: 0.8, baseAngle: -0.7, gravFollow: 0.2),
    'soft': ArmPose(swingAmp: 0.02, freq: 2.0, baseAngle: 0.1, gravFollow: 0.2),
    'active': ArmPose(swingAmp: 0.15, freq: 0.6, baseAngle: 0.2, gravFollow: 0.25),
    'dance': ArmPose(swingAmp: 0.60, freq: 0.6, baseAngle: -1.5),
    'wave': ArmPose(swingAmp: 0.90, freq: 0.675, baseAngle: -0.6),
    'raised': ArmPose(swingAmp: 0.12, freq: 0.9, baseAngle: -1.1),
    'ballant': ArmPose(swingAmp: 0.12, freq: 1.75),
    'trembling': ArmPose(swingAmp: 0.08, freq: 1.3),
    'walk_slow': ArmPose(swingAmp: 0.15, freq: 0.375),
    'walk_normal': ArmPose(swingAmp: 0.20, freq: 0.525),
    'walk_fast': ArmPose(swingAmp: 0.26, freq: 0.775),
    'run': ArmPose(swingAmp: 0.32, freq: 1.3, baseAngle: 0.1, gravFollow: 0.15),
    'panic': ArmPose(swingAmp: 0.80, freq: 1.4, baseAngle: -1.5),
    'sick': ArmPose(swingAmp: 0.03, freq: 2.0, baseAngle: 0.6),
    'dead': ArmPose(freq: 5.0, baseAngle: 0.85),
    'crossed': ArmPose(freq: 2.5, baseAngle: -1.2),
  };

  static const Map<String, ArmPose> armG = {
    'idle': ArmPose(swingAmp: 0.06, freq: 1.05),
    'cheer': ArmPose(swingAmp: 0.22, freq: 0.8, baseAngle: 0.7, gravFollow: 0.2),
    'soft': ArmPose(swingAmp: 0.02, freq: 2.0, baseAngle: -0.1, gravFollow: 0.2),
    'active': ArmPose(
      swingAmp: 0.15,
      freq: 0.6,
      baseAngle: -0.2,
      gravFollow: 0.25,
    ),
    'dance': ArmPose(swingAmp: 0.60, freq: 0.6, baseAngle: 1.5),
    'wave': ArmPose(swingAmp: 0.90, freq: 0.675, baseAngle: 0.6),
    'raised': ArmPose(swingAmp: 0.12, freq: 0.9, baseAngle: 1.1),
    'ballant': ArmPose(swingAmp: 0.12, freq: 1.75),
    'trembling': ArmPose(swingAmp: 0.08, freq: 1.3),
    'walk_slow': ArmPose(swingAmp: 0.15, freq: 0.375),
    'walk_normal': ArmPose(swingAmp: 0.20, freq: 0.525),
    'walk_fast': ArmPose(swingAmp: 0.26, freq: 0.775),
    'run': ArmPose(swingAmp: 0.32, freq: 1.3, baseAngle: -0.1, gravFollow: 0.15),
    'panic': ArmPose(swingAmp: 0.80, freq: 1.4, baseAngle: 1.5),
    'sick': ArmPose(swingAmp: 0.03, freq: 2.0, baseAngle: 0.6),
    'dead': ArmPose(freq: 5.0, baseAngle: 0.85),
    'crossed': ArmPose(freq: 2.5, baseAngle: 1.2),
  };

  static const Map<String, LeafPose> leaf = {
    'idle': LeafPose(swayAmp: 0.02, freq: 0.95),
    'active': LeafPose(swayAmp: 0.08, freq: 0.45, baseAngle: 0.1),
    'breeze_soft': LeafPose(swayAmp: 0.03, freq: 1.4),
    'breeze_fast': LeafPose(swayAmp: 0.06, freq: 0.45),
    'dance': LeafPose(swayAmp: 0.12, freq: 0.55),
    'breeze': LeafPose(swayAmp: 0.04, freq: 0.6),
    'wind': LeafPose(swayAmp: 0.10, freq: 0.3),
    'curl': LeafPose(swayAmp: 0.01, freq: 1.75, baseAngle: 0.2),
    'startle': LeafPose(swayAmp: 0.15, freq: 0.1),
    'drunk': LeafPose(swayAmp: 0.07, freq: 1.0),
    'wasted': LeafPose(swayAmp: 0.09, freq: 1.2),
    // Angles de flétrissement bornés : la branche pivote autour de son point
    // d'attache au corps — au-delà de ~30° elle sort visuellement du creux
    // du sommet (le SVG n'est pas dessiné pour). Le « mort » se lit par la
    // chute + l'immobilité, pas par une rotation à 90°.
    'grounded': LeafPose(freq: 0, baseAngle: 0.45),
    'dead': LeafPose(freq: 5.0, baseAngle: 0.35),
  };

  static const Map<String, EyesPose> eyes = {
    'open': EyesPose(openness: 1.10),
    'half_closed': EyesPose(openness: 0.25, offsetY: 5, blinkInterval: 99),
    'closed': EyesPose(
      openness: 0.01,
      offsetY: 7,
      blinkInterval: 99,
      blinkDuration: 99,
    ),
    'wide': EyesPose(
      openness: 1.60,
      offsetY: -4,
      blinkInterval: 8.0,
      blinkDuration: 0.08,
    ),
    'shock': EyesPose(
      openness: 1.50,
      offsetY: -4,
      blinkInterval: 99,
      blinkDuration: 99,
    ),
    'squint': EyesPose(
      openness: 0.25,
      offsetY: 4,
      blinkInterval: 99,
      blinkDuration: 0.10,
    ),
    'drunk': EyesPose(
      openness: 0.40,
      offsetY: 5,
      driftAmp: 4,
      blinkInterval: 6.0,
      blinkDuration: 0.20,
    ),
    'zen': EyesPose(
      openness: 0.15,
      offsetY: 2,
      blinkInterval: 99,
      blinkDuration: 99,
    ),
    'panting': EyesPose(
      openness: 0.60,
      offsetY: 2,
      blinkInterval: 2.0,
      blinkDuration: 0.15,
    ),
    // Yeux lourds de fatigue : mi-clos, clignements lents et fréquents
    'sleepy': EyesPose(
      openness: 0.50,
      offsetY: 4,
      blinkInterval: 2.5,
      blinkDuration: 0.30,
    ),
    'dead': EyesPose(
      openness: 0.01,
      offsetY: 14,
      blinkInterval: 99,
      blinkDuration: 99,
    ),
  };

  static const Map<String, MouthPose> mouth = {
    'smile': MouthPose(),
    'open': MouthPose(scaleY: 1.40),
    'neutral': MouthPose(scaleY: 0.70),
    'sad': MouthPose(scaleY: 1.20, rotationDeg: 180, offsetY: 14),
    'sick': MouthPose(scaleY: 0.60, rotationDeg: 180),
    'exhausted': MouthPose(scaleY: 1.20, rotationDeg: 10),
    'big_smile': MouthPose(scaleY: 2.10),
    'drunk_smile': MouthPose(scaleY: 1.20, rotationDeg: -12),
  };

  static const Map<String, CheeksPose> cheeks = {
    'visible': CheeksPose(opacity: 0.7),
    'flushed': CheeksPose(opacity: 1.0),
    'hidden': CheeksPose(opacity: 0.0),
    'blinking': CheeksPose(opacity: 0.5),
  };

  /// Noms d'états par couche — pour le panneau de debug
  /// (clés identiques aux anciens noms de couches : compatibilité recettes)
  static Map<String, List<String>> get layerStateNames => {
    'global': global.keys.toList(),
    'milieu': torso.keys.toList(),
    'jambes': legs.keys.toList(),
    'bras_D': armD.keys.toList(),
    'bras_G': armG.keys.toList(),
    'plante': leaf.keys.toList(),
    'yeux': eyes.keys.toList(),
    'bouche': mouth.keys.toList(),
    'joues': cheeks.keys.toList(),
  };
}
