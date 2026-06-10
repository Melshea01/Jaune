/// Special behavior animations beyond health-based presets
/// Includes context-specific animations for various game scenarios
class SpecialAnimationMap {
  /// Per-preset tempo tuning. Values multiply the controller global speed.
  static const Map<String, double> speedMultipliers = {
    'tipsy': 0.95,
    'drunk': 0.90,
    'wasted': 0.80,
    'hungover': 0.75,
    'recovery': 0.90,
    'dehydrated': 0.85,
    'zen': 0.70,
    'asleep': 0.60,
    'pulse': 1.15,
    'loading': 0.85,
    'bored': 0.80,
    'digest': 0.75,
    'secretDance': 1.35,
    'greeting': 1.05,
    'walking': 1.00,
    'sprinting': 1.20,
    'panic': 1.15,
    'workout': 1.05,
    'freezing': 0.85,
    'overheating': 0.90,
    'levitation': 0.95,
  };

  static double getSpeedMultiplier(String name) {
    return speedMultipliers[name] ?? 1.0;
  }

  // ─── Alcohol & Intoxication States ───────────────────────────────────

  /// Tipsy state (light intoxication - 1-2 drinks)
  /// Yeux 'drunk' plutôt que 'half_closed' : le regard flotte et cligne
  /// lentement au lieu de se figer — bien plus éméché.
  static const Map<String, String> tipsy = {
    'global': 'idle',
    'milieu': 'sway_tipsy',
    'jambes': 'drunk',
    'bras_D': 'ballant',
    'bras_G': 'ballant',
    'plante': 'breeze_fast',
    'yeux': 'drunk',
    'bouche': 'drunk_smile',
    'joues': 'flushed',
  };

  /// Drunk state (severe intoxication - dangerous limit)
  static const Map<String, String> drunk = {
    'global': 'idle',
    'milieu': 'sway_drunk',
    'jambes': 'drunk',
    'bras_D': 'ballant',
    'bras_G': 'ballant',
    'plante': 'wasted',
    'yeux': 'drunk',
    'bouche': 'drunk_smile',
    'joues': 'flushed',
  };

  /// Wasted state (unconscious on table/ground)
  static const Map<String, String> wasted = {
    'global': 'idle',
    'milieu': 'sided',
    'jambes': 'spread',
    'bras_D': 'dead',
    'bras_G': 'dead',
    'plante': 'dead',
    'yeux': 'closed',
    'bouche': 'open',
    'joues': 'flushed',
  };

  /// Hangover state (morning after)
  static const Map<String, String> hungover = {
    'global': 'crushed',
    'milieu': 'crushed_tremble',
    'jambes': 'bent',
    'bras_D': 'trembling',
    'bras_G': 'trembling',
    'plante': 'curl',
    'yeux': 'squint',
    'bouche': 'sad',
    'joues': 'hidden',
  };

  // ─── Recovery & Wellness States ──────────────────────────────────────

  /// Recovery state (convalescence - struggling to stand)
  static const Map<String, String> recovery = {
    'global': 'struggle_up',
    'milieu': 'struggle',
    'jambes': 'sick',
    'bras_D': 'ballant',
    'bras_G': 'ballant',
    'plante': 'breeze_soft',
    'yeux': 'half_closed',
    'bouche': 'neutral',
    'joues': 'hidden',
  };

  /// Dehydrated state (thirsty - panting)
  static const Map<String, String> dehydrated = {
    'global': 'idle',
    'milieu': 'panting',
    'jambes': 'drunk',
    'bras_D': 'trembling',
    'bras_G': 'trembling',
    'plante': 'curl',
    'yeux': 'panting',
    'bouche': 'open',
    'joues': 'hidden',
  };

  /// Zen state (perfect control - levitation)
  static const Map<String, String> zen = {
    'global': 'levitate',
    'milieu': 'zen',
    'jambes': 'floating',
    'bras_D': 'soft',
    'bras_G': 'soft',
    'plante': 'breeze_soft',
    'yeux': 'zen',
    'bouche': 'smile',
    'joues': 'visible',
  };

  /// Asleep state (deep sleep - night)
  static const Map<String, String> asleep = {
    'global': 'grounded',
    'milieu': 'sleep',
    'jambes': 'spread',
    'bras_D': 'dead',
    'bras_G': 'dead',
    'plante': 'curl',
    'yeux': 'closed',
    'bouche': 'neutral',
    'joues': 'hidden',
  };

  // ─── Event & Achievement States ──────────────────────────────────────

  /// Pulse state (heartbeat - record achieved)
  static const Map<String, String> pulse = {
    'global': 'pulse',
    'milieu': 'pulse',
    'jambes': 'bounce',
    'bras_D': 'soft',
    'bras_G': 'soft',
    'plante': 'breeze_soft',
    'yeux': 'wide',
    'bouche': 'big_smile',
    'joues': 'flushed',
  };

  /// Loading state (waiting - pendulum effect)
  static const Map<String, String> loading = {
    'global': 'pendulum',
    'milieu': 'pendulum',
    'jambes': 'spread',
    'bras_D': 'ballant',
    'bras_G': 'ballant',
    'plante': 'wind',
    'yeux': 'open',
    'bouche': 'neutral',
    'joues': 'hidden',
  };

  /// Bored state (impatience - app open 30s)
  static const Map<String, String> boredState = {
    'global': 'bored',
    'milieu': 'bored',
    'jambes': 'bent',
    'bras_D': 'ballant',
    'bras_G': 'ballant',
    'plante': 'curl',
    'yeux': 'half_closed',
    'bouche': 'open',
    'joues': 'hidden',
  };

  /// Digest state (after meal - full and sleepy)
  static const Map<String, String> digest = {
    'global': 'digest',
    'milieu': 'digest',
    'jambes': 'spread',
    'bras_D': 'soft',
    'bras_G': 'soft',
    'plante': 'breeze_soft',
    'yeux': 'half_closed',
    'bouche': 'smile',
    'joues': 'flushed',
  };

  /// Secret dance (easter egg - tap 10x)
  static const Map<String, String> secretDance = {
    'global': 'run',
    'milieu': 'breathe_fast',
    'jambes': 'run',
    'bras_D': 'wave',
    'bras_G': 'wave',
    'plante': 'wind',
    'yeux': 'wide',
    'bouche': 'open',
    'joues': 'visible',
  };

  // ─── Movement & Gesture States ──────────────────────────────────────

  /// Greeting state (welcome - waving)
  static const Map<String, String> greeting = {
    'global': 'bounce_light',
    'milieu': 'idle',
    'jambes': 'idle',
    'bras_D': 'wave',
    'bras_G': 'soft',
    'plante': 'breeze_soft',
    'yeux': 'squint',
    'bouche': 'big_smile',
    'joues': 'visible',
  };

  /// Walking state (steady movement)
  static const Map<String, String> walking = {
    'global': 'walk_normal',
    'milieu': 'breathe_fast',
    'jambes': 'walk_normal',
    'bras_D': 'walk_normal',
    'bras_G': 'walk_normal',
    'plante': 'wind',
    'yeux': 'open',
    'bouche': 'smile',
    'joues': 'visible',
  };

  /// Sprinting state (cardio - late!)
  static const Map<String, String> sprinting = {
    'global': 'run',
    'milieu': 'sprint',
    'jambes': 'run',
    'bras_D': 'run',
    'bras_G': 'run',
    'plante': 'wind',
    'yeux': 'wide',
    'bouche': 'open',
    'joues': 'flushed',
  };

  /// Panic mode (critical thirst)
  static const Map<String, String> panicMode = {
    'global': 'tremble',
    'milieu': 'struggle_up',
    'jambes': 'spread',
    'bras_D': 'panic',
    'bras_G': 'panic',
    'plante': 'startle',
    'yeux': 'shock',
    'bouche': 'exhausted',
    'joues': 'hidden',
  };

  /// Workout state (weights - muscles straining)
  static const Map<String, String> workout = {
    'global': 'idle',
    'milieu': 'strain',
    'jambes': 'spread',
    'bras_D': 'raised',
    'bras_G': 'raised',
    'plante': 'breeze',
    'yeux': 'wide',
    'bouche': 'sick',
    'joues': 'flushed',
  };

  // ─── Extreme Environmental States ────────────────────────────────────

  /// Freezing state (cold - hugging self)
  static const Map<String, String> freezing = {
    'global': 'tremble',
    'milieu': 'crushed_tremble',
    'jambes': 'bent',
    'bras_D': 'crossed',
    'bras_G': 'crossed',
    'plante': 'curl',
    'yeux': 'half_closed',
    'bouche': 'sad',
    'joues': 'hidden',
  };

  /// Overheating state (heat - collapsed)
  static const Map<String, String> overheating = {
    'global': 'idle',
    'milieu': 'panting',
    'jambes': 'spread',
    'bras_D': 'dead',
    'bras_G': 'dead',
    'plante': 'curl',
    'yeux': 'half_closed',
    'bouche': 'open',
    'joues': 'flushed',
  };

  /// Levitation state (mystique - floating)
  static const Map<String, String> levitation = {
    'global': 'levitate',
    'milieu': 'zen',
    'jambes': 'floating',
    'bras_D': 'wave',
    'bras_G': 'wave',
    'plante': 'breeze_soft',
    'yeux': 'zen',
    'bouche': 'smile',
    'joues': 'visible',
  };

  /// Get special animation by name
  static Map<String, String>? getAnimation(String name) {
    switch (name) {
      case 'tipsy':
        return tipsy;
      case 'drunk':
        return drunk;
      case 'wasted':
        return wasted;
      case 'hungover':
        return hungover;
      case 'recovery':
        return recovery;
      case 'dehydrated':
        return dehydrated;
      case 'zen':
        return zen;
      case 'asleep':
        return asleep;
      case 'pulse':
        return pulse;
      case 'loading':
        return loading;
      case 'bored':
        return boredState;
      case 'digest':
        return digest;
      case 'secretDance':
        return secretDance;
      case 'greeting':
        return greeting;
      case 'walking':
        return walking;
      case 'sprinting':
        return sprinting;
      case 'panic':
        return panicMode;
      case 'workout':
        return workout;
      case 'freezing':
        return freezing;
      case 'overheating':
        return overheating;
      case 'levitation':
        return levitation;
      default:
        return null;
    }
  }
}
