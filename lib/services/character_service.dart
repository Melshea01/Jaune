import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;

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

class LevelUnlock {
  final int level;
  final UnlockType type;
  final String key;
  final String title;
  final String description;

  const LevelUnlock({
    required this.level,
    required this.type,
    required this.key,
    required this.title,
    required this.description,
  });
}

const List<LevelUnlock> kLevelUnlocks = [
  // --- Phase découverte (niv. 1-5) ---
  LevelUnlock(
    level: 2,
    type: UnlockType.message,
    key: 'messages_lvl2',
    title: 'Le citron parle',
    description: 'Premiers messages personnalisés',
  ),
  LevelUnlock(
    level: 3,
    type: UnlockType.feature,
    key: 'history_7d',
    title: 'Historique 7 jours',
    description: 'Graphique de consommation débloqué',
  ),
  LevelUnlock(
    level: 5,
    type: UnlockType.badge,
    key: 'badge_first_step',
    title: 'Badge "Premier pas"',
    description: 'Tu as commencé ton parcours',
  ),

  // --- Phase engagement (niv. 6-15) ---
  LevelUnlock(
    level: 6,
    type: UnlockType.citronState,
    key: 'state_happy',
    title: 'Citron heureux',
    description: 'Nouvel état visuel — bonne conso',
  ),
  LevelUnlock(
    level: 8,
    type: UnlockType.feature,
    key: 'weekly_insight',
    title: 'Insight hebdomadaire',
    description: 'Analyse de ta semaine',
  ),
  LevelUnlock(
    level: 10,
    type: UnlockType.citronState,
    key: 'state_tired',
    title: 'Citron fatigué',
    description: 'État long terme visible',
  ),
  LevelUnlock(
    level: 12,
    type: UnlockType.feature,
    key: 'stats_advanced',
    title: 'Stats avancées',
    description: 'Tendances et comparaisons',
  ),
  LevelUnlock(
    level: 15,
    type: UnlockType.badge,
    key: 'badge_regularity',
    title: 'Badge "Régularité"',
    description: '30 jours d\'utilisation',
  ),

  // --- Phase maîtrise (niv. 16+) ---
  LevelUnlock(
    level: 16,
    type: UnlockType.citronState,
    key: 'state_wise',
    title: 'Citron sage',
    description: 'Expression rare, longue sobriété',
  ),
  LevelUnlock(
    level: 20,
    type: UnlockType.citronState,
    key: 'skin_dark',
    title: 'Skin sombre',
    description: 'Apparence alternative du citron',
  ),
  LevelUnlock(
    level: 25,
    type: UnlockType.message,
    key: 'messages_deep',
    title: 'Messages profonds',
    description: 'Réflexions sur ton chemin',
  ),
  LevelUnlock(
    level: 30,
    type: UnlockType.badge,
    key: 'badge_master',
    title: 'Badge "Maître citron"',
    description: 'Rare et partageable',
  ),
];

// ---------------------------------------------------------------------------
// XpEvent — pour notifier l'UI de ce qui a été gagné
// ---------------------------------------------------------------------------
class XpEvent {
  final int amount;
  final String reason;
  const XpEvent(this.amount, this.reason);
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
  int soberStreakDays; // jours sobres consécutifs courants

  CharacterProfile({
    this.xp = 0,
    this.level = 1,
    this.maxPv = 100,
    int? currentPv,
    this.lastXpAwardDate = '',
    this.lastAppOpenDate = '',
    this.lastLogDate = '',
    this.lastPerfectWeekDate = '',
    this.soberStreakDays = 0,
  }) : currentPv = currentPv ?? 100;

  static final Map<String, List<String>> _assetMessages = {};
  static bool _assetLoadingStarted = false;

  static Future<void> _loadMessagesFromAsset() async {
    if (_assetMessages.isNotEmpty || _assetLoadingStarted) return;
    _assetLoadingStarted = true;
    try {
      final String raw = await rootBundle.loadString(
        'assets/character_messages.json',
      );
      final Map<String, dynamic> decoded =
          json.decode(raw) as Map<String, dynamic>;
      decoded.forEach((k, v) {
        if (v is List) _assetMessages[k] = v.map((e) => e.toString()).toList();
      });
      debugPrint('Loaded messages: ${_assetMessages.keys.toList()}');
    } catch (e) {
      debugPrint('Failed to load character messages: $e');
    }
  }

  static Future<void> ensureMessagesLoaded() async {
    await _loadMessagesFromAsset();
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

  String get message {
    try {
      final List<String> pool = _assetMessages[zone] ?? [];
      if (pool.isEmpty) return '';
      return pool[math.Random().nextInt(pool.length)];
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
    'soberStreakDays': soberStreakDays,
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
    soberStreakDays: (p['soberStreakDays'] as int?) ?? 0,
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

  void updateProfile(CharacterProfile p) => _profile = p;

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
      xpEvent: const XpEvent(3, 'Ouverture de l\'app'),
      newLevels: newLevels,
      newUnlocks: newUnlocks,
    );
  }

  Future<
    ({
      List<XpEvent> xpEvents,
      List<int> newLevels,
      List<LevelUnlock> newUnlocks,
    })
  >
  awardDailyLogXp(Map<String, int> dailyMap) async {
    final List<XpEvent> events = [];
    List<int> newLevels = [];
    List<LevelUnlock> newUnlocks = [];

    try {
      final int levelBefore = _profile.level;

      // Bonus pour l'enregistrement quotidien
      final String today = _dateKey(DateTime.now());
      if (_profile.lastLogDate != today) {
        _profile.lastLogDate = today;
        _addXp(3);
        events.add(const XpEvent(3, 'Enregistrement du jour'));
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

  List<XpEvent> _awardBehaviorXp(Map<String, int> dailyMap) {
    final List<XpEvent> events = [];
    final DateTime now = DateTime.now();
    final DateTime todayDt = DateTime(now.year, now.month, now.day);

    int drinksAt(int offset) {
      final String k = _dateKey(todayDt.subtract(Duration(days: offset)));
      return dailyMap[k] ?? 0;
    }

    final int todayDrinks = drinksAt(0);

    // Journée sobre
    if (todayDrinks == 0) {
      _profile.soberStreakDays++;
      _addXp(5);
      events.add(const XpEvent(5, 'Journée sobre'));
    } else {
      _profile.soberStreakDays = 0;
    }

    // Journée verte
    if (todayDrinks > 0 && todayDrinks <= 2) {
      bool hasSoberDayInWeek = false;
      for (int i = 1; i <= 7; i++) {
        if (drinksAt(i) == 0) {
          hasSoberDayInWeek = true;
          break;
        }
      }
      if (hasSoberDayInWeek) {
        _addXp(10);
        events.add(const XpEvent(10, 'Journée verte'));
      }
    }

    // Streak de 3 jours sobres
    if (_profile.soberStreakDays > 0 && _profile.soberStreakDays % 3 == 0) {
      _addXp(8);
      events.add(
        XpEvent(8, '${_profile.soberStreakDays} jours sobres d\'affilée'),
      );
    }

    // Semaine parfaite (1x/semaine)
    final String isoWeek = _isoWeekKey(todayDt);
    if (_profile.lastPerfectWeekDate != isoWeek) {
      int weekTotal = 0;
      int soberDays = 0;
      final int dayOfWeek = todayDt.weekday; // 1 = lundi
      for (int i = 0; i < dayOfWeek; i++) {
        final int v = drinksAt(i);
        weekTotal += v;
        if (v == 0) soberDays++;
      }
      if (weekTotal <= 7 && soberDays >= 2) {
        _profile.lastPerfectWeekDate = isoWeek;
        _addXp(15);
        events.add(const XpEvent(15, 'Semaine parfaite'));
      }
    }

    return events;
  }

  // --- Formule HP v3 (SPF / OMS 2023) ---

  double _dailyDamage(int drinks) {
    if (drinks <= 0) return 0;
    double dmg = math.min(drinks, 2) * 5.0;
    if (drinks > 2) dmg += math.min(drinks - 2, 3) * 9.0;
    if (drinks > 5) dmg += (drinks - 5) * 13.0;
    return dmg;
  }

  double computeHealthFromRisk(Map<String, int> dailyMap) {
    try {
      if (dailyMap.isEmpty) return 1.0;

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      int drinksAt(int offsetDays) {
        final String k = _dateKey(today.subtract(Duration(days: offsetDays)));
        return dailyMap[k] ?? 0;
      }

      // --- Calcul des dommages ---
      final int todayDrinks = drinksAt(0);
      final int yesterdayDrinks = drinksAt(1);

      // Dommage à court terme (2 derniers jours)
      final double shortTermDamage =
          _dailyDamage(todayDrinks) + _dailyDamage(yesterdayDrinks) * 0.5;

      // Pénalité pour consommation excessive (binge)
      final double bingePenalty =
          (todayDrinks >= 6 ? 15.0 : 0.0) + (yesterdayDrinks >= 6 ? 8.0 : 0.0);

      // Dommage à long terme (semaine passée)
      int weekSum = 0;
      int soberDaysInWeek = 0;
      for (int i = 2; i <= 8; i++) {
        final int v = drinksAt(i);
        weekSum += v;
        if (v == 0) soberDaysInWeek++;
      }
      final double longTermDamage = math.max(0, weekSum - 7) * 2.2;

      // Pénalité pour absence de pause
      final double noPausePenalty =
          soberDaysInWeek < 2 ? (2 - soberDaysInWeek) * 6.0 : 0.0;

      // --- Calcul de la régénération ---
      int soberStreak = 0;
      for (int i = 1; i <= 8; i++) {
        if (drinksAt(i) == 0) {
          soberStreak++;
        } else {
          break;
        }
      }
      final double regeneration = math.min(soberStreak * 4.0, 18.0);

      // --- Calcul final ---
      final double finalHealth =
          100.0 -
          shortTermDamage -
          bingePenalty -
          longTermDamage -
          noPausePenalty +
          regeneration;

      return (finalHealth.clamp(0.0, 100.0)) / 100.0;
    } catch (e) {
      debugPrint('Error in computeHealthFromRisk: $e');
      return 1.0;
    }
  }

  // --- Helpers date ---
  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _isoWeekKey(DateTime d) {
    final DateTime thu = d.add(Duration(days: 4 - d.weekday));
    final int weekNum =
        ((thu.difference(DateTime(thu.year)).inDays) / 7).floor() + 1;
    return '${thu.year}-W${weekNum.toString().padLeft(2, '0')}';
  }
}
