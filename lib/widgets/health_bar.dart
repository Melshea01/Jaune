import 'package:flutter/material.dart';
import 'dart:ui';

class HealthBar extends StatelessWidget {
  final double percent;
  final int level;

  const HealthBar({super.key, required this.percent, required this.level});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Niveau $level',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 20,
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
              widthFactor: percent,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors:
                        percent > 0.75
                            ? [Color(0xFF43e97b), Color(0xFF38f9d7)]
                            : (percent > 0.25
                                ? [Color(0xFFf7971e), Color(0xFFffd200)]
                                : [Color(0xFFf85757), Color(0xFFf857a6)]),
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
                  height: 16,
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
                '${(percent * 100).round()}%',
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
        ),
      ],
    );
  }
}
