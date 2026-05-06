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

    final hop = math.sin(t * global.hopSpeed * 2 * math.pi) * global.hopAmp;
    final sway = math.sin(t * milieu.swaySpeed * 2 * math.pi) * milieu.swayAmp;
    final breath =
        math.sin(t * milieu.breathSpeed * 2 * math.pi) * milieu.breathAmp;

    final legBounce =
      math.sin(t * jambes.speed * 2 * math.pi) * jambes.ampY * 0.5;
    final legSquash =
      math.sin(t * jambes.speed * 2 * math.pi) * jambes.scaleAmp * 0.35;

    final armWaveD = math.sin(t * brasD.speed * 2 * math.pi) * brasD.amp;
    final armWaveG = math.sin(t * brasG.speed * 2 * math.pi) * brasG.amp;
    final armSway = (armWaveD - armWaveG) * 8;

    final leafWave = math.sin(t * plante.speed * 2 * math.pi) * plante.amp;
    final eyeDrift = math.sin(t * 2.3 * math.pi) * yeux.drift;
    final mouthPulse = math.sin(t * 2.8 * math.pi) * (bouche.scaleY - 1.0);

    final blinkScaleY = widget.controller.blinkActive
      ? 0.08
      : yeux.scaleY.clamp(0.08, 1.4);

    final translateX = sway + armSway + eyeDrift + leafWave * 6 + (milieu.drift * 5);
    final translateY =
      (-hop) - legBounce + (global.slump * 0.6) + milieu.offsetY + yeux.offsetY;
    final rotationDeg = milieu.lean + milieu.rotation + global.rotation +
      ((armWaveD - armWaveG) * 14) + (leafWave * 10);
    final rotationRad = rotationDeg * math.pi / 180;
    final scaleX =
      (milieu.baseScaleX * (1 + breath * 0.8 + legSquash + mouthPulse * 0.08))
        .clamp(0.55, 1.95);
    final scaleY =
      ((milieu.baseScaleY - global.slump * 0.002) *
          (1 - breath * 0.6 - legSquash * 0.7) *
          (1 + (blinkScaleY - 1) * 0.08))
        .clamp(0.55, 1.95);

    final renderOpacity =
      (global.opacity * (0.85 + (joues.opacity.clamp(0, 1) * 0.15)))
        .clamp(0.0, 1.0);

    return Transform.scale(
      scale: widget.scale,
      child: SizedBox(
        width: 420,
        height: 420,
        child: Opacity(
        opacity: renderOpacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(translateX, translateY, 0, 1)
              ..rotateZ(rotationRad)
              ..scaleByDouble(scaleX, scaleY, 1, 1),
            child: svg.SvgPicture.asset(
              'assets/citron.svg',
              width: 420,
              height: 420,
              fit: BoxFit.contain,
              allowDrawingOutsideViewBox: true,
              placeholderBuilder: (context) => const SizedBox(
                width: 420,
                height: 420,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
