import 'package:flutter/foundation.dart';
import '../models/animation_layer_state.dart';

/// Controls animation transitions for a single layer
/// Manages smooth interpolation between states over 1000ms
class LayerController {
  final Map<String, AnimationLayerState> stateDict;
  final String defaultKey;
  late AnimationLayerState _prev;
  late AnimationLayerState _target;
  late int _transStart;

  /// Durée de la transition en cours — les changements d'humeur sont lents,
  /// les réactions (tap, conso) doivent être vives.
  int _transitionMs = 800;

  LayerController({required this.stateDict, required this.defaultKey}) {
    _prev = stateDict[defaultKey]!;
    _target = stateDict[defaultKey]!;
    _transStart = 0;
  }

  /// Set a new animation state for this layer
  /// Transitions smoothly from current to new state
  /// [delayMs] retarde le départ — permet le follow-through entre couches
  /// (le corps bouge d'abord, les membres et la feuille suivent)
  void set(String key, {int durationMs = 800, int delayMs = 0}) {
    if (!stateDict.containsKey(key)) {
      debugPrint('⚠️ Unknown layer state: $key');
      return;
    }

    // Interpolate previous → target, then target → new state
    _prev = get(DateTime.now().millisecondsSinceEpoch);
    _target = stateDict[key]!;
    _transitionMs = durationMs;
    _transStart = DateTime.now().millisecondsSinceEpoch + delayMs;
  }

  /// Get current interpolated state at given timestamp
  AnimationLayerState get(int nowMs) {
    if (_transStart == 0) {
      return _target;
    }

    final elapsed = nowMs - _transStart;
    final t = (elapsed / _transitionMs).clamp(0.0, 1.0);

    // Apply easeInOut curve for smooth animation
    final eased = _easeInOut(t);

    return AnimationLayerState.lerp(_prev, _target, eased);
  }

  /// Cubic ease-in-out easing function
  /// Creates smooth, natural-looking transitions
  static double _easeInOut(double t) {
    if (t < 0.5) {
      return 2 * t * t;
    } else {
      return -1 + (4 - 2 * t) * t;
    }
  }

  /// Check if animation is still transitioning
  bool get isTransitioning {
    if (_transStart == 0) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _transStart;
    return elapsed < _transitionMs;
  }
}
