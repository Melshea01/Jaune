import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;

import '../services/citron_skins.dart';
import '../theme/jaune_design.dart';

/// Avatar citron **statique et léger** pour les listes (classement, demandes).
///
/// Contrairement à [CitronCharacter] (9 SVG animés + ticker + moteur), on ne
/// compose ici que les couches essentielles (corps, yeux, bouche) sans aucune
/// animation, pour préserver les performances de scroll. Les skins sont
/// honorés : filtre couleur pour les variantes, overlay pour les accessoires.
class CitronAvatar extends StatelessWidget {
  final double size;
  final String skin;

  /// Santé bornée 0..1. Plus elle est basse, plus le citron pâlit (même
  /// formule de teinte que [CitronCharacter], en statique). 1.0 = aucun filtre.
  final double healthPercent;

  const CitronAvatar({
    super.key,
    this.size = 44,
    this.skin = '',
    this.healthPercent = 1.0,
  });

  /// Teinte « santé » statique : reprise allégée du `_tintFilter` du
  /// personnage animé (sans la rougeur d'ivresse). `tint` 0 = sain, 1 = malade.
  static ColorFilter _healthTint(double tint) {
    final sat = 1 - 0.75 * tint;
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final inv = 1 - sat;
    final r = inv * lr, g = inv * lg, b = inv * lb;

    final value = 1 - 0.18 * tint; // assombrissement malade
    final gBias = 1 + 0.08 * tint; // pâleur verdâtre
    final bCut = 1 - 0.12 * tint;

    return ColorFilter.matrix([
      (r + sat) * value, g * value, b * value, 0, 0,
      r * value * gBias, (g + sat) * value * gBias, b * value * gBias, 0, 0,
      r * value * bCut, g * value * bCut, (b + sat) * value * bCut, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colorFilter = skinColorFilter(skin);
    final accessory = skinByKey(skin);
    // Le citron ne commence à pâlir que sous ~80 % de PV, puis de plus en
    // plus jusqu'à 0 — pour qu'un ami en pleine forme reste bien jaune.
    final tint = ((0.8 - healthPercent.clamp(0.0, 1.0)) / 0.8).clamp(0.0, 1.0);

    Widget part(String name) => svg.SvgPicture.asset(
      'assets/citron_$name.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    Widget citron = Stack(
      alignment: Alignment.center,
      children: [
        // Membres et tige derrière le corps : chaque part partage le même
        // viewBox 420×420, donc l'empilement centré les positionne correctement.
        part('jambe_g'),
        part('jambe_d'),
        part('bras_g'),
        part('bras_d'),
        part('plante'),
        part('corps'),
        part('joues'),
        part('yeux'),
        part('bouche'),
        // Accessoire (lunettes, chapeau, couronne) à l'échelle du viewBox.
        if (accessory != null &&
            accessory.kind == SkinKind.accessory &&
            accessory.asset != null)
          svg.SvgPicture.asset(
            accessory.asset!,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
      ],
    );

    // Teinte santé d'abord (le fruit pâlit), puis variante de couleur du skin
    // par-dessus — comme dans le personnage animé.
    if (tint > 0.005) {
      citron = ColorFiltered(colorFilter: _healthTint(tint), child: citron);
    }
    if (colorFilter != null) {
      citron = ColorFiltered(colorFilter: colorFilter, child: citron);
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: JauneColors.skyLight.withValues(alpha: 0.35),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: citron,
        ),
      ),
    );
  }
}
