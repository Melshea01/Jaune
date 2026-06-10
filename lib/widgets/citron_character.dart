import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'dart:math' as math;
import '../controllers/citron_animation_controller.dart';

/// Main widget displaying the animated Citron character
/// Renders SVG and applies animated transforms based on layer states
class CitronCharacter extends StatefulWidget {
  final CitronAnimationController controller;
  final double scale;

  const CitronCharacter({
    super.key,
    required this.controller,
    this.scale = 1.0,
  });

  @override
  State<CitronCharacter> createState() => _CitronCharacterState();
}

class _CitronCharacterState extends State<CitronCharacter>
    with SingleTickerProviderStateMixin {
  Duration _lastFrameTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupTicker();
    widget.controller.addListener(_onControllerChanged);
  }

  void _setupTicker() {
    createTicker((elapsed) {
      // Update blinking animation
      final deltaTime = elapsed - _lastFrameTime;
      widget.controller.updateBlinking(deltaTime);
      _lastFrameTime = elapsed;

      // Request rebuild for next frame (60 FPS loop)
      setState(() {});
    }).start();
  }

  void _onControllerChanged() {
    // Rebuild when controller changes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final t = nowMs / 1000.0;

    final global = widget.controller.layerGlobal.get(nowMs);
    final milieu = widget.controller.layerMilieu.get(nowMs);
    final jambes = widget.controller.layerJambes.get(nowMs);
    final brasD = widget.controller.layerBrasD.get(nowMs);
    final brasG = widget.controller.layerBrasG.get(nowMs);
    final plante = widget.controller.layerPlante.get(nowMs);
    final yeux = widget.controller.layerYeux.get(nowMs);
    final bouche = widget.controller.layerBouche.get(nowMs);
    final joues = widget.controller.layerJoues.get(nowMs);

    // --- Phases and primary signals (ported from the JS engine)
    // Apply controller-wide speed factor to slow/sync all phases
    final sf =
        widget.controller.speedFactor *
        widget.controller.animationSpeedMultiplier;
    // Hop: uses absolute sin (only upward/downward magnitude) and is inverted
    final hop =
        -((math.sin(t * global.hopSpeed * sf * 2 * math.pi)).abs() *
            global.hopAmp);

    // Sway is expressed in DEGREES in the states and used as a rotation (converted to radians)
    final swayPhase = t * milieu.swaySpeed * sf * 2 * math.pi;
    final swayRad = (milieu.swayAmp * math.pi / 180.0) * math.sin(swayPhase);

    // Breath (unitless small scale modulation)
    final breath =
        math.sin(t * milieu.breathSpeed * sf * 2 * math.pi) * milieu.breathAmp;

    // Jambes: asymmetric behaviour between left/right as in JS engine
    final legWave = math.sin(t * jambes.speed * sf * 2 * math.pi);
    final legBounceD = jambes.baseD - math.max(0.0, legWave) * jambes.ampY;
    final legBounceG = jambes.baseG - math.max(0.0, -legWave) * jambes.ampY;
    final legSquashD = 1.0 + math.max(0.0, legWave) * jambes.scaleAmp;
    final legSquashG = 1.0 + math.max(0.0, -legWave) * jambes.scaleAmp;

    // Bras (mouvements indépendants) — keep a phase offset for the left arm
    final armWaveD = math.sin(t * brasD.speed * sf * 2 * math.pi) * brasD.amp;
    final armWaveG =
        math.sin((t + 0.5) * brasG.speed * sf * 2 * math.pi) * brasG.amp;

    // Plante and visage signals
    final leafWave = math.sin(t * plante.speed * sf * 2 * math.pi) * plante.amp;
    final eyeDrift = math.sin(t * 2.3 * sf * math.pi) * yeux.drift;
    final mouthPulse = math.sin(t * 2.8 * sf * math.pi) * (bouche.scaleY - 1.0);

    final blinkScaleY =
        widget.controller.blinkActive ? 0.08 : yeux.scaleY.clamp(0.08, 1.4);
    final blinkCompY = (1.0 - blinkScaleY) * 8.0;

    // --- TRANSFORMATIONS GLOBALES ---
    // (Respiration, affaissement, sauts)
    // Root transforms: rotation inherits lean (degrees → radians) + swayRad
    final rootTranslateX = (milieu.drift * 2); // drift remains a small X offset
    final rootTranslateY =
        hop -
        (math.max(legBounceD, legBounceG)) +
        (global.slump * 0.5) +
        milieu.offsetY;
    final rootRotationRad = (milieu.lean * math.pi / 180.0) + swayRad;

    // Prevent excessive squash/stretch: use delta from 1.0 (actual squash), reduce multiplier
    final legSquashDelta = (((legSquashD - 1.0) + (legSquashG - 1.0)) / 2.0);
    final rootScaleX = (milieu.baseScaleX *
            (1 + breath * 0.2 + legSquashDelta * 0.6))
        .clamp(0.6, 1.6);
    final rootScaleY = ((milieu.baseScaleY - global.slump * 0.002) *
            (1 - breath * 0.15 - legSquashDelta * 0.6))
        .clamp(0.6, 1.6);

    final renderOpacity = (global.opacity *
            (0.85 + (joues.opacity.clamp(0, 1) * 0.15)))
        .clamp(0.0, 1.0);

    // --- TRANSFORMATIONS INDIVIDUELLES ---
    // Toutes tes valeurs (amp, base) étaient en fait déjà en RADIANS dans tes configurations !
    // On applique donc directement tes valeurs pures sans multiplicateurs arbitraires.
    // Arms inherit root rotation (gravFollow behaviour) like the JS engine
    final brasDAngle =
        brasD.base + armWaveD - rootRotationRad * (1 - brasD.gravFollow);
    final brasGAngle =
        brasG.base - armWaveG - rootRotationRad * (1 - brasG.gravFollow);
    final brasDMatrix = Matrix4.identity()..rotateZ(brasDAngle);
    final brasGMatrix = Matrix4.identity()..rotateZ(brasGAngle);

    // Keep the stem lightly alive, but anchored at the rendered branch base.
    final planteMatrix = Matrix4.identity()..rotateZ(leafWave * 0.2);
    const plantePivot = Offset(220.0, 97.5);

    // Jambes: asymmetric translate + scale + small inherited rotation
    final gravRotLeg = -rootRotationRad * (1 - jambes.gravFollow);
    final jambeDMatrix =
        Matrix4.identity()
          ..translateByDouble(0.0, legBounceD, 0, 1)
          ..scaleByDouble(legSquashD, 1.0, 1, 1)
          ..rotateZ(gravRotLeg);
    final jambeGMatrix =
        Matrix4.identity()
          ..translateByDouble(0.0, legBounceG, 0, 1)
          ..scaleByDouble(legSquashG, 1.0, 1, 1)
          ..rotateZ(gravRotLeg);

    final yeuxMatrix =
        Matrix4.identity()
          ..translateByDouble(eyeDrift, yeux.offsetY + blinkCompY, 0, 1)
          ..scaleByDouble(1.0, blinkScaleY, 1, 1);

    final boucheMatrix =
        Matrix4.identity()
          ..rotateZ(
            bouche.rotation * math.pi / 180,
          ) // La bouche utilise des degrés (180)
          ..scaleByDouble(1.0, bouche.scaleY.clamp(0.1, 2.0), 1, 1);

    Widget buildPart(
      String name, {
      Matrix4? transform,
      Alignment alignment = Alignment.center,
      Offset? offset,
      Offset? origin,
      double partOpacity = 1.0,
    }) {
      Widget piece = svg.SvgPicture.asset(
        'assets/citron_$name.svg',
        width: 420,
        height: 420,
        fit: BoxFit.contain,
        allowDrawingOutsideViewBox: true,
      );
      if (partOpacity < 1.0) {
        piece = Opacity(opacity: partOpacity, child: piece);
      }
      if (transform != null) {
        piece = Transform(
          alignment: alignment,
          origin: origin,
          transform: transform,
          child: piece,
        );
      }
      if (offset != null) {
        piece = Transform.translate(offset: offset, child: piece);
      }
      return Positioned.fill(child: piece);
    }

    return Transform.scale(
      scale: widget.scale,
      child: SizedBox(
        width: 420,
        height: 420,
        child: Opacity(
          opacity: renderOpacity,
          child: Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()
                  ..translateByDouble(rootTranslateX, rootTranslateY, 0, 1)
                  ..rotateZ(rootRotationRad)
                  ..scaleByDouble(rootScaleX, rootScaleY, 1, 1),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                buildPart(
                  'jambe_g',
                  transform: jambeGMatrix,
                  alignment: const FractionalOffset(0.4, 0.7),
                ),
                buildPart(
                  'jambe_d',
                  transform: jambeDMatrix,
                  alignment: const FractionalOffset(0.6, 0.7),
                ),
                buildPart(
                  'bras_g',
                  transform: brasGMatrix,
                  alignment: const FractionalOffset(0.3, 0.48),
                ),
                buildPart(
                  'bras_d',
                  transform: brasDMatrix,
                  alignment: const FractionalOffset(0.7, 0.48),
                ),
                buildPart(
                  'plante',
                  transform: planteMatrix,
                  alignment: Alignment.topLeft,
                  origin: plantePivot,
                ),
                buildPart('corps'),
                buildPart(
                  'joues',
                  partOpacity: joues.opacity.clamp(0, 1).toDouble(),
                ),
                buildPart(
                  'yeux',
                  transform: yeuxMatrix,
                  alignment: const FractionalOffset(0.5, 0.4),
                ),
                buildPart(
                  'bouche',
                  transform: boucheMatrix,
                  alignment: const FractionalOffset(0.5, 0.46),
                  offset: Offset(
                    bouche.rotation.abs() > 90 ? 20.0 : 0.0,
                    bouche.offsetY +
                        mouthPulse +
                        (bouche.rotation.abs() > 90 ? 4.0 : 0.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
