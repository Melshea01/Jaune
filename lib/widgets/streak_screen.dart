import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/audio_service.dart';
import '../services/character_service.dart';
import '../services/milestone_scheduler.dart';
import '../theme/jaune_design.dart';
import 'pressable.dart';
import 'share_card.dart';

/// Page plein écran dédiée à la **série de jours sobres** (séparée de la page
/// XP/Progression) : grande flamme animée, jours sobres, boucliers, paliers
/// (3/7/30/100) et partage.
class StreakScreen {
  static void open(BuildContext context, CharacterService service) {
    HapticFeedback.selectionClick();
    AudioService.instance.playUiPop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _StreakScreen(service: service)),
    );
  }
}

class _StreakScreen extends StatefulWidget {
  final CharacterService service;
  const _StreakScreen({required this.service});

  @override
  State<_StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<_StreakScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static String _subtitle(AppLocalizations l10n, int streak) {
    for (final target in MilestoneScheduler.streakMilestones) {
      if (streak < target) return l10n.streakCountdown(target - streak, target);
    }
    return l10n.streakKeepGoing;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = widget.service;
    final streak = service.soberStreakDays;
    final shields = service.streakShields;
    const flame = JauneColors.flame;
    final reduce = MediaQuery.of(context).disableAnimations;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // En-tête teinté (remonte derrière la barre d'état)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    flame.withValues(alpha: 0.18),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back,
                              color: JauneColors.ink),
                          tooltip:
                              MaterialLocalizations.of(context).backButtonTooltip,
                        ),
                        Text(
                          l10n.streakScreenTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: JauneColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Grande flamme qui pulse
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final t = reduce
                            ? 0.0
                            : Curves.easeInOut.transform(_pulse.value);
                        return Transform.scale(scale: 1 + 0.08 * t, child: child);
                      },
                      child: const Text('🔥', style: TextStyle(fontSize: 96)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.soberStreakInARow(streak),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: JauneColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle(l10n, streak),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: JauneColors.inkSoft,
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Boucliers
                    _ShieldsCard(shields: shields),

                    const SizedBox(height: 24),
                    // Paliers
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.streakMilestonesTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: JauneColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final m in MilestoneScheduler.streakMilestones)
                          _MilestoneChip(target: m, reached: streak >= m),
                      ],
                    ),

                    const SizedBox(height: 28),
                    // Partage
                    PressableScale(
                      semanticLabel: l10n.shareAction,
                      onTap: () => ShareCard.shareStreak(
                        context,
                        days: streak,
                        skin: service.profile.equippedSkin,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              JauneColors.flameLight,
                              JauneColors.flame,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(JauneRadii.card),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.ios_share,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              l10n.shareAction,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShieldsCard extends StatelessWidget {
  final int shields;
  const _ShieldsCard({required this.shields});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: JauneColors.skyDeep.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border:
            Border.all(color: JauneColors.skyDeep.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.streakShieldsAvailable(shields),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: JauneColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.streakShieldProtected,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JauneColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  final int target;
  final bool reached;
  const _MilestoneChip({required this.target, required this.reached});

  @override
  Widget build(BuildContext context) {
    final color = reached ? JauneColors.flame : Colors.grey.shade300;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached
                ? JauneColors.flame.withValues(alpha: 0.14)
                : Colors.grey.shade100,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: reached
              ? const Text('🔥', style: TextStyle(fontSize: 22))
              : Icon(Icons.lock, size: 18, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 6),
        Text(
          '$target',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: reached ? JauneColors.ink : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
