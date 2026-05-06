// Page de capture BeReal-style refactorisée
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/camera_service.dart';
import 'widgets/image_composer.dart';

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

  Future<void> _takePicture() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      // Prend les deux photos
      final photos = await _cameraService.takeBothPhotos();
      final rearPhoto = photos['rear'];
      final frontPhoto = photos['front'];

      // Compose et partage l'image
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la prise de photo')),
        );
      }
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

  Widget _buildCompositionPreview() {
    final screenWidth = (MediaQuery.of(context).size.width - 32).clamp(
      0.0,
      400.0,
    );
    final aspectRatio = 9 / 12;
    final previewHeight = screenWidth / aspectRatio;

    final healthPercent = widget.healthPercent.clamp(0.0, 1.0);
    final healthValue = (healthPercent * 100).round();

    // Dimensions pour la zone PV
    final pvBoxWidth = screenWidth * 0.32; //(format 9:12)
    final pvBoxHeight = screenWidth * 0.42; //(format 9:12)
    final barWidth = screenWidth * 0.28;
    final barHeight = 8.0;

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
          // Fond
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

          // Zone PV en haut à droite (PV + nombre + avatar sur une ligne)
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              width: pvBoxWidth,
              height: pvBoxHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black.withAlpha((0.95 * 255).round()),
                  width: 3.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.3 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade300, Colors.blue.shade600],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'PV',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha((0.7 * 255).round()),
                    ),
                  ),
                  Text(
                    '$healthValue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 2),
                  Text('🍋', style: TextStyle(fontSize: screenWidth * 0.06)),
                  SizedBox(width: 2),
                ],
              ),
            ),
          ),

          // Barre de santé (juste au-dessus de JAUNE, petit écart)
          Positioned(
            bottom: 36,
            left: (screenWidth - barWidth) / 2,
            child: Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withAlpha((0.35 * 255).round()),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.18 * 255).round()),
                    blurRadius: 6.0,
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
                      borderRadius: BorderRadius.circular(12),
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
                      borderRadius: BorderRadius.circular(12),
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
                  fontSize: 14,
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
