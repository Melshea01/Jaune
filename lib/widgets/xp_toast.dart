import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/l10n_helpers.dart';
import '../services/character_service.dart';

/// Gestionnaire de toasts XP empilables, affichés via l'Overlay.
/// Chaque toast glisse depuis le haut, flotte, puis disparaît en fondu.
class XpToastManager {
  static final List<_XpToastEntry> _active = [];
  static int _stackIndex = 0;

  /// Affiche un toast "+X XP — raison". Les toasts simultanés s'empilent.
  static void show(OverlayState overlay, XpEvent event) {
    HapticFeedback.lightImpact();

    final int slot = _stackIndex++;
    late final _XpToastEntry toastEntry;

    final entry = OverlayEntry(
      builder:
          (context) => _XpToastWidget(
            event: event,
            slot: slot,
            onDismissed: () {
              toastEntry.entry.remove();
              _active.remove(toastEntry);
              if (_active.isEmpty) _stackIndex = 0;
            },
          ),
    );

    toastEntry = _XpToastEntry(entry: entry, slot: slot);
    _active.add(toastEntry);
    overlay.insert(entry);
  }
}

class _XpToastEntry {
  final OverlayEntry entry;
  final int slot;
  _XpToastEntry({required this.entry, required this.slot});
}

class _XpToastWidget extends StatefulWidget {
  final XpEvent event;
  final int slot;
  final VoidCallback onDismissed;

  const _XpToastWidget({
    required this.event,
    required this.slot,
    required this.onDismissed,
  });

  @override
  State<_XpToastWidget> createState() => _XpToastWidgetState();
}

class _XpToastWidgetState extends State<_XpToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideIn;
  late final Animation<double> _fadeOut;
  late final Animation<double> _scale;
  Timer? _dismissTimer;

  static const Duration _visibleDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 350),
    );

    _slideIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    _fadeOut = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Décale légèrement l'apparition des toasts empilés
    Future.delayed(Duration(milliseconds: widget.slot.clamp(0, 5) * 250), () {
      if (!mounted) return;
      _controller.forward();
      _dismissTimer = Timer(_visibleDuration, _dismiss);
    });
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topOffset =
        MediaQuery.of(context).padding.top + 12 + (widget.slot.clamp(0, 5) * 58);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: topOffset + (1 - _slideIn.value) * -40,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Opacity(
              opacity: _fadeOut.value.clamp(0.0, 1.0),
              child: Transform.scale(scale: _scale.value, child: child),
            ),
          ),
        );
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF7D83F), Color(0xFFF6B73F)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withAlpha((0.5 * 255).round()),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF7D83F).withAlpha((0.45 * 255).round()),
                offset: const Offset(0, 4),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).xpToastAmount(widget.event.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  xpReasonLabel(AppLocalizations.of(context), widget.event),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withAlpha((0.55 * 255).round()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
