import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

import '../utils/date_keys.dart';
import 'jaune_health_model.dart';
import 'journey_data.dart';

// Le « Voyage du Citron » (types d'unlock, chapitres, 100 niveaux) vit dans
// journey_data.dart. On le ré-exporte pour que les imports existants de
// `character_service.dart` (UnlockType, LevelUnlock, kLevelUnlocks…) marchent.
export 'journey_data.dart';

// ---------------------------------------------------------------------------
// XP curve — coût en XP pour passer au niveau suivant (jusqu'à 100)
// ---------------------------------------------------------------------------
int xpRequiredForLevel(int targetLevel) {
  if (targetLevel <= 1) return 0;
  if (targetLevel <= 5) return 100;
  if (targetLevel <= 10) return 140;
  if (targetLevel <= 15) return 180;
  if (targetLevel <= 20) return 230;
  if (targetLevel <= 30) return 300;
  if (targetLevel <= 45) return 380;
  if (targetLevel <= 60) return 460;
  if (targetLevel <= 80) return 560;
  if (targetLevel <= 100) return 680;
  return 800;
}

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
  questComplete,
}

// ---------------------------------------------------------------------------
// Quêtes du jour — petites tâches quotidiennes (« toujours qqch à faire »)
// ---------------------------------------------------------------------------

/// Condition de complétion, évaluée à partir des données existantes.
enum QuestType {
  openApp, // ouvrir l'app aujourd'hui
  logToday, // enregistrer sa conso aujourd'hui
  soberToday, // 0 verre aujourd'hui
  underTwoToday, // ≤ 2 verres aujourd'hui
  keepStreak, // garder sa série (hier sobre)
}

/// Pure data : libellés résolus par clé en l10n (questTitle / questDesc).
class DailyQuest {
  final String id;
  final QuestType type;
  final int xpReward;

  const DailyQuest({
    required this.id,
    required this.type,
    required this.xpReward,
  });
}

const List<DailyQuest> kDailyQuests = [
  DailyQuest(id: 'open_app', type: QuestType.openApp, xpReward: 4),
  DailyQuest(id: 'log_day', type: QuestType.logToday, xpReward: 5),
  DailyQuest(id: 'sober_today', type: QuestType.soberToday, xpReward: 8),
  DailyQuest(id: 'under_two', type: QuestType.underTwoToday, xpReward: 6),
  DailyQuest(id: 'keep_streak', type: QuestType.keepStreak, xpReward: 6),
];

/// Nombre de quêtes proposées chaque jour.
const int kDailyQuestCount = 3;

/// État d'une quête pour l'affichage.
class QuestStatus {
  final DailyQuest quest;
  final bool completed;
  const QuestStatus(this.quest, this.completed);
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

  int streakShields; // boucliers « gel de série » disponibles
  List<String> frozenDays; // jours de conso « gelés » (pontés par un bouclier)

  String lastQuestDate; // jour des quêtes actives (reset au changement de jour)
  List<String> completedQuestIds; // quêtes du jour déjà validées

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
    this.streakShields = 0,
    List<String>? frozenDays,
    this.lastQuestDate = '',
    List<String>? completedQuestIds,
  })  : currentPv = currentPv ?? 100,
        frozenDays = frozenDays ?? [],
        completedQuestIds = completedQuestIds ?? [];

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
    'streakShields': streakShields,
    'frozenDays': frozenDays,
    'lastQuestDate': lastQuestDate,
    'completedQuestIds': completedQuestIds,
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
    streakShields: (p['streakShields'] as int?) ?? 0,
    frozenDays:
        (p['frozenDays'] as List?)?.map((e) => e.toString()).toList() ?? [],
    lastQuestDate: (p['lastQuestDate'] as String?) ?? '',
    completedQuestIds:
        (p['completedQuestIds'] as List?)?.map((e) => e.toString()).toList() ??
            [],
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
  int get streakShields => _profile.streakShields;
  bool hasUnlock(String key) => _profile.hasUnlock(key);
  List<LevelUnlock> get acquiredUnlocks => _profile.acquiredUnlocks;

  /// Plafond de boucliers « gel de série » accumulables.
  static const int kMaxShields = 3;

  /// Cible de l'objectif hebdomadaire : jours sobres dans la semaine en cours.
  static const int kWeeklyGoalSoberDays = 3;

  /// Variance haussière bornée (0..+20 %) appliquée aux gains de comportement
  /// et de quêtes : effet « récompense variable » sans jamais punir.
  final math.Random _rng = math.Random();
  int _vary(int base) {
    if (base <= 0) return base;
    final int span = (base * 0.2).ceil();
    return base + _rng.nextInt(span + 1);
  }

  /// Ajoute une XP variée et renvoie le montant réellement attribué.
  int _award(int base) {
    final int amount = _vary(base);
    _addXp(amount);
    return amount;
  }

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

  Future<
    ({
      List<XpEvent> xpEvents,
      List<int> newLevels,
      List<LevelUnlock> newUnlocks,
    })
  >
  awardAppOpenXp([Map<String, int>? dailyMap]) async {
    final String today = _dateKey(DateTime.now());
    final int levelBefore = _profile.level;
    final List<XpEvent> events = [];

    if (_profile.lastAppOpenDate != today) {
      _profile.lastAppOpenDate = today;
      _addXp(3);
      events.add(const XpEvent(3, XpReason.appOpen));
    }

    // Quêtes du jour (ex. « ouvrir l'app ») — idempotent
    events.addAll(_evaluateQuests(dailyMap ?? const {}));

    List<int> newLevels = const [];
    List<LevelUnlock> newUnlocks = const [];
    if (_profile.level > levelBefore) {
      newLevels = List.generate(
        _profile.level - levelBefore,
        (i) => levelBefore + i + 1,
      );
      newUnlocks =
          kLevelUnlocks.where((u) => newLevels.contains(u.level)).toList();
    }

    if (events.isNotEmpty) await saveProfile();
    return (xpEvents: events, newLevels: newLevels, newUnlocks: newUnlocks);
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

      // Gel de série : ponte un écart isolé d'hier avant de dériver le streak.
      _maybeConsumeShield(dailyMap);

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

      // Quêtes du jour — évaluées à chaque log (idempotent)
      events.addAll(_evaluateQuests(dailyMap));

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
      events.add(XpEvent(_award(5), XpReason.soberYesterday));
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
        events.add(XpEvent(_award(10), XpReason.greenDay));
      }
    }

    // Streak de 3 jours sobres
    if (_profile.soberStreakDays > 0 && _profile.soberStreakDays % 3 == 0) {
      events.add(
        XpEvent(_award(8), XpReason.soberStreak, value: _profile.soberStreakDays),
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
        events.add(XpEvent(_award(15), XpReason.perfectWeek));
        // Récompense : un bouclier « gel de série » (plafonné).
        if (_profile.streakShields < kMaxShields) {
          _profile.streakShields += 1;
        }
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
      final String key = _dateKey(day);
      if (_profile.firstUseDate.compareTo(key) > 0) break;
      if ((dailyMap[key] ?? 0) > 0) {
        // Jour de conso : un bouclier déjà posé le « ponte » sans casser la
        // série (le jour gelé ne compte pas mais ne rompt pas la continuité).
        if (_profile.frozenDays.contains(key)) continue;
        break;
      }
      streak++;
    }
    return streak;
  }

  /// Consomme un bouclier pour « geler » un écart **isolé** d'hier, afin que la
  /// série ne reparte pas de zéro pour un seul jour de conso. Idempotent : le
  /// jour gelé est enregistré, donc rappeler la méthode ne reconsomme rien.
  void _maybeConsumeShield(Map<String, int> dailyMap) {
    if (_profile.streakShields <= 0 || _profile.firstUseDate.isEmpty) return;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final String yKey = _dateKey(today.subtract(const Duration(days: 1)));

    // Hier doit être un jour de conso, couvert par les données, pas déjà gelé.
    if (_profile.firstUseDate.compareTo(yKey) > 0) return;
    if ((dailyMap[yKey] ?? 0) <= 0) return;
    if (_profile.frozenDays.contains(yKey)) return;

    // L'avant-veille doit être sobre : on ne ponte que vers une série réelle
    // (sinon on gaspillerait un bouclier à « protéger » une beuverie).
    final String bKey = _dateKey(today.subtract(const Duration(days: 2)));
    if (_profile.firstUseDate.compareTo(bKey) > 0) return;
    if ((dailyMap[bKey] ?? 0) > 0) return;

    _profile.frozenDays.add(yKey);
    _profile.streakShields -= 1;

    // Élagage : ne conserver que les gels récents.
    final String cutoff = _dateKey(today.subtract(const Duration(days: 120)));
    _profile.frozenDays.removeWhere((k) => k.compareTo(cutoff) < 0);
  }

  // --- Quêtes du jour --------------------------------------------------------

  /// Quêtes proposées aujourd'hui, choisies de façon déterministe (seed = jour)
  /// → stables sur la journée, renouvelées le lendemain.
  List<DailyQuest> _questsForDay(String dayKey) {
    final List<DailyQuest> pool = List.of(kDailyQuests);
    pool.shuffle(math.Random(dayKey.hashCode));
    return pool.take(kDailyQuestCount).toList();
  }

  /// État des quêtes du jour pour l'UI (sélection + complétion).
  List<QuestStatus> dailyQuests() {
    final String today = _dateKey(DateTime.now());
    final bool fresh = _profile.lastQuestDate == today;
    final Set<String> done =
        fresh ? _profile.completedQuestIds.toSet() : <String>{};
    return _questsForDay(today)
        .map((q) => QuestStatus(q, done.contains(q.id)))
        .toList();
  }

  bool _questSatisfied(DailyQuest q, Map<String, int> dailyMap) {
    final String today = _dateKey(DateTime.now());
    final int todayDrinks = dailyMap[today] ?? 0;
    final bool loggedToday = _profile.lastLogDate == today;
    switch (q.type) {
      case QuestType.openApp:
        return _profile.lastAppOpenDate == today;
      case QuestType.logToday:
        return loggedToday;
      case QuestType.soberToday:
        return loggedToday && todayDrinks == 0;
      case QuestType.underTwoToday:
        return loggedToday && todayDrinks <= 2;
      case QuestType.keepStreak:
        return _profile.soberStreakDays > 0;
    }
  }

  /// Évalue les quêtes du jour et attribue l'XP des nouvellement complétées.
  /// Idempotent : une quête validée n'est jamais re-récompensée.
  List<XpEvent> _evaluateQuests(Map<String, int> dailyMap) {
    final String today = _dateKey(DateTime.now());
    if (_profile.lastQuestDate != today) {
      _profile.lastQuestDate = today;
      _profile.completedQuestIds = [];
    }
    final List<XpEvent> events = [];
    for (final q in _questsForDay(today)) {
      if (_profile.completedQuestIds.contains(q.id)) continue;
      if (_questSatisfied(q, dailyMap)) {
        _profile.completedQuestIds.add(q.id);
        events.add(XpEvent(_award(q.xpReward), XpReason.questComplete));
      }
    }
    return events;
  }

  // --- Objectif hebdomadaire -------------------------------------------------

  /// Objectif de la semaine ISO en cours (lundi → aujourd'hui) : jours sobres
  /// vs cible. Alimente l'anneau d'en-tête. Aujourd'hui ne compte que s'il est
  /// déjà enregistré (sinon « 0 verre » par défaut serait un faux positif).
  ({int soberDays, int target, double progress}) weeklyGoal(
    Map<String, int> dailyMap,
  ) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
    int soberDays = 0;
    for (int i = 0; i <= today.difference(monday).inDays; i++) {
      final DateTime day = monday.add(Duration(days: i));
      final String key = _dateKey(day);
      if (_profile.firstUseDate.isEmpty ||
          _profile.firstUseDate.compareTo(key) > 0) {
        continue;
      }
      final bool counted = day.isBefore(today) || _profile.lastLogDate == key;
      if (counted && (dailyMap[key] ?? 0) == 0) soberDays++;
    }
    final double progress =
        (soberDays / kWeeklyGoalSoberDays).clamp(0.0, 1.0).toDouble();
    return (
      soberDays: soberDays,
      target: kWeeklyGoalSoberDays,
      progress: progress,
    );
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
