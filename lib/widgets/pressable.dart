import 'package:flutter/material.dart';

import '../theme/jaune_design.dart';
import '../utils/jaune_haptics.dart';

/// Feedback de pression unifié : réduit légèrement l'échelle au toucher
/// avec un retour haptique. À utiliser pour tout élément tappable.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;
  final HitTestBehavior behavior;

  /// Libellé VoiceOver/TalkBack : l'élément est annoncé comme un bouton
  final String? semanticLabel;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Widget interactive = GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap:
          widget.onTap == null
              ? null
              : () {
                if (widget.haptic) JauneHaptics.selection();
                widget.onTap!();
              },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: JauneMotion.tap,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );

    if (widget.semanticLabel == null) return interactive;
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: interactive,
    );
  }
}
