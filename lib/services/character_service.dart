import 'package:flutter/foundation.dart';
import 'package:jaune/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;

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
    if (_assetMessages.isNotEmpty) return;
    if (_assetLoadingStarted) return;
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

  /// Ensures messages are loaded before use - FIX FOR RACE CONDITION
  static Future<void> ensureMessagesLoaded() async {
    await _loadMessagesFromAsset();
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

    // Messages not loaded yet - return empty to prevent UI breaking
    // ensureMessagesLoaded() should have been called in app initialization
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
    if (lastXpAwardDate == today) return; // already awarded today
    try {
      // Load daily consumptions map from prefs. Key name is fixed.
      const String dailyKey = 'daily_consos';
      final String? rawDaily = prefs.getString(dailyKey);
      Map<String, int> dailyMap = {};
      if (rawDaily != null && rawDaily.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded =
              json.decode(rawDaily) as Map<String, dynamic>;
          dailyMap = decoded.map<String, int>((k, v) {
            if (v is int) return MapEntry(k, v);
            return MapEntry(k, int.tryParse(v.toString()) ?? 0);
          });
        } catch (_) {
          dailyMap = {};
        }
      }

      // We check the week containing yesterday
      final DateTime yesterdayDt = DateTime.now().subtract(
        const Duration(days: 1),
      );
      final DateTime yesterday = DateTime(
        yesterdayDt.year,
        yesterdayDt.month,
        yesterdayDt.day,
      );

      // Find Monday of that week (ISO-like, Monday = 1)
      final int weekday = yesterday.weekday; // 1..7
      final DateTime weekStart = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      ).subtract(Duration(days: weekday - 1));

      // Gather counts for the week (default 0 when missing)
      int weeklyTotal = 0;
      int nbZeroDay = 0;
      int maxDailyCount = 0;
      for (int i = 0; i < weekday; i++) {
        final DateTime d = weekStart.add(Duration(days: i));
        final String k = d.toIso8601String().substring(0, 10);
        final int cnt = dailyMap[k] ?? 0;
        weeklyTotal += cnt;
        if (cnt == 0) nbZeroDay += 1;
        maxDailyCount = math.max(maxDailyCount, cnt);
      }

      // Rules:
      // - weeklyTotal <= 10
      // - yesterday <= 2
      // - at least one zero-consumption day in the week
      final bool ruleWeekly = weeklyTotal <= 10;
      final bool ruleDaily = maxDailyCount <= 2;
      final bool ruleZeroDay = nbZeroDay >= 2;

      if (ruleWeekly && ruleDaily && ruleZeroDay) {
        // Optional: also keep healthPct threshold if desired
        addXp(10);
        await _saveToPrefs(prefs, key);
      }
      lastXpAwardDate = today;
    } catch (e) {
      debugPrint('awardDailyXpIfNeeded error: $e');
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
  // FIX: Add lock for SharedPreferences synchronization
  bool _isSavingProfile = false;

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
    // FIX: Prevent concurrent saves with flag lock
    if (_isSavingProfile) return;
    _isSavingProfile = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileKey, json.encode(_profile.toJson()));
    } catch (e) {
      debugPrint('Error saving character profile: $e');
    } finally {
      _isSavingProfile = false;
    }
  }

  void updateProfile(CharacterProfile newProfile) {
    _profile = newProfile;
  }

  void updateHealth(double healthPercent) {
    _profile.setHealthPercent(healthPercent);
  }

  double computeHealthFromRisk(Map<String, int> dailyMap) {
    try {
      if (dailyMap.isEmpty) {
        return 1.0;
      }

      // Determine earliest recorded day in the map
      DateTime? earliest;
      for (var k in dailyMap.keys) {
        try {
          final d = DateTime.parse(k);
          final day = DateTime(d.year, d.month, d.day);
          if (earliest == null || day.isBefore(earliest)) earliest = day;
        } catch (_) {}
      }

      final DateTime now = DateTime.now();
      const int maxWindowDays = 90; // FIX: Limit window to 90 days max
      final DateTime windowLimit = now.subtract(Duration(days: maxWindowDays));

      // Window start is either the earliest recorded day or 90 days ago, whichever is later
      final DateTime windowStart =
          (earliest != null && earliest.isAfter(windowLimit))
              ? earliest
              : DateTime(windowLimit.year, windowLimit.month, windowLimit.day);

      final DateTime startDate = DateTime(
        windowStart.year,
        windowStart.month,
        windowStart.day,
      );
      final DateTime endDate = DateTime(now.year, now.month, now.day);
      int daysInWindow = endDate.difference(startDate).inDays + 1;
      if (daysInWindow <= 0) daysInWindow = 1;

      // Sum consumptions inside window
      int totalConsos = 0;
      dailyMap.forEach((k, v) {
        try {
          final d = DateTime.parse(k);
          final day = DateTime(d.year, d.month, d.day);
          if (!day.isBefore(startDate) && !day.isAfter(endDate)) {
            totalConsos += v;
          }
        } catch (_) {}
      });

      // Average daily consumption over the window
      final double avgDaily = totalConsos / daysInWindow;

      // Multiply by 10 as requested and evaluate model to get PV value
      // FIX: Clamp input to prevent extreme values and NaN from evalModel
      final double x = (avgDaily * 10.0).clamp(0.0, 100.0);
      double pvRaw = 0.0;
      try {
        pvRaw = _profile.maxPv.toDouble() - evalModel(x);
      } catch (e) {
        debugPrint('evalModel error: $e');
        pvRaw = _profile.maxPv.toDouble();
      }

      double pv = pvRaw.isNaN ? _profile.maxPv.toDouble() : pvRaw;
      // FIX: Normalize to 0-1 range properly (divide by maxPv, not 100)
      pv = (pv / _profile.maxPv).clamp(0.0, 1.0);

      return pv;
    } catch (e) {
      debugPrint('Error in _recomputeHealth: $e');
    }
    return 1.0;
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
