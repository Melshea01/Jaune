import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_svg/flutter_svg.dart' as svg;

import '../animation/citron_engine.dart';
import '../controllers/citron_animation_controller.dart';
import '../services/citron_skins.dart';
import 'citron_aura.dart';
import 'citron_particles.dart';

/// Widget d'affichage du citron animé.
///
/// Couche de rendu PURE : à chaque tick, avance le [CitronEngine] puis
/// compose les Transform des 9 SVG depuis le [CitronFrame] publié.
/// Aucun calcul de mouvement ici — tout vit dans le moteur.
class CitronCharacter extends StatefulWidget {
  final CitronAnimationController controller;
  final double scale;

  /// Clé du skin équipé ('' = citron classique). Les accessoires vivent
  /// dans le transform racine : ils suivent toutes les animations.
  final String skin;

  const CitronCharacter({
    super.key,
    required this.controller,
    this.scale = 1.0,
    this.skin = '',
  });

  @override
  State<CitronCharacter> createState() => _CitronCharacterState();
}

class _CitronCharacterState extends State<CitronCharacter>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final CitronParticleSystem _particles = CitronParticleSystem();
  int _frameTick = 0;

  // Pivot de la branche ENTERRÉ dans le corps (sommet du corps ≈ y 105-109,
  // pivot à 112). Le corps est peint par-dessus la plante : avec un ancrage
  // à l'intérieur de sa silhouette, la branche la traverse toujours, quelle
  // que soit la rotation — un détachement est géométriquement impossible.
  // Un pivot posé au point de contact visible (essayé avant) laissait
  // apparaître un liseré de fond dès que la branche tournait.
  static const Offset _leafPivot = Offset(220.0, 112.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    // dt clampé par le moteur (50 ms max) : pas de saut après une pause
    widget.controller.engine.update(dt);
    _particles.update(
      dt.clamp(0.0, CitronEngine.maxDtSec),
      widget.controller.engine.frame.particles,
    );
    _frameTick++;
    setState(() {});
  }

  /// Matrice de couleur combinant la teinte de santé et le flush d'ivresse.
  /// tint 0 + flush 0 = identité (aucun filtre).
  /// tint → désaturation pondérée luminance + assombrissement + biais
  /// verdâtre ; flush → boost du canal rouge.
  static ColorFilter _tintFilter(double tint, double flush) {
    final sat = 1 - 0.75 * tint;
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final inv = 1 - sat;
    final r = inv * lr, g = inv * lg, b = inv * lb;

    final value = 1 - 0.18 * tint; // assombrissement malade
    final rBoost = 1 + 0.15 * flush; // rougeur d'ivresse
    final gBias = 1 + 0.08 * tint; // pâleur verdâtre
    final bCut = 1 - 0.12 * tint - 0.08 * flush;

    return ColorFilter.matrix([
      (r + sat) * value * rBoost, g * value * rBoost, b * value * rBoost, 0, 0,
      r * value * gBias, (g + sat) * value * gBias, b * value * gBias, 0, 0,
      r * value * bCut, g * value * bCut, (b + sat) * value * bCut, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // En arrière-plan : on coupe le ticker (batterie) ; au retour,
    // le clamp du dt absorbe le temps écoulé sans téléportation.
    _ticker.muted = state != AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  Widget _buildPart(
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

  @override
  Widget build(BuildContext context) {
    final CitronFrame f = widget.controller.engine.frame;

    final jambeDMatrix =
        Matrix4.identity()
          ..translateByDouble(0.0, f.legBounceD, 0, 1)
          ..scaleByDouble(f.legSquashD, 1.0, 1, 1)
          ..rotateZ(f.legGravRot);
    final jambeGMatrix =
        Matrix4.identity()
          ..translateByDouble(0.0, f.legBounceG, 0, 1)
          ..scaleByDouble(f.legSquashG, 1.0, 1, 1)
          ..rotateZ(f.legGravRot);

    final brasDMatrix = Matrix4.identity()..rotateZ(f.armDAngle);
    final brasGMatrix = Matrix4.identity()..rotateZ(f.armGAngle);

    // Enfoncement proportionnel à l'inclinaison : plus la branche penche,
    // plus elle s'enfonce dans le fruit. Compense le glissement latéral de
    // la tige hors du creux du sommet quand elle tourne. Coefficient calé
    // visuellement : ~6,6 px à 0.2 rad (curl), ~11,5 px à 0.35 rad (dead).
    final leafSink = f.leafAngle.abs() * 33.0;
    final planteMatrix =
        Matrix4.identity()
          ..translateByDouble(0.0, leafSink, 0, 1)
          ..rotateZ(f.leafAngle);

    final yeuxMatrix =
        Matrix4.identity()
          ..translateByDouble(f.eyeDriftX, f.eyeOffsetY, 0, 1)
          ..scaleByDouble(1.0, f.eyeScaleY, 1, 1);

    final boucheMatrix =
        Matrix4.identity()
          ..rotateZ(f.mouthRotationDeg * math.pi / 180)
          ..scaleByDouble(1.0, f.mouthScaleY.clamp(0.1, 2.0), 1, 1);

    // Compensation de la bouche retournée (rotation 180°) : blend
    // proportionnel au lieu du seuil binaire historique — pas de pop
    // quand le spring de rotation traverse 90°
    final flipBlend = ((f.mouthRotationDeg.abs() - 90) / 90).clamp(0.0, 1.0);
    final mouthOffset = Offset(
      20.0 * flipBlend,
      f.mouthOffsetY + f.mouthPulse + 4.0 * flipBlend,
    );

    // Corps transformé (mouvement) + filtre de teinte santé/ivresse.
    // Le ColorFiltered englobe toutes les parts : le fruit entier pâlit.
    Widget body = Transform(
      alignment: Alignment.center,
      transform:
          Matrix4.identity()
            ..translateByDouble(f.translateX, f.translateY, 0, 1)
            ..rotateZ(f.rotationRad)
            ..scaleByDouble(f.scaleX, f.scaleY, 1, 1),
      child: _buildPartsStack(f, jambeGMatrix, jambeDMatrix, brasGMatrix,
          brasDMatrix, planteMatrix, yeuxMatrix, boucheMatrix, mouthOffset),
    );
    if (f.tint > 0.005 || f.flush > 0.005) {
      body = ColorFiltered(
        colorFilter: _tintFilter(f.tint, f.flush),
        child: body,
      );
    }

    // Variante de couleur du skin (doré, sombre…) — par-dessus la teinte
    // de santé : le citron doré pâlit quand même quand il va mal
    final ColorFilter? skinFilter = skinColorFilter(widget.skin);
    if (skinFilter != null) {
      body = ColorFiltered(colorFilter: skinFilter, child: body);
    }

    // RepaintBoundary : le citron se redessine à 60 fps, cette frontière
    // évite de repeindre tout l'écran à chaque frame.
    // L'aura et les particules vivent HORS du transform racine : la lumière
    // ne tourne pas avec le personnage, les particules volent en espace écran.
    return RepaintBoundary(
      child: Transform.scale(
        scale: widget.scale,
        child: SizedBox(
          width: 420,
          height: 420,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Aura dorée (sous le personnage)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CitronAuraPainter(
                      glow: f.glow,
                      breathValue: f.breathValue,
                    ),
                  ),
                ),
              ),
              body,
              // Particules d'ambiance (au-dessus du personnage)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CitronParticlesPainter(
                      system: _particles,
                      tick: _frameTick,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartsStack(
    CitronFrame f,
    Matrix4 jambeGMatrix,
    Matrix4 jambeDMatrix,
    Matrix4 brasGMatrix,
    Matrix4 brasDMatrix,
    Matrix4 planteMatrix,
    Matrix4 yeuxMatrix,
    Matrix4 boucheMatrix,
    Offset mouthOffset,
  ) {
    return Stack(
              clipBehavior: Clip.none,
              children: [
                _buildPart(
                  'jambe_g',
                  transform: jambeGMatrix,
                  alignment: const FractionalOffset(0.4, 0.7),
                ),
                _buildPart(
                  'jambe_d',
                  transform: jambeDMatrix,
                  alignment: const FractionalOffset(0.6, 0.7),
                ),
                _buildPart(
                  'bras_g',
                  transform: brasGMatrix,
                  alignment: const FractionalOffset(0.3, 0.48),
                ),
                _buildPart(
                  'bras_d',
                  transform: brasDMatrix,
                  alignment: const FractionalOffset(0.7, 0.48),
                ),
                _buildPart(
                  'plante',
                  transform: planteMatrix,
                  alignment: Alignment.topLeft,
                  origin: _leafPivot,
                ),
                _buildPart('corps'),
                _buildPart('joues', partOpacity: f.cheeksOpacity),
                _buildPart(
                  'yeux',
                  transform: yeuxMatrix,
                  alignment: const FractionalOffset(0.5, 0.4),
                ),
                _buildPart(
                  'bouche',
                  transform: boucheMatrix,
                  alignment: const FractionalOffset(0.5, 0.46),
                  offset: mouthOffset,
                ),
                // Accessoire du skin équipé (couche la plus haute)
                ..._buildSkinAccessory(yeuxMatrix),
              ],
    );
  }

  /// Accessoire SVG du skin, ancré sur le corps ou solidaire du regard
  List<Widget> _buildSkinAccessory(Matrix4 yeuxMatrix) {
    final skin = skinByKey(widget.skin);
    final asset = skin?.asset;
    if (skin == null || asset == null || skin.kind != SkinKind.accessory) {
      return const [];
    }

    Widget piece = svg.SvgPicture.asset(
      asset,
      width: 420,
      height: 420,
      fit: BoxFit.contain,
      allowDrawingOutsideViewBox: true,
    );
    if (skin.anchor == SkinAnchor.face) {
      piece = Transform(
        alignment: const FractionalOffset(0.5, 0.4),
        transform: yeuxMatrix,
        child: piece,
      );
    }
    return [Positioned.fill(child: piece)];
  }
}
