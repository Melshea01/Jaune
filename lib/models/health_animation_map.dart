/// Presets mapping health percentage to animation state configurations
/// Each preset is a complete animation state across all 9 layers
///
/// Philosophie (style Duolingo) : chaque palier de santé doit raconter une
/// émotion lisible en 1 seconde, avec une intensité graduée — et rester
/// agréable à regarder en boucle pendant des minutes.
class HealthAnimationMap {
  /// Health > 90%: Super excited and dancing — l'apothéose, réservée au top.
  /// Seul preset avec big_smile + yeux wide + double bras levés : il doit
  /// rester exceptionnel pour être désirable.
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

  /// Health 75-90%: Happy and energetic.
  /// Avant : double 'wave' permanent (frénétique, fatigant à regarder) et
  /// big_smile identique au palier supérieur. Maintenant : bras 'cheer'
  /// (semi-levés, ondulation douce) et sourire normal — l'utilisateur sent
  /// la différence avec le palier >90%.
  static const Map<String, String> happy = {
    'global': 'bounce_light',
    'milieu': 'breathe_fast',
    'jambes': 'floating_soft',
    'bras_D': 'cheer',
    'bras_G': 'cheer',
    'plante': 'active',
    'yeux': 'open',
    'bouche': 'smile',
    'joues': 'flushed',
  };

  /// Health 50-75%: Neutral and calm.
  /// Avant : bouche 'sick' (moue inversée) alors qu'on est au-dessus de 50% !
  /// Un citron à 60% de vie doit rester sympathique : sourire simple.
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

  /// Health 25-50%: Tired and slumped.
  /// Avant : milieu 'slump' (penché à 50° — il tombait), bouche 'open' béante.
  /// Maintenant : 'weary' (10°, respiration lourde), yeux 'sleepy' (mi-clos
  /// avec clignements lents), bouche neutre, et la feuille 'curl' qui retombe
  /// — la plante raconte la fatigue en narration secondaire.
  static const Map<String, String> tired = {
    'global': 'bored',
    'milieu': 'weary',
    'jambes': 'idle',
    'bras_D': 'idle',
    'bras_G': 'idle',
    'plante': 'curl',
    'yeux': 'sleepy',
    'bouche': 'neutral',
    'joues': 'blinking',
  };

  /// Health < 25%: Very sick/critical.
  /// Avant : yeux 'closed' (il avait l'air endormi, pas malade) et membres
  /// inertes. Maintenant : 'squint' (souffrance consciente), bras tremblants,
  /// jambes flageolantes — on a envie de le sauver.
  static const Map<String, String> sick = {
    'global': 'crushed',
    'milieu': 'tremble',
    'jambes': 'sick',
    'bras_D': 'trembling',
    'bras_G': 'trembling',
    'plante': 'grounded',
    'yeux': 'squint',
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
