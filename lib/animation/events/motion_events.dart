import 'dart:math';

/// Événement one-shot : courbe de transformations additives superposée à
/// l'état continu. Clés : hopY (px, + = bas), scaleX, scaleY, swayRad.
///
/// Le moteur applique une enveloppe de blend-in/out (~80 ms) à la
/// contribution de chaque event et crossfade en cas de retrigger — les
/// courbes n'ont donc plus besoin de garantir l'identité aux bornes,
/// mais on la conserve par hygiène (anticipation → action → retombée).
class MotionEvent {
  final String name;
  final Duration duration;
  final Map<String, num> Function(double progress) sample;

  const MotionEvent({
    required this.name,
    required this.duration,
    required this.sample,
  });
}

/// Catalogue des 14 événements one-shot
class MotionEvents {
  // ─── Joie & accomplissements ─────────────────────────────────────────

  /// Saut de joie : anticipation (squat) → vol (étirement) → squash d'impact
  static final MotionEvent jumpJoy = MotionEvent(
    name: 'jump_joy',
    duration: const Duration(milliseconds: 1100),
    sample: (p) {
      if (p < 0.15) {
        final rp = p / 0.15;
        final squat = sin(rp * pi);
        return {
          'hopY': 15 * squat,
          'scaleY': 1 - 0.2 * squat,
          'scaleX': 1 + 0.2 * squat,
        };
      } else if (p < 0.82) {
        final rp = (p - 0.15) / 0.67;
        final height = 4 * rp * (1 - rp);
        return {
          'hopY': -160 * height,
          'scaleX': 1 - 0.15 * height,
          'scaleY': 1 + 0.18 * height,
        };
      } else {
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

  /// Double saut — streak de 3 jours
  static final MotionEvent doubleJump = MotionEvent(
    name: 'double_jump',
    duration: const Duration(milliseconds: 1200),
    sample: (p) {
      final b = (p * 2) % 1;
      final height = 4 * b * (1 - b);
      return {'hopY': -100 * height};
    },
  );

  /// Mega saut — level-up / 1 mois de streak. Squash d'impact amplifié
  /// + micro-rebond résiduel : plus on tombe de haut, plus l'impact se voit.
  static final MotionEvent megaJump = MotionEvent(
    name: 'mega_jump',
    duration: const Duration(milliseconds: 1900),
    sample: (p) {
      if (p < 0.18) {
        final rp = p / 0.18;
        final squat = sin(rp * pi);
        return {
          'hopY': 20 * squat,
          'scaleY': 1 - 0.3 * squat,
          'scaleX': 1 + 0.3 * squat,
        };
      } else if (p < 0.82) {
        final rp = (p - 0.18) / 0.64;
        final height = 4 * rp * (1 - rp);
        return {
          'hopY': -350 * height,
          'scaleY': 1 + 0.35 * height,
          'scaleX': 1 - 0.25 * height,
        };
      } else {
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

  /// Gonflement de fierté — nouveau badge
  static final MotionEvent badgeProud = MotionEvent(
    name: 'badge_proud',
    duration: const Duration(milliseconds: 2000),
    sample: (p) {
      final swell = sin(p * pi);
      return {'scaleY': 1 + 0.2 * swell, 'scaleX': 1 + 0.2 * swell};
    },
  );

  // ─── Alertes & sursauts ──────────────────────────────────────────────

  /// Frisson : tremblement lisible (~550 ms) qui s'amortit naturellement
  static final MotionEvent shiver = MotionEvent(
    name: 'shiver',
    duration: const Duration(milliseconds: 550),
    sample: (p) {
      final decay = 1 - p;
      final tremor = sin(p * pi * 10) * decay;
      return {'swayRad': tremor * 0.08, 'hopY': tremor * 4};
    },
  );

  /// Sursaut de peur
  static final MotionEvent scared = MotionEvent(
    name: 'scared',
    duration: const Duration(milliseconds: 350),
    sample: (p) {
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

  /// Craquage émotionnel — effondrement par écrasement (pas sous le sol)
  static final MotionEvent craquage = MotionEvent(
    name: 'craquage',
    duration: const Duration(milliseconds: 800),
    sample: (p) {
      final drop = sin(p * pi);
      return {
        'hopY': 25 * drop,
        'scaleY': 1 - 0.35 * drop,
        'scaleX': 1 + 0.4 * drop,
      };
    },
  );

  /// Hoquet
  static final MotionEvent hiccup = MotionEvent(
    name: 'hiccup',
    duration: const Duration(milliseconds: 200),
    sample: (p) {
      final j = 4 * p * (1 - p);
      return {'hopY': -20 * j, 'scaleY': 1 - 0.1 * j, 'scaleX': 1 + 0.1 * j};
    },
  );

  // ─── Émotions ────────────────────────────────────────────────────────

  /// Encouragement : penché en avant avec petite levée
  static final MotionEvent encourage = MotionEvent(
    name: 'encourage',
    duration: const Duration(milliseconds: 600),
    sample: (p) {
      final lean = sin(p * pi);
      return {'swayRad': 0.2 * lean, 'hopY': -20 * lean};
    },
  );

  /// Curiosité : inclinaison de tête tenue
  static final MotionEvent curious = MotionEvent(
    name: 'curious',
    duration: const Duration(milliseconds: 2500),
    sample: (p) {
      final base = sin(p * pi);
      final lean = pow(base.abs(), 0.5).toDouble();
      return {'swayRad': 0.26 * lean};
    },
  );

  /// Volonté : se gonfle pour résister
  static final MotionEvent willpower = MotionEvent(
    name: 'willpower',
    duration: const Duration(milliseconds: 1000),
    sample: (p) {
      final swell = sin(p * pi);
      return {
        'scaleY': 1 + 0.1 * swell,
        'scaleX': 1 + 0.1 * swell,
        'hopY': -10 * swell,
      };
    },
  );

  /// Manque : tremblement compulsif avec enveloppe montée/descente
  static final MotionEvent craving = MotionEvent(
    name: 'craving',
    duration: const Duration(milliseconds: 2000),
    sample: (p) {
      final envelope = sin(p * pi);
      final vibe = sin(p * pi * 2 * 12) * envelope;
      return {'swayRad': vibe * 0.1};
    },
  );

  // ─── Gameplay ────────────────────────────────────────────────────────

  /// Pirouette
  static final MotionEvent coinSpin = MotionEvent(
    name: 'coin_spin',
    duration: const Duration(milliseconds: 800),
    sample: (p) {
      return {'swayRad': sin(p * pi * 4) * 0.4};
    },
  );

  /// Boire : bascule en arrière puis atterrissage absorbé par les jambes
  static final MotionEvent drinkBeer = MotionEvent(
    name: 'drink_beer',
    duration: const Duration(milliseconds: 1400),
    sample: (p) {
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

  static final Map<String, MotionEvent> _byName = {
    for (final e in [
      jumpJoy,
      doubleJump,
      megaJump,
      badgeProud,
      shiver,
      scared,
      craquage,
      hiccup,
      encourage,
      curious,
      willpower,
      craving,
      coinSpin,
      drinkBeer,
    ])
      e.name: e,
  };

  static MotionEvent? byName(String name) => _byName[name];

  static Iterable<String> get names => _byName.keys;
}
