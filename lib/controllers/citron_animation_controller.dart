import 'dart:math' as math;

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
  // Clignement fluide : la paupière suit une courbe sinus (fermeture/ouverture
  // douce) au lieu d'un aller-retour binaire, avec un double-clin occasionnel
  // — un détail qui rend le regard vivant.
  late DateTime blinkTimer;
  bool blinkActive = false;
  double blinkElapsed = 0;

  /// 0.0 = œil ouvert, 1.0 = paupière fermée (courbe lissée)
  double blinkAmount = 0;

  final math.Random _rng = math.Random();

  void _initializeBlinking() {
    blinkTimer = DateTime.now();
  }

  // ==================== Eye Saccades (regard vivant) ====================
  // Les yeux dardent vers un point aléatoire toutes les 2,5 à 7,5 s puis
  // reviennent au centre — comme un être qui observe son environnement.
  // Mouvement rapide (saccade réelle) via easing exponentiel.

  /// Décalage X courant du regard, à ajouter au drift de l'état
  double eyeLookX = 0;
  double _eyeLookTarget = 0;
  double _saccadeElapsed = 0;
  double _nextSaccadeAt = 3;

  void _updateEyeSaccades(double dtSec, bool eyesAlive) {
    if (!eyesAlive) {
      _eyeLookTarget = 0;
    } else {
      _saccadeElapsed += dtSec;
      if (_saccadeElapsed >= _nextSaccadeAt) {
        _saccadeElapsed = 0;
        _nextSaccadeAt = 2.5 + _rng.nextDouble() * 5;
        // 60% du temps : fixe un point ; sinon revient au centre
        _eyeLookTarget =
            _rng.nextDouble() < 0.6 ? (_rng.nextDouble() * 8 - 4) : 0;
      }
    }
    // Saccade rapide : convergence exponentielle vers la cible
    eyeLookX +=
        (_eyeLookTarget - eyeLookX) * (1 - math.exp(-dtSec * 12)).clamp(0, 1);
  }

  /// Update blinking animation - call every frame
  void updateBlinking(Duration dt) {
    blinkElapsed += dt.inMilliseconds / 1000.0;

    final currentYeuxState = getLayerState('yeux');
    final blinkInterval = currentYeuxState.blinkInterval;
    final blinkDuration = currentYeuxState.blinkDuration;

    // A blinkInterval >= 99 is a signal to disable blinking for this state
    // (états zen/fermés/morts : le regard revient aussi au centre)
    final eyesAlive = blinkInterval < 99;
    _updateEyeSaccades(dt.inMilliseconds / 1000.0, eyesAlive);

    if (!eyesAlive) {
      blinkActive = false;
      blinkAmount = 0;
      return;
    }

    // Active blinking state machine
    if (!blinkActive) {
      blinkAmount = 0;
      if (blinkElapsed > blinkInterval) {
        // Start blinking
        blinkActive = true;
        blinkElapsed = 0;
      }
    } else {
      // Paupière : 0 → 1 → 0 en suivant un sinus sur la durée du clin
      final progress = (blinkElapsed / blinkDuration).clamp(0.0, 1.0);
      blinkAmount = math.sin(progress * math.pi);
      if (blinkElapsed > blinkDuration) {
        blinkActive = false;
        blinkAmount = 0;
        // 20% de chance de double-clin : le prochain part presque aussitôt
        blinkElapsed =
            _rng.nextDouble() < 0.2
                ? (blinkInterval - 0.25).clamp(0.0, blinkInterval)
                : 0;
      }
    }
  }

  /// Follow-through : lors d'un changement d'état, le tronc bouge en premier,
  /// le visage suit, puis les membres, et la feuille en dernier (principe
  /// d'animation "drag" — les appendices traînent derrière la masse).
  static const Map<String, int> _followThroughDelayMs = {
    'global': 0,
    'milieu': 0,
    'yeux': 60,
    'bouche': 60,
    'joues': 60,
    'jambes': 100,
    'bras_D': 130,
    'bras_G': 130,
    'plante': 200,
  };

  /// Public API: Set animation states for multiple layers at once
  /// Example: setAnimation({'global': 'bounce_light', 'milieu': 'breathe_fast', ...})
  /// [durationMs] : durée de la transition (réactions vives = 400ms,
  /// changements d'humeur = 800ms par défaut)
  void setAnimation(Map<String, String> config, {int durationMs = 800}) {
    _resetAnimationSpeedMultiplier();
    config.forEach((layerName, state) {
      final layer = _layers[layerName];
      if (layer != null) {
        layer.set(
          state,
          durationMs: durationMs,
          delayMs: _followThroughDelayMs[layerName] ?? 0,
        );
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
      // Les animations spéciales sont des réactions : transition vive
      setAnimation(animation, durationMs: 400);
      animationSpeedMultiplier = SpecialAnimationMap.getSpeedMultiplier(name);
      notifyListeners();
      return true;
    }
    debugPrint('⚠️ Special animation not found: $name');
    return false;
  }

  // ==================== One-shot Events ====================
  // Les événements (jump_joy, drink_beer, hiccup…) se superposent à l'état
  // continu : ils renvoient des transformations additives appliquées par
  // CitronCharacter pendant leur durée, puis s'effacent.

  AnimationEvent? _activeEvent;
  int _eventStartMs = 0;

  /// Play a one-shot event animation by name
  /// Returns the AnimationEvent if found, null otherwise
  AnimationEvent? triggerEvent(String eventName) {
    final event = AnimationEvents.getEvent(eventName);
    if (event != null) {
      debugPrint(
        '🎬 Event triggered: $eventName (${event.duration.inMilliseconds}ms)',
      );
      _activeEvent = event;
      _eventStartMs = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    } else {
      debugPrint('⚠️ Event not found: $eventName');
    }
    return event;
  }

  bool get hasActiveEvent => _activeEvent != null;

  /// Transformations de l'événement en cours à l'instant [nowMs].
  /// Clés possibles : hopY, scaleX, scaleY, swayRad. Map vide si aucun.
  Map<String, double> eventTransform(int nowMs) {
    final event = _activeEvent;
    if (event == null) return const {};

    final progress = (nowMs - _eventStartMs) / event.duration.inMilliseconds;
    if (progress >= 1.0) {
      _activeEvent = null;
      return const {};
    }

    final raw = event.update(progress.clamp(0.0, 1.0)) as Map;
    return raw.map(
      (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
    );
  }

  // ==================== Idle Life ====================
  // Le secret d'un personnage attachant : il ne boucle pas la même animation
  // à l'infini. Toutes les 7 à 15 s, un micro-comportement aléatoire adapté à
  // son humeur (curiosité, petit saut, hoquet…) casse la monotonie.

  /// 'happy' | 'neutral' | 'low' | 'none' — défini par la santé courante
  String idleMood = 'neutral';

  double _idleElapsed = 0;
  double _nextIdleAt = 6;

  static const Map<String, List<String>> _idlePools = {
    'happy': ['curious', 'jump_joy', 'hiccup', 'coin_spin', 'encourage'],
    'neutral': ['curious', 'encourage', 'hiccup', 'shiver'],
    'low': ['shiver', 'curious'],
  };

  /// Update idle micro-behaviors - call every frame
  void updateIdleLife(Duration dt) {
    if (idleMood == 'none' || _activeEvent != null) return;

    _idleElapsed += dt.inMilliseconds / 1000.0;
    if (_idleElapsed < _nextIdleAt) return;

    _idleElapsed = 0;
    _nextIdleAt = 7 + _rng.nextDouble() * 8;

    final pool = _idlePools[idleMood];
    if (pool != null && pool.isNotEmpty) {
      triggerEvent(pool[_rng.nextInt(pool.length)]);
    }
  }

  /// Apply animation based on current health (0-100)
  void updateHealth(int health) {
    final preset = HealthAnimationMap.getPreset(health);
    setAnimation(preset);
  }
}
