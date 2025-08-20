// Page de capture BeReal-style: prend d'abord la photo arrière puis le selfie,
// compose l'image finale et lance le partage.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_share/social_share.dart';
import 'package:url_launcher/url_launcher.dart';

class BeRealCapturePage extends StatefulWidget {
  final String avatarAsset;
  final String message;
  final double healthPercent;

  const BeRealCapturePage({
    super.key,
    required this.avatarAsset,
    required this.message,
    required this.healthPercent,
  });

  @override
  State<BeRealCapturePage> createState() => _BeRealCapturePageState();
}

class _BeRealCapturePageState extends State<BeRealCapturePage> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  CameraController? _frontController;
  XFile? _rearPhoto;
  XFile? _frontPhoto;
  bool _busy = false;
  String _cameraDiagnostic = '';

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  @override
  void dispose() {
    // Ensure controller is disposed and cleared to avoid using a disposed
    // controller from async tasks or build methods.
    try {
      _controller?.dispose();
    } catch (e) {
      debugPrint('Error disposing controller in dispose(): $e');
    }
    try {
      _frontController?.dispose();
    } catch (e) {
      debugPrint('Error disposing front controller in dispose(): $e');
    }
    _controller = null;
    _frontController = null;
    super.dispose();
  }

  Future<void> _initCameras() async {
    try {
      debugPrint('[_initCameras] calling availableCameras()');
      _cameras = await availableCameras();
      debugPrint('[_initCameras] found ${_cameras.length} cameras');
      if (_cameras.isEmpty) return;

      // Find back and front cameras
      final backCam = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      CameraDescription? frontCam;
      try {
        frontCam = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
      } catch (_) {
        frontCam = null;
      }

      // Log available cameras for debugging with more detail
      for (var i = 0; i < _cameras.length; i++) {
        final c = _cameras[i];
        debugPrint(
          '[camera list][$i] name=${c.name} lens=${c.lensDirection} orient=${c.sensorOrientation} desc=${c.toString()}',
        );
      }
      if (frontCam != null) {
        debugPrint(
          '[selected cams] back=${backCam.name} front=${frontCam.name}',
        );
        if (frontCam.name == backCam.name) {
          debugPrint(
            '[camera selection] front camera equals back camera, ignoring front',
          );
          frontCam = null;
        }
      } else {
        debugPrint('[selected cams] back=${backCam.name} front=<none>');
      }

      // Initialize rear controller for preview with fallback presets to
      // avoid failures on devices that don't support very high resolutions.
      debugPrint('[init] trying to init rear camera ${backCam.name}');
      _controller = await _initControllerWithFallback(backCam);
      if (_controller == null) {
        debugPrint('Rear controller failed to initialize');
      }

      // Do not initialize front controller here to avoid stealing hardware
      // resources and breaking the rear preview. The front camera will be
      // initialized on-demand when the user takes a picture.
    } catch (e) {
      debugPrint('Camera init error (availableCameras): $e');
    }
    if (mounted) setState(() {});
    // Update diagnostic summary for UI
    final buf = StringBuffer();
    buf.writeln('cameras=${_cameras.length}');
    for (var i = 0; i < _cameras.length; i++) {
      final c = _cameras[i];
      buf.writeln(
        '[$i] name=${c.name} lens=${c.lensDirection} orient=${c.sensorOrientation}',
      );
    }
    buf.writeln(
      'rear_controller=${_controller != null && _controller!.value.isInitialized}',
    );
    buf.writeln(
      'front_controller=${_frontController != null && _frontController!.value.isInitialized}',
    );
    _cameraDiagnostic = buf.toString();
  }

  /// Returns true if we can access cameras (at least one available), false otherwise.
  Future<bool> _checkCameraAvailable() async {
    try {
      final cams = await availableCameras();
      return cams.isNotEmpty;
    } catch (e) {
      debugPrint('[ _checkCameraAvailable ] error: $e');
      return false;
    }
  }

  Future<void> _startControllerFor(CameraLensDirection dir) async {
    if (_cameras.isEmpty) return;
    final cam = _cameras.firstWhere(
      (c) => c.lensDirection == dir,
      orElse: () => _cameras.first,
    );
    // If there's an existing controller, remove reference first so the UI
    // doesn't try to build CameraPreview with a controller that will be
    // disposed. Then dispose the old controller.
    final old = _controller;
    if (old != null) {
      _controller = null;
      if (mounted) setState(() {});
      try {
        await old.dispose();
      } catch (e) {
        debugPrint('Error disposing old controller: $e');
      }
    }

    _controller = CameraController(
      cam,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Controller init error: $e');
      // If initialization fails, clear controller to avoid disposed use.
      try {
        await _controller?.dispose();
      } catch (_) {}
      _controller = null;
      if (mounted) setState(() {});
    }
  }

  // Try to initialize a controller using multiple presets, returning the
  // first one that successfully initializes, or null.
  Future<CameraController?> _initControllerWithFallback(
    CameraDescription cam,
  ) async {
    final presets = [
      ResolutionPreset.high,
      ResolutionPreset.max,
      ResolutionPreset.medium,
    ];
    for (final p in presets) {
      CameraController c = CameraController(
        cam,
        p,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      try {
        await c.initialize();
        if (mounted) setState(() {});
        debugPrint('Initialized camera ${cam.name} with preset $p');
        return c;
      } catch (e) {
        debugPrint('Init camera ${cam.name} with preset $p failed: $e');
        try {
          await c.dispose();
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> _takePicture() async {
    if (_busy) return;
    setState(() => _busy = true);

    XFile? rearFile;
    XFile? frontFile;

    // Find explicit back/front descriptions first
    CameraDescription? backDesc;
    CameraDescription? frontDesc;
    try {
      backDesc = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
    } catch (_) {
      backDesc = null;
    }
    try {
      frontDesc = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
    } catch (_) {
      frontDesc = null;
    }

    try {
      // If we have both explicit back and front devices, prefer a single
      // controller switching strategy: start controller on back -> capture ->
      // switch to front -> capture -> restore back. This guarantees distinct
      // sensors are used and avoids initializing two controllers in parallel
      // which on some devices produced double-front flashes.
      if (backDesc != null && frontDesc != null) {
        debugPrint(
          '[takePicture] using non-switch strategy: keep preview on back=${backDesc.name} and init temp front=${frontDesc.name}',
        );

        // Ensure we have a rear preview controller, but do NOT switch the
        // currently-displayed controller if it's already the back camera.
        if (_controller == null ||
            !_controller!.value.isInitialized ||
            _controller!.description.lensDirection !=
                CameraLensDirection.back) {
          await _startControllerFor(CameraLensDirection.back);
        }

        if (_controller != null &&
            _controller!.value.isInitialized &&
            _controller!.description.lensDirection ==
                CameraLensDirection.back) {
          try {
            try {
              await _controller!.setFocusMode(FocusMode.auto);
              await _controller!.setExposureMode(ExposureMode.auto);
            } catch (_) {}
            await Future.delayed(const Duration(milliseconds: 700));

            for (int attempt = 1; attempt <= 2; attempt++) {
              try {
                rearFile = await _controller!.takePicture();
                debugPrint(
                  '[takePicture] rear captured (attempt $attempt): ${rearFile.path}',
                );
                break;
              } catch (e) {
                debugPrint(
                  '[takePicture] rear capture attempt $attempt failed: $e',
                );
                if (attempt == 1) {
                  await Future.delayed(const Duration(milliseconds: 300));
                }
              }
            }
          } catch (e) {
            debugPrint('[takePicture] rear capture error: $e');
          }
        }

        // Capture selfie using a temporary front controller so we don't
        // disturb the main preview controller.
        CameraController? tempFront;
        try {
          tempFront = await _initControllerWithFallback(frontDesc);
          if (tempFront != null && tempFront.value.isInitialized) {
            try {
              try {
                await tempFront.setFocusMode(FocusMode.auto);
                await tempFront.setExposureMode(ExposureMode.auto);
              } catch (_) {}
              await Future.delayed(const Duration(milliseconds: 600));
              frontFile = await tempFront.takePicture();
              debugPrint(
                '[takePicture] temp front captured: ${frontFile.path}',
              );
            } catch (e) {
              debugPrint('[takePicture] temp front capture failed: $e');
            }
          }
        } catch (e) {
          debugPrint('[takePicture] init temp front failed: $e');
        } finally {
          if (tempFront != null) {
            try {
              await tempFront.dispose();
            } catch (_) {}
          }
        }
      } else {
        // Fallback: previous strategy when only one camera type is detected or
        // explicit front/back pair not available. Use whatever controllers we
        // have without switching the active controller repeatedly.
        debugPrint(
          '[takePicture] fallback fast-strategy: using existing controllers',
        );

        final rear = _controller;
        CameraController? front = _frontController;

        // Attempt to init a temporary front if we don't have one and a frontDesc exists
        if ((front == null || !front.value.isInitialized) &&
            frontDesc != null) {
          try {
            debugPrint(
              '[takePicture] initializing temporary front controller ${frontDesc.name}',
            );
            final tmp = await _initControllerWithFallback(frontDesc);
            if (tmp != null) {
              front = tmp;
              _frontController = tmp;
            }
          } catch (e) {
            debugPrint('[takePicture] temp front init failed: $e');
          }
        }

        try {
          if (rear != null &&
              rear.value.isInitialized &&
              rear.description.lensDirection == CameraLensDirection.back) {
            try {
              await rear.setFocusMode(FocusMode.auto);
              await rear.setExposureMode(ExposureMode.auto);
            } catch (_) {}
            await Future.delayed(const Duration(milliseconds: 600));
            for (int attempt = 1; attempt <= 2; attempt++) {
              try {
                rearFile = await rear.takePicture();
                debugPrint(
                  '[takePicture] rear captured (fallback) (attempt $attempt): ${rearFile.path}',
                );
                break;
              } catch (e) {
                debugPrint(
                  '[takePicture] rear capture attempt $attempt failed: $e',
                );
                if (attempt == 1) {
                  await Future.delayed(const Duration(milliseconds: 250));
                }
              }
            }
          } else {
            debugPrint(
              '[takePicture] no initialized rear controller available for fallback rear capture',
            );
          }
        } catch (e) {
          debugPrint('[takePicture] fallback rear capture error: $e');
        }

        await Future.delayed(const Duration(milliseconds: 400));

        if (front != null &&
            front.value.isInitialized &&
            front.description.lensDirection == CameraLensDirection.front) {
          try {
            try {
              await front.setFocusMode(FocusMode.auto);
              await front.setExposureMode(ExposureMode.auto);
            } catch (_) {}
            frontFile = await front.takePicture();
            debugPrint(
              '[takePicture] fallback front captured: ${frontFile.path}',
            );
          } catch (e) {
            debugPrint('[takePicture] fallback front capture failed: $e');
          }
        }
      }

      _rearPhoto = rearFile;
      _frontPhoto = frontFile;

      // If both photos exist but are identical (same file length), it's
      // likely we captured the same sensor twice (double-front). In that
      // case attempt a fallback: re-capture by switching the main controller
      // between physical rear/front devices to force distinct captures.
      if (_rearPhoto != null && _frontPhoto != null) {
        try {
          final rBytes = await File(_rearPhoto!.path).length();
          final fBytes = await File(_frontPhoto!.path).length();
          debugPrint('[takePicture] rear size=$rBytes front size=$fBytes');
          if (rBytes == fBytes) {
            debugPrint(
              '[takePicture] Detected duplicate-size images, running fallback capture with controller switching',
            );
            // Find explicit back/front descriptions
            CameraDescription? backDesc;
            CameraDescription? frontDesc;
            try {
              backDesc = _cameras.firstWhere(
                (c) => c.lensDirection == CameraLensDirection.back,
              );
            } catch (_) {
              backDesc = null;
            }
            try {
              frontDesc = _cameras.firstWhere(
                (c) => c.lensDirection == CameraLensDirection.front,
              );
            } catch (_) {
              frontDesc = null;
            }

            if (backDesc != null && frontDesc != null) {
              try {
                // Ensure rear controller points to the back device and capture
                await _startControllerFor(CameraLensDirection.back);
                await Future.delayed(const Duration(milliseconds: 300));
                XFile? rear2;
                try {
                  rear2 = await _controller!.takePicture();
                  debugPrint(
                    '[takePicture][fallback] rear captured: ${rear2.path}',
                  );
                } catch (e) {
                  debugPrint('[takePicture][fallback] rear capture failed: $e');
                }

                // Switch to front and capture
                await _startControllerFor(CameraLensDirection.front);
                await Future.delayed(const Duration(milliseconds: 300));
                XFile? front2;
                try {
                  front2 = await _controller!.takePicture();
                  debugPrint(
                    '[takePicture][fallback] front captured: ${front2.path}',
                  );
                } catch (e) {
                  debugPrint(
                    '[takePicture][fallback] front capture failed: $e',
                  );
                }

                // Restore rear controller
                await _startControllerFor(CameraLensDirection.back);

                if (rear2 != null) _rearPhoto = rear2;
                if (front2 != null) _frontPhoto = front2;
              } catch (e) {
                debugPrint('[takePicture][fallback] error: $e');
              } finally {
                // IMPORTANT: do not dispose and reassign the saved `old`
                // controller here — disposing it then setting it back made
                // the active controller a disposed instance, breaking
                // subsequent previews/captures. Keep the controller that
                // `_startControllerFor` left us with and log its state.
                debugPrint(
                  '[takePicture][fallback] finished, active controller=${_controller?.description.name}',
                );
                if (mounted) setState(() {});
              }
            }
          }
        } catch (e) {
          debugPrint('[takePicture] error comparing files: $e');
        }
      }

      if (_rearPhoto != null || _frontPhoto != null) {
        await _composeAndShare();
      }
    } catch (e) {
      debugPrint('Take picture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la prise de photo')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ui.Image> _decodeImageFromList(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => completer.complete(img));
    return completer.future;
  }

  Future<void> _composeAndShare() async {
    // Accept single-photo cases: if rear is missing, use front as background
    if (_rearPhoto == null && _frontPhoto == null) return;
    try {
      debugPrint(
        '[compose] rearPath=${_rearPhoto?.path} frontPath=${_frontPhoto?.path}',
      );
      try {
        if (_rearPhoto != null) {
          final rlen = await File(_rearPhoto!.path).length();
          debugPrint('[compose] rear size=$rlen');
        }
      } catch (e) {
        debugPrint('[compose] cannot read rear file: $e');
      }
      try {
        if (_frontPhoto != null) {
          final flen = await File(_frontPhoto!.path).length();
          debugPrint('[compose] front size=$flen');
        }
      } catch (e) {
        debugPrint('[compose] cannot read front file: $e');
      }
      final rearBytes =
          _rearPhoto != null
              ? await File(_rearPhoto!.path).readAsBytes()
              : null;
      final frontBytes =
          _frontPhoto != null
              ? await File(_frontPhoto!.path).readAsBytes()
              : null;

      final rearImg =
          rearBytes != null ? await _decodeImageFromList(rearBytes) : null;
      final frontImg =
          frontBytes != null ? await _decodeImageFromList(frontBytes) : null;

      final avatarData = await rootBundle.load(widget.avatarAsset);
      final avatarImg = await _decodeImageFromList(
        avatarData.buffer.asUint8List(),
      );

      // If rear image missing, use front as background (scaled up)
      final int width = (rearImg ?? frontImg)!.width;
      final int height = (rearImg ?? frontImg)!.height;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // background (use rear if available, otherwise front)
      if (rearImg != null) {
        canvas.drawImage(rearImg, Offset.zero, paint);
      } else if (frontImg != null) {
        // draw front as background, scaled to full canvas
        final src = Rect.fromLTWH(
          0,
          0,
          frontImg.width.toDouble(),
          frontImg.height.toDouble(),
        );
        final dst = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
        canvas.drawImageRect(frontImg, src, dst, paint);
      }

      // selfie circle top-right (only if frontImg available and it's not the background)
      if (frontImg != null && rearImg != null) {
        // Center-crop the front image to a portrait 9:12 rectangle (story)
        // and draw it but never upscale: only scale down.
        const double targetAspect = 9.0 / 12.0;
        final double srcW = frontImg.width.toDouble();
        final double srcH = frontImg.height.toDouble();

        double srcCropW, srcCropH;
        if (srcW / srcH >= targetAspect) {
          // source is wider than 16:9 -> use full height
          srcCropH = srcH;
          srcCropW = srcCropH * targetAspect;
        } else {
          // source is taller -> use full width
          srcCropW = srcW;
          srcCropH = srcCropW / targetAspect;
        }

        final double srcLeft = (srcW - srcCropW) / 2.0;
        final double srcTop = (srcH - srcCropH) / 2.0;
        final Rect srcRect = Rect.fromLTWH(srcLeft, srcTop, srcCropW, srcCropH);

        final double maxSelfieW = width * 0.40;
        // never upscale: limit desired width to source crop width
        final double selfieW = math.min(maxSelfieW, srcCropW);
        final double selfieH = selfieW / targetAspect;

        final double selfieLeft = width - selfieW - 24;
        final double selfieTop = 24;
        final Rect dstRect = Rect.fromLTWH(
          selfieLeft,
          selfieTop,
          selfieW,
          selfieH,
        );

        // Rounded crop + border
        canvas.save();
        final RRect clipR = RRect.fromRectAndRadius(
          dstRect,
          // use a radius based on width so corners look consistent on tall crops
          Radius.circular(selfieW * 0.12),
        );
        canvas.clipRRect(clipR);
        canvas.drawImageRect(frontImg, srcRect, dstRect, paint);

        // border (proportional thickness)
        final borderPaint =
            Paint()
              ..style = PaintingStyle.stroke
              ..color = Colors.black.withAlpha((0.95 * 255).round())
              ..strokeWidth = 6.0
              ..isAntiAlias = true;
        canvas.drawRRect(clipR, borderPaint);
        canvas.restore();
      }

      // avatar bottom-left (rounded)
      final double avatarSize = width * 0.20;
      final double avatarLeft = 16;
      final double avatarTop = height - avatarSize - 32 - 8 - 16;
      final Rect avatarDst = Rect.fromLTWH(
        avatarLeft,
        avatarTop,
        avatarSize,
        avatarSize,
      );
      canvas.save();
      final RRect avatarR = RRect.fromRectAndRadius(
        avatarDst,
        Radius.circular(avatarSize * 0.18),
      );
      canvas.clipRRect(avatarR);
      canvas.drawImageRect(
        avatarImg,
        Rect.fromLTWH(
          0,
          0,
          avatarImg.width.toDouble(),
          avatarImg.height.toDouble(),
        ),
        avatarDst,
        paint,
      );
      canvas.restore();

      // PV bar: reproduce the Stack widget appearance: frosted glass
      // background, fractionally-sized colored fill, subtle top highlight
      // and centered percent text with embossed shadows.
      final double barWidth = avatarSize; // match character width
      final double barHeight = 16.0; // same as UI
      double barLeft = avatarLeft;
      double barTop = height - barHeight - 32.0;

      // shadow for 3D effect
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

      // frosted background
      final RRect bgR = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        Radius.circular(14),
      );
      final Paint bgPaint =
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(barLeft, barTop),
              Offset(barLeft, barTop + barHeight),
              [
                Colors.white.withAlpha((0.28 * 255).round()),
                Colors.white.withAlpha((0.10 * 255).round()),
              ],
            );
      canvas.drawRRect(bgR, bgPaint);

      // border
      final Paint borderPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withAlpha((0.35 * 255).round());
      canvas.drawRRect(bgR, borderPaint);

      // filled gradient depending on percent (mimic FractionallySizedBox)
      final double pct = widget.healthPercent.clamp(0.0, 1.0);
      final double filledW = barWidth * pct;
      if (filledW > 0.5) {
        final RRect fillR = RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop, filledW, barHeight),
          Radius.circular(14),
        );
        List<Color> fillColors;
        if (pct > 0.6) {
          fillColors = [const Color(0xFF43e97b), const Color(0xFF38f9d7)];
        } else if (pct > 0.3) {
          fillColors = [const Color(0xFFf7971e), const Color(0xFFffd200)];
        } else {
          fillColors = [const Color(0xFFf85757), const Color(0xFFf857a6)];
        }

        final Paint fillPaint =
            Paint()
              ..shader = ui.Gradient.linear(
                Offset(barLeft, barTop),
                Offset(barLeft + barWidth, barTop),
                fillColors,
              );
        canvas.drawRRect(fillR, fillPaint);

        // subtle halo beneath the fill
        final Paint halo =
            Paint()
              ..color = Colors.black.withAlpha((0.06 * 255).round())
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawRRect(fillR.shift(const Offset(0, 1.0)), halo);
      }

      // top highlight (overlay)
      final Paint highlight =
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(barLeft, barTop),
              Offset(barLeft, barTop + barHeight),
              [
                Colors.white.withAlpha((0.02 * 255).round()),
                Colors.transparent,
              ],
            );
      canvas.drawRRect(bgR, highlight);

      // centered percent text with embossed shadows (match Stack Text style)
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

      // message card on top-right: improved layout inspired by the Widget
      // Header "Jaune" (yellow strip) + main card with white inner panel
      final double cardW = width - avatarSize - 32 - 8;
      final double cardH = avatarSize + barHeight + 8 - 36;
      final double cardLeft = avatarSize + 16 + 8;
      final double cardTop = height - 32.0 - cardH;
      final Rect cardOuterRect = Rect.fromLTWH(cardLeft, cardTop, cardW, cardH);
      final RRect cardOuter = RRect.fromRectAndCorners(
        cardOuterRect,
        topRight: const Radius.circular(16),
        bottomLeft: const Radius.circular(16),
        bottomRight: const Radius.circular(16),
      );
      // drop shadow
      canvas.drawShadow(
        Path()..addRRect(cardOuter),
        Colors.black.withAlpha((0.12 * 255).round()),
        12.0,
        false,
      );
      // outer gradient (yellow)
      final Paint cardOuterPaint =
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(cardOuterRect.left, cardOuterRect.top),
              Offset(cardOuterRect.left, cardOuterRect.bottom),
              [const Color(0xFFF7D83F), const Color(0xFFEFB192)],
            );
      canvas.drawRRect(cardOuter, cardOuterPaint);

      // inner white panel
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
      // Emulate the widget BoxShadow stack: large soft shadow, smaller soft
      // shadow, and a subtle white top highlight with slight negative spread.
      // 1) large shadow (color black .12, offset (0,8), blur 18)
      final Paint innerShadowLarge =
          Paint()
            ..color = Colors.black.withAlpha((0.12 * 255).round())
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18.0 / 2.0);
      canvas.drawRRect(cardInner.shift(const Offset(0, 8)), innerShadowLarge);

      // 2) smaller shadow (color black .06, offset (0,4), blur 8)
      final Paint innerShadowSmall =
          Paint()
            ..color = Colors.black.withAlpha((0.06 * 255).round())
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 / 2.0);
      canvas.drawRRect(cardInner.shift(const Offset(0, 4)), innerShadowSmall);

      // 3) subtle white top highlight to mimic the lighter spread (offset 0,-2,
      // blur 6, spreadRadius -4) — emulate by drawing a slightly smaller rounded
      // rect shifted up with a white blurred paint.
      final Rect highlightRect = cardInnerRect.deflate(4.0);
      final RRect highlightR = RRect.fromRectAndCorners(
        highlightRect,
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(28),
        bottomLeft: const Radius.circular(28),
        bottomRight: const Radius.circular(12),
      );
      final Paint highlightPaint =
          Paint()
            ..color = Colors.white.withAlpha((0.90 * 255).round())
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 / 2.0);
      canvas.drawRRect(highlightR.shift(const Offset(0, -2)), highlightPaint);

      // inner white panel (gradient)
      final Paint cardInnerPaint =
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(cardInnerRect.left, cardInnerRect.top),
              Offset(cardInnerRect.left, cardInnerRect.bottom),
              [
                Colors.white.withAlpha((0.98 * 255).round()),
                Colors.grey.shade50,
              ],
            );
      canvas.drawRRect(cardInner, cardInnerPaint);

      // Header pill (yellow bar) placed above the inner panel, centered horizontally
      final double headerH = 36.0;
      final double headerW = (cardInnerRect.width * 0.3).clamp(
        88.0,
        cardInnerRect.width,
      );
      final double headerLeft = cardLeft;
      final double headerTop =
          cardOuterRect.top - headerH + 8.0; // align similar to widget spacing
      final RRect headerR = RRect.fromRectAndRadius(
        Rect.fromLTWH(headerLeft, headerTop, headerW, headerH),
        const Radius.circular(8),
      );
      final Paint headerPaint = Paint()..color = const Color(0xFFF7D83F);
      canvas.drawRRect(headerR, headerPaint);

      // Header text 'Jaune' centered
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

      // Message text inside inner card with padding like the widget
      final double msgPadLeft = 16.0;
      final double msgPadRight = 8.0;
      final double msgPadTop = 12.0;
      // final double msgPadBottom = 8.0; // unused
      final double msgMaxW = cardInnerRect.width - msgPadLeft - msgPadRight;
      final TextPainter msgTp = TextPainter(
        text: TextSpan(
          text: widget.message,
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

      final picture = recorder.endRecording();
      final ui.Image finalImg = await picture.toImage(width, height);
      final ByteData? pngBytes = await finalImg.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (pngBytes == null) throw Exception('Failed to encode image');

      final tempDir = await getTemporaryDirectory();
      final outPath =
          '${tempDir.path}/jaune_share_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(pngBytes.buffer.asUint8List());

      // Create a transparent PNG (same size) to satisfy social_share's
      // required `imagePath` (sticker). Instagram expects a sticker image
      // which can be transparent while the backgroundResourcePath provides
      // the full background image.
      try {
        final recorder2 = ui.PictureRecorder();
        final canvas2 = Canvas(recorder2);
        final paintClear = Paint()..color = const Color(0x00000000);
        canvas2.drawRect(
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          paintClear,
        );
        final picture2 = recorder2.endRecording();
        final ui.Image transImg = await picture2.toImage(width, height);
        final ByteData? transBytes = await transImg.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (transBytes == null) {
          debugPrint('Failed to encode transparent image');
        } else {
          final transparentPath =
              '${tempDir.path}/jaune_transparent_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(
            transparentPath,
          ).writeAsBytes(transBytes.buffer.asUint8List());

          try {
            await SocialShare.shareInstagramStory(
              imagePath: transparentPath,
              backgroundResourcePath: outPath,
              appId: 'com.instagram.android',
            );
          } catch (e) {
            debugPrint('social_share failed: $e');
          }
        }
      } catch (e) {
        debugPrint('Transparent PNG creation or share failed: $e');
      }

      if (mounted) {
        Navigator.of(context).pop(outPath);
      }
    } catch (e, st) {
      debugPrint('Compose/share error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la composition ou du partage'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_down,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        title: const Text(
          'JAUNE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<bool>(
        future: _checkCameraAvailable(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hasCamera = snap.data!;
          if (!hasCamera) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Accès caméra indisponible ou refusé.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // try to re-init cameras which will re-trigger availableCameras
                      await _initCameras();
                      setState(() {});
                    },
                    child: const Text('Essayer à nouveau'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.parse('app-settings:');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: const Text('Ouvrir les réglages'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (isReady)
                // Preview area: keep aspect ratio and show a busy overlay
                // on top while capture/composition is in progress.
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Center(
                              child: SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: CameraPreview(controller),
                              ),
                            );
                          },
                        ),

                        // iOS-style frosted busy overlay during capture/composition
                        if (_busy)
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: 6.0,
                                sigmaY: 6.0,
                              ),
                              child: Container(
                                color: Colors.black.withAlpha(
                                  (0.22 * 255).round(),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CupertinoActivityIndicator(
                                        radius: 14,
                                      ),

                                      const SizedBox(height: 12),
                                      Text(
                                        'Ditês JAUNEEE...',
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(
                                            (0.87 * 255).round(),
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam_off,
                          size: 48,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aperçu indisponible',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _cameraDiagnostic,
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await _initCameras();
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                margin: EdgeInsets.all(4),
                child: Text(
                  "PHOTO",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 80),
                child: GestureDetector(
                  onTap: _busy ? null : _takePicture,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
