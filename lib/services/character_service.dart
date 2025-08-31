import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../models.dart';

class CharacterProfile {
  int xp;
  int level;
  String lastXpAwardDate;
  int maxPv;
  int currentPv;

  static const int xpPerLevel = 100;

  CharacterProfile({
    this.xp = 0,
    this.level = 1,
    this.lastXpAwardDate = '',
    this.maxPv = 100,
    int? currentPv,
  }) : currentPv = currentPv ?? 100;

  // Asset-backed messages cache
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
        if (v is List) {
          _assetMessages[k] = v.map((e) => e.toString()).toList();
        }
      });
      debugPrint(
        'Loaded character messages from assets: ${_assetMessages.keys.toList()}',
      );
    } catch (e) {
      debugPrint('Failed to load character messages asset: $e');
    }
  }

  void addXp(int amount) {
    xp += amount;
    while (xp >= xpPerLevel) {
      xp -= xpPerLevel;
      level += 1;
    }
  }

  String getMessage() {
    try {
      final String zone = zoneFromPercent();
      final List<String> pool = messagesForZone(zone);
      if (pool.isEmpty) return '';
      return pool[math.Random().nextInt(pool.length)];
    } catch (_) {
      return '';
    }
  }

  String get message => getMessage();

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

  List<String> messagesForZone(String zone) {
    if (_assetMessages.containsKey(zone)) {
      return List<String>.from(_assetMessages[zone]!);
    }

    if (!_assetLoadingStarted) {
      _loadMessagesFromAsset();
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'xp': xp,
      'level': level,
      'lastXpAwardDate': lastXpAwardDate,
      'maxPv': maxPv,
      'currentPv': currentPv,
    };
  }

  static CharacterProfile fromJson(Map<String, dynamic> p) {
    return CharacterProfile(
      xp: (p['xp'] as int?) ?? 0,
      level: (p['level'] as int?) ?? 1,
      lastXpAwardDate: (p['lastXpAwardDate'] as String?) ?? '',
      maxPv: (p['maxPv'] as int?) ?? 100,
      currentPv: (p['currentPv'] as int?) ?? 100,
    );
  }

  Future<void> awardDailyXpIfNeeded(
      double healthPct,
      SharedPreferences prefs,
      String key,
      ) async {
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastXpAwardDate == today) return;

    if (healthPct > 0.75) {
      addXp(10);
      lastXpAwardDate = today;
      await _saveToPrefs(prefs, key);
    }
  }

  Future<void> _saveToPrefs(SharedPreferences prefs, String key) async {
    try {
      await prefs.setString(key, json.encode(toJson()));
    } catch (_) {
      // ignore
    }
  }
}

class CharacterService {
  static const String _kProfileKey = 'character_profile';
  CharacterProfile _profile = CharacterProfile();

  CharacterProfile get profile => _profile;
  int get level => _profile.level;
  double get healthPercent => _profile.healthPercent();
  String get currentMessage => _profile.message;

  Future<CharacterProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawProfile = prefs.getString(_kProfileKey);

      if (rawProfile != null && rawProfile.isNotEmpty) {
        final Map<String, dynamic> p =
        json.decode(rawProfile) as Map<String, dynamic>;
        _profile = CharacterProfile.fromJson(p);
      } else {
        _profile = CharacterProfile(maxPv: 100, currentPv: 100);
      }

      return _profile;
    } catch (e) {
      debugPrint('Error loading character profile: $e');
      _profile = CharacterProfile(maxPv: 100, currentPv: 100);
      return _profile;
    }
  }

  Future<void> saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileKey, json.encode(_profile.toJson()));
    } catch (e) {
      debugPrint('Error saving character profile: $e');
    }
  }

  void updateProfile(CharacterProfile newProfile) {
    _profile = newProfile;
  }

  void updateHealth(double healthPercent) {
    _profile.setHealthPercent(healthPercent);
  }

  double computeHealthFromRisk(Map<String, int> dailyMap, {String gender = 'H'}) {
    try {
      final Map<String, double> weeklyRisks = _computeWeeklyAverageRisk(
          dailyMap,
          gender: gender
      );

      if (weeklyRisks.isNotEmpty) {
        final double sumAll = weeklyRisks.values.fold(0.0, (p, e) => p + e);
        final double avgRisk = sumAll / weeklyRisks.length;
        return _riskToHealthPercent(avgRisk);
      }

      return 1.0; // Full health if no data
    } catch (e) {
      debugPrint('Error computing health from risk: $e');
      return 1.0;
    }
  }

  Map<String, double> _computeWeeklyAverageRisk(
      Map<String, int> dailyMap, {
        String gender = 'H'
      }) {
    // Get earliest date
    DateTime? earliestKey;
    dailyMap.forEach((dateKey, val) {
      final date = DateTime.tryParse(dateKey);
      if (date != null && (earliestKey == null || date.isBefore(earliestKey!))) {
        earliestKey = date;
      }
    });

    if (earliestKey == null) return <String, double>{};

    // Generate weekly aggregations
    final Map<String, Map<String, int>> weeklyAgg = {};

    dailyMap.forEach((dateKey, val) {
      try {
        final DateTime dRaw = DateTime.parse(dateKey);
        final DateTime day = DateTime(dRaw.year, dRaw.month, dRaw.day);
        final String weekNumber = _isoWeekNumber(day).toString();
        final String key = "${dRaw.year}-$weekNumber";

        final w = weeklyAgg.putIfAbsent(
          key,
              () => <String, int>{'sum': 0, 'drinking_days': 0},
        );
        w['sum'] = (w['sum'] ?? 0) + val;
        if (val > 0) w['drinking_days'] = (w['drinking_days'] ?? 0) + 1;
      } catch (_) {
        // ignore malformed dates
      }
    });

    // Compute risks
    final Map<String, double> weeklyRisks = {};
    weeklyAgg.forEach((weekKey, data) {
      final int total = data['sum'] ?? 0;
      final int drinkingDays = data['drinking_days'] ?? 0;

      double risk = 0.0;
      if (drinkingDays > 0) {
        final String sheet = gender.toUpperCase().startsWith('F') ? 'Femme' : 'Homme';
        try {
          risk = ModelPredictor.predict(sheet, drinkingDays, total);
        } catch (e) {
          debugPrint('ModelPredictor error: $e');
          risk = 0.0;
        }
      }
      weeklyRisks[weekKey] = risk;
    });

    return weeklyRisks;
  }

  int _isoWeekNumber(DateTime date) {
    int weekday = date.weekday;
    DateTime monday = date.add(Duration(days: 1 - weekday));
    DateTime jan1 = DateTime(date.year, 1, 1);
    int daysToAdd = (8 - jan1.weekday) % 7;
    DateTime firstMonday = jan1.add(Duration(days: daysToAdd));
    int weekNumber = ((monday.difference(firstMonday).inDays) / 7).floor() + 1;
    return weekNumber;
  }

  double _riskToHealthPercent(double risk) {
    if (risk.isNaN) return 1.0;
    if (risk >= 0.15) return 0.0;
    final double v = 1.0 - (risk / 0.15);
    return v.clamp(0.0, 1.0);
  }

  Future<void> awardDailyXpIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _profile.awardDailyXpIfNeeded(
        _profile.healthPercent(),
        prefs,
        _kProfileKey,
      );
    } catch (e) {
      debugPrint('Error awarding daily XP: $e');
    }
  }
}