import 'package:flutter/foundation.dart';
import '../models/animation_layer_state.dart';
import '../models/health_animation_map.dart';
import '../models/special_animation_map.dart';
import '../models/animation_events.dart';
import '../services/layer_controller.dart';

/// Central orchestrator for all 9 animation layers
/// Manages state transitions and provides public API for animation control
class CitronAnimationController extends ChangeNotifier {
  late LayerController layerGlobal;
  late LayerController layerMilieu;
  late LayerController layerJambes;
  late LayerController layerBrasD;
  late LayerController layerBrasG;
  late LayerController layerPlante;
  late LayerController layerYeux;
  late LayerController layerBouche;
  late LayerController layerJoues;

  CitronAnimationController() {
    _initializeLayers();
    _initializeBlinking();
  }

  void _initializeLayers() {
    layerGlobal = LayerController(
      stateDict: layerStates['global']!,
      defaultKey: 'idle',
    );
    layerMilieu = LayerController(
      stateDict: layerStates['milieu']!,
      defaultKey: 'idle',
    );
    layerJambes = LayerController(
      stateDict: layerStates['jambes']!,
      defaultKey: 'idle',
    );
    layerBrasD = LayerController(
      stateDict: layerStates['bras_D']!,
      defaultKey: 'idle',
    );
    layerBrasG = LayerController(
      stateDict: layerStates['bras_G']!,
      defaultKey: 'idle',
    );
    layerPlante = LayerController(
      stateDict: layerStates['plante']!,
      defaultKey: 'idle',
    );
    layerYeux = LayerController(
      stateDict: layerStates['yeux']!,
      defaultKey: 'open',
    );
    layerBouche = LayerController(
      stateDict: layerStates['bouche']!,
      defaultKey: 'smile',
    );
    layerJoues = LayerController(
      stateDict: layerStates['joues']!,
      defaultKey: 'visible',
    );
  }

  // ==================== Eye Blinking State Machine ====================
  late DateTime blinkTimer;
  bool blinkActive = false;
  double blinkElapsed = 0;

  void _initializeBlinking() {
    blinkTimer = DateTime.now();
  }

  /// Update blinking animation - call every frame
  void updateBlinking(Duration dt) {
    blinkElapsed += dt.inMilliseconds / 1000;

    final currentYeuxState = layerYeux.get(DateTime.now().millisecondsSinceEpoch);
    final blinkInterval = currentYeuxState.blinkInterval;
    final blinkDuration = currentYeuxState.blinkDuration;

    if (blinkInterval < 99) {
      // Active blinking
      if (blinkElapsed > blinkInterval) {
        if (!blinkActive) {
          blinkActive = true;
          blinkElapsed = 0;
        }
      }

      if (blinkActive && blinkElapsed > blinkDuration) {
        blinkActive = false;
        blinkElapsed = 0;
      }
    }
  }

  /// Public API: Set animation states for multiple layers at once
  /// Example: setAnimation({'global': 'bounce_light', 'milieu': 'breathe_fast', ...})
  void setAnimation(Map<String, String> config) {
    for (final entry in config.entries) {
      final layer = entry.key;
      final state = entry.value;

      switch (layer) {
        case 'global':
          layerGlobal.set(state);
        case 'milieu':
          layerMilieu.set(state);
        case 'jambes':
          layerJambes.set(state);
        case 'bras_D':
          layerBrasD.set(state);
        case 'bras_G':
          layerBrasG.set(state);
        case 'plante':
          layerPlante.set(state);
        case 'yeux':
          layerYeux.set(state);
        case 'bouche':
          layerBouche.set(state);
        case 'joues':
          layerJoues.set(state);
        default:
          debugPrint('⚠️ Unknown layer: $layer');
      }
    }

    notifyListeners();
  }

  /// Get current animation state for a specific layer
  AnimationLayerState getLayerState(String layer) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    return switch (layer) {
      'global' => layerGlobal.get(nowMs),
      'milieu' => layerMilieu.get(nowMs),
      'jambes' => layerJambes.get(nowMs),
      'bras_D' => layerBrasD.get(nowMs),
      'bras_G' => layerBrasG.get(nowMs),
      'plante' => layerPlante.get(nowMs),
      'yeux' => layerYeux.get(nowMs),
      'bouche' => layerBouche.get(nowMs),
      'joues' => layerJoues.get(nowMs),
      _ => throw ArgumentError('Unknown layer: $layer'),
    };
  }

  /// Check if any layer is currently transitioning
  bool get isAnimating {
    return layerGlobal.isTransitioning ||
        layerMilieu.isTransitioning ||
        layerJambes.isTransitioning ||
        layerBrasD.isTransitioning ||
        layerBrasG.isTransitioning ||
        layerPlante.isTransitioning ||
        layerYeux.isTransitioning ||
        layerBouche.isTransitioning ||
        layerJoues.isTransitioning;
  }

  // ==================== Special Animations API ====================

  /// Play a special behavior animation by name
  /// Returns true if animation was found and applied
  bool playSpecialAnimation(String name) {
    final animation = SpecialAnimationMap.getAnimation(name);
    if (animation != null) {
      setAnimation(animation);
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
      debugPrint('🎬 Event triggered: $eventName (${event.duration.inMilliseconds}ms)');
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


