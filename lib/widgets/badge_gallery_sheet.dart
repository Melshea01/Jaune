import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    HapticFeedback.selectionClick();
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

  static String _unlockIcon(UnlockType type) => switch (type) {
    UnlockType.citronState => '🎨',
    UnlockType.feature => '⭐',
    UnlockType.badge => '🏅',
    UnlockType.message => '💬',
  };

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
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: kLevelUnlocks.length,
              itemBuilder: (context, index) {
                final unlock = kLevelUnlocks[index];
                final bool acquired = unlock.level <= level;
                final bool isSkin = skinByKey(unlock.key) != null;
                final bool equipped =
                    isSkin && service.profile.equippedSkin == unlock.key;

                final tile = _BadgeTile(
                  icon: isSkin ? '🧢' : _unlockIcon(unlock.type),
                  title: l10n_helpers.unlockTitle(l10n, unlock),
                  acquired: acquired,
                  lockedLabel: l10n.badgeLockedLevel(unlock.level),
                  equipLabel:
                      !isSkin || !acquired
                          ? null
                          : equipped
                          ? l10n.badgeEquipped
                          : l10n.badgeEquip,
                  equipped: equipped,
                );

                if (!isSkin || !acquired) return tile;
                return PressableScale(
                  haptic: false,
                  semanticLabel:
                      '${l10n_helpers.unlockTitle(l10n, unlock)} — '
                      '${equipped ? l10n.badgeEquipped : l10n.badgeEquip}',
                  onTap: () => _toggleSkin(unlock.key),
                  child: tile,
                );
              },
            ),
      ],
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
