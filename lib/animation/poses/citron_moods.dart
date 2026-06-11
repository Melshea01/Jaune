/// Style visuel d'une humeur : couleur, lumière et particules.
/// Ces canaux sont pilotés par les springs du moteur — les transitions
/// de teinte glissent avec les mêmes garanties que le mouvement.
class MoodStyle {
  /// 0 = citron éclatant, 1 = gris mort (désaturation + pâleur verdâtre)
  final double tint;

  /// 0..1 : rougeur d'ivresse (boost du canal rouge)
  final double flush;

  /// 0..1 : intensité de l'aura dorée
  final double glow;

  /// 'none' | 'sparkles' | 'bubbles' | 'sweat'
  final String particles;

  const MoodStyle({
    this.tint = 0,
    this.flush = 0,
    this.glow = 0,
    this.particles = 'none',
  });

  static const neutral = MoodStyle();
}

/// Recettes d'humeur : assignation d'une pose nommée à chacune des 9 couches.
///
/// Remplace `health_animation_map.dart` et `special_animation_map.dart`.
/// Philosophie (style Duolingo) : chaque palier raconte une émotion lisible
/// en 1 seconde, avec une intensité graduée, agréable à regarder en boucle.
class CitronMoods {
  /// Pose de repos complète (état initial du moteur)
  static const Map<String, String> defaults = {
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

  // ─── Presets de santé ────────────────────────────────────────────────

  /// > 90 % : l'apothéose — seul preset avec big_smile + yeux wide,
  /// il doit rester exceptionnel pour être désirable
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

  /// 75-90 % : joyeux — bras 'cheer' (semi-levés, doux), sourire normal :
  /// la progression vers 90 % se sent
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

  /// 50-75 % : calme et content (au-dessus de 50 %, il doit sourire)
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

  /// 25-50 % : fatigué — weary (10°), yeux sleepy, feuille qui retombe
  /// (narration secondaire de la fatigue)
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

  /// < 25 % : malade — squint (souffrance consciente), membres tremblants :
  /// on a envie de le sauver
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

  /// 0 %
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

  /// Preset selon la santé (0-100)
  static Map<String, String> healthPreset(int health) {
    if (health >= 90) return superHappy;
    if (health >= 75) return happy;
    if (health >= 50) return neutral;
    if (health >= 25) return tired;
    if (health > 0) return sick;
    return dead;
  }

  /// Style visuel selon la santé : le citron rayonne en pleine forme,
  /// pâlit en fatigue, verdit malade, grise mort.
  static MoodStyle healthStyle(int health) {
    if (health >= 90) {
      return const MoodStyle(glow: 1.0, particles: 'sparkles');
    }
    if (health >= 75) return const MoodStyle(glow: 0.35);
    if (health >= 50) return const MoodStyle(tint: 0.12);
    if (health >= 25) return const MoodStyle(tint: 0.38);
    if (health > 0) return const MoodStyle(tint: 0.65);
    return const MoodStyle(tint: 1.0);
  }

  /// Styles visuels des animations spéciales (les absentes = neutre)
  static const Map<String, MoodStyle> specialStyles = {
    'tipsy': MoodStyle(flush: 0.5, particles: 'bubbles'),
    'drunk': MoodStyle(flush: 0.8, particles: 'bubbles'),
    'wasted': MoodStyle(flush: 0.6, tint: 0.3),
    'hungover': MoodStyle(tint: 0.55),
    'recovery': MoodStyle(tint: 0.35),
    'dehydrated': MoodStyle(tint: 0.3, particles: 'sweat'),
    'zen': MoodStyle(glow: 0.5),
    'asleep': MoodStyle(tint: 0.2),
    'pulse': MoodStyle(glow: 0.7, particles: 'sparkles'),
    'secretDance': MoodStyle(glow: 0.8, particles: 'sparkles'),
    'greeting': MoodStyle(glow: 0.25),
    'sprinting': MoodStyle(flush: 0.3, particles: 'sweat'),
    'panic': MoodStyle(particles: 'sweat'),
    'workout': MoodStyle(flush: 0.4, particles: 'sweat'),
    'freezing': MoodStyle(tint: 0.4),
    'overheating': MoodStyle(flush: 0.3, particles: 'sweat'),
    'levitation': MoodStyle(glow: 0.6),
  };

  // ─── Animations spéciales (réactions, contextes) ─────────────────────

  static const Map<String, Map<String, String>> specials = {
    // Alcool — yeux 'drunk' dès tipsy : le regard flotte et cligne lentement
    'tipsy': {
      'global': 'idle',
      'milieu': 'sway_tipsy',
      'jambes': 'drunk',
      'bras_D': 'ballant',
      'bras_G': 'ballant',
      'plante': 'breeze_fast',
      'yeux': 'drunk',
      'bouche': 'drunk_smile',
      'joues': 'flushed',
    },
    'drunk': {
      'global': 'idle',
      'milieu': 'sway_drunk',
      'jambes': 'drunk',
      'bras_D': 'ballant',
      'bras_G': 'ballant',
      'plante': 'wasted',
      'yeux': 'drunk',
      'bouche': 'drunk_smile',
      'joues': 'flushed',
    },
    'wasted': {
      'global': 'idle',
      'milieu': 'sided',
      'jambes': 'spread',
      'bras_D': 'dead',
      'bras_G': 'dead',
      'plante': 'dead',
      'yeux': 'closed',
      'bouche': 'open',
      'joues': 'flushed',
    },
    'hungover': {
      'global': 'crushed',
      'milieu': 'crushed_tremble',
      'jambes': 'bent',
      'bras_D': 'trembling',
      'bras_G': 'trembling',
      'plante': 'curl',
      'yeux': 'squint',
      'bouche': 'sad',
      'joues': 'hidden',
    },
    // Récupération & bien-être
    'recovery': {
      'global': 'struggle_up',
      'milieu': 'struggle',
      'jambes': 'sick',
      'bras_D': 'ballant',
      'bras_G': 'ballant',
      'plante': 'breeze_soft',
      'yeux': 'half_closed',
      'bouche': 'neutral',
      'joues': 'hidden',
    },
    'dehydrated': {
      'global': 'idle',
      'milieu': 'panting',
      'jambes': 'drunk',
      'bras_D': 'trembling',
      'bras_G': 'trembling',
      'plante': 'curl',
      'yeux': 'panting',
      'bouche': 'open',
      'joues': 'hidden',
    },
    'zen': {
      'global': 'levitate',
      'milieu': 'zen',
      'jambes': 'floating',
      'bras_D': 'soft',
      'bras_G': 'soft',
      'plante': 'breeze_soft',
      'yeux': 'zen',
      'bouche': 'smile',
      'joues': 'visible',
    },
    'asleep': {
      'global': 'grounded',
      'milieu': 'sleep',
      'jambes': 'spread',
      'bras_D': 'dead',
      'bras_G': 'dead',
      'plante': 'curl',
      'yeux': 'closed',
      'bouche': 'neutral',
      'joues': 'hidden',
    },
    // Événements & exploits
    'pulse': {
      'global': 'pulse',
      'milieu': 'pulse',
      'jambes': 'bounce',
      'bras_D': 'soft',
      'bras_G': 'soft',
      'plante': 'breeze_soft',
      'yeux': 'wide',
      'bouche': 'big_smile',
      'joues': 'flushed',
    },
    'loading': {
      'global': 'pendulum',
      'milieu': 'pendulum',
      'jambes': 'spread',
      'bras_D': 'ballant',
      'bras_G': 'ballant',
      'plante': 'wind',
      'yeux': 'open',
      'bouche': 'neutral',
      'joues': 'hidden',
    },
    'bored': {
      'global': 'bored',
      'milieu': 'bored',
      'jambes': 'bent',
      'bras_D': 'ballant',
      'bras_G': 'ballant',
      'plante': 'curl',
      'yeux': 'half_closed',
      'bouche': 'open',
      'joues': 'hidden',
    },
    'digest': {
      'global': 'digest',
      'milieu': 'digest',
      'jambes': 'spread',
      'bras_D': 'soft',
      'bras_G': 'soft',
      'plante': 'breeze_soft',
      'yeux': 'half_closed',
      'bouche': 'smile',
      'joues': 'flushed',
    },
    'secretDance': {
      'global': 'run',
      'milieu': 'breathe_fast',
      'jambes': 'run',
      'bras_D': 'wave',
      'bras_G': 'wave',
      'plante': 'wind',
      'yeux': 'wide',
      'bouche': 'open',
      'joues': 'visible',
    },
    // Mouvements & gestes
    'greeting': {
      'global': 'bounce_light',
      'milieu': 'idle',
      'jambes': 'idle',
      'bras_D': 'wave',
      'bras_G': 'soft',
      'plante': 'breeze_soft',
      'yeux': 'squint',
      'bouche': 'big_smile',
      'joues': 'visible',
    },
    'walking': {
      'global': 'walk_normal',
      'milieu': 'breathe_fast',
      'jambes': 'walk_normal',
      'bras_D': 'walk_normal',
      'bras_G': 'walk_normal',
      'plante': 'wind',
      'yeux': 'open',
      'bouche': 'smile',
      'joues': 'visible',
    },
    'sprinting': {
      'global': 'run',
      'milieu': 'sprint',
      'jambes': 'run',
      'bras_D': 'run',
      'bras_G': 'run',
      'plante': 'wind',
      'yeux': 'wide',
      'bouche': 'open',
      'joues': 'flushed',
    },
    'panic': {
      'global': 'tremble',
      'milieu': 'struggle',
      'jambes': 'spread',
      'bras_D': 'panic',
      'bras_G': 'panic',
      'plante': 'startle',
      'yeux': 'shock',
      'bouche': 'exhausted',
      'joues': 'hidden',
    },
    'workout': {
      'global': 'idle',
      'milieu': 'strain',
      'jambes': 'spread',
      'bras_D': 'raised',
      'bras_G': 'raised',
      'plante': 'breeze',
      'yeux': 'wide',
      'bouche': 'sick',
      'joues': 'flushed',
    },
    // Environnements extrêmes
    'freezing': {
      'global': 'tremble',
      'milieu': 'crushed_tremble',
      'jambes': 'bent',
      'bras_D': 'crossed',
      'bras_G': 'crossed',
      'plante': 'curl',
      'yeux': 'half_closed',
      'bouche': 'sad',
      'joues': 'hidden',
    },
    'overheating': {
      'global': 'idle',
      'milieu': 'panting',
      'jambes': 'spread',
      'bras_D': 'dead',
      'bras_G': 'dead',
      'plante': 'curl',
      'yeux': 'half_closed',
      'bouche': 'open',
      'joues': 'flushed',
    },
    'levitation': {
      'global': 'levitate',
      'milieu': 'zen',
      'jambes': 'floating',
      'bras_D': 'wave',
      'bras_G': 'wave',
      'plante': 'breeze_soft',
      'yeux': 'zen',
      'bouche': 'smile',
      'joues': 'visible',
    },
  };

  /// Tempo par animation spéciale : multiplie les fréquences de la recette
  static const Map<String, double> tempos = {
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
}
