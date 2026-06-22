import 'package:flutter/material.dart';

import '../theme/jaune_design.dart';

/// Contenu de bottom sheet défilable et « tirable pour fermer ».
///
/// Mutualise le comportement de toutes les feuilles longues : un
/// [DraggableScrollableSheet] dont le contrôleur de défilement pilote aussi le
/// glissement de la feuille. Résultat : tirer vers le bas (contenu déjà en
/// haut) referme la feuille, comme on s'y attend — au lieu de rester coincé
/// parce que le scroll interne avalait le geste.
///
/// Le contenu fourni via [children] est posé sous une poignée, dans un
/// [SingleChildScrollView]. À utiliser dans `showModalBottomSheet(
/// isScrollControlled: true, backgroundColor: Colors.transparent, ...)`.
class DraggableSheet extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final Color? backgroundColor;
  final Gradient? gradient;

  const DraggableSheet({
    super.key,
    required this.children,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.initialChildSize = 0.85,
    this.minChildSize = 0.5,
    this.maxChildSize = 0.92,
    this.backgroundColor = Colors.white,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final pad =
        padding ??
        EdgeInsets.only(
          left: 24,
          right: 24,
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: gradient == null ? backgroundColor : null,
            gradient: gradient,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(JauneRadii.sheet),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: pad,
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: MainAxisSize.min,
              children: [const _SheetHandle(), ...children],
            ),
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
