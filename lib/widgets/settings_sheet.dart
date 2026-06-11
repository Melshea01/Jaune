import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/jaune_design.dart';
import 'confirm_sheet.dart';
import 'pressable.dart';

/// Bottom sheet des réglages : rappels, sons, langue, confidentialité,
/// version et suppression des données.
class SettingsSheet {
  static void show(
    BuildContext context, {
    required Future<void> Function(bool enabled) onNotificationsChanged,
    required Future<void> Function() onDeleteData,
  }) {
    HapticFeedback.selectionClick();
    AudioService.instance.playUiPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _SettingsSheetContent(
            onNotificationsChanged: onNotificationsChanged,
            onDeleteData: onDeleteData,
          ),
    );
  }
}

class _SettingsSheetContent extends StatefulWidget {
  final Future<void> Function(bool enabled) onNotificationsChanged;
  final Future<void> Function() onDeleteData;

  const _SettingsSheetContent({
    required this.onNotificationsChanged,
    required this.onDeleteData,
  });

  @override
  State<_SettingsSheetContent> createState() => _SettingsSheetContentState();
}

class _SettingsSheetContentState extends State<_SettingsSheetContent> {
  final SettingsService _settings = SettingsService.instance;
  bool _privacyExpanded = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(JauneRadii.sheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          // Poignée de drag
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              HapticFeedback.selectionClick();
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
                              HapticFeedback.selectionClick();
                              await _settings.setSoundEnabled(value);
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
              ),
            ),
          ),
        ],
      ),
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
