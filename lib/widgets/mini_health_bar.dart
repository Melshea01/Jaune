import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/jaune_design.dart';

/// Barre de vie miniature réutilisable (lignes du classement, etc.).
///
/// Partage la source de vérité couleur ([JauneColors.healthGradient], 5
/// paliers) et la courbe d'animation de la barre principale, mais en version
/// compacte et sans header de niveau. Le pourcentage textuel est optionnel et
/// rendu à droite (cf. [HealthBar] pour la grande barre de la home).
class MiniHealthBar extends StatelessWidget {
  /// Santé bornée 0..1.
  final double percent;

  /// Hauteur de la barre remplie.
  final double height;

  /// Affiche « 87 % » à droite de la barre.
  final bool showLabel;

  /// Anime la transition vers [percent] (désactivable pour les listes).
  final bool animate;

  const MiniHealthBar({
    super.key,
    required this.percent,
    this.height = 14,
    this.showLabel = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final bar = Expanded(child: _buildBar(context));
    if (!showLabel) return _buildBar(context);
    return Row(
      children: [
        bar,
        const SizedBox(width: 8),
        SizedBox(
          width: 38,
          child: Text(
            '${(percent.clamp(0.0, 1.0) * 100).round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: JauneColors.ink.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: animate ? 0 : percent, end: percent),
      duration: animate ? JauneMotion.emphasized : Duration.zero,
      curve: JauneMotion.smooth,
      builder: (context, value, _) {
        final v = value.clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Piste de fond
            Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            // Remplissage dégradé
            FractionallySizedBox(
              widthFactor: v == 0 ? 0.001 : v,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  gradient: LinearGradient(
                    colors: JauneColors.healthGradient(v),
                  ),
                ),
              ),
            ),
            // Gloss : léger reflet en haut, fidèle à la grande barre
            FractionallySizedBox(
              widthFactor: v == 0 ? 0.001 : v,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.30),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
