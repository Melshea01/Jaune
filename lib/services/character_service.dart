import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;

// ---------------------------------------------------------------------------
// XP curve — coût en XP pour passer au niveau suivant
// Phase 1 (niv. 1-5)   : 100 XP/niv  → découverte
// Phase 2 (niv. 6-15)  : 120-180/niv  → engagement
// Phase 3 (niv. 16-30) : 200-300/niv  → maîtrise
// Phase 4 (niv. 31+)   : 400 XP/niv   → prestige
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
  feature,     // fonctionnalité app
  badge,       // badge partageable
  message,     // nouveaux messages du citron
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
  LevelUnlock(level: 2,  type: UnlockType.message,     key: 'messages_lvl2',    title: 'Le citron parle',        description: 'Premiers messages personnalisés'),
  LevelUnlock(level: 3,  type: UnlockType.feature,     key: 'history_7d',       title: 'Historique 7 jours',     description: 'Graphique de consommation débloqué'),
  LevelUnlock(level: 5,  type: UnlockType.badge,       key: 'badge_first_step', title: 'Badge "Premier pas"',    description: 'Tu as commencé ton parcours'),

  // --- Phase engagement (niv. 6-15) ---
  LevelUnlock(level: 6,  type: UnlockType.citronState, key: 'state_happy',      title: 'Citron heureux',         description: 'Nouvel état visuel — bonne conso'),
  LevelUnlock(level: 8,  type: UnlockType.feature,     key: 'weekly_insight',   title: 'Insight hebdomadaire',   description: 'Analyse de ta semaine'),
  LevelUnlock(level: 10, type: UnlockType.citronState, key: 'state_tired',      title: 'Citron fatigué',         description: 'État long terme visible'),
  LevelUnlock(level: 12, type: UnlockType.feature,     key: 'stats_advanced',   title: 'Stats avancées',         description: 'Tendances et comparaisons'),
  LevelUnlock(level: 15, type: UnlockType.badge,       key: 'badge_regularity', title: 'Badge "Régularité"',     description: '30 jours d\'utilisation'),

  // --- Phase maîtrise (niv. 16+) ---
  LevelUnlock(level: 16, type: UnlockType.citronState, key: 'state_wise',       title: 'Citron sage',            description: 'Expression rare, longue sobriété'),
  LevelUnlock(level: 20, type: UnlockType.citronState, key: 'skin_dark',        title: 'Skin sombre',            description: 'Apparence alternative du citron'),
  LevelUnlock(level: 25, type: UnlockType.message,     key: 'messages_deep',    title: 'Messages profonds',      description: 'Réflexions sur ton chemin'),
  LevelUnlock(level: 30, type: UnlockType.badge,       key: 'badge_master',     title: 'Badge "Maître citron"',  description: 'Rare et partageable'),
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
// CharacterProfile
// ---------------------------------------------------------------------------
class CharacterProfile {
  int xp;
  int level;
  int maxPv;
  int currentPv;

  String lastXpAwardDate;     // jour J : comportement (sobre/verte/semaine)
  String lastAppOpenDate;     // jour J : bonus ouverture app
  String lastLogDate;         // jour J : bonus enregistrement
  String lastPerfectWeekDate; // clé semaine ISO : bonus semaine parfaite
  int soberStreakDays;        // jours sobres consécutifs courants

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
      final String raw =
          await rootBundle.loadString('assets/character_messages.json');
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

  /// Ensures messages are loaded before use - FIX FOR RACE CONDITION
  static Future<void> ensureMessagesLoaded() async {
    await _loadMessagesFromAsset();
  }

  // --- XP / Niveau ---

  /// XP nécessaire pour passer au niveau suivant.
  int get xpToNextLevel => xpRequiredForLevel(level + 1);

  /// Progression dans le niveau actuel, de 0.0 à 1.0.
  double get levelProgress {
    final int needed = xpToNextLevel;
    if (needed <= 0) return 1.0;
    return (xp / needed).clamp(0.0, 1.0);
  }

  /// Phase de progression : 'discovery' | 'engagement' | 'mastery'
  String get levelPhase {
    if (level <= 5) return 'discovery';
    if (level <= 15) return 'engagement';
    return 'mastery';
  }

  /// Ajoute des XP, fait monter les niveaux si nécessaire.
  /// Retourne la liste des niveaux nouvellement atteints.
  List<int> addXp(int amount) {
    final List<int> newLevels = [];
    xp += amount;
    while (xp >= xpRequiredForLevel(level + 1)) {
      xp -= xpRequiredForLevel(level + 1);
      level += 1;
      newLevels.add(level);
    }
    return newLevels;
  }

  /// Déblocables déclenchés par une liste de nouveaux niveaux.
  List<LevelUnlock> unlocksForLevels(List<int> newLevels) =>
      kLevelUnlocks.where((u) => newLevels.contains(u.level)).toList();

  /// Tous les déblocables acquis jusqu'au niveau actuel.
  List<LevelUnlock> get acquiredUnlocks =>
      kLevelUnlocks.where((u) => u.level <= level).toList();

  bool hasUnlock(String key) => acquiredUnlocks.any((u) => u.key == key);

  // --- HP / Zone ---

  double healthPercent() {
    if (maxPv <= 0) return 1.0;
    return (currentPv / maxPv).clamp(0.0, 1.0).toDouble();
  }

  void setHealthPercent(double pct) {
    final p = pct.clamp(0.0, 1.0);
    currentPv = (p * maxPv).round().clamp(0, maxPv);
  }

  String zoneFromPercent() {
    final double pct = healthPercent();
    if (pct > 0.75) return 'power';
    if (pct > 0.50) return 'warning';
    if (pct > 0.25) return 'danger';
    if (pct > 0.0) return 'critical';
    return 'dead';
  }

  // --- Messages ---

  String getMessage() {
    try {
      final List<String> pool = messagesForZone(zoneFromPercent());
      if (pool.isEmpty) return '';
      return pool[math.Random().nextInt(pool.length)];
    } catch (_) {
      return '';
    }
  }

  String get message => getMessage();

  List<String> messagesForZone(String zone) {
    if (_assetMessages.containsKey(zone)) {
      return List<String>.from(_assetMessages[zone]!);
    }
    // Messages not loaded yet - return empty to prevent UI breaking
    // ensureMessagesLoaded() should have been called in app initialization
    return [];
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

  Future<void> _saveToPrefs(SharedPreferences prefs, String key) async {
    try {
      await prefs.setString(key, json.encode(toJson()));
    } catch (_) {}
  }

  // --- Attribution XP ---

  /// Bonus ouverture app (+3 XP, 1x/jour).
  Future<XpEvent?> awardAppOpenXp(
      SharedPreferences prefs, String key) async {
    final String today = _dateKey(DateTime.now());
    if (lastAppOpenDate == today) return null;
    lastAppOpenDate = today;
    addXp(3);
    await _saveToPrefs(prefs, key);
    return const XpEvent(3, 'Ouverture de l\'app');
  }

  /// Bonus enregistrement (+3 XP, 1x/jour, même si bu).
  Future<XpEvent?> awardDailyLogXp(
      SharedPreferences prefs, String key) async {
    final String today = _dateKey(DateTime.now());
    if (lastLogDate == today) return null;
    lastLogDate = today;
    addXp(3);
    await _saveToPrefs(prefs, key);
    return const XpEvent(3, 'Enregistrement du jour');
  }

  /// Évalue et attribue les XP de comportement (1x/jour).
  /// Sources :
  ///   +5  journée sobre (0 verre)
  ///   +10 journée verte (1-2v avec au moins 1j sobre cette semaine)
  ///   +8  streak 3j sobres consécutifs
  ///   +15 semaine parfaite (≤7v, ≥2j sobres — 1x/semaine)
  Future<List<XpEvent>> awardBehaviorXpIfNeeded(
    Map<String, int> dailyMap,
    SharedPreferences prefs,
    String key,
  ) async {
    final String today = _dateKey(DateTime.now());
    if (lastXpAwardDate == today) return [];

    final List<XpEvent> events = [];

    try {
      final DateTime now = DateTime.now();
      final DateTime todayDt = DateTime(now.year, now.month, now.day);

      int drinksAt(int offset) {
        final String k = _dateKey(todayDt.subtract(Duration(days: offset)));
        return dailyMap[k] ?? 0;
      }

      final int todayDrinks = drinksAt(0);

      // Journée sobre
      if (todayDrinks == 0) {
        soberStreakDays++;
        addXp(5);
        events.add(const XpEvent(5, 'Journée sobre'));
      } else {
        soberStreakDays = 0;
      }

      // Journée verte
      if (todayDrinks > 0 && todayDrinks <= 2) {
        bool hasSoberDay = false;
        for (int i = 1; i <= 7; i++) {
          if (drinksAt(i) == 0) {
            hasSoberDay = true;
            break;
          }
        }
        if (hasSoberDay) {
          addXp(10);
          events.add(const XpEvent(10, 'Journée verte'));
        }
      }

      // Streak tous les 3 jours sobres
      if (soberStreakDays > 0 && soberStreakDays % 3 == 0) {
        addXp(8);
        events.add(XpEvent(8, '$soberStreakDays jours sobres d\'affilée'));
      }

      // Semaine parfaite (1x/semaine)
      final String isoWeek = _isoWeekKey(todayDt);
      if (lastPerfectWeekDate != isoWeek) {
        int weekTotal = 0;
        int soberDays = 0;
        final int dayOfWeek = todayDt.weekday; // 1 = lundi
        for (int i = 0; i < dayOfWeek; i++) {
          final int v = drinksAt(i);
          weekTotal += v;
          if (v == 0) soberDays++;
        }
        if (weekTotal <= 7 && soberDays >= 2) {
          lastPerfectWeekDate = isoWeek;
          addXp(15);
          events.add(const XpEvent(15, 'Semaine parfaite'));
        }
      }

      lastXpAwardDate = today;
      await _saveToPrefs(prefs, key);
    } catch (e) {
      debugPrint('awardBehaviorXpIfNeeded error: $e');
    }

    return events;
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

// ---------------------------------------------------------------------------
// CharacterService
// ---------------------------------------------------------------------------
class CharacterService {
  static const String _kProfileKey = 'character_profile';
  CharacterProfile _profile = CharacterProfile();
  // FIX: Add lock for SharedPreferences synchronization
  bool _isSavingProfile = false;

  CharacterProfile get profile => _profile;
  int get level => _profile.level;
  double get healthPercent => _profile.healthPercent();
  String get currentMessage => _profile.message;
  double get levelProgress => _profile.levelProgress;
  int get xpToNextLevel => _profile.xpToNextLevel;
  String get levelPhase => _profile.levelPhase;
  bool hasUnlock(String key) => _profile.hasUnlock(key);
  List<LevelUnlock> get acquiredUnlocks => _profile.acquiredUnlocks;

  // --- Persistance ---

  Future<CharacterProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kProfileKey);
      _profile = raw != null && raw.isNotEmpty
          ? CharacterProfile.fromJson(json.decode(raw) as Map<String, dynamic>)
          : CharacterProfile(maxPv: 100, currentPv: 100);
      return _profile;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _profile = CharacterProfile(maxPv: 100, currentPv: 100);
      return _profile;
    }
  }

  Future<void> saveProfile() async {
    // FIX: Prevent concurrent saves with flag lock
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

  void updateProfile(CharacterProfile p) => _profile = p;
  void updateHealth(double hp) => _profile.setHealthPercent(hp);

  // --- Attribution XP publique ---

  /// À appeler à chaque ouverture de l'app.
  Future<XpEvent?> awardAppOpenXp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await _profile.awardAppOpenXp(prefs, _kProfileKey);
    } catch (e) {
      debugPrint('Error awarding app open XP: $e');
      return null;
    }
  }

  /// À appeler quand l'utilisateur enregistre sa conso du jour.
  /// Retourne les XP gagnés + les nouveaux déblocables déclenchés.
  Future<({List<XpEvent> xpEvents, List<LevelUnlock> newUnlocks})>
      awardDailyLogXp(Map<String, int> dailyMap) async {
    final List<XpEvent> events = [];
    List<LevelUnlock> newUnlocks = [];

    try {
      final prefs = await SharedPreferences.getInstance();

      final int levelBefore = _profile.level;

      final XpEvent? logEvent =
          await _profile.awardDailyLogXp(prefs, _kProfileKey);
      if (logEvent != null) events.add(logEvent);

      final List<XpEvent> behaviorEvents =
          await _profile.awardBehaviorXpIfNeeded(dailyMap, prefs, _kProfileKey);
      events.addAll(behaviorEvents);

      // Déblocables liés aux niveaux nouvellement atteints
      if (_profile.level > levelBefore) {
        final List<int> gained = List.generate(
          _profile.level - levelBefore,
          (i) => levelBefore + i + 1,
        );
        newUnlocks = _profile.unlocksForLevels(gained);
      }
    } catch (e) {
      debugPrint('Error in awardDailyLogXp: $e');
    }

    return (xpEvents: events, newUnlocks: newUnlocks);
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
        final String k = CharacterProfile._dateKey(
            today.subtract(Duration(days: offsetDays)));
        return dailyMap[k] ?? 0;
      }

      final int todayDrinks = drinksAt(0);
      final int yesterdayDrinks = drinksAt(1);

      final double stDmg =
          _dailyDamage(todayDrinks) + _dailyDamage(yesterdayDrinks) * 0.5;
      final double bingePenalty =
          (todayDrinks >= 6 ? 15.0 : 0.0) + (yesterdayDrinks >= 6 ? 8.0 : 0.0);

      int weekSum = 0;
      int soberDaysInWeek = 0;
      for (int i = 2; i <= 8; i++) {
        final int v = drinksAt(i);
        weekSum += v;
        if (v == 0) soberDaysInWeek++;
      }

      final double ltDmg = math.max(0, weekSum - 7) * 2.2;
      final double noPausePenalty =
          soberDaysInWeek < 2 ? (2 - soberDaysInWeek) * 6.0 : 0.0;

      int streak = 0;
      for (int i = 1; i <= 8; i++) {
        if (drinksAt(i) == 0) {
          streak++;
        } else {
          break;
        }
      }
      final double regen = math.min(streak * 4.0, 18.0);

      return ((100.0 - stDmg - bingePenalty - ltDmg - noPausePenalty + regen)
              .clamp(0.0, 100.0)) /
          100.0;
    } catch (e) {
      debugPrint('Error in computeHealthFromRisk: $e');
      return 1.0;
    }
  }
}
