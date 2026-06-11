// Tests du moteur d'animation du citron.
//
// La propriété centrale vérifiée ici est la CONTINUITÉ : l'ancien moteur
// calculait sin(temps_absolu × vitesse) et sautait de phase à chaque
// changement de vitesse (la cause des transitions saccadées). Le nouveau
// moteur garantit numériquement qu'aucun changement de cible — même brutal,
// même en plein milieu d'une transition — ne produit de discontinuité.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:jaune/animation/core/oscillator.dart';
import 'package:jaune/animation/core/spring_value.dart';
import 'package:jaune/animation/citron_engine.dart';
import 'package:jaune/animation/poses/citron_moods.dart';

void main() {
  group('SpringValue', () {
    test('converge vers la cible', () {
      final spring = SpringValue(0, omega: 10);
      spring.setTarget(100);
      for (int i = 0; i < 2000; i++) {
        spring.update(0.001);
      }
      expect(spring.value, closeTo(100, 0.01));
    });

    test('pas de dépassement depuis le repos (amortissement critique)', () {
      final spring = SpringValue(0, omega: 10);
      spring.setTarget(100);
      double previous = 0;
      for (int i = 0; i < 5000; i++) {
        final v = spring.update(0.001);
        expect(v, lessThanOrEqualTo(100.0 + 1e-9));
        expect(v, greaterThanOrEqualTo(previous - 1e-9)); // monotone
        previous = v;
      }
    });

    test('re-ciblage en cours de route : continu, pas de saut', () {
      final spring = SpringValue(0, omega: 10);
      spring.setTarget(100);
      double previous = spring.value;
      for (int i = 0; i < 1000; i++) {
        // Interruption brutale à mi-chemin : nouvelle cible opposée
        if (i == 100) spring.setTarget(-50);
        final v = spring.update(0.001);
        expect(
          (v - previous).abs(),
          lessThan(1.0),
          reason: 'saut détecté au pas $i',
        );
        previous = v;
      }
      expect(spring.value, closeTo(-50, 0.5));
    });
  });

  group('Oscillator', () {
    test(
      'changement brutal de fréquence : la position reste continue '
      '(LA propriété anti-saccade)',
      () {
        final osc = Oscillator(frequency: 2.6, amplitude: 10, omega: 8);
        // Régime établi
        for (int i = 0; i < 500; i++) {
          osc.update(0.001);
        }
        double previous = osc.sine;
        // Le pire cas de l'ancien moteur : la vitesse change pendant
        // que l'oscillation tourne
        osc.setFrequencyTarget(0.3);
        for (int i = 0; i < 3000; i++) {
          osc.update(0.001);
          final v = osc.sine;
          // Pente max d'un sinus : amp·2π·freq → 10·2π·2.6·0.001 ≈ 0.16/pas
          expect(
            (v - previous).abs(),
            lessThan(0.25),
            reason: 'discontinuité au pas $i',
          );
          previous = v;
        }
        // La fréquence a bien convergé
        expect(osc.frequency, closeTo(0.3, 0.01));
      },
    );

    test('la phase reste bornée à [0, 2π)', () {
      final osc = Oscillator(frequency: 50, amplitude: 1);
      for (int i = 0; i < 10000; i++) {
        osc.update(0.001);
        expect(osc.phase, greaterThanOrEqualTo(0));
        expect(osc.phase, lessThan(2 * math.pi));
      }
    });
  });

  group('CitronEngine', () {
    test(
      'changement d\'humeur en PLEIN MILIEU d\'une transition : '
      'aucune discontinuité de frame',
      () {
        final engine = CitronEngine(random: math.Random(42));
        engine.idleMood = 'none'; // pas d'événements aléatoires pendant le test

        // Humeur très animée
        engine.applyRecipe(CitronMoods.superHappy);

        double prevY = engine.frame.translateY;
        double prevRot = engine.frame.rotationRad;
        double prevScaleY = engine.frame.scaleY;

        for (int i = 0; i < 3000; i++) {
          // Interruption brutale à 200 ms : humeur opposée (malade)
          if (i == 200) engine.applyRecipe(CitronMoods.sick);
          // Et re-interruption à 350 ms : retour au neutre
          if (i == 350) engine.applyRecipe(CitronMoods.neutral);

          engine.update(0.001);
          final f = engine.frame;

          expect(
            (f.translateY - prevY).abs(),
            lessThan(3.0),
            reason: 'saut de position au pas $i',
          );
          expect(
            (f.rotationRad - prevRot).abs(),
            lessThan(0.05),
            reason: 'saut de rotation au pas $i',
          );
          expect(
            (f.scaleY - prevScaleY).abs(),
            lessThan(0.02),
            reason: 'saut d\'échelle au pas $i',
          );

          prevY = f.translateY;
          prevRot = f.rotationRad;
          prevScaleY = f.scaleY;
        }
      },
    );

    test('événement one-shot : blendé, pas de snap au déclenchement', () {
      final engine = CitronEngine(random: math.Random(42));
      engine.idleMood = 'none';

      // Stabiliser
      for (int i = 0; i < 1000; i++) {
        engine.update(0.001);
      }

      double prevY = engine.frame.translateY;
      engine.triggerEvent('jump_joy');
      for (int i = 0; i < 1500; i++) {
        engine.update(0.001);
        final y = engine.frame.translateY;
        expect(
          (y - prevY).abs(),
          lessThan(3.0),
          reason: 'snap de l\'événement au pas $i',
        );
        prevY = y;
      }
      // L'événement est terminé et retiré
      expect(engine.hasActiveEvent, isFalse);
    });

    test(
      'teinte de santé : changement 100→10 en pleine transition, '
      'la couleur glisse sans saut',
      () {
        final engine = CitronEngine(random: math.Random(42));
        engine.idleMood = 'none';

        // Pleine forme : teinte 0
        engine.applyHealth(100);
        engine.applyStyle(CitronMoods.healthStyle(100));
        for (int i = 0; i < 500; i++) {
          engine.update(0.001);
        }
        expect(engine.frame.tint, lessThan(0.05));

        // Effondrement de la santé en plein milieu, puis re-changement
        double prevTint = engine.frame.tint;
        for (int i = 0; i < 3000; i++) {
          if (i == 100) {
            engine.applyHealth(10);
            engine.applyStyle(CitronMoods.healthStyle(10));
          }
          if (i == 300) {
            engine.applyHealth(60);
            engine.applyStyle(CitronMoods.healthStyle(60));
          }
          engine.update(0.001);
          final tint = engine.frame.tint;
          expect(
            (tint - prevTint).abs(),
            lessThan(0.01),
            reason: 'saut de teinte au pas $i',
          );
          prevTint = tint;
        }
        // Convergence vers le style santé 60 (tint 0.12)
        expect(engine.frame.tint, closeTo(0.12, 0.02));
      },
    );

    test('retrigger en plein vol : crossfade, pas de snap', () {
      final engine = CitronEngine(random: math.Random(42));
      engine.idleMood = 'none';
      for (int i = 0; i < 500; i++) {
        engine.update(0.001);
      }

      engine.triggerEvent('mega_jump');
      double prevY = engine.frame.translateY;
      for (int i = 0; i < 2500; i++) {
        // Retrigger brutal au milieu du vol du premier saut
        if (i == 600) engine.triggerEvent('hiccup');
        engine.update(0.001);
        final y = engine.frame.translateY;
        expect(
          (y - prevY).abs(),
          lessThan(8.0),
          reason: 'snap au retrigger au pas $i',
        );
        prevY = y;
      }
    });
  });
}
