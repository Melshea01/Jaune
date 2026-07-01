import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/jaune_haptics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/jaune_design.dart';
import 'confirm_sheet.dart';
import 'draggable_sheet.dart';
import 'leaderboard_sheet.dart';
import 'pressable.dart';

/// Bottom sheet des réglages : rappels, sons, langue, confidentialité,
/// version et suppression des données.
class SettingsSheet {
  static void show(
    BuildContext context, {
    required String username,
    required Future<void> Function(bool enabled) onNotificationsChanged,
    required Future<void> Function(String name) onUsernameChanged,
    required Future<void> Function() onDeleteData,
    required Future<void> Function() onRedoTutorial,
  }) {
    JauneHaptics.selection();
    AudioService.instance.playUiPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _SettingsSheetContent(
            username: username,
            onNotificationsChanged: onNotificationsChanged,
            onUsernameChanged: onUsernameChanged,
            onDeleteData: onDeleteData,
            onRedoTutorial: onRedoTutorial,
          ),
    );
  }
}

class _SettingsSheetContent extends StatefulWidget {
  final String username;
  final Future<void> Function(bool enabled) onNotificationsChanged;
  final Future<void> Function(String name) onUsernameChanged;
  final Future<void> Function() onDeleteData;
  final Future<void> Function() onRedoTutorial;

  const _SettingsSheetContent({
    required this.username,
    required this.onNotificationsChanged,
    required this.onUsernameChanged,
    required this.onDeleteData,
    required this.onRedoTutorial,
  });

  @override
  State<_SettingsSheetContent> createState() => _SettingsSheetContentState();
}

class _SettingsSheetContentState extends State<_SettingsSheetContent> {
  final SettingsService _settings = SettingsService.instance;
  bool _privacyExpanded = false;
  String _version = '';
  late String _username;

  /// Identifiant de la fiche App Store. ⚠️ À REMPLACER par l'ID réel (visible
  /// dans App Store Connect / l'URL de la fiche) avant publication.
  static const String _appStoreId = '000000000';

  /// Ouvre la fiche App Store directement sur le formulaire de note.
  Future<void> _rateApp() async {
    JauneHaptics.selection();
    final uri = Uri.parse(
      'https://apps.apple.com/app/id$_appStoreId?action=write-review',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Rate app launch failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableSheet(
      children: [
                  Center(
                    child: Text(
                      l10n.settingsTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: JauneColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Pseudo ---
                  PressableScale(
                    onTap: () async {
                      final name = await UsernamePrompt.show(
                        context,
                        initial: _username,
                      );
                      if (name == null || name.trim().isEmpty) return;
                      setState(() => _username = name.trim());
                      await widget.onUsernameChanged(name.trim());
                    },
                    child: _SettingsRow(
                      emoji: '✏️',
                      title: l10n.settingsUsername,
                      subtitle: _username.isEmpty
                          ? l10n.settingsUsernameEmpty
                          : _username,
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        size: 18,
                        color: JauneColors.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Rappels ---
                  ValueListenableBuilder<bool>(
                    valueListenable: _settings.notificationsEnabled,
                    builder:
                        (context, enabled, _) => _SettingsRow(
                          emoji: '🔔',
                          title: l10n.settingsNotifications,
                          subtitle: l10n.settingsNotificationsSubtitle,
                          trailing: CupertinoSwitch(
                            value: enabled,
                            activeTrackColor: JauneColors.lemonDeep,
                            onChanged: (value) async {
                              JauneHaptics.selection();
                              await _settings.setNotificationsEnabled(value);
                              await widget.onNotificationsChanged(value);
                            },
                          ),
                        ),
                  ),
                  const SizedBox(height: 14),

                  // --- Sons ---
                  ValueListenableBuilder<bool>(
                    valueListenable: _settings.soundEnabled,
                    builder:
                        (context, enabled, _) => _SettingsRow(
                          emoji: '🔊',
                          title: l10n.settingsSound,
                          subtitle: l10n.settingsSoundSubtitle,
                          trailing: CupertinoSwitch(
                            value: enabled,
                            activeTrackColor: JauneColors.lemonDeep,
                            onChanged: (value) async {
                              JauneHaptics.selection();
                              await _settings.setSoundEnabled(value);
                            },
                          ),
                        ),
                  ),
                  const SizedBox(height: 14),

                  // --- Vibrations ---
                  ValueListenableBuilder<bool>(
                    valueListenable: _settings.hapticsEnabled,
                    builder:
                        (context, enabled, _) => _SettingsRow(
                          emoji: '📳',
                          title: l10n.settingsHaptics,
                          subtitle: l10n.settingsHapticsSubtitle,
                          trailing: CupertinoSwitch(
                            value: enabled,
                            activeTrackColor: JauneColors.lemonDeep,
                            onChanged: (value) async {
                              await _settings.setHapticsEnabled(value);
                              // Retour tactile immédiat quand on (ré)active
                              if (value) JauneHaptics.selection();
                            },
                          ),
                        ),
                  ),
                  const SizedBox(height: 20),

                  // --- Langue ---
                  Text(
                    l10n.settingsLanguage,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: JauneColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<ui.Locale?>(
                    valueListenable: _settings.localeOverride,
                    builder:
                        (context, locale, _) => Row(
                          children: [
                            _LanguageChip(
                              label: l10n.settingsLanguageSystem,
                              selected: locale == null,
                              onTap: () => _settings.setLocaleOverride(null),
                            ),
                            const SizedBox(width: 8),
                            _LanguageChip(
                              // Nom propre de la langue : jamais traduit
                              label: 'Français',
                              selected: locale?.languageCode == 'fr',
                              onTap:
                                  () => _settings.setLocaleOverride(
                                    const ui.Locale('fr'),
                                  ),
                            ),
                            const SizedBox(width: 8),
                            _LanguageChip(
                              label: 'English',
                              selected: locale?.languageCode == 'en',
                              onTap:
                                  () => _settings.setLocaleOverride(
                                    const ui.Locale('en'),
                                  ),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 20),

                  // --- Confidentialité & santé ---
                  PressableScale(
                    onTap:
                        () => setState(
                          () => _privacyExpanded = !_privacyExpanded,
                        ),
                    child: _SettingsRow(
                      emoji: '🔒',
                      title: l10n.settingsPrivacy,
                      trailing: AnimatedRotation(
                        turns: _privacyExpanded ? 0.25 : 0,
                        duration: JauneMotion.quick,
                        child: const Icon(
                          CupertinoIcons.chevron_right,
                          size: 18,
                          color: JauneColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: JauneMotion.quick,
                    sizeCurve: JauneMotion.smooth,
                    crossFadeState:
                        _privacyExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(JauneRadii.card),
                        ),
                        child: Text(
                          l10n.settingsPrivacyBody,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: JauneColors.inkSoft,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Revoir le tutoriel ---
                  PressableScale(
                    onTap: () async {
                      Navigator.of(context).pop();
                      await widget.onRedoTutorial();
                    },
                    child: _SettingsRow(
                      emoji: '🎓',
                      title: l10n.settingsRedoTutorial,
                      subtitle: l10n.settingsRedoTutorialSubtitle,
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        size: 18,
                        color: JauneColors.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Noter Jaune (App Store) ---
                  PressableScale(
                    onTap: _rateApp,
                    child: _SettingsRow(
                      emoji: '⭐',
                      title: l10n.settingsRate,
                      subtitle: l10n.settingsRateSubtitle,
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        size: 18,
                        color: JauneColors.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Version ---
                  _SettingsRow(
                    emoji: '🍋',
                    title: l10n.settingsVersion,
                    trailing: Text(
                      _version,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: JauneColors.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Suppression des données ---
                  PressableScale(
                    onTap: () async {
                      final confirmed = await ConfirmSheet.show(
                        context,
                        title: l10n.deleteDataTitle,
                        message: l10n.deleteDataMessage,
                        confirmLabel: l10n.deleteAction,
                        cancelLabel: l10n.cancel,
                      );
                      if (!confirmed) return;
                      await widget.onDeleteData();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(JauneRadii.card),
                      ),
                      child: Text(
                        l10n.settingsDeleteData,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget trailing;

  const _SettingsRow({
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: JauneColors.lemon.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: JauneColors.ink,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JauneColors.inkSoft,
                  ),
                ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: JauneMotion.quick,
        curve: JauneMotion.smooth,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? JauneColors.lemon : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected
                    ? JauneColors.lemonDeep
                    : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black87 : JauneColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
