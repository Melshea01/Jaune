// ============================================================================
//  JAUNE — Modèle de Points de Vie (PV) face à la consommation d'alcool
// ============================================================================
//
//  PHILOSOPHIE : "santé de fond"
//  -----------------------------
//  Le score (0–100) reflète la santé de fond de l'utilisateur, pilotée par sa
//  consommation récente. Concrètement :
//
//    • Le score gravite vers un NIVEAU D'ÉQUILIBRE déterminé par le volume bu
//      sur les ~3 dernières semaines, pondéré par la récence (les jours récents
//      comptent plus).
//    • Chaque verre creuse la jauge le jour même (retour immédiat, visible),
//      mais ce creux se RÉPARE en quelques jours secs.
//    • Le volume cumulé est ce qui fixe le niveau de fond : une cuite isolée
//      se rattrape, mais boire sans répit fait chuter durablement.
//
//  ANCRAGES DE CALIBRATION (validés par simulation) :
//    • 6 verres/jour sans répit ............... score → 0
//    • Seuil OMS (~10 verres/semaine) ......... score ≈ 85
//    • 8 verres en une soirée isolée .......... creux à ~70 le jour même,
//                                               puis remontée vers ~90 en 5 j
//    • Un binger du weekend finit AU-DESSUS d'un buveur quotidien lourd,
//      MÊME mesuré le soir de son binge (le volume cumulé prime sur l'effet
//      spectaculaire d'une cuite isolée).
//
//  PLAFOND DU CREUX AIGU (_dMax)
//  -----------------------------
//  Les dégâts aigus d'une SEULE nuit sont bornés : au-delà d'une cuite ~10
//  verres, le creux du jour même sature. Physiologiquement, on ne peut "crasher"
//  qu'un certain montant en une nuit ; c'est la RÉPÉTITION (volume cumulé, donc
//  l'équilibre de fond) qui fait chuter durablement. Conséquence voulue : une
//  soirée isolée de 8, 20 ou 50 verres donne le même creux le jour même (~70 si
//  le fond était plein), mais un weekend de 9 puis 10 verres EMPILE les creux
//  sur deux jours et descend bien plus bas. Sans ce plafond, le creux quadratique
//  d'un seul gros soir écrasait la jauge sous celle d'un buveur quotidien lourd,
//  contredisant la philosophie « le volume cumulé prime ».
//
//  UNITÉ D'ENTRÉE : le "verre standard" (10 g d'alcool pur).
//  PAS DE TEMPS    : 1 jour.
//
//  Le modèle est STATELESS : on recalcule toute la trajectoire à partir de
//  l'historique de consommation. C'est déterministe, robuste, et trivial à
//  stocker (il suffit de garder le journal des verres par jour).
// ============================================================================

import 'dart:math' as math;

import '../utils/date_keys.dart';

/// Résultat d'un jour de simulation.
class JauneDay {
  final int dayIndex; // 0 = premier jour de l'historique
  final int drinks; // verres standards ce jour-là
  final double hp; // points de vie affichés (0–100)
  final double equilibrium; // niveau de fond visé ce jour-là (debug/affichage)

  const JauneDay({
    required this.dayIndex,
    required this.drinks,
    required this.hp,
    required this.equilibrium,
  });
}

class JauneHealthModel {
  // --- Constantes de calibration (ne pas modifier sans re-simuler) ---

  /// Décroissance de la pondération récence : poids d'un jour = decay^(âge-1).
  static const double _decay = 0.88;

  /// Fenêtre de mémoire du volume de fond, en jours.
  static const int _window = 21;

  /// Droite d'équilibre : E(vol) = _eqB - _eqA * volHebdo, bornée [0, 100].
  /// Calée sur (10 verres/sem → 85) et (42 verres/sem ≈ 6/jour → 0).
  static const double _eqA = 2.656;
  static const double _eqB = 111.56;

  /// Fonction de dégâts aigus : D(x) = _c1*x + _c2*max(0, x - _xCrit)^2,
  /// plafonnée à [_dMax]. Linéaire jusqu'au seuil de tolérance, accélération
  /// (binge), puis saturation pour une nuit isolée extrême.
  static const double _c1 = 1.0;
  static const double _c2 = 0.9;
  static const double _xCrit = 3.0;

  /// Plafond du creux aigu d'UNE journée (cf. en-tête « PLAFOND DU CREUX AIGU »).
  /// Atteint vers ~10 verres. Le déficit cumulé sur plusieurs jours, lui, n'est
  /// PAS plafonné — les binges consécutifs empilent.
  static const double _dMax = 30.0;

  /// Inertie de l'équilibre : il glisse vers sa cible à cette vitesse/jour.
  /// (Évite que la santé de fond s'effondre le jour même où l'on boit.)
  static const double _eqInertia = 0.5;

  /// Réparation du creux aigu : deficit_jour = max(0, deficit*_repMul - _repAdd).
  /// Volontairement plus lente que le corps ne « dégrise » : le lendemain
  /// d'une grosse soirée ne doit PAS rendre un gros paquet de PV (sinon la
  /// récupération est ressentie comme trop facile). Réglé pour que le jour
  /// d'après un binge ne remonte que de ~2 PV, tout en laissant une glissade
  /// isolée revenir >90 en ~5 jours (non punitif, ancrage OMS préservé).
  static const double _repMul = 0.62;
  static const double _repAdd = 1.0;

  // ----------------------------------------------------------------------
  //  Briques de calcul
  // ----------------------------------------------------------------------

  /// Volume hebdomadaire de fond, pondéré par la récence, calculé sur les
  /// jours PASSÉS uniquement (exclut le jour courant `t`).
  static double _backgroundWeeklyVolume(List<int> drinks, int t) {
    double num = 0, den = 0;
    final maxAge = math.min(_window, t); // jusqu'à 'hier'
    for (int age = 1; age <= maxAge; age++) {
      final w = math.pow(_decay, age - 1).toDouble();
      num += drinks[t - age] * w;
      den += w;
    }
    final avgDaily = den > 0 ? num / den : 0;
    return avgDaily * 7.0; // équivalent hebdomadaire
  }

  /// Niveau d'équilibre (santé de fond) en fonction du volume hebdomadaire.
  static double _equilibrium(double weeklyVolume) {
    final e = _eqB - _eqA * weeklyVolume;
    return e.clamp(0.0, 100.0);
  }

  /// Dégâts aigus d'une journée de consommation (avant atténuation), plafonnés.
  static double _damage(int drinks) {
    final over = math.max(0, drinks - _xCrit);
    final raw = _c1 * drinks + _c2 * over * over;
    return math.min(_dMax, raw);
  }

  /// Réparation du déficit aigu d'un jour à l'autre.
  static double _repair(double deficit) =>
      math.max(0.0, deficit * _repMul - _repAdd);

  // ----------------------------------------------------------------------
  //  API publique
  // ----------------------------------------------------------------------

  /// Calcule la trajectoire complète des PV à partir de l'historique de
  /// consommation `dailyDrinks` (ordre chronologique, le plus ancien d'abord ;
  /// chaque entrée = nombre de verres standards ce jour-là).
  ///
  /// Retourne un [JauneDay] par jour. Le dernier élément porte le PV courant.
  static List<JauneDay> simulate(List<int> dailyDrinks) {
    final out = <JauneDay>[];
    double deficit = 0.0;
    double ePrev = 100.0; // on démarre en pleine forme

    for (int t = 0; t < dailyDrinks.length; t++) {
      final x = dailyDrinks[t];

      // 1) Équilibre cible (santé de fond), avec inertie : il glisse doucement.
      final eTarget = _equilibrium(_backgroundWeeklyVolume(dailyDrinks, t));
      final e = ePrev + _eqInertia * (eTarget - ePrev);
      ePrev = e;

      // 2) Le creux aigu de la veille se répare.
      deficit = _repair(deficit);

      // 3) Si on a bu aujourd'hui, on creuse la jauge (atténué si le fond est bas).
      if (x > 0) {
        final attenuation = 0.45 + 0.55 * (e / 100.0);
        deficit += _damage(x) * attenuation;
      }

      // 4) PV affiché = équilibre - déficit aigu, borné à 0.
      final hp = math.max(0.0, e - deficit);

      out.add(JauneDay(
        dayIndex: t,
        drinks: x,
        hp: hp,
        equilibrium: e,
      ));
    }
    return out;
  }

  /// Raccourci : renvoie uniquement le PV courant (0–100) pour un historique
  /// donné. Pratique pour l'affichage de la jauge.
  static double currentHp(List<int> dailyDrinks) {
    if (dailyDrinks.isEmpty) return 100.0;
    return simulate(dailyDrinks).last.hp;
  }

  /// Adaptateur app : calcule le PV courant (0–100) directement à partir du
  /// `dailyMap` (clé date 'yyyy-MM-dd' → verres) persisté par l'app.
  ///
  /// Construit l'historique chronologique de [firstUseDateKey] (ou la première
  /// clé présente) jusqu'à aujourd'hui, en comblant les jours sans log par 0,
  /// puis déroule [simulate]. Démarrer la simulation à la première utilisation
  /// (et non sur une fenêtre glissante) laisse l'équilibre converger
  /// proprement et donne au nouvel utilisateur le bénéfice du doute sur son
  /// passé inconnu — cohérent avec [computeSoberStreak].
  static double currentHpFromHistory(
    Map<String, int> dailyMap, {
    String firstUseDateKey = '',
    DateTime? now,
  }) {
    if (dailyMap.isEmpty) return 100.0;

    final DateTime n = now ?? DateTime.now();
    final DateTime today = DateTime(n.year, n.month, n.day);

    // Date de départ : première utilisation, sinon la plus ancienne conso.
    DateTime? start = _parseKey(firstUseDateKey);
    if (start == null) {
      String? earliest;
      for (final k in dailyMap.keys) {
        if (earliest == null || k.compareTo(earliest) < 0) earliest = k;
      }
      start = _parseKey(earliest ?? '');
    }
    if (start == null || start.isAfter(today)) return 100.0;

    final int days = today.difference(start).inDays + 1;
    final history = List<int>.generate(days, (i) {
      final key = dateKey(start!.add(Duration(days: i)));
      return dailyMap[key] ?? 0;
    });

    return currentHp(history);
  }

  /// Parse une clé 'yyyy-MM-dd' en date locale ; null si vide/invalide.
  static DateTime? _parseKey(String key) {
    if (key.isEmpty) return null;
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
