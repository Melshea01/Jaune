import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaune/services/character_service.dart';
import 'package:jaune/utils/date_keys.dart';

/// Clé de date relative à aujourd'hui (offset en jours dans le passé).
String _ago(int days) =>
    dateKey(DateTime.now().subtract(Duration(days: days)));

CharacterProfile _profile({
  int streakShields = 0,
  List<String>? frozenDays,
  String lastLogDate = '',
  int daysSinceFirstUse = 60,
}) =>
    CharacterProfile(
      firstUseDate: _ago(daysSinceFirstUse),
      streakShields: streakShields,
      frozenDays: frozenDays,
      lastLogDate: lastLogDate,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('computeSoberStreak', () {
    test('compte les jours sobres consécutifs jusqu\'au premier écart', () {
      final s = CharacterService()..updateProfile(_profile());
      // hier, -2 sobres ; -3 = conso → série de 2
      final daily = {_ago(3): 4};
      expect(s.computeSoberStreak(daily), 2);
    });

    test('un jour gelé ponte la série sans la compter ni la casser', () {
      // firstUse il y a 3 jours → série bornée ; hier gelé
      final s = CharacterService()
        ..updateProfile(
          _profile(frozenDays: [_ago(1)], daysSinceFirstUse: 3),
        );
      // hier = conso mais GELÉ ; -2, -3 sobres jusqu'à firstUse → pontée = 2
      final daily = {_ago(1): 3};
      expect(s.computeSoberStreak(daily), 2);
    });
  });

  group('gel de série (bouclier)', () {
    test('un écart isolé d\'hier consomme un bouclier et préserve la série',
        () async {
      // firstUse récent (4 j) → la semaine précédente n'est pas « couverte »,
      // donc pas de bonus « semaine parfaite » qui re-créditerait un bouclier.
      final s = CharacterService()
        ..updateProfile(_profile(streakShields: 1, daysSinceFirstUse: 4));
      // hier = conso isolée ; avant-hier sobre
      final daily = {_ago(1): 2};

      await s.awardDailyLogXp(daily, includeLogBonus: false);

      expect(s.streakShields, 0, reason: 'bouclier consommé');
      expect(s.profile.frozenDays, contains(_ago(1)));
      expect(s.soberStreakDays, greaterThanOrEqualTo(1));
    });

    test('idempotent : recalculer ne reconsomme pas de bouclier', () async {
      final s = CharacterService()
        ..updateProfile(_profile(streakShields: 1, daysSinceFirstUse: 4));
      final daily = {_ago(1): 2};

      await s.awardDailyLogXp(daily, includeLogBonus: false);
      final streakAfter1 = s.soberStreakDays;
      await s.awardDailyLogXp(daily, includeLogBonus: false);

      expect(s.streakShields, 0);
      expect(s.profile.frozenDays.where((k) => k == _ago(1)).length, 1);
      expect(s.soberStreakDays, streakAfter1);
    });

    test('ne gaspille pas un bouclier si l\'avant-veille n\'est pas sobre',
        () async {
      final s = CharacterService()
        ..updateProfile(_profile(streakShields: 1, daysSinceFirstUse: 4));
      // hier ET avant-hier = conso → pas de série réelle à protéger
      final daily = {_ago(1): 2, _ago(2): 3};

      await s.awardDailyLogXp(daily, includeLogBonus: false);

      expect(s.streakShields, 1, reason: 'bouclier préservé');
      expect(s.soberStreakDays, 0);
    });
  });

  group('quêtes du jour', () {
    test('propose un nombre stable de quêtes du catalogue', () {
      final s = CharacterService()..updateProfile(_profile());
      final quests = s.dailyQuests();
      expect(quests.length, kDailyQuestCount);
      for (final q in quests) {
        expect(kDailyQuests.map((e) => e.id), contains(q.quest.id));
      }
    });

    test('la sélection est stable sur la même journée', () {
      final s = CharacterService()..updateProfile(_profile());
      final a = s.dailyQuests().map((q) => q.quest.id).toList();
      final b = s.dailyQuests().map((q) => q.quest.id).toList();
      expect(a, b);
    });
  });

  group('objectif hebdomadaire', () {
    test('cible exposée et progression bornée [0,1]', () {
      final s = CharacterService()..updateProfile(_profile());
      final goal = s.weeklyGoal({});
      expect(goal.target, CharacterService.kWeeklyGoalSoberDays);
      expect(goal.progress, inInclusiveRange(0.0, 1.0));
    });

    test('sans historique couvert, aucun jour sobre compté', () {
      // Première utilisation = aujourd'hui, rien loggé → 0 jour sobre
      final s = CharacterService()
        ..updateProfile(_profile(daysSinceFirstUse: 0));
      final goal = s.weeklyGoal({});
      expect(goal.soberDays, 0);
      expect(goal.progress, 0.0);
    });
  });

  group('variance d\'XP', () {
    test('le gain « journée sobre » reste dans [base, base + 20 %]', () async {
      final s = CharacterService()..updateProfile(_profile());
      // hier sobre → événement soberYesterday (base 5)
      final result = await s.awardDailyLogXp({}, includeLogBonus: false);
      final sober = result.xpEvents
          .where((e) => e.reason == XpReason.soberYesterday)
          .toList();
      expect(sober, isNotEmpty);
      expect(sober.first.amount, inInclusiveRange(5, 6));
    });
  });
}
