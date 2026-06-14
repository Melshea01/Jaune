import 'package:flutter_test/flutter_test.dart';
import 'package:jaune/services/jaune_health_model.dart';
import 'package:jaune/utils/date_keys.dart';

List<int> _rep(int n, int v) => List<int>.filled(n, v);

/// Profil hebdomadaire répété sur [weeks] semaines (lundi → dimanche).
List<int> _weekly(List<int> week, int weeks) =>
    [for (int i = 0; i < week.length * weeks; i++) week[i % week.length]];

void main() {
  group('JauneHealthModel — ancrages de calibration', () {
    test('6 verres/jour sans répit → 0', () {
      expect(JauneHealthModel.currentHp(_rep(30, 6)), 0.0);
    });

    test('seuil OMS (~10 verres/sem) → ~85', () {
      final histo = _weekly([0, 2, 0, 2, 0, 3, 3], 4); // 10/sem
      expect(JauneHealthModel.currentHp(histo), closeTo(83, 4));
    });

    test('8 verres en soirée isolée → creux ~70 le jour même', () {
      final histo = [..._rep(20, 0), 8];
      expect(JauneHealthModel.currentHp(histo), closeTo(70, 3));
    });

    test('8 verres isolés, 5 jours plus tard → remontée >90', () {
      final histo = [..._rep(20, 0), 8, 0, 0, 0, 0, 0];
      expect(JauneHealthModel.currentHp(histo), greaterThan(90));
    });

    test('abstinence prolongée → 100', () {
      expect(JauneHealthModel.currentHp(_rep(30, 0)), 100.0);
    });

    test('historique vide → 100', () {
      expect(JauneHealthModel.currentHp(const []), 100.0);
    });
  });

  group('JauneHealthModel — philosophie « le volume cumulé prime »', () {
    final hugo = _weekly([0, 0, 0, 0, 0, 9, 10], 4); // binge weekend
    final marc = _weekly([4, 5, 4, 5, 4, 5, 4], 4); // buveur quotidien lourd

    test('le binger du weekend finit AU-DESSUS du buveur quotidien lourd', () {
      // …même mesuré le soir du binge (dernier jour = dimanche, 10 verres).
      expect(JauneHealthModel.currentHp(hugo),
          greaterThan(JauneHealthModel.currentHp(marc)));
    });

    test('le creux aigu d\'UNE nuit isolée sature (8 vs 50 même jour)', () {
      final eight = [..._rep(20, 0), 8];
      final fifty = [..._rep(20, 0), 50];
      expect(JauneHealthModel.currentHp(eight),
          closeTo(JauneHealthModel.currentHp(fifty), 0.5));
    });

    test('mais deux binges consécutifs EMPILENT le creux', () {
      final one = [..._rep(20, 0), 10]; // une nuit
      final two = [..._rep(20, 0), 10, 10]; // deux nuits d'affilée
      expect(JauneHealthModel.currentHp(two),
          lessThan(JauneHealthModel.currentHp(one)));
    });
  });

  group('JauneHealthModel — robustesse', () {
    test('PV toujours borné dans [0, 100]', () {
      for (final histo in [
        _rep(60, 12),
        _weekly([0, 0, 0, 0, 0, 20, 0], 6),
        [..._rep(40, 1), 30],
        _rep(1, 9),
      ]) {
        final pv = JauneHealthModel.currentHp(histo);
        expect(pv, inInclusiveRange(0.0, 100.0));
      }
    });

    test('monotonie : boire plus un jour donné ne remonte jamais le PV', () {
      double prev = 100.0;
      for (int x = 0; x <= 12; x++) {
        final pv = JauneHealthModel.currentHp([..._rep(20, 0), x]);
        expect(pv, lessThanOrEqualTo(prev + 1e-9));
        prev = pv;
      }
    });
  });

  group('JauneHealthModel.currentHpFromHistory — adaptateur app', () {
    final now = DateTime(2026, 6, 14);
    String key(int daysAgo) =>
        dateKey(DateTime(2026, 6, 14).subtract(Duration(days: daysAgo)));

    test('map vide → 100', () {
      expect(
        JauneHealthModel.currentHpFromHistory(const {}, now: now),
        100.0,
      );
    });

    test('comble les jours sans log par 0 et déroule la trajectoire', () {
      // Binge isolé il y a 0 jour, première utilisation il y a 25 jours.
      final map = {key(0): 8};
      final pv = JauneHealthModel.currentHpFromHistory(
        map,
        firstUseDateKey: key(25),
        now: now,
      );
      expect(pv, closeTo(70, 3));
    });

    test('équivalent à currentHp sur l\'historique reconstruit', () {
      final map = <String, int>{
        for (int i = 0; i < 14; i++) key(i): [0, 0, 0, 0, 0, 3, 2][i % 7],
      };
      final viaMap = JauneHealthModel.currentHpFromHistory(
        map,
        firstUseDateKey: key(13),
        now: now,
      );
      // Reconstruit le même historique ancien → récent.
      final histo = [for (int i = 13; i >= 0; i--) map[key(i)] ?? 0];
      expect(viaMap, closeTo(JauneHealthModel.currentHp(histo), 1e-9));
    });
  });
}
