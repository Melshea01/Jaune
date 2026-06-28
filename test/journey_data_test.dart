import 'package:flutter_test/flutter_test.dart';

import 'package:jaune/services/journey_data.dart';
import 'package:jaune/services/citron_skins.dart';

void main() {
  group('Voyage du Citron — intégrité des données', () {
    test('exactement 100 niveaux, 1 à 100, sans trou ni doublon', () {
      expect(kLevelUnlocks.length, 100);
      final levels = kLevelUnlocks.map((u) => u.level).toList()..sort();
      expect(levels.first, 1);
      expect(levels.last, 100);
      expect(levels.toSet().length, 100, reason: 'pas de doublon');
      for (int i = 0; i < 100; i++) {
        expect(levels[i], i + 1, reason: 'niveau ${i + 1} manquant');
      }
    });

    test('les 5 chapitres couvrent 1..100 de façon contiguë', () {
      expect(kChapters.length, 5);
      expect(kChapters.first.from, 1);
      expect(kChapters.last.to, 100);
      for (int i = 1; i < kChapters.length; i++) {
        expect(kChapters[i].from, kChapters[i - 1].to + 1,
            reason: 'chapitres contigus');
      }
    });

    test('le chapitre déclaré de chaque niveau correspond à son intervalle', () {
      for (final u in kLevelUnlocks) {
        expect(u.chapter, chapterOfLevel(u.level).id,
            reason: 'niveau ${u.level} : chapitre incohérent');
      }
    });

    test('chaque tenue (citronState) pointe vers un skin réel', () {
      for (final u in kLevelUnlocks) {
        if (u.type == UnlockType.citronState) {
          expect(skinByKey(u.key), isNotNull,
              reason: 'skin manquant pour ${u.key} (niv ${u.level})');
        }
      }
    });

    test('icône et libellés bilingues toujours renseignés', () {
      for (final u in kLevelUnlocks) {
        expect(u.icon.trim(), isNotEmpty, reason: 'icône niv ${u.level}');
        expect(u.titleFr.trim(), isNotEmpty);
        expect(u.titleEn.trim(), isNotEmpty);
        expect(u.descFr.trim(), isNotEmpty);
        expect(u.descEn.trim(), isNotEmpty);
      }
    });

    test('les clés non-cosmétiques sont uniques', () {
      final keys = kLevelUnlocks.map((u) => u.key).toList();
      expect(keys.toSet().length, keys.length, reason: 'clés uniques');
    });
  });
}
