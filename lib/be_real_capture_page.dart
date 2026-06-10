// Page de capture BeReal-style refactorisée
import 'dart:ui' as ui;
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/camera_service.dart';
import 'widgets/image_composer.dart';

class BeRealCapturePage extends StatefulWidget {
  final String avatarAsset;
  final String message;
  final double healthPercent;
  final int level;
  final int streakDays;

  const BeRealCapturePage({
    super.key,
    required this.avatarAsset,
    required this.message,
    required this.healthPercent,
    this.level = 1,
    this.streakDays = 0,
  });

  @override
  State<BeRealCapturePage> createState() => _BeRealCapturePageState();
}

class _BeRealCapturePageState extends State<BeRealCapturePage> {
  late final CameraService _cameraService;
  late final ImageComposer _imageComposer;
  bool _busy = false;
  bool _debugMode = false; // Mode preview pour déboguer sans caméra

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _imageComposer = ImageComposer();
    _initCameras();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _initCameras() async {
    await _cameraService.initCameras();
    if (mounted) setState(() {});
  }

  Future<ui.Image?> _decodeXFileToUiImage(XFile? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => completer.complete(img));
    return completer.future;
  }

  Future<Uint8List?> _capturePreviewPng({
    XFile? rearPhoto,
    XFile? frontPhoto,
  }) async {
    final overlay = Overlay.of(context);
    const double pixelRatio = 1.0;

    const double storyWidth = 1080.0;
    const double storyHeight = 1920.0;

    // On décode directement les images pour le rendu
    final rearUiImage = await _decodeXFileToUiImage(rearPhoto);
    final frontUiImage = await _decodeXFileToUiImage(frontPhoto);

    final completer = Completer<Uint8List?>();
    final previewKey = GlobalKey();

    final entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: -10000,
          top: -10000,
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              key: previewKey,
              child: SizedBox(
                width: storyWidth,
                height: storyHeight,
                child: _buildCompositionPreview(
                  rearUiImage: rearUiImage,
                  frontUiImage: frontUiImage,
                  targetWidth: storyWidth,
                  targetHeight: storyHeight,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    // Attendre un frame pour que le rendu hors écran soit prêt
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary =
          previewKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        completer.complete(null);
      } else {
        final ui.Image img = await boundary.toImage(pixelRatio: pixelRatio);
        final ByteData? byteData = await img.toByteData(
          format: ui.ImageByteFormat.png,
        );
        completer.complete(byteData?.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Preview capture error: $e');
      completer.complete(null);
    } finally {
      entry.remove();
    }

    return completer.future;
  }

  Future<void> _takePicture() async {
    if (_busy) return;
    HapticFeedback.heavyImpact();
    setState(() => _busy = true);

    try {
      final photos = await _cameraService.takeBothPhotos();
      final rearPhoto = photos['rear'];
      final frontPhoto = photos['front'];

      final Uint8List? preview = await _capturePreviewPng(
        rearPhoto: rearPhoto,
        frontPhoto: frontPhoto,
      );

      if (preview != null) {
        final outputPath = await _imageComposer.composeAndShare(
          rearPhoto: null,
          frontPhoto: null,
          avatarAsset: widget.avatarAsset,
          message: widget.message,
          healthPercent: widget.healthPercent,
          previewBytes: preview,
        );
        if (mounted && outputPath != null)
          Navigator.of(context).pop(outputPath);
        return;
      }

      // Fallback
      if (rearPhoto != null || frontPhoto != null) {
        final outputPath = await _imageComposer.composeAndShare(
          rearPhoto: rearPhoto,
          frontPhoto: frontPhoto,
          avatarAsset: widget.avatarAsset,
          message: widget.message,
          healthPercent: widget.healthPercent,
        );

        if (mounted && outputPath != null) {
          Navigator.of(context).pop(outputPath);
        }
      }
    } catch (e) {
      debugPrint('Take picture error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mode debug: affiche directement la prévisualisation du montage
    if (_debugMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildCompositionPreview(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _debugMode = false),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retour à la caméra'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '📱 Aperçu du montage final',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: FutureBuilder<bool>(
        future: _cameraService.checkCameraAvailable(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasCamera = snapshot.data!;
          if (!hasCamera) {
            return _buildNoCameraView();
          }

          return _buildCameraView();
        },
      ),
    );
  }

  Widget _buildCompositionPreview({
    ui.Image? rearUiImage,
    ui.Image? frontUiImage,
    double? targetWidth,
    double? targetHeight,
  }) {
    final screenWidth =
        targetWidth ??
        (MediaQuery.of(context).size.width - 32).clamp(0.0, 400.0);
    final aspectRatio = 9 / 16;
    final previewHeight = targetHeight ?? (screenWidth / aspectRatio);
    final double uiScale =
        (targetHeight != null || targetWidth != null) ? 2.0 : 1.0;

    final healthPercent = widget.healthPercent.clamp(0.0, 1.0);
    final healthValue = (healthPercent * 100).round();

    // Dimensions pour la zone PV
    final pvBoxWidth = screenWidth * 0.22 * uiScale; //(format 9:12)
    final pvBoxHeight = screenWidth * 0.30 * uiScale; //(format 9:12)
    final barWidth = screenWidth * 0.22 * uiScale;
    final barHeight = 14.0 * uiScale;

    return Container(
      width: screenWidth,
      height: previewHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          // Fond : image ou dégradé
          if (rearUiImage != null || frontUiImage != null)
            SizedBox(
              width: screenWidth,
              height: previewHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RawImage(
                  image: rearUiImage ?? frontUiImage,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: screenWidth,
              height: previewHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.amber.shade700, Colors.orange.shade900],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: Colors.white.withAlpha((0.2 * 255).round()),
                ),
              ),
            ),

          // Niveau + streak en haut à gauche
          Positioned(
            left: 16 * uiScale,
            top: 16 * uiScale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShareChip(
                  uiScale: uiScale,
                  emoji: '🎮',
                  label: 'Niv. ${widget.level}',
                  gradientColors: const [Color(0xFFF7D83F), Color(0xFFF6B73F)],
                ),
                if (widget.streakDays > 0) ...[
                  SizedBox(height: 8 * uiScale),
                  _buildShareChip(
                    uiScale: uiScale,
                    emoji: '🔥',
                    label:
                        '${widget.streakDays} ${widget.streakDays > 1 ? 'jours' : 'jour'}',
                    gradientColors: const [
                      Color(0xFFFF9D42),
                      Color(0xFFFF6B35),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Selfie (front photo) en haut a droite avec PV
          if (frontUiImage != null)
            Positioned(
              right: 16 * uiScale,
              top: 16 * uiScale,
              child: Container(
                width: pvBoxWidth,
                height: pvBoxHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12 * uiScale),
                  border: Border.all(
                    color: Colors.black.withAlpha((0.95 * 255).round()),
                    width: 3.0 * uiScale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.3 * 255).round()),
                      blurRadius: 12 * uiScale,
                      offset: Offset(0, 4 * uiScale),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9 * uiScale),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RawImage(image: frontUiImage, fit: BoxFit.cover),
                      Positioned(
                        right: 6 * uiScale,
                        top: -3 * uiScale,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'PV',
                              style: TextStyle(
                                fontSize: 9 * uiScale * 1.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(
                                  (0.7 * 255).round(),
                                ),
                              ),
                            ),
                            SizedBox(width: 2 * uiScale),
                            Text(
                              '$healthValue',
                              style: TextStyle(
                                fontSize: 16 * uiScale * 1.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 2 * uiScale),
                            Text(
                              '🍋',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04 * uiScale,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Barre de santé (juste au-dessus de JAUNE, petit écart)
          Positioned(
            bottom: 40 * uiScale,
            left: (screenWidth - barWidth) / 2,
            child: Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * uiScale),
                border: Border.all(
                  color: Colors.white.withAlpha((0.35 * 255).round()),
                  width: 1.5 * uiScale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.18 * 255).round()),
                    blurRadius: 6.0 * uiScale,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Fond givré
                  Container(
                    width: barWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12 * uiScale),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withAlpha((0.28 * 255).round()),
                          Colors.white.withAlpha((0.10 * 255).round()),
                        ],
                      ),
                    ),
                  ),
                  // Remplissage coloré
                  Container(
                    width: barWidth * healthPercent,
                    height: barHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12 * uiScale),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: _getHealthGradientColors(healthPercent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // JAUNE en bas centré (discret et petit)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'JAUNE',
                style: TextStyle(
                  fontSize: 18 * 2.4,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip arrondi (niveau, streak…) affiché sur l'image partagée
  Widget _buildShareChip({
    required double uiScale,
    required String emoji,
    required String label,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * uiScale,
        vertical: 6 * uiScale,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20 * uiScale),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.2 * uiScale,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: Offset(0, 2 * uiScale),
            blurRadius: 8 * uiScale,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 13 * uiScale * 1.4)),
          SizedBox(width: 4 * uiScale),
          Text(
            label,
            style: TextStyle(
              fontSize: 12 * uiScale * 1.4,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getHealthGradientColors(double healthPercent) {
    if (healthPercent > 0.6) {
      return [const Color(0xFF43e97b), const Color(0xFF38f9d7)];
    } else if (healthPercent > 0.3) {
      return [const Color(0xFFf7971e), const Color(0xFFffd200)];
    } else {
      return [const Color(0xFFf85757), const Color(0xFFf857a6)];
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
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
      title: GestureDetector(
        onLongPress: () {
          setState(() => _debugMode = !_debugMode);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _debugMode ? '🐛 Mode debug activé' : '📸 Mode normal',
              ),
              duration: const Duration(milliseconds: 800),
            ),
          );
        },
        child: const Text(
          'BEJAUNE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildNoCameraView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Accès caméra indisponible ou refusé.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
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

  Widget _buildCameraView() {
    return Column(
      children: [Expanded(child: _buildPreviewArea()), _buildCaptureControls()],
    );
  }

  Widget _buildPreviewArea() {
    if (_cameraService.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_cameraService.isReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            const Text(
              'Aperçu indisponible',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              _cameraService.getCameraDiagnostic(),
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initCameras,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final scale =
                  size.aspectRatio *
                  _cameraService.controller!.value.aspectRatio;

              return Transform.scale(
                scale: scale < 1 ? 1 / scale : scale,
                child: Center(child: CameraPreview(_cameraService.controller!)),
              );
            },
          ),
          // Camera switch button (bottom-right) — small white circular icon
          Positioned(
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: () async {
                await _cameraService.switchPreviewCamera();
                if (mounted) setState(() {});
              },
              child: const Icon(
                CupertinoIcons.switch_camera,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Overlay pendant la capture
          if (_busy) _buildBusyOverlay(),
        ],
      ),
    );
  }

  Widget _buildBusyOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Container(
          color: Colors.black.withAlpha((0.22 * 255).round()),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(radius: 14),
                SizedBox(height: 12),
                Text(
                  'Ditês JAUNEEE...',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(4),
          child: const Text(
            "PHOTO",
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 80),
          child: GestureDetector(
            onTap: _busy ? null : _takePicture,
            child: Container(
              padding: const EdgeInsets.all(4),
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
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
  }
}
