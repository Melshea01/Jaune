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
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.12),
        duration: JauneMotion.standard,
        curve: JauneMotion.springy,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: JauneMotion.quick,
          curve: JauneMotion.smooth,
          child: AnimatedScale(
            scale: visible ? 1.0 : 0.82,
            duration: JauneMotion.standard,
            curve: JauneMotion.springy,
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    // Léger dégradé blanc → citron pâle : la bulle « respire ».
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFFFF), Color(0xFFFFFBEA)],
                    ),
                    borderRadius: BorderRadius.circular(JauneRadii.pill),
                    border: Border.all(
                      color: JauneColors.lemon.withValues(alpha: 0.9),
                      width: 1.5,
                    ),
                    boxShadow: [
                      // Halo citronné, chaud et diffus.
                      BoxShadow(
                        color: JauneColors.lemonDeep.withValues(alpha: 0.22),
                        offset: const Offset(0, 4),
                        blurRadius: 20,
                        spreadRadius: -2,
                      ),
                      // Ombre portée nette pour décoller du fond.
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        offset: const Offset(0, 8),
                        blurRadius: 16,
                        spreadRadius: -4,
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
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                // Queue de la bulle, pointée vers le citron.
                CustomPaint(
                  size: const Size(22, 12),
                  painter: _BubbleTailPainter(
                    fill: const Color(0xFFFFFBEA),
                    border: JauneColors.lemon.withValues(alpha: 0.9),
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

class _BubbleTailPainter extends CustomPainter {
  final Color fill;
  final Color border;

  _BubbleTailPainter({required this.fill, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Queue aux flancs légèrement incurvés et à la pointe arrondie :
    // une goutte plutôt qu'un triangle sec.
    final tail =
        Path()
          ..moveTo(0, 0)
          ..cubicTo(w * 0.30, h * 0.15, w * 0.42, h * 0.75, w / 2, h)
          ..cubicTo(w * 0.58, h * 0.75, w * 0.70, h * 0.15, w, 0)
          ..close();

    // Remplissage (dépasse d'1px vers le haut pour masquer le liseré du corps).
    canvas.drawPath(
      Path.from(tail)..addRect(Rect.fromLTWH(0, -1.5, w, 1.5)),
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );

    // Contour, sans la base (elle se fond dans le corps de la bulle).
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(w * 0.30, h * 0.15, w * 0.42, h * 0.75, w / 2, h)
        ..cubicTo(w * 0.58, h * 0.75, w * 0.70, h * 0.15, w, 0),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}
