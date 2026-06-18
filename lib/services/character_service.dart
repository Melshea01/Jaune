import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

import '../utils/date_keys.dart';
import 'jaune_health_model.dart';

// ---------------------------------------------------------------------------
// XP curve — coût en XP pour passer au niveau suivant
// ---------------------------------------------------------------------------
int xpRequiredForLevel(int targetLevel) {
  if (targetLevel <= 1) return 0;
  if (targetLevel <= 5) return 100;
  if (targetLevel <= 10) return 140;
  if (targetLevel <= 15) return 180;
  if (targetLevel <= 20) return 230;
  if (targetLevel <= 30) return 300;
  return 400;
}

// ---------------------------------------------------------------------------
// Déblocables par niveau
// ---------------------------------------------------------------------------
enum UnlockType {
  citronState, // nouvel état visuel Rive
  feature, // fonctionnalité app
  badge, // badge partageable
  message, // nouveaux messages du citron
}

/// Pure data : les libellés localisés sont résolus par clé dans
/// lib/l10n/l10n_helpers.dart (unlockTitle / unlockDescription)
class LevelUnlock {
  final int level;
  final UnlockType type;
  final String key;

  const LevelUnlock({
    required this.level,
    required this.type,
    required this.key,
  });
}

const List<LevelUnlock> kLevelUnlocks = [
  // --- Phase découverte (niv. 1-5) ---
  LevelUnlock(level: 2, type: UnlockType.message, key: 'messages_lvl2'),
  LevelUnlock(level: 3, type: UnlockType.feature, key: 'history_7d'),
  LevelUnlock(level: 4, type: UnlockType.citronState, key: 'skin_sunglasses'),
  LevelUnlock(level: 5, type: UnlockType.badge, key: 'badge_first_step'),

  // --- Phase engagement (niv. 6-15) ---
  LevelUnlock(level: 6, type: UnlockType.citronState, key: 'state_happy'),
  LevelUnlock(level: 7, type: UnlockType.citronState, key: 'skin_party_hat'),
  LevelUnlock(level: 8, type: UnlockType.feature, key: 'weekly_insight'),
  LevelUnlock(level: 10, type: UnlockType.citronState, key: 'state_tired'),
  LevelUnlock(level: 12, type: UnlockType.feature, key: 'stats_advanced'),
  LevelUnlock(level: 14, type: UnlockType.citronState, key: 'skin_crown'),
  LevelUnlock(level: 15, type: UnlockType.badge, key: 'badge_regularity'),

  // --- Phase maîtrise (niv. 16+) ---
  LevelUnlock(level: 16, type: UnlockType.citronState, key: 'state_wise'),
  LevelUnlock(level: 18, type: UnlockType.citronState, key: 'skin_gold'),
  LevelUnlock(level: 20, type: UnlockType.citronState, key: 'skin_dark'),
  LevelUnlock(level: 25, type: UnlockType.message, key: 'messages_deep'),
  LevelUnlock(level: 30, type: UnlockType.badge, key: 'badge_master'),
];

// ---------------------------------------------------------------------------
// XpEvent — pour notifier l'UI de ce qui a été gagné
// ---------------------------------------------------------------------------

/// Raison d'un gain d'XP. Jamais persisté : refactor sûr.
/// Libellé localisé résolu à l'affichage (xpReasonLabel).
enum XpReason {
  appOpen,
  dailyLog,
  soberYesterday,
  greenDay,
  soberStreak,
  perfectWeek,
}

class XpEvent {
  final int amount;
  final XpReason reason;

  /// Valeur contextuelle (ex : nombre de jours du streak)
  final int? value;

  const XpEvent(this.amount, this.reason, {this.value});
}

// ---------------------------------------------------------------------------
// CharacterProfile (Plain Old Dart Object)
// ---------------------------------------------------------------------------
class CharacterProfile {
  int xp;
  int level;
  int maxPv;
  int currentPv;

  String lastXpAwardDate; // jour J : comportement (sobre/verte/semaine)
  String lastAppOpenDate; // jour J : bonus ouverture app
  String lastLogDate; // jour J : bonus enregistrement
  String lastPerfectWeekDate; // clé semaine ISO : bonus semaine parfaite
  String firstUseDate; // première utilisation — ancre des streaks
  int soberStreakDays; // jours sobres consécutifs (dérivé du calendrier)
  String equippedSkin; // clé du skin porté ('' = citron classique)

  String username; // pseudo affiché dans le classement entre amis ('' = non défini)
  String userId; // identifiant stable / code ami ('' = pas encore généré)

  CharacterProfile({
    this.xp = 0,
    this.level = 1,
    this.maxPv = 100,
    int? currentPv,
    this.lastXpAwardDate = '',
    this.lastAppOpenDate = '',
    this.lastLogDate = '',
    this.lastPerfectWeekDate = '',
    this.firstUseDate = '',
    this.soberStreakDays = 0,
    this.equippedSkin = '',
    this.username = '',
    this.userId = '',
  }) : currentPv = currentPv ?? 100;

  static final Map<String, List<String>> _assetMessages = {};
  static String _loadedMessagesLocale = '';

  /// Charge les messages du citron pour la langue donnée ('fr' ou 'en').
  /// Rechargé si la langue change (changement dans les réglages).
  static Future<void> ensureMessagesLoaded([String languageCode = 'fr']) async {
    if (_loadedMessagesLocale == languageCode && _assetMessages.isNotEmpty) {
      return;
    }
    try {
      final String asset =
          languageCode == 'fr'
              ? 'assets/character_messages.json'
              : 'assets/character_messages_en.json';
      final String raw = await rootBundle.loadString(asset);
      final Map<String, dynamic> decoded =
          json.decode(raw) as Map<String, dynamic>;
      _assetMessages.clear();
      decoded.forEach((k, v) {
        if (v is List) _assetMessages[k] = v.map((e) => e.toString()).toList();
      });
      _loadedMessagesLocale = languageCode;
      debugPrint('Loaded messages ($languageCode): ${_assetMessages.keys.toList()}');
    } catch (e) {
      debugPrint('Failed to load character messages: $e');
    }
  }

  // --- Getters ---

  int get xpToNextLevel => xpRequiredForLevel(level + 1);

  double get levelProgress {
    final int needed = xpToNextLevel;
    if (needed <= 0) return 1.0;
    return (xp / needed).clamp(0.0, 1.0);
  }

  String get levelPhase {
    if (level <= 5) return 'discovery';
    if (level <= 15) return 'engagement';
    return 'mastery';
  }

  List<LevelUnlock> get acquiredUnlocks =>
      kLevelUnlocks.where((u) => u.level <= level).toList();

  bool hasUnlock(String key) => acquiredUnlocks.any((u) => u.key == key);

  double get healthPercent {
    if (maxPv <= 0) return 1.0;
    return (currentPv / maxPv).clamp(0.0, 1.0).toDouble();
  }

  String get zone {
    final double pct = healthPercent;
    if (pct > 0.75) return 'power';
    if (pct > 0.50) return 'warning';
    if (pct > 0.25) return 'danger';
    if (pct > 0.0) return 'critical';
    return 'dead';
  }

  /// Dernier message affiché (index global) — évite la répétition immédiate
  static int _lastMessageIndex = -1;

  String get message {
    try {
      final List<String> pool = _assetMessages[zone] ?? [];
      if (pool.isEmpty) return '';
      if (pool.length == 1) return pool.first;
      int idx;
      do {
        idx = math.Random().nextInt(pool.length);
      } while (idx == _lastMessageIndex);
      _lastMessageIndex = idx;
      return pool[idx];
    } catch (_) {
      return '';
    }
  }

  // --- Sérialisation ---

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'level': level,
    'maxPv': maxPv,
    'currentPv': currentPv,
    'lastXpAwardDate': lastXpAwardDate,
    'lastAppOpenDate': lastAppOpenDate,
    'lastLogDate': lastLogDate,
    'lastPerfectWeekDate': lastPerfectWeekDate,
    'firstUseDate': firstUseDate,
    'soberStreakDays': soberStreakDays,
    'equippedSkin': equippedSkin,
    'username': username,
    'userId': userId,
  };

  static CharacterProfile fromJson(Map<String, dynamic> p) => CharacterProfile(
    xp: (p['xp'] as int?) ?? 0,
    level: (p['level'] as int?) ?? 1,
    maxPv: (p['maxPv'] as int?) ?? 100,
    currentPv: (p['currentPv'] as int?) ?? 100,
    lastXpAwardDate: (p['lastXpAwardDate'] as String?) ?? '',
    lastAppOpenDate: (p['lastAppOpenDate'] as String?) ?? '',
    lastLogDate: (p['lastLogDate'] as String?) ?? '',
    lastPerfectWeekDate: (p['lastPerfectWeekDate'] as String?) ?? '',
    firstUseDate: (p['firstUseDate'] as String?) ?? '',
    soberStreakDays: (p['soberStreakDays'] as int?) ?? 0,
    equippedSkin: (p['equippedSkin'] as String?) ?? '',
    username: (p['username'] as String?) ?? '',
    userId: (p['userId'] as String?) ?? '',
  );
}

// ---------------------------------------------------------------------------
// CharacterService
// ---------------------------------------------------------------------------
class CharacterService {
  static const String _kProfileKey = 'character_profile';
  CharacterProfile _profile = CharacterProfile();
  bool _isSavingProfile = false;

  // --- Getters directs ---
  CharacterProfile get profile => _profile;
  int get level => _profile.level;
  double get healthPercent => _profile.healthPercent;
  String get currentMessage => _profile.message;
  double get levelProgress => _profile.levelProgress;
  int get xpToNextLevel => _profile.xpToNextLevel;
  String get levelPhase => _profile.levelPhase;
  int get soberStreakDays => _profile.soberStreakDays;
  bool hasUnlock(String key) => _profile.hasUnlock(key);
  List<LevelUnlock> get acquiredUnlocks => _profile.acquiredUnlocks;

  // --- Persistance ---

  Future<CharacterProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kProfileKey);
      _profile =
          raw != null && raw.isNotEmpty
              ? CharacterProfile.fromJson(
                json.decode(raw) as Map<String, dynamic>,
              )
              : CharacterProfile(maxPv: 100, currentPv: 100);

      // Ancre des streaks : avant cette date, aucune donnée n'existe —
      // on ne peut rien affirmer sur la sobriété
      if (_profile.firstUseDate.isEmpty) {
        _profile.firstUseDate = _dateKey(DateTime.now());
        await saveProfile();
      }
      return _profile;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _profile = CharacterProfile(maxPv: 100, currentPv: 100);
      return _profile;
    }
  }

  Future<void> saveProfile() async {
    if (_isSavingProfile) return;
    _isSavingProfile = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileKey, json.encode(_profile.toJson()));
    } catch (e) {
      debugPrint('Error saving profile: $e');
    } finally {
      _isSavingProfile = false;
    }
  }

  // --- Logique métier ---

  /// Skin équipé, observable : la home re-rend le citron sans devoir
  /// faire transiter un callback à travers les sheets
  final ValueNotifier<String> equippedSkin = ValueNotifier<String>('');

  Future<void> equipSkin(String key) async {
    _profile.equippedSkin = key;
    equippedSkin.value = key;
    await saveProfile();
  }

  void updateProfile(CharacterProfile p) {
    _profile = p;
    equippedSkin.value = p.equippedSkin;
  }

  void updateHealth(double newHealthPercent) {
    final p = newHealthPercent.clamp(0.0, 1.0);
    _profile.currentPv = (p * _profile.maxPv).round().clamp(0, _profile.maxPv);
  }

  List<int> _addXp(int amount) {
    final List<int> newLevels = [];
    _profile.xp += amount;
    while (_profile.xp >= xpRequiredForLevel(_profile.level + 1)) {
      _profile.xp -= xpRequiredForLevel(_profile.level + 1);
      _profile.level += 1;
      newLevels.add(_profile.level);
    }
    return newLevels;
  }

  Future<({XpEvent? xpEvent, List<int> newLevels, List<LevelUnlock> newUnlocks})>
  awardAppOpenXp() async {
    final String today = _dateKey(DateTime.now());
    if (_profile.lastAppOpenDate == today) {
      return (xpEvent: null, newLevels: const <int>[], newUnlocks: const <LevelUnlock>[]);
    }

    _profile.lastAppOpenDate = today;
    final List<int> newLevels = _addXp(3);
    await saveProfile();
    final newUnlocks =
        kLevelUnlocks.where((u) => newLevels.contains(u.level)).toList();
    return (
      xpEvent: const XpEvent(3, XpReason.appOpen),
      newLevels: newLevels,
      newUnlocks: newUnlocks,
    );
  }

  /// [includeLogBonus] : ne donner le bonus « Enregistrement du jour » que
  /// lors d'une vraie action de log de l'utilisateur — pas au simple
  /// recalcul de santé à l'ouverture de l'app (sinon +3 XP gratuits/jour).
  Future<
    ({
      List<XpEvent> xpEvents,
      List<int> newLevels,
      List<LevelUnlock> newUnlocks,
    })
  >
  awardDailyLogXp(
    Map<String, int> dailyMap, {
    bool includeLogBonus = true,
  }) async {
    final List<XpEvent> events = [];
    List<int> newLevels = [];
    List<LevelUnlock> newUnlocks = [];

    try {
      final int levelBefore = _profile.level;

      // Le streak est DÉRIVÉ du calendrier à chaque recalcul — source unique
      // de vérité (l'ancien compteur incrémental dérivait : il survivait aux
      // jours de conso jamais évalués et sous-comptait les absences sobres)
      _profile.soberStreakDays = computeSoberStreak(dailyMap);

      // Bonus pour l'enregistrement quotidien
      final String today = _dateKey(DateTime.now());
      if (includeLogBonus && _profile.lastLogDate != today) {
        _profile.lastLogDate = today;
        _addXp(3);
        events.add(const XpEvent(3, XpReason.dailyLog));
      }

      // Bonus de comportement (1x par jour)
      if (_profile.lastXpAwardDate != today) {
        final behaviorEvents = _awardBehaviorXp(dailyMap);
        events.addAll(behaviorEvents);
        _profile.lastXpAwardDate = today;
      }

      // Vérifier les nouveaux niveaux et déblocages
      if (_profile.level > levelBefore) {
        newLevels = List.generate(
          _profile.level - levelBefore,
          (i) => levelBefore + i + 1,
        );
        newUnlocks =
            kLevelUnlocks.where((u) => newLevels.contains(u.level)).toList();
      }

      if (events.isNotEmpty) {
        await saveProfile();
      }
    } catch (e) {
      debugPrint('Error in awardDailyLogXp: $e');
    }

    return (xpEvents: events, newLevels: newLevels, newUnlocks: newUnlocks);
  }

  /// Les bonus de comportement évaluent la journée d'HIER (terminée).
  /// Avant : « aujourd'hui » était jugé à l'ouverture matinale — l'utilisateur
  /// gagnait +5 XP « journée sobre » à 9h puis pouvait boire le soir en
  /// gardant l'XP et le streak (évalués une seule fois par jour).
  List<XpEvent> _awardBehaviorXp(Map<String, int> dailyMap) {
    final List<XpEvent> events = [];
    final DateTime now = DateTime.now();
    final DateTime todayDt = DateTime(now.year, now.month, now.day);

    int drinksAt(int offset) {
      final String k = _dateKey(todayDt.subtract(Duration(days: offset)));
      return dailyMap[k] ?? 0;
    }

    final int yesterdayDrinks = drinksAt(1);

    // Journée sobre (hier, journée close). Condition sur le streak dérivé :
    // streak ≥ 1 ⟺ hier était sobre ET couvert par les données (pas un jour
    // d'avant la première utilisation)
    if (_profile.soberStreakDays > 0) {
      _addXp(5);
      events.add(const XpEvent(5, XpReason.soberYesterday));
    }

    // Journée verte (hier : 1-2 verres + un jour sobre dans la semaine d'avant)
    if (yesterdayDrinks > 0 && yesterdayDrinks <= 2) {
      bool hasSoberDayInWeek = false;
      for (int i = 2; i <= 8; i++) {
        if (drinksAt(i) == 0) {
          hasSoberDayInWeek = true;
          break;
        }
      }
      if (hasSoberDayInWeek) {
        _addXp(10);
        events.add(const XpEvent(10, XpReason.greenDay));
      }
    }

    // Streak de 3 jours sobres
    if (_profile.soberStreakDays > 0 && _profile.soberStreakDays % 3 == 0) {
      _addXp(8);
      events.add(
        XpEvent(8, XpReason.soberStreak, value: _profile.soberStreakDays),
      );
    }

    // Semaine parfaite — jugée sur la semaine PRÉCÉDENTE COMPLÈTE
    // (lundi → dimanche clos). L'ancienne version évaluait la semaine en
    // cours partielle : sobre lundi-mardi suffisait pour décrocher le bonus
    // dès mercredi, beuverie libre ensuite.
    final DateTime lastSunday = todayDt.subtract(
      Duration(days: todayDt.weekday),
    );
    final DateTime lastMonday = lastSunday.subtract(const Duration(days: 6));
    final String prevWeekKey = _isoWeekKey(lastSunday);
    final bool weekFullyCovered =
        _profile.firstUseDate.isNotEmpty &&
        _profile.firstUseDate.compareTo(_dateKey(lastMonday)) <= 0;

    if (weekFullyCovered && _profile.lastPerfectWeekDate != prevWeekKey) {
      int weekTotal = 0;
      int soberDays = 0;
      for (int i = 0; i < 7; i++) {
        final int v =
            dailyMap[_dateKey(lastMonday.add(Duration(days: i)))] ?? 0;
        weekTotal += v;
        if (v == 0) soberDays++;
      }
      if (weekTotal <= 7 && soberDays >= 2) {
        _profile.lastPerfectWeekDate = prevWeekKey;
        _addXp(15);
        events.add(const XpEvent(15, XpReason.perfectWeek));
      }
    }

    return events;
  }

  /// Jours sobres consécutifs, dérivés du calendrier : marche arrière depuis
  /// hier tant que la journée est sans conso, bornée par la première
  /// utilisation de l'app (avant : aucune donnée, on ne compte pas).
  /// Source unique de vérité pour le badge, les bonus ET la régénération.
  int computeSoberStreak(Map<String, int> dailyMap) {
    if (_profile.firstUseDate.isEmpty) return 0;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    int streak = 0;
    for (int i = 1; i <= 365; i++) {
      final DateTime day = today.subtract(Duration(days: i));
      if (_profile.firstUseDate.compareTo(_dateKey(day)) > 0) break;
      if ((dailyMap[_dateKey(day)] ?? 0) > 0) break;
      streak++;
    }
    return streak;
  }

  // --- Modèle de santé « santé de fond » (cf. jaune_health_model.dart) ---

  /// Santé de l'utilisateur en fraction [0, 1], dérivée de l'historique de
  /// consommation via le modèle PV « santé de fond ». Délègue toute la logique
  /// de calibration à [JauneHealthModel] ; ici on se contente d'adapter
  /// l'historique (dailyMap + première utilisation) et de normaliser en [0, 1].
  double computeHealthFromRisk(Map<String, int> dailyMap) {
    try {
      if (dailyMap.isEmpty) return 1.0;
      final double pv = JauneHealthModel.currentHpFromHistory(
        dailyMap,
        firstUseDateKey: _profile.firstUseDate,
      );
      return (pv / 100.0).clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error in computeHealthFromRisk: $e');
      return 1.0;
    }
  }

  // --- Helpers date ---
  static String _dateKey(DateTime d) => dateKey(d);

  static String _isoWeekKey(DateTime d) {
    final DateTime thu = d.add(Duration(days: 4 - d.weekday));
    final int weekNum =
        ((thu.difference(DateTime(thu.year)).inDays) / 7).floor() + 1;
    return '${thu.year}-W${weekNum.toString().padLeft(2, '0')}';
  }
}
