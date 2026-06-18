import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/friend.dart';
import 'friends_service.dart';

/// Implémentation Phase 1 : données factices + persistance locale des
/// amitiés acceptées. Permet de valider toute l'UX (tri, animations, flux
/// de demandes) sans aucune dépendance backend.
///
/// Au premier lancement, quelques amis et demandes sont préchargés pour que
/// l'écran ne soit jamais vide en démo.
class MockFriendsService implements FriendsService {
  static const String _kFriendsKey = 'mock_friends';
  static const String _kRequestsKey = 'mock_friend_requests';
  static const String _kSeededKey = 'mock_friends_seeded';

  final List<LeaderboardEntry> _friends = [];
  final List<FriendRequest> _requests = [];
  final ValueNotifier<int> _pendingCount = ValueNotifier<int>(0);
  bool _loaded = false;

  @override
  String get myCode => 'JAUNE-MOCK-ME';

  @override
  ValueListenable<int> get pendingCount => _pendingCount;

  @override
  Future<List<LeaderboardEntry>> friends() async {
    await _ensureLoaded();
    return List.unmodifiable(_friends);
  }

  @override
  Future<List<FriendRequest>> pendingRequests() async {
    await _ensureLoaded();
    return List.unmodifiable(_requests);
  }

  @override
  Future<void> refresh() async {
    _loaded = false;
    await _ensureLoaded();
  }

  @override
  Future<void> syncProfile({
    required String username,
    required double healthPercent,
    required int streakDays,
    required String equippedSkin,
  }) async {
    // Mock local : aucune publication réseau. No-op volontaire.
  }

  @override
  Future<void> sendRequest(String friendCode) async {
    await _ensureLoaded();
    // En mock, envoyer une demande simule un ami fictif qui accepte
    // immédiatement, pour rendre le flux d'ajout visible.
    if (friendCode.trim().isEmpty) return;
    final entry = LeaderboardEntry(
      userId: 'sent-${DateTime.now().millisecondsSinceEpoch}',
      username: _usernameFromCode(friendCode),
      healthPercent: 0.82,
      streakDays: 5,
      equippedSkin: '',
    );
    _friends.add(entry);
    await _persist();
  }

  @override
  Future<void> acceptRequest(String userId) async {
    await _ensureLoaded();
    final idx = _requests.indexWhere((r) => r.userId == userId);
    if (idx == -1) return;
    final req = _requests.removeAt(idx);
    _friends.add(
      LeaderboardEntry(
        userId: req.userId,
        username: req.username,
        // Stats factices plausibles pour un nouvel ami accepté.
        healthPercent: 0.7 + (req.username.length % 4) * 0.07,
        streakDays: 1 + req.username.length % 9,
        equippedSkin: req.equippedSkin,
      ),
    );
    await _persist();
  }

  @override
  Future<void> ignoreRequest(String userId) async {
    await _ensureLoaded();
    _requests.removeWhere((r) => r.userId == userId);
    await _persist();
  }

  // --- Interne ---

  String _usernameFromCode(String code) {
    final cleaned = code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.isEmpty) return 'Nouvel ami';
    return 'Ami ${cleaned.substring(0, cleaned.length.clamp(0, 4)).toUpperCase()}';
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    if (!(prefs.getBool(_kSeededKey) ?? false)) {
      _seed();
      await _persist();
      await prefs.setBool(_kSeededKey, true);
    } else {
      _friends
        ..clear()
        ..addAll(_decodeFriends(prefs.getString(_kFriendsKey)));
      _requests
        ..clear()
        ..addAll(_decodeRequests(prefs.getString(_kRequestsKey)));
    }

    _pendingCount.value = _requests.length;
    _loaded = true;
  }

  void _seed() {
    _friends
      ..clear()
      ..addAll(const [
        LeaderboardEntry(
          userId: 'seed-lea',
          username: 'Léa',
          healthPercent: 0.96,
          streakDays: 34,
          equippedSkin: 'skin_gold',
        ),
        LeaderboardEntry(
          userId: 'seed-tom',
          username: 'Tom',
          healthPercent: 0.81,
          streakDays: 12,
          equippedSkin: 'skin_sunglasses',
        ),
        LeaderboardEntry(
          userId: 'seed-nina',
          username: 'Nina',
          healthPercent: 0.64,
          streakDays: 4,
        ),
        LeaderboardEntry(
          userId: 'seed-hugo',
          username: 'Hugo',
          healthPercent: 0.42,
          streakDays: 0,
        ),
      ]);
    _requests
      ..clear()
      ..addAll([
        FriendRequest(
          userId: 'req-sasha',
          username: 'Sasha',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        FriendRequest(
          userId: 'req-manon',
          username: 'Manon',
          equippedSkin: 'skin_party_hat',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kFriendsKey,
      json.encode(_friends.map((f) => f.toJson()).toList()),
    );
    await prefs.setString(
      _kRequestsKey,
      json.encode(_requests.map((r) => r.toJson()).toList()),
    );
    _pendingCount.value = _requests.length;
  }

  List<LeaderboardEntry> _decodeFriends(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List;
      return list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<FriendRequest> _decodeRequests(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List;
      return list
          .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
