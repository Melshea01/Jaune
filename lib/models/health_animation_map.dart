/// Presets mapping health percentage to animation state configurations
/// Each preset is a complete animation state across all 9 layers
class HealthAnimationMap {
  /// Health > 75%: Very happy and energetic
  static const Map<String, String> happy = {
    'global': 'bounce_light',
    'milieu': 'breathe_fast',
    'jambes': 'floating_soft',
    'bras_D': 'wave',
    'bras_G': 'wave',
    'plante': 'active',
    'yeux': 'wide',
    'bouche': 'big_smile',
    'joues': 'flushed',
  };

  /// Health > 90%: Super excited and dancing
  static const Map<String, String> superHappy = {
    'global': 'dance',
    'milieu': 'pulse',
    'jambes': 'bounce_light',
    'bras_D': 'raised',
    'bras_G': 'raised',
    'plante': 'active',
    'yeux': 'wide',
    'bouche': 'big_smile',
    'joues': 'flushed',
  };

  /// Health 50-75%: Neutral and calm
  static const Map<String, String> neutral = {
    'global': 'idle',
    'milieu': 'breathe_deep',
    'jambes': 'idle',
    'bras_D': 'idle',
    'bras_G': 'idle',
    'plante': 'idle',
    'yeux': 'open',
    'bouche': 'smile',
    'joues': 'visible',
  };

  /// Health 25-50%: Tired and slumped
  static const Map<String, String> tired = {
    'global': 'bored',
    'milieu': 'slump',
    'jambes': 'idle',
    'bras_D': 'idle',
    'bras_G': 'idle',
    'plante': 'idle',
    'yeux': 'half_closed',
    'bouche': 'open',
    'joues': 'visible',
  };

  /// Health < 25%: Very sick/critical
  static const Map<String, String> sick = {
    'global': 'crushed',
    'milieu': 'tremble',
    'jambes': 'idle',
    'bras_D': 'idle',
    'bras_G': 'idle',
    'plante': 'grounded',
    'yeux': 'closed',
    'bouche': 'sick',
    'joues': 'hidden',
  };

  /// Health 0%: Dead
  static const Map<String, String> dead = {
    'global': 'dead',
    'milieu': 'dead',
    'jambes': 'grounded',
    'bras_D': 'dead',
    'bras_G': 'dead',
    'plante': 'grounded',
    'yeux': 'dead',
    'bouche': 'dead',
    'joues': 'hidden',
  };

  /// Get animation preset based on health percentage (0-100)
  static Map<String, String> getPreset(int health) {
    if (health >= 90) {
      return superHappy;
    } else if (health >= 75) {
      return happy;
    } else if (health >= 50) {
      return neutral;
    } else if (health >= 25) {
      return tired;
    } else if (health > 0) {
      return sick;
    } else {
      return dead;
    }
  }
}
