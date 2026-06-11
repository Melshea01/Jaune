/// Poses typées par couche — chaque couche n'expose QUE ses paramètres.
///
/// Remplace l'ancien `AnimationLayerState` : 25 champs plats partagés par
/// 9 couches dont chacune n'en utilisait que 3 à 5.
///
/// Toutes les fréquences sont en Hz réels (l'ancien `speedFactor = 0.5`
/// est intégré dans les valeurs du catalogue).
library;

/// Couche racine : rebond global et affaissement
class GlobalPose {
  final double hopAmp; // px
  final double hopFreq; // Hz (onde |sin| : 2 rebonds visuels par cycle)
  final double slump; // px d'affaissement (+ écrasement vertical dérivé)

  const GlobalPose({this.hopAmp = 0, this.hopFreq = 1, this.slump = 0});
}

/// Tronc : balancement, respiration, inclinaison, échelle
class TorsoPose {
  final double swayAmpDeg; // degrés
  final double swayFreq; // Hz
  final double breathAmp; // modulation d'échelle (sans unité)
  final double breathFreq; // Hz
  final double leanDeg; // inclinaison de base, degrés
  final double scaleX;
  final double scaleY;
  final double offsetY; // px
  final double driftX; // px

  const TorsoPose({
    this.swayAmpDeg = 0,
    this.swayFreq = 1,
    this.breathAmp = 0,
    this.breathFreq = 1,
    this.leanDeg = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.offsetY = 0,
    this.driftX = 0,
  });
}

/// Jambes : rebond asymétrique D/G partageant une même phase
class LegsPose {
  final double bounceAmp; // px
  final double squashAmp; // modulation d'échelle X
  final double freq; // Hz
  final double baseLiftD; // px, levée statique droite
  final double baseLiftG; // px, levée statique gauche
  final double gravFollow; // 0..1 : suit la rotation du tronc

  const LegsPose({
    this.bounceAmp = 0,
    this.squashAmp = 0,
    this.freq = 1,
    this.baseLiftD = 0,
    this.baseLiftG = 0,
    this.gravFollow = 0,
  });
}

/// Bras (une instance par bras)
class ArmPose {
  final double swingAmp; // radians
  final double freq; // Hz
  final double baseAngle; // radians
  final double gravFollow; // 0..1

  const ArmPose({
    this.swingAmp = 0,
    this.freq = 1,
    this.baseAngle = 0,
    this.gravFollow = 0,
  });
}

/// Feuille (plante) sur la tête
class LeafPose {
  final double swayAmp; // radians (atténué ×0.2 au rendu, comme avant)
  final double freq; // Hz
  final double baseAngle; // radians — appliqué au pivot de la branche

  const LeafPose({this.swayAmp = 0, this.freq = 1, this.baseAngle = 0});
}

/// Yeux : ouverture, clignement, dérive
class EyesPose {
  final double openness; // échelle Y de l'œil
  final double offsetY; // px
  final double driftAmp; // px — flottement horizontal (état ivre)
  final double blinkInterval; // s — ≥ 99 désactive le clignement
  final double blinkDuration; // s

  const EyesPose({
    this.openness = 1,
    this.offsetY = 0,
    this.driftAmp = 0,
    this.blinkInterval = 4,
    this.blinkDuration = 0.12,
  });
}

/// Bouche
class MouthPose {
  final double scaleY;
  final double rotationDeg; // 180 = retournée (moue)
  final double offsetY; // px

  const MouthPose({this.scaleY = 1, this.rotationDeg = 0, this.offsetY = 0});
}

/// Joues
class CheeksPose {
  final double opacity; // 0..1

  const CheeksPose({this.opacity = 1});
}
