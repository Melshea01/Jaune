import 'dart:math';

/// One-shot animation events with specific durations
/// These overlay on top of continuous animation states
class AnimationEvent {
  final String name;
  final Duration duration;

  /// progress: 0.0 to 1.0 → transformations additives
  /// (clés : hopY, scaleX, scaleY, swayRad)
  final Map<String, num> Function(double progress) update;

  const AnimationEvent({
    required this.name,
    required this.duration,
    required this.update,
  });
}

/// One-shot event definitions for special moments
class AnimationEvents {
  // ─── Joy & Achievement Events ───────────────────────────────────────

  /// Jump of joy - daily success
  /// Trois phases : anticipation (squat) → vol (étirement à l'apex) →
  /// atterrissage (squash d'impact qui se résorbe). Sans la 3e phase,
  /// le personnage atterrissait comme un sprite sans poids.
  static AnimationEvent jumpJoy = AnimationEvent(
    name: 'jump_joy',
    duration: const Duration(milliseconds: 1100),
    update: (p) {
      if (p < 0.15) {
        // Anticipation
        final rp = p / 0.15;
        final squat = sin(rp * pi);
        return {
          'hopY': 15 * squat,
          'scaleY': 1 - 0.2 * squat,
          'scaleX': 1 + 0.2 * squat,
        };
      } else if (p < 0.82) {
        // Vol
        final rp = (p - 0.15) / 0.67;
        final height = 4 * rp * (1 - rp);
        return {
          'hopY': -160 * height,
          'scaleX': 1 - 0.15 * height,
          'scaleY': 1 + 0.18 * height,
        };
      } else {
        // Atterrissage : squash d'impact
        final rp = (p - 0.82) / 0.18;
        final squash = sin(rp * pi);
        return {
          'hopY': 0,
          'scaleY': 1 - 0.16 * squash,
          'scaleX': 1 + 0.20 * squash,
        };
      }
    },
  );

  /// Double jump - 3-day streak
  static AnimationEvent doubleJump = AnimationEvent(
    name: 'double_jump',
    duration: const Duration(milliseconds: 1200),
    update: (p) {
      final b = (p * 2) % 1;
      final height = 4 * b * (1 - b);
      return {'hopY': -100 * height};
    },
  );

  /// Mega jump - 1 month streak / level-up
  /// Même structure 3 phases que jump_joy, amplifiée : plus l'impact est
  /// haut, plus le squash d'atterrissage doit être fort pour vendre le poids.
  static AnimationEvent megaJump = AnimationEvent(
    name: 'mega_jump',
    duration: const Duration(milliseconds: 1900),
    update: (p) {
      if (p < 0.18) {
        // Anticipation profonde
        final rp = p / 0.18;
        final squat = sin(rp * pi);
        return {
          'hopY': 20 * squat,
          'scaleY': 1 - 0.3 * squat,
          'scaleX': 1 + 0.3 * squat,
        };
      } else if (p < 0.82) {
        // Vol haut
        final rp = (p - 0.18) / 0.64;
        final height = 4 * rp * (1 - rp);
        return {
          'hopY': -350 * height,
          'scaleY': 1 + 0.35 * height,
          'scaleX': 1 - 0.25 * height,
        };
      } else {
        // Gros squash d'impact avec petit rebond résiduel
        final rp = (p - 0.82) / 0.18;
        final squash = sin(rp * pi);
        final rebound = sin(rp * pi * 2) * (1 - rp);
        return {
          'hopY': -12 * rebound.abs(),
          'scaleY': 1 - 0.28 * squash,
          'scaleX': 1 + 0.32 * squash,
        };
      }
    },
  );

  /// Badge proud - new achievement
  static AnimationEvent badgeProud = AnimationEvent(
    name: 'badge_proud',
    duration: const Duration(milliseconds: 2000),
    update: (p) {
      final swell = sin(p * pi);
      return {'scaleY': 1 + 0.2 * swell, 'scaleX': 1 + 0.2 * swell};
    },
  );

  // ─── Alert & Startle Events ─────────────────────────────────────────

  /// Shiver - sudden cold
  /// Fix : 150ms était imperceptible. Un frisson lisible dure ~500ms et
  /// s'amortit naturellement (enveloppe décroissante) au lieu de couper net.
  static AnimationEvent shiver = AnimationEvent(
    name: 'shiver',
    duration: const Duration(milliseconds: 550),
    update: (p) {
      final decay = 1 - p;
      final tremor = sin(p * pi * 10) * decay;
      return {'swayRad': tremor * 0.08, 'hopY': tremor * 4};
    },
  );

  /// Scared - surprise/alarm
  static AnimationEvent scared = AnimationEvent(
    name: 'scared',
    duration: const Duration(milliseconds: 350),
    update: (p) {
      if (p < 0.15) {
        final rp = p / 0.15;
        final squat = sin(rp * pi);
        return {
          'hopY': 8 * squat,
          'scaleY': 1 - 0.15 * squat,
          'scaleX': 1 + 0.15 * squat,
        };
      } else {
        final rp = (p - 0.15) / 0.85;
        final height = 4 * rp * (1 - rp);
        return {
          'hopY': -60 * height,
          'scaleY': 1 + 0.15 * height,
          'scaleX': 1 - 0.1 * height,
        };
      }
    },
  );

  /// Craquage - emotional breakdown
  /// Fix : il s'enfonçait de 150px sous le sol. Un effondrement se lit par
  /// l'écrasement (squash), pas par la traversée du plancher.
  static AnimationEvent craquage = AnimationEvent(
    name: 'craquage',
    duration: const Duration(milliseconds: 800),
    update: (p) {
      final drop = sin(p * pi);
      return {
        'hopY': 25 * drop,
        'scaleY': 1 - 0.35 * drop,
        'scaleX': 1 + 0.4 * drop,
      };
    },
  );

  /// Hiccup - involuntary
  static AnimationEvent hiccup = AnimationEvent(
    name: 'hiccup',
    duration: const Duration(milliseconds: 200),
    update: (p) {
      final j = 4 * p * (1 - p);
      return {'hopY': -20 * j, 'scaleY': 1 - 0.1 * j, 'scaleX': 1 + 0.1 * j};
    },
  );

  // ─── Emotional Events ───────────────────────────────────────────────

  /// Encourage - gentle lean forward
  static AnimationEvent encourage = AnimationEvent(
    name: 'encourage',
    duration: const Duration(milliseconds: 600),
    update: (p) {
      final lean = sin(p * pi);
      return {'swayRad': 0.2 * lean, 'hopY': -20 * lean};
    },
  );

  /// Curious - head tilt observation
  static AnimationEvent curious = AnimationEvent(
    name: 'curious',
    duration: const Duration(milliseconds: 2500),
    update: (p) {
      final base = sin(p * pi);
      final lean = pow(base.abs(), 0.5).toDouble();
      return {'swayRad': 0.26 * lean};
    },
  );

  /// Willpower - resisting temptation
  static AnimationEvent willpower = AnimationEvent(
    name: 'willpower',
    duration: const Duration(milliseconds: 1000),
    update: (p) {
      final swell = sin(p * pi);
      return {
        'scaleY': 1 + 0.1 * swell,
        'scaleX': 1 + 0.1 * swell,
        'hopY': -10 * swell,
      };
    },
  );

  /// Craving - compulsive trembling
  /// Enveloppe montée/descente : le tremblement s'installe puis s'apaise,
  /// au lieu de vibrer à amplitude constante et s'arrêter d'un coup.
  static AnimationEvent craving = AnimationEvent(
    name: 'craving',
    duration: const Duration(milliseconds: 2000),
    update: (p) {
      final envelope = sin(p * pi);
      final vibe = sin(p * pi * 2 * 12) * envelope;
      return {'swayRad': vibe * 0.1};
    },
  );

  // ─── Gameplay Events ────────────────────────────────────────────────

  /// Coin spin - rotating token animation
  static AnimationEvent coinSpin = AnimationEvent(
    name: 'coin_spin',
    duration: const Duration(milliseconds: 800),
    update: (p) {
      return {'swayRad': sin(p * pi * 4) * 0.4};
    },
  );

  /// Drink beer - tilt back then land
  /// Fix : l'atterrissage descendait de 40px sous la ligne de sol (le citron
  /// traversait le plancher). Le squash scaleX/scaleY suffit à vendre
  /// l'impact, avec un micro-enfoncement de 8px absorbé par les jambes.
  static AnimationEvent drinkBeer = AnimationEvent(
    name: 'drink_beer',
    duration: const Duration(milliseconds: 1400),
    update: (p) {
      if (p < 0.6) {
        final rp = p / 0.6;
        final tilt = sin(rp * pi / 2);
        return {
          'swayRad': -25 * tilt * (pi / 180),
          'scaleY': 1 + 0.1 * tilt,
          'scaleX': 1 - 0.05 * tilt,
          'hopY': 0,
        };
      } else {
        final rp = (p - 0.6) / 0.4;
        final bounce = sin(rp * pi);
        return {
          'swayRad': -25 * (1 - rp) * (pi / 180),
          'scaleY': 1 - 0.15 * bounce,
          'scaleX': 1 + 0.2 * bounce,
          'hopY': 8 * bounce,
        };
      }
    },
  );

  /// Get event by name
  static AnimationEvent? getEvent(String name) {
    switch (name) {
      case 'jump_joy':
        return jumpJoy;
      case 'double_jump':
        return doubleJump;
      case 'mega_jump':
        return megaJump;
      case 'badge_proud':
        return badgeProud;
      case 'shiver':
        return shiver;
      case 'scared':
        return scared;
      case 'craquage':
        return craquage;
      case 'hiccup':
        return hiccup;
      case 'encourage':
        return encourage;
      case 'curious':
        return curious;
      case 'willpower':
        return willpower;
      case 'craving':
        return craving;
      case 'coin_spin':
        return coinSpin;
      case 'drink_beer':
        return drinkBeer;
      default:
        return null;
    }
  }
}
