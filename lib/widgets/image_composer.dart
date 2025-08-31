// Service pour composer l'image finale et gérer le partage
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ImageComposer {
  final AppinioSocialShare _appinioSocialShare = AppinioSocialShare();

  /// Compose l'image finale avec les photos et les éléments UI
  Future<String?> composeAndShare({
    required XFile? rearPhoto,
    required XFile? frontPhoto,
    required String avatarAsset,
    required String message,
    required double healthPercent,
  }) async {
    if (rearPhoto == null && frontPhoto == null) return null;

    try {
      debugPrint('[compose] rearPath=${rearPhoto?.path} frontPath=${frontPhoto?.path}');

      // Charge les images
      final rearBytes = rearPhoto != null ? await File(rearPhoto.path).readAsBytes() : null;
      final frontBytes = frontPhoto != null ? await File(frontPhoto.path).readAsBytes() : null;

      final rearImg = rearBytes != null ? await _decodeImageFromList(rearBytes) : null;
      final frontImg = frontBytes != null ? await _decodeImageFromList(frontBytes) : null;

      final avatarData = await rootBundle.load(avatarAsset);
      final avatarImg = await _decodeImageFromList(avatarData.buffer.asUint8List());

      // Dimensions de l'image finale
      final int width = (rearImg ?? frontImg)!.width;
      final int height = (rearImg ?? frontImg)!.height;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Dessine l'image de fond
      await _drawBackground(canvas, rearImg, frontImg, width, height);

      // Dessine le selfie en cercle
      if (frontImg != null && rearImg != null) {
        await _drawSelfieCircle(canvas, frontImg, width, height);
      }

      // Dessine l'avatar
      await _drawAvatar(canvas, avatarImg, width, height);

      // Dessine la barre de PV
      await _drawHealthBar(canvas, width, height, healthPercent);

      // Dessine la carte de message
      await _drawMessageCard(canvas, width, height, message);

      // Finalise l'image
      final picture = recorder.endRecording();
      final ui.Image finalImg = await picture.toImage(width, height);
      final ByteData? pngBytes = await finalImg.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes == null) throw Exception('Failed to encode image');

      // Sauvegarde le fichier final
      final tempDir = await getTemporaryDirectory();
      final outPath = '${tempDir.path}/jaune_share_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(pngBytes.buffer.asUint8List());

      // Partage sur Instagram
      await _shareToInstagram(outPath, width, height);

      return outPath;
    } catch (e, st) {
      debugPrint('Compose error: $e\n$st');
      return null;
    }
  }

  /// Décode une image à partir de bytes
  Future<ui.Image> _decodeImageFromList(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => completer.complete(img));
    return completer.future;
  }

  /// Dessine l'image de fond
  Future<void> _drawBackground(Canvas canvas, ui.Image? rearImg, ui.Image? frontImg, int width, int height) async {
    final paint = Paint();

    if (rearImg != null) {
      canvas.drawImage(rearImg, Offset.zero, paint);
    } else if (frontImg != null) {
      // Utilise l'image avant comme fond si pas d'arrière
      final src = Rect.fromLTWH(0, 0, frontImg.width.toDouble(), frontImg.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
      canvas.drawImageRect(frontImg, src, dst, paint);
    }
  }

  /// Dessine le selfie en cercle arrondi
  Future<void> _drawSelfieCircle(Canvas canvas, ui.Image frontImg, int width, int height) async {
    const double targetAspect = 9.0 / 12.0;
    final double srcW = frontImg.width.toDouble();
    final double srcH = frontImg.height.toDouble();

    // Calcule le crop centré
    double srcCropW, srcCropH;
    if (srcW / srcH >= targetAspect) {
      srcCropH = srcH;
      srcCropW = srcCropH * targetAspect;
    } else {
      srcCropW = srcW;
      srcCropH = srcCropW / targetAspect;
    }

    final double srcLeft = (srcW - srcCropW) / 2.0;
    final double srcTop = (srcH - srcCropH) / 2.0;
    final Rect srcRect = Rect.fromLTWH(srcLeft, srcTop, srcCropW, srcCropH);

    // Position et taille du selfie
    final double maxSelfieW = width * 0.40;
    final double selfieW = math.min(maxSelfieW, srcCropW);
    final double selfieH = selfieW / targetAspect;
    final double selfieLeft = width - selfieW - 24;
    final double selfieTop = 24;
    final Rect dstRect = Rect.fromLTWH(selfieLeft, selfieTop, selfieW, selfieH);

    // Dessine avec coins arrondis et bordure
    canvas.save();
    final RRect clipR = RRect.fromRectAndRadius(
      dstRect,
      Radius.circular(selfieW * 0.12),
    );
    canvas.clipRRect(clipR);
    canvas.drawImageRect(frontImg, srcRect, dstRect, Paint());

    // Bordure noire
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withAlpha((0.95 * 255).round())
      ..strokeWidth = 6.0
      ..isAntiAlias = true;
    canvas.drawRRect(clipR, borderPaint);
    canvas.restore();
  }

  /// Dessine l'avatar en bas à gauche
  Future<void> _drawAvatar(Canvas canvas, ui.Image avatarImg, int width, int height) async {
    final double avatarSize = width * 0.20;
    final double avatarLeft = 16;
    final double avatarTop = height - avatarSize - 32 - 8 - 16;
    final Rect avatarDst = Rect.fromLTWH(avatarLeft, avatarTop, avatarSize, avatarSize);

    canvas.save();
    final RRect avatarR = RRect.fromRectAndRadius(
      avatarDst,
      Radius.circular(avatarSize * 0.18),
    );
    canvas.clipRRect(avatarR);
    canvas.drawImageRect(
      avatarImg,
      Rect.fromLTWH(0, 0, avatarImg.width.toDouble(), avatarImg.height.toDouble()),
      avatarDst,
      Paint(),
    );
    canvas.restore();
  }

  /// Dessine la barre de santé/PV
  Future<void> _drawHealthBar(Canvas canvas, int width, int height, double healthPercent) async {
    final double avatarSize = width * 0.20;
    final double barWidth = avatarSize;
    final double barHeight = 16.0;
    final double barLeft = 16;
    final double barTop = height - barHeight - 32.0;

    // Ombre pour effet 3D
    final RRect shadowR = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
      Radius.circular(14),
    );
    canvas.drawShadow(
      Path()..addRRect(shadowR),
      Colors.black.withAlpha((0.18 * 255).round()),
      6.0,
      false,
    );

    // Fond givré
    final RRect bgR = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
      Radius.circular(14),
    );
    final Paint bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(barLeft, barTop),
        Offset(barLeft, barTop + barHeight),
        [
          Colors.white.withAlpha((0.28 * 255).round()),
          Colors.white.withAlpha((0.10 * 255).round()),
        ],
      );
    canvas.drawRRect(bgR, bgPaint);

    // Bordure
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withAlpha((0.35 * 255).round());
    canvas.drawRRect(bgR, borderPaint);

    // Remplissage selon le pourcentage
    final double pct = healthPercent.clamp(0.0, 1.0);
    final double filledW = barWidth * pct;

    if (filledW > 0.5) {
      final RRect fillR = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, filledW, barHeight),
        Radius.circular(14),
      );

      // Couleurs selon le pourcentage
      List<Color> fillColors;
      if (pct > 0.6) {
        fillColors = [const Color(0xFF43e97b), const Color(0xFF38f9d7)];
      } else if (pct > 0.3) {
        fillColors = [const Color(0xFFf7971e), const Color(0xFFffd200)];
      } else {
        fillColors = [const Color(0xFFf85757), const Color(0xFFf857a6)];
      }

      final Paint fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(barLeft, barTop),
          Offset(barLeft + barWidth, barTop),
          fillColors,
        );
      canvas.drawRRect(fillR, fillPaint);

      // Halo subtil
      final Paint halo = Paint()
        ..color = Colors.black.withAlpha((0.06 * 255).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawRRect(fillR.shift(const Offset(0, 1.0)), halo);
    }

    // Surbrillance du haut
    final Paint highlight = Paint()
      ..shader = ui.Gradient.linear(
        Offset(barLeft, barTop),
        Offset(barLeft, barTop + barHeight),
        [
          Colors.white.withAlpha((0.02 * 255).round()),
          Colors.transparent,
        ],
      );
    canvas.drawRRect(bgR, highlight);

    // Texte du pourcentage
    final String pctLabel = '${(pct * 100).round()}%';
    final TextPainter pctTp = TextPainter(
      text: TextSpan(
        text: pctLabel,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Colors.transparent,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha((0.32 * 255).round()),
              offset: const Offset(0, 1),
              blurRadius: 6,
            ),
            Shadow(
              color: Colors.white.withAlpha((0.6 * 255).round()),
              offset: const Offset(0, -1),
              blurRadius: 0,
            ),
          ],
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    pctTp.layout(minWidth: 0, maxWidth: barWidth);
    final double textX = barLeft + (barWidth - pctTp.width) / 2.0;
    final double textY = barTop + (barHeight - pctTp.height) / 2.0;
    pctTp.paint(canvas, Offset(textX, textY));
  }

  /// Dessine la carte de message
  Future<void> _drawMessageCard(Canvas canvas, int width, int height, String message) async {
    final double avatarSize = width * 0.20;
    final double cardW = width - avatarSize - 32 - 8;
    final double cardH = avatarSize + 16 + 8 - 36;
    final double cardLeft = avatarSize + 16 + 8;
    final double cardTop = height - 32.0 - cardH;

    final Rect cardOuterRect = Rect.fromLTWH(cardLeft, cardTop, cardW, cardH);
    final RRect cardOuter = RRect.fromRectAndCorners(
      cardOuterRect,
      topRight: const Radius.circular(16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    // Ombre portée
    canvas.drawShadow(
      Path()..addRRect(cardOuter),
      Colors.black.withAlpha((0.12 * 255).round()),
      12.0,
      false,
    );

    // Fond extérieur jaune
    final Paint cardOuterPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cardOuterRect.left, cardOuterRect.top),
        Offset(cardOuterRect.left, cardOuterRect.bottom),
        [const Color(0xFFF7D83F), const Color(0xFFEFB192)],
      );
    canvas.drawRRect(cardOuter, cardOuterPaint);

    // Panneau intérieur blanc
    final Rect cardInnerRect = Rect.fromLTWH(
      cardOuterRect.left + 8,
      cardOuterRect.top + 8,
      cardW - 16,
      cardH - 16,
    );
    final RRect cardInner = RRect.fromRectAndCorners(
      cardInnerRect,
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(32),
      bottomLeft: const Radius.circular(32),
      bottomRight: const Radius.circular(16),
    );

    // Ombres multiples pour l'effet 3D
    _drawCardShadows(canvas, cardInner);

    // Fond blanc du panneau intérieur
    final Paint cardInnerPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cardInnerRect.left, cardInnerRect.top),
        Offset(cardInnerRect.left, cardInnerRect.bottom),
        [
          Colors.white.withAlpha((0.98 * 255).round()),
          Colors.grey.shade50,
        ],
      );
    canvas.drawRRect(cardInner, cardInnerPaint);

    // Header "Jaune"
    _drawHeader(canvas, cardLeft, cardOuterRect.top);

    // Texte du message
    _drawMessageText(canvas, cardInnerRect, message);
  }

  /// Dessine les ombres de la carte
  void _drawCardShadows(Canvas canvas, RRect cardInner) {
    // Grande ombre
    final Paint innerShadowLarge = Paint()
      ..color = Colors.black.withAlpha((0.12 * 255).round())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18.0 / 2.0);
    canvas.drawRRect(cardInner.shift(const Offset(0, 8)), innerShadowLarge);

    // Petite ombre
    final Paint innerShadowSmall = Paint()
      ..color = Colors.black.withAlpha((0.06 * 255).round())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 / 2.0);
    canvas.drawRRect(cardInner.shift(const Offset(0, 4)), innerShadowSmall);

    // Surbrillance blanche du haut
    final Rect highlightRect = cardInner.outerRect.deflate(4.0);
    final RRect highlightR = RRect.fromRectAndCorners(
      highlightRect,
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(28),
      bottomLeft: const Radius.circular(28),
      bottomRight: const Radius.circular(12),
    );
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withAlpha((0.90 * 255).round())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 / 2.0);
    canvas.drawRRect(highlightR.shift(const Offset(0, -2)), highlightPaint);
  }

  /// Dessine le header "Jaune"
  void _drawHeader(Canvas canvas, double cardLeft, double cardTop) {
    final double headerH = 36.0;
    final double headerW = 88.0;
    final double headerLeft = cardLeft;
    final double headerTop = cardTop - headerH + 8.0;

    final RRect headerR = RRect.fromRectAndRadius(
      Rect.fromLTWH(headerLeft, headerTop, headerW, headerH),
      const Radius.circular(8),
    );
    final Paint headerPaint = Paint()..color = const Color(0xFFF7D83F);
    canvas.drawRRect(headerR, headerPaint);

    // Texte "Jaune"
    final TextPainter headerTp = TextPainter(
      text: TextSpan(
        text: 'Jaune',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 24,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    headerTp.layout(minWidth: 0, maxWidth: headerW - 32);
    final double hx = headerLeft + (headerW - headerTp.width) / 2.0;
    final double hy = headerTop + (headerH - headerTp.height) / 2.0;
    headerTp.paint(canvas, Offset(hx, hy));
  }

  /// Dessine le texte du message
  void _drawMessageText(Canvas canvas, Rect cardInnerRect, String message) {
    final double msgPadLeft = 16.0;
    final double msgPadRight = 8.0;
    final double msgPadTop = 12.0;
    final double msgMaxW = cardInnerRect.width - msgPadLeft - msgPadRight;

    final TextPainter msgTp = TextPainter(
      text: TextSpan(
        text: message,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontStyle: FontStyle.italic,
          height: 1.35,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: 4,
      ellipsis: '...',
    );
    msgTp.layout(maxWidth: msgMaxW);
    final double msgX = cardInnerRect.left + msgPadLeft;
    final double msgY = cardInnerRect.top + msgPadTop;
    msgTp.paint(canvas, Offset(msgX, msgY));
  }

  /// Partage sur Instagram pour debugguer
  Future<void> _shareToInstagram(String imagePath, int width, int height) async {
    try {
      if (Platform.isAndroid) {
        // Essaie plusieurs méthodes pour Android
        await _shareToInstagramAndroid(imagePath, width, height);
      } else if (Platform.isIOS) {
        await _shareToInstagramIOS(imagePath, width, height);
      }
    } catch (e) {
      debugPrint('Instagram share failed: $e');
    }
  }

  Future<void> _shareToInstagramAndroid(String imagePath, int width, int height) async {
    try {
      // Charger l'image depuis assets
      final byteData = await rootBundle.load('assets/avatar.png');

      // Sauvegarder l'image dans le cache temporaire
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/avatar.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Partager sur Instagram Stories
      await AppinioSocialShare().android.shareToInstagramStory(
        'com.instagram.android',
        backgroundImage: file.path,
      );

      debugPrint('Instagram share attempted with avatar.png');
    } catch (e, stack) {
      debugPrint('Failed to share avatar.png: $e\n$stack');
    }
  }

  Future<void> _shareToInstagramIOS(String imagePath, int width, int height) async {
    final tempDir = await getTemporaryDirectory();

      final transparentPath = await _createTransparentSticker(tempDir, width, height);

      if (transparentPath != null) {
        await _appinioSocialShare.iOS.shareToInstagramStory(
          'instagram-stories://share',
          stickerImage: transparentPath,
          backgroundImage: imagePath,
        );
      }
  }

  /// Crée un sticker transparent pour Instagram Stories
  Future<String?> _createTransparentSticker(Directory tempDir, int width, int height) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paintClear = Paint()..color = const Color(0x00000000);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        paintClear,
      );

      final picture = recorder.endRecording();
      final ui.Image transImg = await picture.toImage(width, height);
      final ByteData? transBytes = await transImg.toByteData(format: ui.ImageByteFormat.png);

      if (transBytes != null) {
        final transparentPath = '${tempDir.path}/jaune_transparent_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(transparentPath).writeAsBytes(transBytes.buffer.asUint8List());
        return transparentPath;
      }
    } catch (e) {
      debugPrint('Failed to create transparent sticker: $e');
    }
    return null;
  }
}