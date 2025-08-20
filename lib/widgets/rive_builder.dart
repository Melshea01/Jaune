import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:flutter/services.dart' show rootBundle;

/// A safe Rive loader adapted from the original project. Extracted from
/// `lib/main.dart` to improve readability.
class RiveBuilder extends StatefulWidget {
  const RiveBuilder({super.key});

  @override
  State<RiveBuilder> createState() => _RiveBuilderState();
}

class _RiveBuilderState extends State<RiveBuilder> {
  late Future<String?> _loadError;

  Future<String?> _tryLoadAndParse() async {
    try {
      final data = await rootBundle.load('assets/jaune.riv');
      try {
        // Ensure the Rive runtime is initialized before importing the file.
        // This avoids the warning: "RiveFile.import called before RiveFile.initialize()".
        await rive.RiveFile.initialize();

        // parse to detect errors early
        rive.RiveFile.import(data);
        return null; // success
      } catch (e, st) {
        final msg = 'Rive parse error: $e\n$st';
        debugPrint(msg);
        return msg;
      }
    } catch (e, st) {
      final msg = 'Asset load error: $e\n$st';
      debugPrint(msg);
      return msg;
    }
  }

  @override
  void initState() {
    super.initState();

    _loadError = _tryLoadAndParse();
  }

  Widget _errorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/avatar.png', width: 120, height: 120),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.9 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadError,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Parsing failed: show error details
          return _errorWidget(snapshot.data!);
        }

        // Parsed OK: return the Rive animation. Use a try/catch to fallback at runtime.
        try {
          return rive.RiveAnimation.asset(
            'assets/jaune.riv',
            fit: BoxFit.contain,
            alignment: Alignment.center,
          );
        } catch (e, st) {
          final msg = 'Rive runtime error: $e\n$st';
          debugPrint(msg);
          return _errorWidget(msg);
        }
      },
    );
  }
}
