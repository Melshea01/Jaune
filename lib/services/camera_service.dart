// Service pour gérer les caméras et captures
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  CameraController? _frontController;

  List<CameraDescription> get cameras => _cameras;
  CameraController? get controller => _controller;
  bool get isReady => _controller != null && _controller!.value.isInitialized;

  /// Initialise les caméras disponibles
  Future<void> initCameras() async {
    try {
      debugPrint('[CameraService] calling availableCameras()');
      _cameras = await availableCameras();
      debugPrint('[CameraService] found ${_cameras.length} cameras');

      if (_cameras.isEmpty) return;

      // Log des caméras disponibles
      for (var i = 0; i < _cameras.length; i++) {
        final c = _cameras[i];
        debugPrint(
          '[camera list][$i] name=${c.name} lens=${c.lensDirection} orient=${c.sensorOrientation}',
        );
      }

      // Initialise la caméra arrière par défaut
      final backCam = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = await _initControllerWithFallback(backCam);
      if (_controller == null) {
        debugPrint('Rear controller failed to initialize');
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  /// Vérifie si des caméras sont disponibles
  Future<bool> checkCameraAvailable() async {
    try {
      final cams = await availableCameras();
      return cams.isNotEmpty;
    } catch (e) {
      debugPrint('[checkCameraAvailable] error: $e');
      return false;
    }
  }

  /// Initialise un contrôleur avec fallback sur différentes résolutions
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

  /// Switch the preview camera between front and back by starting the
  /// appropriate controller. If only one camera type exists, this is a no-op.
  Future<void> switchPreviewCamera() async {
    if (_cameras.isEmpty) return;
    try {
      final current = _controller;
      final currentDir = current?.description.lensDirection;
      final CameraLensDirection target =
          (currentDir == CameraLensDirection.back)
              ? CameraLensDirection.front
              : CameraLensDirection.back;

      await _startControllerFor(target);
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  /// Démarre le contrôleur pour une direction de caméra spécifique
  Future<void> _startControllerFor(CameraLensDirection dir) async {
    if (_cameras.isEmpty) return;

    final cam = _cameras.firstWhere(
      (c) => c.lensDirection == dir,
      orElse: () => _cameras.first,
    );

    // Dispose de l'ancien contrôleur
    final old = _controller;
    if (old != null) {
      _controller = null;
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
    } catch (e) {
      debugPrint('Controller init error: $e');
      try {
        await _controller?.dispose();
      } catch (_) {}
      _controller = null;
    }
  }

  /// Prend les photos arrière et avant
  Future<Map<String, XFile?>> takeBothPhotos() async {
    XFile? rearFile;
    XFile? frontFile;

    // Trouve les descriptions des caméras
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
      if (backDesc != null && frontDesc != null) {
        // Capture avec les deux caméras distinctes
        rearFile = await _captureRearPhoto(backDesc);
        frontFile = await _captureFrontPhoto(frontDesc);

        // Vérifie si les images sont identiques (même taille = même capteur)
        if (rearFile != null && frontFile != null) {
          if (await _arePhotosIdentical(rearFile, frontFile)) {
            debugPrint(
              'Detected duplicate images, retrying with controller switching',
            );
            final retryResults = await _retryWithControllerSwitching(
              backDesc,
              frontDesc,
            );
            rearFile = retryResults['rear'] ?? rearFile;
            frontFile = retryResults['front'] ?? frontFile;
          }
        }
      } else {
        // Fallback avec un seul type de caméra
        rearFile = await _captureFallback(CameraLensDirection.back);
        frontFile = await _captureFallback(CameraLensDirection.front);
      }
    } catch (e) {
      debugPrint('Take both photos error: $e');
    }

    return {'rear': rearFile, 'front': frontFile};
  }

  /// Capture la photo arrière
  Future<XFile?> _captureRearPhoto(CameraDescription backDesc) async {
    // S'assure que le contrôleur principal est sur la caméra arrière
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.description.lensDirection != CameraLensDirection.back) {
      await _startControllerFor(CameraLensDirection.back);
    }

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.setFocusMode(FocusMode.auto);
        await _controller!.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 700));

      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final photo = await _controller!.takePicture();
          debugPrint('Rear captured (attempt $attempt): ${photo.path}');
          return photo;
        } catch (e) {
          debugPrint('Rear capture attempt $attempt failed: $e');
          if (attempt == 1) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
      }
    }
    return null;
  }

  /// Capture la photo avant avec un contrôleur temporaire
  Future<XFile?> _captureFrontPhoto(CameraDescription frontDesc) async {
    CameraController? tempFront;
    try {
      tempFront = await _initControllerWithFallback(frontDesc);
      if (tempFront != null && tempFront.value.isInitialized) {
        try {
          await tempFront.setFocusMode(FocusMode.auto);
          await tempFront.setExposureMode(ExposureMode.auto);
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 600));
        final photo = await tempFront.takePicture();
        debugPrint('Front captured: ${photo.path}');
        return photo;
      }
    } catch (e) {
      debugPrint('Front capture failed: $e');
    } finally {
      if (tempFront != null) {
        try {
          await tempFront.dispose();
        } catch (_) {}
      }
    }
    return null;
  }

  /// Capture en mode fallback
  Future<XFile?> _captureFallback(CameraLensDirection direction) async {
    final controller =
        direction == CameraLensDirection.back ? _controller : _frontController;

    if (controller != null &&
        controller.value.isInitialized &&
        controller.description.lensDirection == direction) {
      try {
        await controller.setFocusMode(FocusMode.auto);
        await controller.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 600));

      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final photo = await controller.takePicture();
          debugPrint(
            '${direction.name} captured (fallback attempt $attempt): ${photo.path}',
          );
          return photo;
        } catch (e) {
          debugPrint('${direction.name} capture attempt $attempt failed: $e');
          if (attempt == 1) {
            await Future.delayed(const Duration(milliseconds: 250));
          }
        }
      }
    }
    return null;
  }

  /// Vérifie si deux photos sont identiques (même taille)
  Future<bool> _arePhotosIdentical(XFile rear, XFile front) async {
    try {
      final rBytes = await File(rear.path).length();
      final fBytes = await File(front.path).length();
      debugPrint('Rear size=$rBytes Front size=$fBytes');
      return rBytes == fBytes;
    } catch (e) {
      debugPrint('Error comparing files: $e');
      return false;
    }
  }

  /// Retry avec changement de contrôleur pour forcer l'utilisation de capteurs différents
  Future<Map<String, XFile?>> _retryWithControllerSwitching(
    CameraDescription backDesc,
    CameraDescription frontDesc,
  ) async {
    XFile? rear2;
    XFile? front2;

    try {
      // Capture arrière
      await _startControllerFor(CameraLensDirection.back);
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        rear2 = await _controller!.takePicture();
        debugPrint('Fallback rear captured: ${rear2.path}');
      } catch (e) {
        debugPrint('Fallback rear capture failed: $e');
      }

      // Capture avant
      await _startControllerFor(CameraLensDirection.front);
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        front2 = await _controller!.takePicture();
        debugPrint('Fallback front captured: ${front2.path}');
      } catch (e) {
        debugPrint('Fallback front capture failed: $e');
      }

      // Restore rear controller
      await _startControllerFor(CameraLensDirection.back);
    } catch (e) {
      debugPrint('Retry with controller switching error: $e');
    }

    return {'rear': rear2, 'front': front2};
  }

  /// Génère un diagnostic des caméras
  String getCameraDiagnostic() {
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
    return buf.toString();
  }

  /// Dispose des contrôleurs
  Future<void> dispose() async {
    try {
      await _controller?.dispose();
    } catch (e) {
      debugPrint('Error disposing controller: $e');
    }
    try {
      await _frontController?.dispose();
    } catch (e) {
      debugPrint('Error disposing front controller: $e');
    }
    _controller = null;
    _frontController = null;
  }
}
