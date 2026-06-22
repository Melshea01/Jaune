import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/citron_animation_controller.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/jaune_design.dart';
import 'citron_character.dart';

/// Cartes de partage des grands moments (palier de streak, level-up) :
/// rendues hors écran en 1080×1350 (format feed) puis partagées en PNG.
/// Le citron y porte son skin équipé — chaque carte est personnelle.
abstract class ShareCard {
  static Future<void> shareStreak(
    BuildContext context, {
    required int days,
    String skin = '',
  }) {
    final l10n = AppLocalizations.of(context);
    return _share(
      context,
      headline: '$days 🔥',
      caption: l10n.soberStreakInARow(days),
      skin: skin,
    );
  }

  /// Carte de partage des statistiques : série en gros + sous-titre récap.
  static Future<void> shareStats(
    BuildContext context, {
    required int streakDays,
    required int soberDays,
    required String caption,
    String skin = '',
  }) {
    return _share(
      context,
      headline: '$streakDays 🔥',
      caption: caption,
      skin: skin,
    );
  }

  static Future<void> shareLevel(
    BuildContext context, {
    required int level,
    String skin = '',
  }) {
    final l10n = AppLocalizations.of(context);
    return _share(
      context,
      headline: l10n.levelUpTitle(level),
      caption: l10n.appTitle,
      skin: skin,
    );
  }

  /// Rend la carte dans un Overlay hors écran (même technique éprouvée que
  /// la composition BeJaune), capture le RepaintBoundary et partage le PNG.
  static Future<void> _share(
    BuildContext context, {
    required String headline,
    required String caption,
    required String skin,
  }) async {
    final overlay = Overlay.of(context);
    final boundaryKey = GlobalKey();
    final citronController = CitronAnimationController()
      ..updateHealth(100)
      ..idleMood = 'happy';

    final entry = OverlayEntry(
      builder:
          (_) => Positioned(
            left: -10000,
            top: -10000,
            child: Material(
              color: Colors.transparent,
              child: RepaintBoundary(
                key: boundaryKey,
                child: _ShareCardContent(
                  headline: headline,
                  caption: caption,
                  skin: skin,
                  controller: citronController,
                ),
              ),
            ),
          ),
    );

    overlay.insert(entry);
    // Deux frames : le ticker du citron doit publier une pose avant capture
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? bytes = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/jaune_card_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes.buffer.asUint8List());

      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      debugPrint('Share card error: $e');
    } finally {
      entry.remove();
      citronController.dispose();
    }
  }
}

class _ShareCardContent extends StatelessWidget {
  final String headline;
  final String caption;
  final String skin;
  final CitronAnimationController controller;

  const _ShareCardContent({
    required this.headline,
    required this.caption,
    required this.skin,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 540,
      height: 675,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [JauneColors.sky, JauneColors.skyLight, Colors.white],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 44),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 3),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: JauneColors.ink.withValues(alpha: 0.75),
            ),
          ),
          Expanded(
            child: Center(
              child: CitronCharacter(
                controller: controller,
                skin: skin,
                scale: 0.9,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              children: [
                const Text(
                  'JAUNE',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: JauneColors.ink,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '🍋 jaune.app',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: JauneColors.inkSoft.withValues(alpha: 0.9),
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
