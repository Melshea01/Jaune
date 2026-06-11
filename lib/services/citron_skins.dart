import 'package:flutter/material.dart';

/// Registre des skins du citron. La clé d'un skin == la clé de son
/// déblocage dans kLevelUnlocks : le système d'unlocks existant gère
/// l'acquisition, ce registre ne décrit que le rendu.
enum SkinKind {
  /// SVG overlay (canvas 420×420, même viewBox que les couches du citron) —
  /// rendu dans le transform racine : suit toutes les animations
  accessory,

  /// Matrice de couleur appliquée au fruit entier
  colorVariant,
}

/// Point d'ancrage d'un accessoire : statique sur le corps, ou solidaire
/// du regard (suit la transform des yeux)
enum SkinAnchor { body, face }

class CitronSkin {
  final String key;
  final SkinKind kind;
  final String? asset;
  final SkinAnchor anchor;
  final List<double>? colorMatrix;

  const CitronSkin({
    required this.key,
    required this.kind,
    this.asset,
    this.anchor = SkinAnchor.body,
    this.colorMatrix,
  });
}

const List<CitronSkin> kCitronSkins = [
  CitronSkin(
    key: 'skin_sunglasses',
    kind: SkinKind.accessory,
    asset: 'assets/skins/skin_sunglasses.svg',
    anchor: SkinAnchor.face,
  ),
  CitronSkin(
    key: 'skin_party_hat',
    kind: SkinKind.accessory,
    asset: 'assets/skins/skin_party_hat.svg',
  ),
  CitronSkin(
    key: 'skin_crown',
    kind: SkinKind.accessory,
    asset: 'assets/skins/skin_crown.svg',
  ),
  CitronSkin(
    key: 'skin_gold',
    kind: SkinKind.colorVariant,
    // Dorure : rouge/vert boostés, bleu coupé, léger offset chaud
    colorMatrix: [
      1.08, 0.10, 0, 0, 12, //
      0.04, 1.02, 0, 0, 4, //
      0, 0, 0.72, 0, 0, //
      0, 0, 0, 1, 0,
    ],
  ),
  CitronSkin(
    key: 'skin_dark',
    kind: SkinKind.colorVariant,
    // Mode nuit : assombri, biais bleuté
    colorMatrix: [
      0.62, 0, 0, 0, 0, //
      0, 0.64, 0, 0, 6, //
      0, 0, 0.80, 0, 26, //
      0, 0, 0, 1, 0,
    ],
  ),
];

CitronSkin? skinByKey(String key) {
  for (final skin in kCitronSkins) {
    if (skin.key == key) return skin;
  }
  return null;
}

ColorFilter? skinColorFilter(String key) {
  final skin = skinByKey(key);
  final matrix = skin?.colorMatrix;
  return matrix == null ? null : ColorFilter.matrix(matrix);
}
