import 'package:flutter/foundation.dart';
import '../models/animation_layer_state.dart';
import '../models/health_animation_map.dart';
import '../models/special_animation_map.dart';
import '../models/animation_events.dart';
import '../services/layer_controller.dart';

/// Central orchestrator for all animation layers
/// Manages state transitions and provides a public API for animation control
class CitronAnimationController extends ChangeNotifier {
  final Map<String, LayerController> _layers = {};

  // Define layer names and their default states
  static const Map<String, String> _layerDefaults = {
    'global': 'idle',
    'milieu': 'idle',
    'jambes': 'idle',
    'bras_D': 'idle',
    'bras_G': 'idle',
    'plante': 'idle',
    'yeux': 'open',
    'bouche': 'smile',
    'joues': 'visible',
  };

  // Public accessors for each layer
  LayerController get layerGlobal => _layers['global']!;
  LayerController get layerMilieu => _layers['milieu']!;
  LayerController get layerJambes => _layers['jambes']!;
  LayerController get layerBrasD => _layers['bras_D']!;
  LayerController get layerBrasG => _layers['bras_G']!;
  LayerController get layerPlante => _layers['plante']!;
  LayerController get layerYeux => _layers['yeux']!;
  LayerController get layerBouche => _layers['bouche']!;
  LayerController get layerJoues => _layers['joues']!;

  CitronAnimationController() {
    _initializeLayers();
    _initializeBlinking();
  }

  /// Global speed factor applied to all animation phases.
  /// Values < 1.0 slow animations, > 1.0 speed them up.
  double speedFactor = 0.50;

  /// Additional tempo applied to the currently active preset.
  /// Defaults to 1.0 and is tuned per special animation.
  double animationSpeedMultiplier = 1.0;

  void _resetAnimationSpeedMultiplier() {
    animationSpeedMultiplier = 1.0;
  }

  /// Update the global speed factor at runtime and notify listeners.
  void setSpeedFactor(double factor) {
    speedFactor = factor.clamp(0.1, 4.0);
    notifyListeners();
  }

  void _initializeLayers() {
    for (final entry in _layerDefaults.entries) {
      final layerName = entry.key;
      final defaultState = entry.value;
      if (layerStates.containsKey(layerName)) {
        _layers[layerName] = LayerController(
          stateDict: layerStates[layerName]!,
          defaultKey: defaultState,
        );
      } else {
        debugPrint(
          '⚠️ Configuration for layer "$layerName" not found in layerStates.',
        );
      }
    }
  }

  // ==================== Eye Blinking State Machine ====================
  // This logic remains complex and could be a separate state machine class.
  // For now, we'll keep it as is but acknowledge it's an area for future improvement.
  late DateTime blinkTimer;
  bool blinkActive = false;
  double blinkElapsed = 0;

  void _initializeBlinking() {
    blinkTimer = DateTime.now();
  }

  /// Update blinking animation - call every frame
  void updateBlinking(Duration dt) {
    blinkElapsed += dt.inMilliseconds / 1000.0;

    final currentYeuxState = getLayerState('yeux');
    final blinkInterval = currentYeuxState.blinkInterval;
    final blinkDuration = currentYeuxState.blinkDuration;

    // A blinkInterval >= 99 is a signal to disable blinking for this state
    if (blinkInterval >= 99) {
      blinkActive = false;
      return;
    }

    // Active blinking state machine
    if (!blinkActive) {
      if (blinkElapsed > blinkInterval) {
        // Start blinking
        blinkActive = true;
        blinkElapsed = 0;
        // Note: This doesn't actually trigger a state change on the layer.
        // The Rive animation likely handles the visual blink based on a boolean.
      }
    } else {
      if (blinkElapsed > blinkDuration) {
        // Stop blinking
        blinkActive = false;
        blinkElapsed = 0;
      }
    }
  }

  /// Public API: Set animation states for multiple layers at once
  /// Example: setAnimation({'global': 'bounce_light', 'milieu': 'breathe_fast', ...})
  void setAnimation(Map<String, String> config) {
    _resetAnimationSpeedMultiplier();
    config.forEach((layerName, state) {
      final layer = _layers[layerName];
      if (layer != null) {
        layer.set(state);
      } else {
        debugPrint('⚠️ Attempted to set state for unknown layer: $layerName');
      }
    });
    notifyListeners();
  }

  /// Get current animation state for a specific layer
  AnimationLayerState getLayerState(String layerName) {
    final layer = _layers[layerName];
    if (layer == null) {
      throw ArgumentError('Unknown layer: $layerName');
    }
    return layer.get(DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if any layer is currently transitioning
  bool get isAnimating {
    return _layers.values.any((layer) => layer.isTransitioning);
  }

  // ==================== Special Animations API ====================

  /// Play a special behavior animation by name
  /// Returns true if animation was found and applied
  bool playSpecialAnimation(String name) {
    final animation = SpecialAnimationMap.getAnimation(name);
    if (animation != null) {
      setAnimation(animation);
      animationSpeedMultiplier = SpecialAnimationMap.getSpeedMultiplier(name);
      notifyListeners();
      return true;
    }
    debugPrint('⚠️ Special animation not found: $name');
    return false;
  }

  /// Play a one-shot event animation by name
  /// Returns the AnimationEvent if found, null otherwise
  AnimationEvent? triggerEvent(String eventName) {
    final event = AnimationEvents.getEvent(eventName);
    if (event != null) {
      debugPrint(
        '🎬 Event triggered: $eventName (${event.duration.inMilliseconds}ms)',
      );
      // Event can be further handled by CitronCharacter widget for overlay
    } else {
      debugPrint('⚠️ Event not found: $eventName');
    }
    return event;
  }

  /// Apply animation based on current health (0-100)
  void updateHealth(int health) {
    final preset = HealthAnimationMap.getPreset(health);
    setAnimation(preset);
  }
}
