import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/audio_service.dart';
import '../theme/jaune_design.dart';

/// Bottom sheet "Comment ça marche ?" — remplace l'ancien CupertinoAlertDialog
/// par une présentation illustrée en trois étapes.
class InfoSheet {
  static void show(BuildContext context) {
    HapticFeedback.selectionClick();
    AudioService.instance.playUiPop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InfoSheetContent(),
    );
  }
}

class _InfoSheetContent extends StatelessWidget {
  const _InfoSheetContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(JauneRadii.sheet),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée de drag
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).infoTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: JauneColors.ink,
            ),
          ),
          const SizedBox(height: 24),
          _InfoStep(
            emoji: '🍻',
            title: AppLocalizations.of(context).infoStep1Title,
            text: AppLocalizations.of(context).infoStep1Text,
          ),
          const SizedBox(height: 18),
          _InfoStep(
            emoji: '🍋',
            title: AppLocalizations.of(context).infoStep2Title,
            text: AppLocalizations.of(context).infoStep2Text,
          ),
          const SizedBox(height: 18),
          _InfoStep(
            emoji: '🔥',
            title: AppLocalizations.of(context).infoStep3Title,
            text: AppLocalizations.of(context).infoStep3Text,
          ),
        ],
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final String emoji;
  final String title;
  final String text;

  const _InfoStep({
    required this.emoji,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: JauneColors.lemon.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 14),
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
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: JauneColors.inkSoft,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
