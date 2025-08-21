// Minimal Dart utility to predict using the trimmed `flutter_models.json` structure.
// Usage: provide the parsed JSON (Map<String, dynamic>) loaded from assets or network,
// then call `ModelPredictor.predict(modelsJson, 'Homme', 1, 12.5)`.

import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ModelPredictor {
  // Populated by loadModels(). Null until successfully loaded.
  static Map<String, dynamic>? modelsJson;

  /// Load and decode the JSON model file from assets.
  /// Call this once during app startup before calling `predict`.
  static Future<void> loadModels({
    String assetPath = 'assets/risk_models.json',
  }) async {
    try {
      final s = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) {
        modelsJson = decoded;
      } else {
        modelsJson = <String, dynamic>{};
        throw StateError('Models JSON is not a Map');
      }
    } catch (e) {
      // Keep modelsJson non-null but empty to avoid repeated null checks.
      modelsJson = <String, dynamic>{};
      // Surface the error to the caller via exception.
      rethrow;
    }
  }

  /// Predict value for given sheet, y (group) and x using the loaded models JSON.
  static double predict(String sheet, int y, int x) {
    if (modelsJson == null || modelsJson!.isEmpty) {
      throw StateError(
        'ModelPredictor not initialized or models empty. Call loadModels() first.',
      );
    }
    if (!modelsJson!.containsKey(sheet)) {
      throw ArgumentError('Sheet not found: $sheet');
    }
    final sheetObj = modelsJson![sheet] as Map<String, dynamic>;
    final perY = (sheetObj['per_y_best'] ?? {}) as Map<String, dynamic>;
    final yKey = y.toString();
    if (!perY.containsKey(yKey)) {
      throw ArgumentError('Group Y not found: $y in sheet $sheet');
    }
    final yInfo = perY[yKey] as Map<String, dynamic>;
    final modelExport = (yInfo['model_export'] ?? {}) as Map<String, dynamic>;
    if (modelExport.isEmpty) {
      throw ArgumentError('No model_export for $sheet Y=$y');
    }

    final coefDyn = modelExport['coef'];
    final interceptDyn = modelExport['intercept'];

    double intercept = 0.0;
    if (interceptDyn != null) {
      intercept =
          (interceptDyn is num)
              ? interceptDyn.toDouble()
              : double.parse(interceptDyn.toString());
    }

    if (coefDyn is List) {
      double sum = intercept;
      for (int i = 0; i < coefDyn.length; ++i) {
        final c = coefDyn[i];
        final coef = (c is num) ? c.toDouble() : double.parse(c.toString());
        final power = i + 1; // coef[0] * x^1, coef[1] * x^2, ...
        sum += coef * math.pow(x, power);
      }
      return sum;
    }

    throw ArgumentError('Unsupported model_export format for $sheet Y=$y');
  }
}

// Example quick test (uncomment to run in a Dart REPL):
//
// print(ModelPredictor.predict(parsed, 'Homme', 1, 10.0));
