import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/l10n_helpers.dart' as l10n_helpers;
import '../services/audio_service.dart';
import '../services/character_service.dart';
import '../services/milestone_scheduler.dart';
import '../theme/jaune_design.dart';
import 'badge_gallery_sheet.dart';
import 'draggable_sheet.dart';
import 'pressable.dart';
import 'share_card.dart';

/// Bottom sheet de progression : niveau, rang, phase, XP, streak,
/// déblocables acquis et prochains défis.
/// Remplace l'ancien CupertinoAlertDialog surchargé.
class LevelSheet {
  static void show(BuildContext context, CharacterService service) {
    HapticFeedback.selectionClick();
    AudioService.instance.playUiPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LevelSheetContent(service: service),
    );
  }
}

class _LevelSheetContent extends StatelessWidget {
  final CharacterService service;

  const _LevelSheetContent({required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final level = service.level;
    final phase = service.levelPhase;
    final xp = service.profile.xp;
    final xpToNext = service.xpToNextLevel;
    final progress = service.levelProgress;
    final unlocks = service.acquiredUnlocks;
    final streak = service.soberStreakDays;

    final phaseLevels = switch (phase) {
      'discovery' => 5,
      'engagement' => 10,
      _ => 20,
    };
    final levelInPhase = (level - 1) % phaseLevels + 1;

    final phaseLabel = l10n_helpers.phaseLabel(l10n, phase);
    final phaseColor = JauneColors.phaseColor(phase);

    final rankTitle = l10n_helpers.rankTitle(l10n, level);

    final currentLevelUnlocks = unlocks.where((u) => u.level == level).toList();
    final nextUnlocks =
        kLevelUnlocks.where((u) => u.level > level).take(3).toList();
    final nextUnlock = nextUnlocks.isNotEmpty ? nextUnlocks.first : null;
    final xpToNextKeyUnlock =
        nextUnlock != null ? ((nextUnlock.level - level) * xpToNext) - xp : 0;

    return DraggableSheet(
      children: [
                    // --- En-tête : ring + rang ---
                    Row(
                      children: [
                        _ProgressRing(
                          progress: progress,
                          color: phaseColor,
                          level: level,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rankTitle,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: JauneColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _PhaseChip(
                                label:
                                    '$phaseLabel  ·  $levelInPhase/$phaseLevels',
                                color: phaseColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.xpProgress(xp, xpToNext),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: JauneColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // --- Streak ---
                    if (streak > 0) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              JauneColors.flameLight.withValues(alpha: 0.15),
                              JauneColors.flame.withValues(alpha: 0.10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(JauneRadii.card),
                          border: Border.all(
                            color: JauneColors.flame.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.soberStreakInARow(streak),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: JauneColors.ink,
                                    ),
                                  ),
                                  Text(
                                    _streakSubtitle(l10n, streak),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: JauneColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Aux paliers, le streak se partage en carte brandée
                            if (MilestoneScheduler.streakMilestones.contains(
                              streak,
                            )) ...[
                              const SizedBox(width: 8),
                              PressableScale(
                                semanticLabel: l10n.shareAction,
                                onTap:
                                    () => ShareCard.shareStreak(
                                      context,
                                      days: streak,
                                      skin: service.profile.equippedSkin,
                                    ),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: JauneColors.flame.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.ios_share,
                                    size: 18,
                                    color: JauneColors.flame,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // --- Déblocables de ce niveau ---
                    if (currentLevelUnlocks.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.unlockedAtThisLevel),
                      const SizedBox(height: 10),
                      ...currentLevelUnlocks.map(
                        (u) => _UnlockRow(unlock: u, accent: phaseColor),
                      ),
                    ],

                    // --- Prochain défi (mis en avant) ---
                    if (nextUnlock != null) ...[
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.nextChallenge),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: phaseColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(JauneRadii.card),
                          border: Border.all(color: phaseColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _unlockIcon(nextUnlock.type),
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n_helpers.unlockTitle(l10n, nextUnlock),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: JauneColors.ink,
                                    ),
                                  ),
                                  Text(
                                    l10n.levelWithDescription(
                                      nextUnlock.level,
                                      l10n_helpers.unlockDescription(
                                        l10n,
                                        nextUnlock,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: JauneColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: phaseColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                l10n.xpReward(xpToNextKeyUnlock),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // --- Toute la collection ---
                    const SizedBox(height: 20),
                    PressableScale(
                      semanticLabel: l10n.badgeGalleryViewAll,
                      onTap: () => BadgeGallerySheet.show(context, service),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: JauneColors.lemon.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(JauneRadii.card),
                          border: Border.all(
                            color: JauneColors.lemonDeep.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🏅', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              l10n.badgeGalleryViewAll,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: JauneColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Autres déblocables à venir ---
                    if (nextUnlocks.length > 1) ...[
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.andThen),
                      const SizedBox(height: 10),
                      ...nextUnlocks
                          .skip(1)
                          .map(
                            (u) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${u.level}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _unlockIcon(u.type),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n_helpers.unlockTitle(l10n, u),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: JauneColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
      ],
    );
  }

  static String _unlockIcon(UnlockType type) => switch (type) {
    UnlockType.citronState => '🎨',
    UnlockType.feature => '⭐',
    UnlockType.badge => '🏅',
    UnlockType.message => '💬',
  };

  /// Sous-titre de la carte streak : compte à rebours vers le prochain
  /// palier {3, 7, 30, 100}, sinon l'encouragement générique
  static String _streakSubtitle(AppLocalizations l10n, int streak) {
    for (final target in MilestoneScheduler.streakMilestones) {
      if (streak < target) {
        return l10n.streakCountdown(target - streak, target);
      }
    }
    return l10n.streakKeepGoing;
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: JauneColors.ink,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PhaseChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _UnlockRow extends StatelessWidget {
  final LevelUnlock unlock;
  final Color accent;

  const _UnlockRow({required this.unlock, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              _LevelSheetContent._unlockIcon(unlock.type),
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n_helpers.unlockTitle(
                    AppLocalizations.of(context),
                    unlock,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: JauneColors.ink,
                  ),
                ),
                Text(
                  l10n_helpers.unlockDescription(
                    AppLocalizations.of(context),
                    unlock,
                  ),
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

/// Anneau de progression XP avec le niveau au centre.
/// S'anime de 0 à la valeur courante à l'ouverture du sheet.
class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final int level;

  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: JauneMotion.smooth,
      builder: (context, value, _) {
        return SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _RingPainter(progress: value, color: color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$level',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: JauneColors.ink,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).levelRingLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final background =
        Paint()
          ..color = Colors.grey.shade200
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, background);

    if (progress > 0) {
      final foreground =
          Paint()
            ..shader = SweepGradient(
              startAngle: -math.pi / 2,
              endAngle: 3 * math.pi / 2,
              colors: [color.withValues(alpha: 0.7), color],
              transform: const GradientRotation(-math.pi / 2),
            ).createShader(Rect.fromCircle(center: center, radius: radius))
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        foreground,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
