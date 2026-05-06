import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AppState {
  final int todayConsos;
  final Map<String, int> dailyMap;

  AppState({required this.todayConsos, required this.dailyMap});
}

class StorageService {
  static const String _kDailyConsosKey = 'daily_consos';

  Map<String, int> _dailyMap = {};

  Map<String, int> get dailyMap => Map.from(_dailyMap);

  Future<AppState> loadAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDaily = prefs.getString(_kDailyConsosKey);

      int todayConsos = 0;

      if (savedDaily != null && savedDaily.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded =
              json.decode(savedDaily) as Map<String, dynamic>;
          _dailyMap = decoded.map<String, int>((k, v) {
            if (v is int) return MapEntry(k, v);
            return MapEntry(k, int.tryParse(v.toString()) ?? 0);
          });

          final todayKey = DateTime.now().toIso8601String().substring(0, 10);
          todayConsos = _dailyMap[todayKey] ?? 0;
        } catch (e) {
          debugPrint('Error parsing saved daily map: $e');
          _dailyMap = {};
          todayConsos = 0;
        }
      }

      return AppState(todayConsos: todayConsos, dailyMap: _dailyMap);
    } catch (e) {
      debugPrint('Error loading app state: $e');
      return AppState(todayConsos: 0, dailyMap: {});
    }
  }

  Future<void> saveAppState({
    required int todayConsos,
    required Map<String, int> dailyMap,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);

      _dailyMap = Map.from(dailyMap);
      _dailyMap[todayKey] = todayConsos;

      await prefs.setString(_kDailyConsosKey, json.encode(_dailyMap));
    } catch (e) {
      debugPrint('Error saving app state: $e');
    }
  }

  void updateTodayConsos(int consos) {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    _dailyMap[todayKey] = consos;
  }

  void resetTodayConsos() {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    _dailyMap.remove(todayKey);
  }

  int getTodayConsos() {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    return _dailyMap[todayKey] ?? 0;
  }

  int getConsosForDate(DateTime date) {
    final dateKey = date.toIso8601String().substring(0, 10);
    return _dailyMap[dateKey] ?? 0;
  }

  void setConsosForDate(DateTime date, int consos) {
    final dateKey = date.toIso8601String().substring(0, 10);
    if (consos <= 0) {
      _dailyMap.remove(dateKey);
    } else {
      _dailyMap[dateKey] = consos;
    }
  }

  List<DateTime> getDatesWithConsos() {
    return _dailyMap.keys
        .map((key) => DateTime.tryParse(key))
        .where((date) => date != null)
        .cast<DateTime>()
        .toList()
      ..sort();
  }

  Map<String, int> getConsosInRange(DateTime start, DateTime end) {
    final Map<String, int> result = {};

    _dailyMap.forEach((dateKey, consos) {
      final date = DateTime.tryParse(dateKey);
      if (date != null && !date.isBefore(start) && !date.isAfter(end)) {
        result[dateKey] = consos;
      }
    });

    return result;
  }

  int getTotalConsosInRange(DateTime start, DateTime end) {
    return getConsosInRange(
      start,
      end,
    ).values.fold(0, (sum, consos) => sum + consos);
  }

  double getAverageConsosPerDay(DateTime start, DateTime end) {
    final consos = getConsosInRange(start, end);
    if (consos.isEmpty) return 0.0;

    final totalDays = end.difference(start).inDays + 1;
    final totalConsos = consos.values.fold(0, (sum, c) => sum + c);

    return totalConsos / totalDays;
  }

  // ==================== NOTIFICATION TRACKING ====================

  static const String _kLastNotificationSentKey = 'last_notification_sent';

  Future<DateTime?> getLastNotificationSent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_kLastNotificationSentKey);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      debugPrint('Error getting last notification sent: $e');
      return null;
    }
  }

  Future<void> setLastNotificationSent(DateTime dateTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastNotificationSentKey, dateTime.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error setting last notification sent: $e');
    }
  }
}
