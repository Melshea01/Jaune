import re

with open("lib/be_real_capture_page.dart","r") as f:
    text = f.read()

# Make sure imports are clean
if "import 'dart:io';" not in text:
    text = text.replace("import 'dart:ui' as ui;", "import 'dart:ui' as ui;\nimport 'dart:io';\nimport 'dart:typed_data';\nimport 'dart:async';")

# replace Widget _buildCompositionPreview() with the new signature
old_sig = """Widget _buildCompositionPreview() {"""
new_sig = """Widget _buildCompositionPreview({ui.Image? rearUiImage, ui.Image? frontUiImage}) {"""
if old_sig in text:
    text = text.replace(old_sig, new_sig)

# replace the background box
old_box = """          // Fond
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
          ),"""

new_box = """          // Fond : image ou dégradé
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

          // Selfie (front photo)
          if (frontUiImage != null && rearUiImage != null)
            Positioned(
              top: previewHeight * 0.08,
              left: screenWidth * 0.08,
              child: Container(
                width: screenWidth * 0.35,
                height: (screenWidth * 0.35) / (9 / 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13), 
                  child: RawImage(
                    image: frontUiImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),"""

if old_box in text:
    text = text.replace(old_box, new_box)

# Now remove the JAUNE text carefully
text = re.sub(r'\s*// JAUNE en bas centré \(discret et petit\).*?Positioned\([\s\S]*?child: Text\([\s\S]*?JAUNE[\s\S]*?\}\),\s*\),\s*\),\s*\),', '', text, flags=re.MULTILINE|re.DOTALL)


# Now fix _takePicture
old_take_pic = """  Future<void> _takePicture() async {
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
  }"""

new_take_pic = """  Future<ui.Image?> _decodeXFileToUiImage(XFile? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => completer.complete(img));
    return completer.future;
  }

  Future<Uint8List?> _capturePreviewPng({XFile? rearPhoto, XFile? frontPhoto}) async {
    final overlay = Overlay.of(context);
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    // On décode directement les images pour le rendu
    final rearUiImage = await _decodeXFileToUiImage(rearPhoto);
    final frontUiImage = await _decodeXFileToUiImage(frontPhoto);

    final completer = Completer<Uint8List?>();
    final previewKey = GlobalKey();

    final entry = OverlayEntry(builder: (ctx) {
      return Positioned(
        left: -10000,
        top: -10000,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: previewKey,
            child: SizedBox(
              width: 400,
              child: _buildCompositionPreview(rearUiImage: rearUiImage, frontUiImage: frontUiImage),
            ),
          ),
        ),
      );
    });

    overlay?.insert(entry);

    // Attendre un peu que Flutter fasse le rendu complet hors écran
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final boundary = previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        completer.complete(null);
      } else {
        final ui.Image img = await boundary.toImage(pixelRatio: pixelRatio);
        final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
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
        if (mounted && outputPath != null) Navigator.of(context).pop(outputPath);
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
  }"""

if old_take_pic in text:
    text = text.replace(old_take_pic, new_take_pic)

with open("lib/be_real_capture_page.dart", "w") as f:
    f.write(text)

