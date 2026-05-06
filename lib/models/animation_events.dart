import 'dart:math';

/// One-shot animation events with specific durations
/// These overlay on top of continuous animation states
class AnimationEvent {
  final String name;
  final Duration duration;
  final Function(double progress) update; // progress: 0.0 to 1.0

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
  static AnimationEvent jumpJoy = AnimationEvent(
    name: 'jump_joy',
    duration: const Duration(milliseconds: 1000),
    update: (p) {
      if (p < 0.15) {
        final rp = p / 0.15;
        final squat = sin(rp * pi);
        return {
          'hopY': 15 * squat,
          'scaleY': 1 - 0.2 * squat,
          'scaleX': 1 + 0.2 * squat,
        };
      } else {
        final rp = (p - 0.15) / 0.85;
        final height = 4 * rp * (1 - rp);
        return {
          'hopY': -160 * height,
          'scaleX': 1 - 0.25 * height,
          'scaleY': 1 + 0.25 * sin(rp * pi),
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

  /// Mega jump - 1 month streak
  static AnimationEvent megaJump = AnimationEvent(
    name: 'mega_jump',
    duration: const Duration(milliseconds: 1800),
    update: (p) {
      if (p < 0.2) {
        final rp = p / 0.2;
        final squat = sin(rp * pi);
        return {
          'hopY': 20 * squat,
          'scaleY': 1 - 0.3 * squat,
          'scaleX': 1 + 0.3 * squat,
        };
      } else {
        final rp = (p - 0.2) / 0.8;
        final height = 4 * rp * (1 - rp);
        return {
          'hopY': -350 * height,
          'scaleY': 1 + 0.4 * height,
          'scaleX': 1 - 0.3 * height,
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
      return {
        'scaleY': 1 + 0.2 * swell,
        'scaleX': 1 + 0.2 * swell,
      };
    },
  );

  // ─── Alert & Startle Events ─────────────────────────────────────────

  /// Shiver - sudden cold
  static AnimationEvent shiver = AnimationEvent(
    name: 'shiver',
    duration: const Duration(milliseconds: 150),
    update: (p) {
      final tremor = sin(p * pi * 8);
      return {
        'swayRad': tremor * 0.1,
        'hopY': tremor * 6,
      };
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
  static AnimationEvent craquage = AnimationEvent(
    name: 'craquage',
    duration: const Duration(milliseconds: 800),
    update: (p) {
      final drop = sin(p * pi);
      return {
        'hopY': 150 * drop,
        'scaleY': 1 - 0.3 * drop,
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
      return {
        'hopY': -20 * j,
        'scaleY': 1 - 0.1 * j,
        'scaleX': 1 + 0.1 * j,
      };
    },
  );

  // ─── Emotional Events ───────────────────────────────────────────────

  /// Encourage - gentle lean forward
  static AnimationEvent encourage = AnimationEvent(
    name: 'encourage',
    duration: const Duration(milliseconds: 600),
    update: (p) {
      final lean = sin(p * pi);
      return {
        'swayRad': 0.2 * lean,
        'hopY': -20 * lean,
      };
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
  static AnimationEvent craving = AnimationEvent(
    name: 'craving',
    duration: const Duration(milliseconds: 2000),
    update: (p) {
      final vibe = sin(p * pi * 2 * 12);
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
          'hopY': 40 * bounce,
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
