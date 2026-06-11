import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// Badge flamme 🔥 affichant le streak de jours sobres consécutifs.
/// Pulse doucement quand le streak est actif pour attirer l'œil.
class StreakBadge extends StatefulWidget {
  final int streakDays;
  final VoidCallback? onTap;

  const StreakBadge({super.key, required this.streakDays, this.onTap});

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _previousStreak = 0;

  @override
  void initState() {
    super.initState();
    _previousStreak = widget.streakDays;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakDays > _previousStreak) {
      // Le streak a augmenté : petit burst d'animation
      _pulseController
        ..duration = const Duration(milliseconds: 400)
        ..repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        _pulseController
          ..duration = const Duration(milliseconds: 1600)
          ..repeat(reverse: true);
      });
    }
    _previousStreak = widget.streakDays;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Dégradé du badge selon le palier : orange → rouge profond (7 j) →
  /// or (30 j, couleur de la marque)
  static List<Color> _tierColors(int days) {
    if (days >= 30) return const [Color(0xFFF7D83F), Color(0xFFFF6B35)];
    if (days >= 7) return const [Color(0xFFFF6B35), Color(0xFFE63946)];
    return const [Color(0xFFFF9D42), Color(0xFFFF6B35)];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streakDays <= 0) return const SizedBox.shrink();

    return Semantics(
      button: widget.onTap != null,
      label: AppLocalizations.of(context).a11yStreakBadge(widget.streakDays),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + _pulseController.value * 0.08;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            // Paliers : la flamme s'intensifie à 7 jours, devient dorée à 30
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _tierColors(widget.streakDays),
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _tierColors(
                  widget.streakDays,
                ).last.withValues(alpha: 0.4),
                offset: const Offset(0, 3),
                blurRadius: widget.streakDays >= 7 ? 14 : 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔥',
                style: TextStyle(
                  fontSize: widget.streakDays >= 30
                      ? 20
                      : widget.streakDays >= 7
                      ? 18
                      : 16,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${widget.streakDays}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                AppLocalizations.of(context).dayUnit(widget.streakDays),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
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
