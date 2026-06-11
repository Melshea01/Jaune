import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'core/oscillator.dart';
import 'core/spring_value.dart';
import 'events/motion_events.dart';
import 'poses/citron_pose.dart';
import 'poses/citron_moods.dart';
import 'poses/pose_catalog.dart';

/// Instantané immuable d'une frame d'animation : tous les scalaires finaux
/// dont le rendu a besoin. Le widget ne calcule plus AUCUN mouvement.
class CitronFrame {
  // Racine
  final double translateX;
  final double translateY;
  final double rotationRad;
  final double scaleX;
  final double scaleY;

  // Jambes
  final double legBounceD;
  final double legBounceG;
  final double legSquashD;
  final double legSquashG;
  final double legGravRot;

  // Bras
  final double armDAngle;
  final double armGAngle;

  // Feuille
  final double leafAngle;

  // Yeux
  final double eyeDriftX;
  final double eyeOffsetY;
  final double eyeScaleY;

  // Bouche
  final double mouthScaleY;
  final double mouthRotationDeg;
  final double mouthOffsetY;
  final double mouthPulse;

  // Joues
  final double cheeksOpacity;

  // Habillage visuel (couleur, lumière, particules)
  /// 0 = éclatant, 1 = gris mort
  final double tint;

  /// 0..1 rougeur d'ivresse
  final double flush;

  /// 0..1 intensité de l'aura dorée
  final double glow;

  /// Valeur de respiration courante (pulsation de l'aura)
  final double breathValue;

  /// Mode de particules : 'none' | 'sparkles' | 'bubbles' | 'sweat'
  final String particles;

  const CitronFrame({
    required this.translateX,
    required this.translateY,
    required this.rotationRad,
    required this.scaleX,
    required this.scaleY,
    required this.legBounceD,
    required this.legBounceG,
    required this.legSquashD,
    required this.legSquashG,
    required this.legGravRot,
    required this.armDAngle,
    required this.armGAngle,
    required this.leafAngle,
    required this.eyeDriftX,
    required this.eyeOffsetY,
    required this.eyeScaleY,
    required this.mouthScaleY,
    required this.mouthRotationDeg,
    required this.mouthOffsetY,
    required this.mouthPulse,
    required this.cheeksOpacity,
    required this.tint,
    required this.flush,
    required this.glow,
    required this.breathValue,
    required this.particles,
  });
}

/// Instance d'un événement one-shot en cours, avec son enveloppe de blend
class _EventInstance {
  final MotionEvent event;
  double elapsed = 0;
  bool fading = false; // supplanté par un retrigger → fondu de sortie
  double fadeElapsed = 0;

  _EventInstance(this.event);

  double get durationSec => event.duration.inMilliseconds / 1000.0;
  bool get finished =>
      elapsed >= durationSec ||
      (fading && fadeElapsed >= CitronEngine.eventRampSec);

  /// Poids de la contribution : rampe d'entrée, rampe de sortie,
  /// et fondu forcé si supplanté — plus jamais de snap.
  double get weight {
    const ramp = CitronEngine.eventRampSec;
    final wIn = (elapsed / ramp).clamp(0.0, 1.0);
    final wOut = ((durationSec - elapsed) / ramp).clamp(0.0, 1.0);
    var w = math.min(wIn, wOut);
    if (fading) w *= (1 - fadeElapsed / ramp).clamp(0.0, 1.0);
    return w;
  }
}

/// Le cerveau de l'animation du citron.
///
/// Tout le mouvement vit ici : springs critiquement amortis pour chaque
/// paramètre de pose, oscillateurs à phase intégrée, clignement, saccades
/// oculaires, micro-comportements d'idle et piste d'événements one-shot.
/// `update(dt)` avance le monde puis publie un [CitronFrame] prêt à rendre.
///
/// Garanties anti-saccade :
/// - la phase des oscillateurs ne saute jamais (intégrée, pas recalculée) ;
/// - tout changement de cible converge par spring : une transition
///   interrompue continue depuis sa position ET sa vitesse courantes ;
/// - les événements ont une enveloppe d'entrée/sortie et se crossfadent.
class CitronEngine {
  /// Rampe de blend des événements one-shot
  static const double eventRampSec = 0.08;

  /// dt maximal accepté (50 ms) : pas de saut après un retour d'arrière-plan
  static const double maxDtSec = 0.05;

  /// Échelle de temps globale (1.0 = temps réel) — slider du debug panel
  double timeScale = 1.0;

  /// Humeur des micro-comportements d'idle : 'happy' | 'neutral' | 'low' | 'none'
  String idleMood = 'neutral';

  final math.Random _rng;

  // ─── Raideurs par groupe : le follow-through est PHYSIQUE ──────────────
  // Le tronc mène (ω=8), le visage est vif (ω=14), les membres suivent
  // (ω=10), la feuille traîne (ω=5). Remplace les délais artificiels.
  static const double _wTorso = 8;
  static const double _wFace = 14;
  static const double _wLimbs = 10;
  static const double _wLeaf = 5;

  // ─── Springs des paramètres de pose ────────────────────────────────────
  late final SpringValue _slump = SpringValue(0, omega: _wTorso);
  late final SpringValue _lean = SpringValue(0, omega: _wTorso);
  late final SpringValue _torsoScaleX = SpringValue(1, omega: _wTorso);
  late final SpringValue _torsoScaleY = SpringValue(1, omega: _wTorso);
  late final SpringValue _torsoOffsetY = SpringValue(0, omega: _wTorso);
  late final SpringValue _torsoDriftX = SpringValue(0, omega: _wTorso);

  late final SpringValue _legBaseD = SpringValue(0, omega: _wLimbs);
  late final SpringValue _legBaseG = SpringValue(0, omega: _wLimbs);
  late final SpringValue _legGrav = SpringValue(0, omega: _wLimbs);
  late final SpringValue _legSquashAmp = SpringValue(0, omega: _wLimbs);

  late final SpringValue _armDBase = SpringValue(0, omega: _wLimbs);
  late final SpringValue _armDGrav = SpringValue(0, omega: _wLimbs);
  late final SpringValue _armGBase = SpringValue(0, omega: _wLimbs);
  late final SpringValue _armGGrav = SpringValue(0, omega: _wLimbs);

  // L'orientation de BASE de la feuille suit le corps de près (ω tronc) :
  // seule l'oscillation traîne (ω feuille). Sinon la branche pointe dans la
  // mauvaise direction pendant ~1 s après un changement d'état et semble
  // détachée du corps.
  late final SpringValue _leafBase = SpringValue(0, omega: _wTorso);

  late final SpringValue _eyeOpenness = SpringValue(1, omega: _wFace);
  late final SpringValue _eyeOffsetY = SpringValue(0, omega: _wFace);

  late final SpringValue _mouthScaleY = SpringValue(1, omega: _wFace);
  late final SpringValue _mouthRotation = SpringValue(0, omega: _wFace);
  late final SpringValue _mouthOffsetY = SpringValue(0, omega: _wFace);

  late final SpringValue _cheeksOpacity = SpringValue(1, omega: _wFace);

  // ─── Habillage visuel (couleur, lumière) ───────────────────────────────
  // La teinte est une ambiance : elle glisse lentement (ω=4). Le flush et
  // l'aura sont plus réactifs (ω=6).
  late final SpringValue _tint = SpringValue(0, omega: 4);
  late final SpringValue _flush = SpringValue(0, omega: 6);
  late final SpringValue _glow = SpringValue(0, omega: 6);

  /// Mode de particules courant — le switch est instantané, c'est
  /// l'émetteur (côté rendu) qui fait la rampe d'apparition/extinction
  String particleMode = 'none';

  // ─── Oscillateurs (phase intégrée, jamais de saut) ─────────────────────
  late final Oscillator _hop = Oscillator(omega: _wTorso);
  late final Oscillator _sway = Oscillator(omega: _wTorso); // amp en degrés
  late final Oscillator _breath = Oscillator(omega: _wTorso);
  late final Oscillator _legs = Oscillator(omega: _wLimbs);
  late final Oscillator _armD = Oscillator(omega: _wLimbs);
  // Bras gauche déphasé d'un demi-cycle : désynchronisation naturelle
  late final Oscillator _armG = Oscillator(omega: _wLimbs, initialPhase: math.pi);
  late final Oscillator _leaf = Oscillator(omega: _wLeaf);
  // Fréquences fixes historiques (2.3·sf·π et 2.8·sf·π rad/s → Hz)
  late final Oscillator _eyeWobble = Oscillator(omega: _wFace, frequency: 0.575);
  late final Oscillator _mouthPulse = Oscillator(omega: _wFace, frequency: 0.7);

  // Config de clignement (réglage, pas une animation : pas de spring)
  double _blinkInterval = 4.0;
  double _blinkDuration = 0.12;

  // ─── État des sous-systèmes ────────────────────────────────────────────
  bool blinkActive = false;
  double _blinkElapsed = 0;

  /// 0.0 = œil ouvert, 1.0 = paupière fermée (courbe sinus lissée)
  double blinkAmount = 0;

  /// Décalage X courant du regard (saccades oculaires)
  double eyeLookX = 0;
  double _eyeLookTarget = 0;
  double _saccadeElapsed = 0;
  double _nextSaccadeAt = 3;

  double _idleElapsed = 0;
  double _nextIdleAt = 6;

  static const Map<String, List<String>> _idlePools = {
    'happy': ['curious', 'jump_joy', 'hiccup', 'coin_spin', 'encourage'],
    'neutral': ['curious', 'encourage', 'hiccup', 'shiver'],
    'low': ['shiver', 'curious'],
  };

  final List<_EventInstance> _events = [];

  /// Frame courante, recalculée à chaque update — la seule chose que lit le rendu
  late CitronFrame frame;

  CitronEngine({math.Random? random}) : _rng = random ?? math.Random() {
    applyRecipe(CitronMoods.defaults, snap: true);
    frame = _composeFrame();
  }

  // ─── API publique ──────────────────────────────────────────────────────

  bool get hasActiveEvent => _events.any((e) => !e.fading);

  /// Applique une recette { couche → nom de pose }. Les cibles changent,
  /// les springs convergent — interruption fluide garantie.
  /// [tempo] multiplie les fréquences (caractère des animations spéciales).
  void applyRecipe(
    Map<String, String> recipe, {
    double tempo = 1.0,
    bool snap = false,
  }) {
    recipe.forEach((layer, poseName) {
      switch (layer) {
        case 'global':
          final p = PoseCatalog.global[poseName];
          if (p != null) _applyGlobal(p, tempo, snap);
        case 'milieu':
          final p = PoseCatalog.torso[poseName];
          if (p != null) _applyTorso(p, tempo, snap);
        case 'jambes':
          final p = PoseCatalog.legs[poseName];
          if (p != null) _applyLegs(p, tempo, snap);
        case 'bras_D':
          final p = PoseCatalog.armD[poseName];
          if (p != null) _applyArm(p, _armD, _armDBase, _armDGrav, tempo, snap);
        case 'bras_G':
          final p = PoseCatalog.armG[poseName];
          if (p != null) _applyArm(p, _armG, _armGBase, _armGGrav, tempo, snap);
        case 'plante':
          final p = PoseCatalog.leaf[poseName];
          if (p != null) _applyLeaf(p, tempo, snap);
        case 'yeux':
          final p = PoseCatalog.eyes[poseName];
          if (p != null) _applyEyes(p, snap);
        case 'bouche':
          final p = PoseCatalog.mouth[poseName];
          if (p != null) _applyMouth(p, snap);
        case 'joues':
          final p = PoseCatalog.cheeks[poseName];
          if (p != null) _applyCheeks(p, snap);
        default:
          debugPrint('⚠️ CitronEngine: couche inconnue "$layer"');
      }
    });
  }

  /// Applique un style visuel (teinte, flush, aura, particules)
  void applyStyle(MoodStyle style, {bool snap = false}) {
    if (snap) {
      _tint.snapTo(style.tint);
      _flush.snapTo(style.flush);
      _glow.snapTo(style.glow);
    } else {
      _tint.setTarget(style.tint);
      _flush.setTarget(style.flush);
      _glow.setTarget(style.glow);
    }
    particleMode = style.particles;
  }

  /// Flash d'aura (level-up) : impulsion de vélocité sur le spring —
  /// l'aura jaillit puis retombe naturellement vers sa cible
  void kickGlow([double impulse = 8.0]) => _glow.kick(impulse);

  /// Déclenche un événement one-shot. Tout événement en cours est
  /// crossfadé (80 ms) vers le nouveau — jamais de snap au retrigger.
  MotionEvent? triggerEvent(String name) {
    final event = MotionEvents.byName(name);
    if (event == null) {
      debugPrint('⚠️ CitronEngine: événement inconnu "$name"');
      return null;
    }
    for (final inst in _events) {
      inst.fading = true;
    }
    _events.add(_EventInstance(event));
    return event;
  }

  /// Applique le preset correspondant à la santé (0-100)
  void applyHealth(int health) => applyRecipe(CitronMoods.healthPreset(health));

  /// Avance le monde de [rawDt] secondes (clampé) et publie la frame.
  void update(double rawDt) {
    final dt = rawDt.clamp(0.0, maxDtSec) * timeScale;
    if (dt <= 0) {
      frame = _composeFrame();
      return;
    }

    // Springs scalaires
    _slump.update(dt);
    _lean.update(dt);
    _torsoScaleX.update(dt);
    _torsoScaleY.update(dt);
    _torsoOffsetY.update(dt);
    _torsoDriftX.update(dt);
    _legBaseD.update(dt);
    _legBaseG.update(dt);
    _legGrav.update(dt);
    _legSquashAmp.update(dt);
    _armDBase.update(dt);
    _armDGrav.update(dt);
    _armGBase.update(dt);
    _armGGrav.update(dt);
    _leafBase.update(dt);
    _eyeOpenness.update(dt);
    _eyeOffsetY.update(dt);
    _mouthScaleY.update(dt);
    _mouthRotation.update(dt);
    _mouthOffsetY.update(dt);
    _cheeksOpacity.update(dt);
    _tint.update(dt);
    _flush.update(dt);
    _glow.update(dt);

    // Oscillateurs
    _hop.update(dt);
    _sway.update(dt);
    _breath.update(dt);
    _legs.update(dt);
    _armD.update(dt);
    _armG.update(dt);
    _leaf.update(dt);
    _eyeWobble.update(dt);
    _mouthPulse.update(dt);

    // Sous-systèmes vivants
    _updateBlink(dt);
    _updateSaccades(dt);
    _updateIdleLife(dt);
    _updateEvents(dt);

    frame = _composeFrame();
  }

  // ─── Application des poses ─────────────────────────────────────────────

  void _applyGlobal(GlobalPose p, double tempo, bool snap) {
    if (snap) {
      _hop.snapTo(frequency: p.hopFreq * tempo, amplitude: p.hopAmp);
      _slump.snapTo(p.slump);
    } else {
      _hop.setFrequencyTarget(p.hopFreq * tempo);
      _hop.setAmplitudeTarget(p.hopAmp);
      _slump.setTarget(p.slump);
    }
  }

  void _applyTorso(TorsoPose p, double tempo, bool snap) {
    if (snap) {
      _sway.snapTo(frequency: p.swayFreq * tempo, amplitude: p.swayAmpDeg);
      _breath.snapTo(frequency: p.breathFreq * tempo, amplitude: p.breathAmp);
      _lean.snapTo(p.leanDeg);
      _torsoScaleX.snapTo(p.scaleX);
      _torsoScaleY.snapTo(p.scaleY);
      _torsoOffsetY.snapTo(p.offsetY);
      _torsoDriftX.snapTo(p.driftX);
    } else {
      _sway.setFrequencyTarget(p.swayFreq * tempo);
      _sway.setAmplitudeTarget(p.swayAmpDeg);
      _breath.setFrequencyTarget(p.breathFreq * tempo);
      _breath.setAmplitudeTarget(p.breathAmp);
      _lean.setTarget(p.leanDeg);
      _torsoScaleX.setTarget(p.scaleX);
      _torsoScaleY.setTarget(p.scaleY);
      _torsoOffsetY.setTarget(p.offsetY);
      _torsoDriftX.setTarget(p.driftX);
    }
  }

  void _applyLegs(LegsPose p, double tempo, bool snap) {
    if (snap) {
      _legs.snapTo(frequency: p.freq * tempo, amplitude: p.bounceAmp);
      _legBaseD.snapTo(p.baseLiftD);
      _legBaseG.snapTo(p.baseLiftG);
      _legGrav.snapTo(p.gravFollow);
      _legSquashAmp.snapTo(p.squashAmp);
    } else {
      _legs.setFrequencyTarget(p.freq * tempo);
      _legs.setAmplitudeTarget(p.bounceAmp);
      _legBaseD.setTarget(p.baseLiftD);
      _legBaseG.setTarget(p.baseLiftG);
      _legGrav.setTarget(p.gravFollow);
      _legSquashAmp.setTarget(p.squashAmp);
    }
  }

  void _applyArm(
    ArmPose p,
    Oscillator osc,
    SpringValue base,
    SpringValue grav,
    double tempo,
    bool snap,
  ) {
    if (snap) {
      osc.snapTo(frequency: p.freq * tempo, amplitude: p.swingAmp);
      base.snapTo(p.baseAngle);
      grav.snapTo(p.gravFollow);
    } else {
      osc.setFrequencyTarget(p.freq * tempo);
      osc.setAmplitudeTarget(p.swingAmp);
      base.setTarget(p.baseAngle);
      grav.setTarget(p.gravFollow);
    }
  }

  void _applyLeaf(LeafPose p, double tempo, bool snap) {
    if (snap) {
      _leaf.snapTo(frequency: p.freq * tempo, amplitude: p.swayAmp);
      _leafBase.snapTo(p.baseAngle);
    } else {
      _leaf.setFrequencyTarget(p.freq * tempo);
      _leaf.setAmplitudeTarget(p.swayAmp);
      _leafBase.setTarget(p.baseAngle);
    }
  }

  void _applyEyes(EyesPose p, bool snap) {
    _blinkInterval = p.blinkInterval;
    _blinkDuration = p.blinkDuration;
    if (snap) {
      _eyeOpenness.snapTo(p.openness);
      _eyeOffsetY.snapTo(p.offsetY);
      _eyeWobble.snapTo(frequency: 0.575, amplitude: p.driftAmp);
    } else {
      _eyeOpenness.setTarget(p.openness);
      _eyeOffsetY.setTarget(p.offsetY);
      _eyeWobble.setAmplitudeTarget(p.driftAmp);
    }
  }

  void _applyMouth(MouthPose p, bool snap) {
    if (snap) {
      _mouthScaleY.snapTo(p.scaleY);
      _mouthRotation.snapTo(p.rotationDeg);
      _mouthOffsetY.snapTo(p.offsetY);
      _mouthPulse.snapTo(frequency: 0.7, amplitude: p.scaleY - 1.0);
    } else {
      _mouthScaleY.setTarget(p.scaleY);
      _mouthRotation.setTarget(p.rotationDeg);
      _mouthOffsetY.setTarget(p.offsetY);
      _mouthPulse.setAmplitudeTarget(p.scaleY - 1.0);
    }
  }

  void _applyCheeks(CheeksPose p, bool snap) {
    if (snap) {
      _cheeksOpacity.snapTo(p.opacity);
    } else {
      _cheeksOpacity.setTarget(p.opacity);
    }
  }

  // ─── Sous-systèmes vivants ─────────────────────────────────────────────

  void _updateBlink(double dt) {
    // blinkInterval ≥ 99 : clignement désactivé pour cet état
    if (_blinkInterval >= 99) {
      blinkActive = false;
      blinkAmount = 0;
      return;
    }

    _blinkElapsed += dt;
    if (!blinkActive) {
      blinkAmount = 0;
      if (_blinkElapsed > _blinkInterval) {
        blinkActive = true;
        _blinkElapsed = 0;
      }
    } else {
      // Paupière : 0 → 1 → 0 en sinus sur la durée du clin
      final progress = (_blinkElapsed / _blinkDuration).clamp(0.0, 1.0);
      blinkAmount = math.sin(progress * math.pi);
      if (_blinkElapsed > _blinkDuration) {
        blinkActive = false;
        blinkAmount = 0;
        // 20 % de chance de double-clin : le prochain part presque aussitôt
        _blinkElapsed =
            _rng.nextDouble() < 0.2
                ? (_blinkInterval - 0.25).clamp(0.0, _blinkInterval)
                : 0;
      }
    }
  }

  void _updateSaccades(double dt) {
    final eyesAlive = _blinkInterval < 99;
    if (!eyesAlive) {
      _eyeLookTarget = 0;
    } else {
      _saccadeElapsed += dt;
      if (_saccadeElapsed >= _nextSaccadeAt) {
        _saccadeElapsed = 0;
        _nextSaccadeAt = 2.5 + _rng.nextDouble() * 5;
        // 60 % du temps : fixe un point ; sinon revient au centre
        _eyeLookTarget =
            _rng.nextDouble() < 0.6 ? (_rng.nextDouble() * 8 - 4) : 0;
      }
    }
    // Saccade rapide : convergence exponentielle vers la cible
    eyeLookX +=
        (_eyeLookTarget - eyeLookX) * (1 - math.exp(-dt * 12)).clamp(0.0, 1.0);
  }

  void _updateIdleLife(double dt) {
    if (idleMood == 'none' || hasActiveEvent) return;

    _idleElapsed += dt;
    if (_idleElapsed < _nextIdleAt) return;

    _idleElapsed = 0;
    _nextIdleAt = 7 + _rng.nextDouble() * 8;

    final pool = _idlePools[idleMood];
    if (pool != null && pool.isNotEmpty) {
      triggerEvent(pool[_rng.nextInt(pool.length)]);
    }
  }

  void _updateEvents(double dt) {
    for (final inst in _events) {
      inst.elapsed += dt;
      if (inst.fading) inst.fadeElapsed += dt;
    }
    _events.removeWhere((inst) => inst.finished);
  }

  // ─── Composition de la frame ───────────────────────────────────────────

  CitronFrame _composeFrame() {
    // Contribution pondérée des événements one-shot
    double evHop = 0;
    double evSway = 0;
    double evScaleX = 1;
    double evScaleY = 1;
    for (final inst in _events) {
      final w = inst.weight;
      if (w <= 0) continue;
      final progress = (inst.elapsed / inst.durationSec).clamp(0.0, 1.0);
      final s = inst.event.sample(progress);
      evHop += w * (s['hopY']?.toDouble() ?? 0);
      evSway += w * (s['swayRad']?.toDouble() ?? 0);
      evScaleX *= 1 + w * ((s['scaleX']?.toDouble() ?? 1) - 1);
      evScaleY *= 1 + w * ((s['scaleY']?.toDouble() ?? 1) - 1);
    }

    final hop = -_hop.absSine;
    final swayRad = _sway.sine * math.pi / 180.0;
    final breath = _breath.sine;

    // Jambes : phase partagée, exploitation asymétrique D/G
    final legRaw = _legs.raw;
    final legAmp = _legs.amplitude;
    final bounceD = _legBaseD.value - math.max(0.0, legRaw) * legAmp;
    final bounceG = _legBaseG.value - math.max(0.0, -legRaw) * legAmp;
    final squashD = 1 + math.max(0.0, legRaw) * _legSquashAmp.value;
    final squashG = 1 + math.max(0.0, -legRaw) * _legSquashAmp.value;

    final rootRot = _lean.value * math.pi / 180.0 + swayRad + evSway;
    final legGravRot = -rootRot * (1 - _legGrav.value);

    final armDAngle =
        _armDBase.value + _armD.sine - rootRot * (1 - _armDGrav.value);
    final armGAngle =
        _armGBase.value - _armG.sine - rootRot * (1 - _armGGrav.value);

    // Garde-fou : au-delà de ±0.55 rad la branche sortirait du creux du
    // corps quel que soit le pivot — aucune recette ne peut la détacher
    final leafAngle = (_leafBase.value + _leaf.sine * 0.2).clamp(-0.55, 0.55);

    // Yeux : ouverture × clignement, dérive d'état + saccades
    final baseEye = _eyeOpenness.value.clamp(0.08, 1.6);
    final eyeScaleY = baseEye * (1 - blinkAmount) + 0.06 * blinkAmount;
    final blinkCompY = (1.0 - eyeScaleY) * 8.0;
    final eyeDriftX = _eyeWobble.sine + eyeLookX;

    // Squash & stretch dérivé de la VITESSE du hop : écrasement maximal
    // au contact du sol (|cos| max quand |sin| ≈ 0), étirement à l'apex
    final hopUp = _hop.raw.abs();
    final ampNorm = (_hop.amplitude / 10).clamp(0.0, 1.0);
    final impact = (1 - hopUp) * _hop.speedNorm * 0.05 * ampNorm;
    final apex = hopUp * 0.03 * ampNorm;

    final legSquashDelta = ((squashD - 1) + (squashG - 1)) / 2;
    final scaleX = (_torsoScaleX.value *
            (1 + breath * 0.2 + legSquashDelta * 0.6 + impact - apex * 0.5) *
            evScaleX)
        .clamp(0.5, 1.8);
    final scaleY = ((_torsoScaleY.value - _slump.value * 0.002) *
            (1 - breath * 0.15 - legSquashDelta * 0.6 - impact + apex) *
            evScaleY)
        .clamp(0.5, 1.8);

    return CitronFrame(
      translateX: _torsoDriftX.value * 2,
      translateY:
          hop -
          math.max(bounceD, bounceG) +
          _slump.value * 0.5 +
          _torsoOffsetY.value +
          evHop,
      rotationRad: rootRot,
      scaleX: scaleX,
      scaleY: scaleY,
      legBounceD: bounceD,
      legBounceG: bounceG,
      legSquashD: squashD,
      legSquashG: squashG,
      legGravRot: legGravRot,
      armDAngle: armDAngle,
      armGAngle: armGAngle,
      leafAngle: leafAngle,
      eyeDriftX: eyeDriftX,
      eyeOffsetY: _eyeOffsetY.value + blinkCompY,
      eyeScaleY: eyeScaleY,
      mouthScaleY: _mouthScaleY.value,
      mouthRotationDeg: _mouthRotation.value,
      mouthOffsetY: _mouthOffsetY.value,
      mouthPulse: _mouthPulse.sine,
      cheeksOpacity: _cheeksOpacity.value.clamp(0.0, 1.0),
      tint: _tint.value.clamp(0.0, 1.0),
      flush: _flush.value.clamp(0.0, 1.0),
      glow: _glow.value.clamp(0.0, 1.6), // le kick peut dépasser 1 (flash)
      breathValue: breath,
      particles: particleMode,
    );
  }
}
