import 'package:flutter/material.dart';
import 'dart:ui';

import '../l10n/gen/app_localizations.dart';
import '../theme/jaune_design.dart';

class HealthBar extends StatelessWidget {
  final double percent;
  final int level;
  final VoidCallback? onTap;

  const HealthBar({
    super.key,
    required this.percent,
    required this.level,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: AppLocalizations.of(
        context,
      ).a11yHealthBar((percent * 100).round(), level),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade300,
                  Colors.amber.shade200,
                ], // Dégradé plus doux
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(
                    alpha: 0.3,
                  ), // Ombre plus subtile
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.black.withValues(
                    alpha: 0.5,
                  ), // Couleur de l'icône adoucie
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Niveau $level',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withValues(
                      alpha: 0.6,
                    ), // Couleur du texte adoucie
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: percent),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, animatedPercent, _) {
            return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((0.18 * 255).round()),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            FractionallySizedBox(
              widthFactor: animatedPercent.clamp(0.0, 1.0),
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  // 5 paliers alignés sur les émotions du citron : la barre
                  // change de couleur quand le personnage change d'humeur
                  gradient: LinearGradient(
                    colors: JauneColors.healthGradient(animatedPercent),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.10 * 255).round()),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withAlpha((0.28 * 255).round()),
                        Colors.white.withAlpha((0.10 * 255).round()),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.35 * 255).round()),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withAlpha((0.02 * 255).round()),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.6],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                '${(animatedPercent * 100).round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.transparent,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha((0.32 * 255).round()),
                      offset: const Offset(0, 1),
                      blurRadius: 6,
                    ),
                    Shadow(
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                      offset: const Offset(0, -1),
                      blurRadius: 0,
                    ),
                  ],
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
            );
          },
        ),
      ],
    );
  }
}
