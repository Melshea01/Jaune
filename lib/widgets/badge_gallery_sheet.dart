import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/l10n_helpers.dart' as l10n_helpers;
import '../services/audio_service.dart';
import '../services/character_service.dart';
import '../services/citron_skins.dart';
import '../theme/jaune_design.dart';
import '../utils/jaune_haptics.dart';
import 'draggable_sheet.dart';
import 'pressable.dart';

/// Galerie de tous les déblocables : les acquis en couleur, les verrouillés
/// en gris avec leur niveau — la collection donne envie de continuer.
class BadgeGallerySheet {
  static void show(BuildContext context, CharacterService service) {
    JauneHaptics.selection();
    AudioService.instance.playUiPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BadgeGalleryContent(service: service),
    );
  }
}

class _BadgeGalleryContent extends StatefulWidget {
  final CharacterService service;

  const _BadgeGalleryContent({required this.service});

  @override
  State<_BadgeGalleryContent> createState() => _BadgeGalleryContentState();
}

class _BadgeGalleryContentState extends State<_BadgeGalleryContent> {
  CharacterService get service => widget.service;

  /// Équipe le skin (ou le retire s'il est déjà porté)
  Future<void> _toggleSkin(String key) async {
    JauneHaptics.tick();
    final bool wearing = service.profile.equippedSkin == key;
    await service.equipSkin(wearing ? '' : key);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool fr = Localizations.localeOf(context).languageCode == 'fr';
    final int level = service.level;

    return DraggableSheet(
      children: [
        Center(
          child: Text(
            l10n.badgeGalleryTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: JauneColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Collection rangée par monde (façon collection d'arènes)
        for (final chapter in kChapters) ...[
          _ChapterHeader(
            label: '${chapter.emoji}  ${chapter.name(fr)}',
            sub: l10n.chapterTitle(chapter.id),
            color: chapter.color,
            acquired: level >= chapter.from,
          ),
          const SizedBox(height: 12),
          _worldGrid(context, l10n, fr, level, chapter),
          const SizedBox(height: 22),
        ],
      ],
    );
  }

  Widget _worldGrid(
    BuildContext context,
    AppLocalizations l10n,
    bool fr,
    int level,
    JourneyChapter chapter,
  ) {
    final items = kLevelUnlocks
        .where((u) => u.level >= chapter.from && u.level <= chapter.to)
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final unlock = items[index];
        final bool acquired = unlock.level <= level;
        final bool isSkin = skinByKey(unlock.key) != null;
        final bool equipped =
            isSkin && service.profile.equippedSkin == unlock.key;

        final tile = _BadgeTile(
          icon: unlock.icon,
          title: l10n_helpers.unlockTitle(unlock, fr),
          acquired: acquired,
          lockedLabel: l10n.badgeLockedLevel(unlock.level),
          equipLabel: !isSkin || !acquired
              ? null
              : equipped
                  ? l10n.badgeEquipped
                  : l10n.badgeEquip,
          equipped: equipped,
        );

        if (!isSkin || !acquired) return tile;
        return PressableScale(
          haptic: false,
          semanticLabel: '${l10n_helpers.unlockTitle(unlock, fr)} — '
              '${equipped ? l10n.badgeEquipped : l10n.badgeEquip}',
          onTap: () => _toggleSkin(unlock.key),
          child: tile,
        );
      },
    );
  }
}

/// En-tête de section « monde » dans la collection.
class _ChapterHeader extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final bool acquired;

  const _ChapterHeader({
    required this.label,
    required this.sub,
    required this.color,
    required this.acquired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: acquired ? 0.20 : 0.10),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: JauneColors.ink,
                  ),
                ),
              ],
            ),
          ),
          if (!acquired)
            Icon(Icons.lock, size: 18, color: color.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String icon;
  final String title;
  final bool acquired;
  final String lockedLabel;
  final String? equipLabel;
  final bool equipped;

  const _BadgeTile({
    required this.icon,
    required this.title,
    required this.acquired,
    required this.lockedLabel,
    this.equipLabel,
    this.equipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            acquired
                ? JauneColors.lemon.withValues(alpha: equipped ? 0.30 : 0.14)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(
          color:
              equipped
                  ? JauneColors.lemonDeep
                  : acquired
                  ? JauneColors.lemonDeep.withValues(alpha: 0.5)
                  : Colors.grey.shade300,
          width: equipped ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Les verrouillés sont grisés : l'émoji passe en niveaux de gris
          acquired
              ? Text(icon, style: const TextStyle(fontSize: 30))
              : Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.25,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0, //
                        0.2126, 0.7152, 0.0722, 0, 0, //
                        0.2126, 0.7152, 0.0722, 0, 0, //
                        0, 0, 0, 1, 0,
                      ]),
                      child: Text(icon, style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                  const Icon(
                    Icons.lock,
                    size: 16,
                    color: JauneColors.inkSoft,
                  ),
                ],
              ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: acquired ? JauneColors.ink : JauneColors.inkSoft,
            ),
          ),
          if (!acquired) ...[
            const SizedBox(height: 2),
            Text(
              lockedLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ] else if (equipLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              equipLabel!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color:
                    equipped
                        ? JauneColors.ink
                        : JauneColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
