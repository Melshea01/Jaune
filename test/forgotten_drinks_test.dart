import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaune/services/character_service.dart';
import 'package:jaune/services/storage_service.dart';
import 'package:jaune/utils/date_keys.dart';

/// Clé de date relative à aujourd'hui (offset en jours dans le passé).
DateTime _agoDate(int days) =>
    DateTime.now().subtract(Duration(days: days));

CharacterProfile _profile({int daysSinceFirstUse = 60}) => CharacterProfile(
      firstUseDate: dateKey(_agoDate(daysSinceFirstUse)),
    );

/// Ajout de verres oubliés sur un jour passé (J-1 / J-2) : la couche données
/// (`setConsosForDate`) écrit, et tout se re-dérive du calendrier de façon
/// idempotente (série + PV). Reflète le flux `_setConsosForPastDate` de main.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('éditer hier casse la série et fait converger la santé (idempotent)',
      () async {
    final storage = StorageService();
    final character = CharacterService()..updateProfile(_profile());

    // État initial : que du sobre → série sur les jours passés.
    final streakBefore = character.computeSoberStreak(storage.dailyMap);
    final hpBefore = character.computeHealthFromRisk(storage.dailyMap);
    expect(streakBefore, greaterThanOrEqualTo(2));
    expect(hpBefore, 1.0); // dailyMap vide → pleine santé

    // L'utilisateur se souvient d'avoir bu 3 verres HIER.
    await storage.setConsosForDate(_agoDate(1), 3);

    final streakAfter = character.computeSoberStreak(storage.dailyMap);
    final hpAfter = character.computeHealthFromRisk(storage.dailyMap);

    // Hier n'étant plus sobre, la série repart de 0 (marche arrière dès hier).
    expect(streakAfter, 0);
    // La conso passée pèse sur les PV.
    expect(hpAfter, lessThan(hpBefore));

    // Idempotence : ré-appliquer la même valeur ne change plus rien.
    await storage.setConsosForDate(_agoDate(1), 3);
    expect(character.computeSoberStreak(storage.dailyMap), streakAfter);
    expect(character.computeHealthFromRisk(storage.dailyMap), hpAfter);
  });

  test('remettre un jour édité à 0 le retire de la map et restaure la série',
      () async {
    final storage = StorageService();
    final character = CharacterService()..updateProfile(_profile());

    await storage.setConsosForDate(_agoDate(2), 4);
    expect(storage.dailyMap.containsKey(dateKey(_agoDate(2))), isTrue);

    // Correction : c'était une erreur, on remet à 0.
    await storage.setConsosForDate(_agoDate(2), 0);
    expect(storage.dailyMap.containsKey(dateKey(_agoDate(2))), isFalse);
    // Retour à un calendrier entièrement sobre → série restaurée.
    expect(character.computeSoberStreak(storage.dailyMap),
        greaterThanOrEqualTo(2));
    expect(character.computeHealthFromRisk(storage.dailyMap), 1.0);
  });
}
