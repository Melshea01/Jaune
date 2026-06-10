import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/jaune_design.dart';

/// Bottom sheet "Comment ça marche ?" — remplace l'ancien CupertinoAlertDialog
/// par une présentation illustrée en trois étapes.
class InfoSheet {
  static void show(BuildContext context) {
    HapticFeedback.selectionClick();
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
          const Text(
            'Comment ça marche ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: JauneColors.ink,
            ),
          ),
          const SizedBox(height: 24),
          const _InfoStep(
            emoji: '🍻',
            title: 'Loggue tes verres',
            text:
                'Chaque fois que tu bois, appuie sur le bouton « 🍻 ». '
                '1 verre standard = 1 clic (ex : une pinte = 2 clics).',
          ),
          const SizedBox(height: 18),
          const _InfoStep(
            emoji: '🍋',
            title: 'Ton citron vit avec toi',
            text:
                'Ton citron a des points de vie qui montent ou descendent '
                'selon ta consommation. Prends soin de lui !',
          ),
          const SizedBox(height: 18),
          const _InfoStep(
            emoji: '🔥',
            title: 'Gagne de l\'XP',
            text:
                'Journées sobres, semaines équilibrées et régularité '
                'te font monter de niveau et débloquer des surprises.',
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
