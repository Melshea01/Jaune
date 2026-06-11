import 'package:flutter/material.dart';

import '../theme/jaune_design.dart';

/// Bulle de dialogue du citron — sa personnalité rendue visible.
/// Apparaît avec un rebond au-dessus du personnage, queue pointée vers lui,
/// puis disparaît d'elle-même (gérée par le parent via [visible]).
class CitronSpeechBubble extends StatelessWidget {
  final String message;
  final bool visible;

  const CitronSpeechBubble({
    super.key,
    required this.message,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: JauneMotion.quick,
        curve: JauneMotion.smooth,
        child: AnimatedScale(
          scale: visible ? 1.0 : 0.85,
          duration: JauneMotion.standard,
          curve: JauneMotion.springy,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(JauneRadii.card),
                  border: Border.all(
                    color: JauneColors.lemon.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: JauneColors.ink,
                    height: 1.35,
                  ),
                ),
              ),
              // Queue de la bulle, pointée vers le citron
              CustomPaint(
                size: const Size(18, 9),
                painter: _BubbleTailPainter(
                  fill: Colors.white,
                  border: JauneColors.lemon.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color fill;
  final Color border;

  _BubbleTailPainter({required this.fill, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}
