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
import 'pressable.dart';
import 'share_card.dart';

/// Écran de progression repensé en **parcours** : un chemin vertical de
/// nœuds (un par niveau) que le citron grimpe. Chaque chapitre est une section
/// colorée ; les nœuds-jalons portent un déblocable (anticipation). En-tête
/// épinglé (niveau, stats, XP toujours visibles), corps défilant centré sur le
/// niveau courant. Plein écran : un parcours respire mieux qu'une feuille.
class LevelScreen {
  static void open(
    BuildContext context,
    CharacterService service, {
    Map<String, int>? dailyMap,
  }) {
    HapticFeedback.selectionClick();
    AudioService.instance.playUiPop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LevelScreen(service: service, dailyMap: dailyMap),
      ),
    );
  }
}

// --- Description d'un chapitre du parcours -----------------------------------

class _Chapter {
  final int index; // 1..4
  final int from;
  final int? to; // null = ouvert (Légende)
  const _Chapter(this.index, this.from, this.to);
}

const List<_Chapter> _kChapters = [
  _Chapter(1, 1, 5),
  _Chapter(2, 6, 15),
  _Chapter(3, 16, 30),
  _Chapter(4, 31, null),
];

enum _NodeState { acquired, current, locked }

class _LevelScreen extends StatefulWidget {
  final CharacterService service;
  final Map<String, int>? dailyMap;

  const _LevelScreen({required this.service, this.dailyMap});

  @override
  State<_LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<_LevelScreen> {
  final GlobalKey _currentNodeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Ouvre le parcours centré sur la position actuelle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentNodeKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: JauneMotion.standard,
          curve: JauneMotion.smooth,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = widget.service;
    final level = service.level;
    final streak = service.soberStreakDays;

    final quests = service.dailyQuests();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Barre de titre épinglée ---
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: JauneColors.ink),
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                  ),
                  Text(
                    l10n.levelScreenTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: JauneColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            // --- En-tête épinglé : niveau, stats, XP toujours visibles ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
              child: _Header(service: service),
            ),
            Container(height: 1, color: Colors.grey.shade100),

            // --- Corps défilant : objectif, quêtes, parcours ---
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.dailyMap != null) ...[
                      _WeeklyGoalCard(
                        service: service,
                        dailyMap: widget.dailyMap!,
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (streak > 0) ...[
                      _StreakCard(service: service),
                      const SizedBox(height: 14),
                    ],

                    _SectionTitle(l10n.dailyQuestsTitle),
                    const SizedBox(height: 12),
                    ...quests.map((q) => _QuestRow(status: q)),

                    const SizedBox(height: 20),
                    _SectionTitle(l10n.levelJourneyTitle),
                    const SizedBox(height: 14),
                    ..._buildJourney(context, level),

                    const SizedBox(height: 22),
                    PressableScale(
                      semanticLabel: l10n.badgeGalleryViewAll,
                      onTap: () => BadgeGallerySheet.show(context, service),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le parcours de haut (niveaux verrouillés à venir) en bas
  /// (niveau 1). Les chapitres sont rendus du plus élevé au plus bas.
  List<Widget> _buildJourney(BuildContext context, int level) {
    final l10n = AppLocalizations.of(context);
    final service = widget.service;
    final progress = service.levelProgress;
    final unlockByLevel = {for (final u in kLevelUnlocks) u.level: u};

    // Fenêtre autour du niveau courant (style Duolingo : on ne déroule pas les
    // 30 niveaux d'un coup). Un peu d'historique en bas, l'horizon proche en
    // haut — la collection complète reste accessible via la galerie.
    final int windowFrom = math.max(1, level - 4);
    final int windowTo = level + 6;

    final List<Widget> widgets = [];

    for (final chapter in _kChapters.reversed) {
      final int rawTop = chapter.to ?? windowTo;
      final int chapterTop = math.min(rawTop, windowTo);
      final int chapterBottom = math.max(chapter.from, windowFrom);
      if (chapterTop < chapterBottom) continue; // hors fenêtre

      // Bannière du chapitre.
      widgets.add(
        _ChapterBanner(
          index: chapter.index,
          name: l10n_helpers.rankTitle(l10n, chapter.from),
          color: JauneColors.chapterColor(chapter.from),
        ),
      );

      for (int lvl = chapterTop; lvl >= chapterBottom; lvl--) {
        final _NodeState state = lvl < level
            ? _NodeState.acquired
            : (lvl == level ? _NodeState.current : _NodeState.locked);
        final unlock = unlockByLevel[lvl];
        final bool isChapterTop = lvl == chapterTop;
        final bool isChapterBottom = lvl == chapterBottom;

        widgets.add(
          _LevelNode(
            key: lvl == level ? _currentNodeKey : null,
            level: lvl,
            state: state,
            unlock: unlock,
            color: JauneColors.chapterColor(lvl),
            currentLevel: level,
            progress: progress,
            xp: service.profile.xp,
            xpToNext: service.xpToNextLevel,
            equippedSkin: service.profile.equippedSkin,
            hasLineAbove: !isChapterTop,
            hasLineBelow: !isChapterBottom,
            onTapBadge: (state == _NodeState.acquired &&
                    unlock != null &&
                    unlock.type == UnlockType.badge)
                ? () => ShareCard.shareStreak(
                      context,
                      days: service.soberStreakDays,
                      skin: service.profile.equippedSkin,
                    )
                : null,
          ),
        );
      }
    }

    return widgets;
  }
}

// --- En-tête : niveau, rang, chapitre, stats multi-axes ----------------------

class _Header extends StatelessWidget {
  final CharacterService service;
  const _Header({required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final level = service.level;
    final phase = service.levelPhase;
    final xp = service.profile.xp;
    final xpToNext = service.xpToNextLevel;
    final progress = service.levelProgress;
    final color = JauneColors.chapterColor(level);
    final rankTitle = l10n_helpers.rankTitle(l10n, level);

    final phaseLevels = switch (phase) {
      'discovery' => 5,
      'engagement' => 10,
      _ => 20,
    };
    final levelInPhase = (level - 1) % phaseLevels + 1;
    final phaseLabel = l10n_helpers.phaseLabel(l10n, phase);

    final unlocks = service.acquiredUnlocks;
    final badges =
        unlocks.where((u) => u.type == UnlockType.badge).length;
    final skins =
        unlocks.where((u) => u.type == UnlockType.citronState).length;

    return Row(
      children: [
        _ProgressRing(progress: progress, color: color, level: level),
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
                label: '$phaseLabel  ·  $levelInPhase/$phaseLevels',
                color: color,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatPill(
                    emoji: '🔥',
                    value: '${service.soberStreakDays}',
                    label: l10n.levelStatStreak,
                  ),
                  _StatPill(
                    emoji: '🛡️',
                    value: '${service.streakShields}',
                    label: l10n.levelStatShields,
                  ),
                  _StatPill(
                    emoji: '🏅',
                    value: '$badges',
                    label: l10n.levelStatBadges,
                  ),
                  _StatPill(
                    emoji: '🎨',
                    value: '$skins',
                    label: l10n.levelStatSkins,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.xpProgress(xp, xpToNext),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: JauneColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatPill({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: JauneColors.ink,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: JauneColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Carte streak (loss aversion) --------------------------------------------

class _StreakCard extends StatelessWidget {
  final CharacterService service;
  const _StreakCard({required this.service});

  static String _streakSubtitle(AppLocalizations l10n, int streak) {
    for (final target in MilestoneScheduler.streakMilestones) {
      if (streak < target) {
        return l10n.streakCountdown(target - streak, target);
      }
    }
    return l10n.streakKeepGoing;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final streak = service.soberStreakDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JauneColors.flameLight.withValues(alpha: 0.15),
            JauneColors.flame.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(color: JauneColors.flame.withValues(alpha: 0.3)),
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
                if (service.streakShields > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.streakShieldProtected,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: JauneColors.skyDeep,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (MilestoneScheduler.streakMilestones.contains(streak)) ...[
            const SizedBox(width: 8),
            PressableScale(
              semanticLabel: l10n.shareAction,
              onTap: () => ShareCard.shareStreak(
                context,
                days: streak,
                skin: service.profile.equippedSkin,
              ),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: JauneColors.flame.withValues(alpha: 0.15),
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
    );
  }
}

// --- Objectif hebdomadaire (anneau) ------------------------------------------

class _WeeklyGoalCard extends StatelessWidget {
  final CharacterService service;
  final Map<String, int> dailyMap;

  const _WeeklyGoalCard({required this.service, required this.dailyMap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goal = service.weeklyGoal(dailyMap);
    const color = JauneColors.skyDeep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(46, 46),
                  painter: _RingPainter(progress: goal.progress, color: color),
                ),
                Text(
                  '${goal.soberDays}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.weeklyGoalTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: JauneColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.weeklyGoalProgress(goal.soberDays, goal.target),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JauneColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (goal.progress >= 1.0)
            const Text('✅', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}

// --- Quête du jour -----------------------------------------------------------

class _QuestRow extends StatelessWidget {
  final QuestStatus status;
  const _QuestRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = status.completed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: done
              ? JauneColors.lemon.withValues(alpha: 0.14)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(JauneRadii.card),
          border: Border.all(
            color: done
                ? JauneColors.lemonDeep.withValues(alpha: 0.4)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: done ? JauneColors.lemonDeep : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n_helpers.questTitle(l10n, status.quest),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: done ? JauneColors.ink : JauneColors.inkSoft,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: JauneColors.inkSoft,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: done
                    ? JauneColors.lemonDeep.withValues(alpha: 0.18)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.xpReward(status.quest.xpReward),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: done ? JauneColors.lemonDeep : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Bannière de chapitre ----------------------------------------------------

class _ChapterBanner extends StatelessWidget {
  final int index;
  final String name;
  final Color color;

  const _ChapterBanner({
    required this.index,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.chapterTitle(index),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: JauneColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.35), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Nœud de niveau ----------------------------------------------------------

class _LevelNode extends StatelessWidget {
  final int level;
  final _NodeState state;
  final LevelUnlock? unlock;
  final Color color;
  final int currentLevel;
  final double progress;
  final int xp;
  final int xpToNext;
  final String equippedSkin;
  final bool hasLineAbove;
  final bool hasLineBelow;
  final VoidCallback? onTapBadge;

  const _LevelNode({
    super.key,
    required this.level,
    required this.state,
    required this.unlock,
    required this.color,
    required this.currentLevel,
    required this.progress,
    required this.xp,
    required this.xpToNext,
    required this.equippedSkin,
    required this.hasLineAbove,
    required this.hasLineBelow,
    this.onTapBadge,
  });

  bool get _isMilestone => unlock != null;

  double get _rowHeight {
    if (state == _NodeState.current) return 96;
    return _isMilestone ? 82 : 60;
  }

  @override
  Widget build(BuildContext context) {
    // Un demi-segment est « rempli » s'il relie deux nœuds acquis.
    final bool topFilled = level < currentLevel; // relie level+1
    final bool bottomFilled = level <= currentLevel; // relie level-1

    final Widget row = SizedBox(
      height: _rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: _rowHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(64, _rowHeight),
                  painter: _SpinePainter(
                    color: color,
                    topFilled: hasLineAbove && topFilled,
                    bottomFilled: hasLineBelow && bottomFilled,
                    topExists: hasLineAbove,
                    bottomExists: hasLineBelow,
                  ),
                ),
                _circle(context),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _sideContent(context)),
        ],
      ),
    );

    if (onTapBadge != null) {
      return PressableScale(
        semanticLabel: 'badge',
        onTap: onTapBadge!,
        child: row,
      );
    }
    return row;
  }

  Widget _circle(BuildContext context) {
    if (state == _NodeState.current) {
      // Le citron EST ici : posé au centre de l'anneau de progression.
      // (Pas de numéro : il doublonnerait l'en-tête épinglé.)
      return SizedBox(
        width: 62,
        height: 62,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(62, 62),
              painter: _RingPainter(progress: progress, color: color),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('🍋', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      );
    }

    final bool acquired = state == _NodeState.acquired;
    final double size = _isMilestone ? 50 : (acquired ? 26 : 22);

    if (_isMilestone) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: acquired
              ? color.withValues(alpha: 0.16)
              : Colors.grey.shade100,
          border: Border.all(
            color: acquired ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: acquired
            ? Text(
                _unlockIcon(unlock!.type),
                style: const TextStyle(fontSize: 22),
              )
            : Icon(Icons.lock, size: 18, color: Colors.grey.shade400),
      );
    }

    // Nœud simple.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: acquired ? color : Colors.grey.shade300,
      ),
      alignment: Alignment.center,
      child: acquired
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Text(
              '$level',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
              ),
            ),
    );
  }

  Widget _sideContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state == _NodeState.current) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.levelYouAreHere,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.xpProgress(xp, xpToNext),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: JauneColors.inkSoft,
            ),
          ),
        ],
      );
    }

    if (!_isMilestone) return const SizedBox.shrink();

    final bool acquired = state == _NodeState.acquired;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n_helpers.unlockTitle(l10n, unlock!),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: acquired ? JauneColors.ink : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          acquired
              ? l10n_helpers.unlockDescription(l10n, unlock!)
              : l10n.levelLockedShort(unlock!.level),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: acquired ? JauneColors.inkSoft : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  static String _unlockIcon(UnlockType type) => switch (type) {
        UnlockType.citronState => '🎨',
        UnlockType.feature => '⭐',
        UnlockType.badge => '🏅',
        UnlockType.message => '💬',
      };
}

/// Peint les deux demi-segments verticaux du chemin (au-dessus / au-dessous du
/// noeud). Rempli = couleur du chapitre, sinon gris.
class _SpinePainter extends CustomPainter {
  final Color color;
  final bool topFilled;
  final bool bottomFilled;
  final bool topExists;
  final bool bottomExists;

  _SpinePainter({
    required this.color,
    required this.topFilled,
    required this.bottomFilled,
    required this.topExists,
    required this.bottomExists,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double w = 4;
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    Paint p(bool filled) => Paint()
      ..color = filled ? color : Colors.grey.shade200
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;

    if (topExists) {
      canvas.drawLine(Offset(cx, 0), Offset(cx, cy), p(topFilled));
    }
    if (bottomExists) {
      canvas.drawLine(Offset(cx, cy), Offset(cx, size.height), p(bottomFilled));
    }
  }

  @override
  bool shouldRepaint(_SpinePainter old) =>
      old.color != color ||
      old.topFilled != topFilled ||
      old.bottomFilled != bottomFilled ||
      old.topExists != topExists ||
      old.bottomExists != bottomExists;
}

// --- Widgets partagés --------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
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

/// Anneau de progression XP avec le niveau au centre. S'anime de 0 à la valeur
/// courante à l'ouverture.
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
    final strokeWidth = size.width < 70 ? 6.0 : 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final background = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, background);

    if (progress > 0) {
      final foreground = Paint()
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
