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
      title: const Text(
        'JAUNE',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
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
      children: [
        Expanded(
          child: _buildPreviewArea(),
        ),
        _buildCaptureControls(),
      ],
    );
  }

  Widget _buildPreviewArea() {
    if (!_cameraService.isReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off,
              size: 48,
              color: Colors.white70,
            ),
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
          // Aperçu de la caméra
          LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_cameraService.controller!),
                ),
              );
            },
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