import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/friend.dart';
import 'friends_service.dart';

/// Implémentation Phase 2 : backend Supabase (Postgres + Auth anonyme + RLS).
///
/// Le schéma et les politiques de sécurité vivent dans
/// `supabase/migrations/0001_friends.sql`. Cette classe ne fait que parler à
/// ces tables via l'API PostgREST, derrière la même interface [FriendsService]
/// que le mock — l'UI ne change pas d'un poil.
class SupabaseFriendsService implements FriendsService {
  final SupabaseClient _client = Supabase.instance.client;
  final ValueNotifier<int> _pendingCount = ValueNotifier<int>(0);
  String _myId = '';
  RealtimeChannel? _channel;

  @override
  String get myCode => _myId;

  @override
  ValueListenable<int> get pendingCount => _pendingCount;

  /// Ferme l'abonnement temps réel (si le service venait à être remplacé).
  Future<void> dispose() async {
    final channel = _channel;
    if (channel != null) {
      await _client.removeChannel(channel);
      _channel = null;
    }
  }

  /// Connexion anonyme + abonnement temps réel + premier rafraîchissement.
  Future<void> init() async {
    final auth = _client.auth;
    if (auth.currentSession == null) {
      await auth.signInAnonymously();
    }
    _myId = auth.currentUser?.id ?? '';
    _subscribe();
    await refresh();
  }

  @override
  Future<List<LeaderboardEntry>> friends() async {
    if (_myId.isEmpty) return [];
    final rows = await _client
        .from('friendships')
        .select('requester, addressee')
        .eq('status', 'accepted')
        .or('requester.eq.$_myId,addressee.eq.$_myId');

    final ids = <String>[];
    for (final row in (rows as List)) {
      final m = row as Map<String, dynamic>;
      final requester = m['requester'] as String;
      final addressee = m['addressee'] as String;
      ids.add(requester == _myId ? addressee : requester);
    }
    if (ids.isEmpty) return [];

    final profs =
        await _client.from('profiles').select().inFilter('id', ids);
    return [
      for (final p in (profs as List)) _entry(p as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<FriendRequest>> pendingRequests() async {
    if (_myId.isEmpty) return [];
    final rows = await _client
        .from('friendships')
        .select('requester, created_at')
        .eq('addressee', _myId)
        .eq('status', 'pending');

    final createdByRequester = <String, String>{};
    for (final row in (rows as List)) {
      final m = row as Map<String, dynamic>;
      createdByRequester[m['requester'] as String] =
          m['created_at']?.toString() ?? '';
    }
    if (createdByRequester.isEmpty) {
      _pendingCount.value = 0;
      return [];
    }

    final profs = await _client
        .from('profiles')
        .select()
        .inFilter('id', createdByRequester.keys.toList());

    final out = <FriendRequest>[];
    for (final p in (profs as List)) {
      final m = p as Map<String, dynamic>;
      final id = m['id'] as String;
      out.add(FriendRequest(
        userId: id,
        username: (m['username'] as String?) ?? '',
        equippedSkin: (m['equipped_skin'] as String?) ?? '',
        createdAt:
            DateTime.tryParse(createdByRequester[id] ?? '') ?? DateTime.now(),
      ));
    }
    _pendingCount.value = out.length;
    return out;
  }

  @override
  Future<void> refresh() async {
    if (_myId.isEmpty) return;
    try {
      final rows = await _client
          .from('friendships')
          .select('requester')
          .eq('addressee', _myId)
          .eq('status', 'pending');
      _pendingCount.value = (rows as List).length;
    } catch (e) {
      debugPrint('SupabaseFriendsService.refresh: $e');
    }
  }

  @override
  Future<void> sendRequest(String friendCode) async {
    final target = friendCode.trim();
    if (target.isEmpty || target == _myId) return;
    try {
      await _client.from('friendships').insert({
        'requester': _myId,
        'addressee': target,
        'status': 'pending',
      });
    } on PostgrestException catch (e) {
      // Doublon (contrainte unique) ou cible inexistante : on ignore en
      // silence — l'utilisateur n'a pas à connaître le détail.
      debugPrint('SupabaseFriendsService.sendRequest: ${e.message}');
    }
  }

  @override
  Future<void> acceptRequest(String userId) async {
    await _client
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('requester', userId)
        .eq('addressee', _myId);
    await refresh();
  }

  @override
  Future<void> ignoreRequest(String userId) async {
    await _client
        .from('friendships')
        .delete()
        .eq('requester', userId)
        .eq('addressee', _myId);
    await refresh();
  }

  @override
  Future<void> removeFriend(String userId) async {
    if (_myId.isEmpty) return;
    try {
      // L'amitié peut avoir été créée dans un sens ou l'autre : on supprime
      // la ligne qui relie les deux identités, quel que soit le rôle.
      await _client
          .from('friendships')
          .delete()
          .or(
            'and(requester.eq.$_myId,addressee.eq.$userId),'
            'and(requester.eq.$userId,addressee.eq.$_myId)',
          );
    } on PostgrestException catch (e) {
      debugPrint('SupabaseFriendsService.removeFriend: ${e.message}');
    }
    await refresh();
  }

  @override
  Future<void> syncProfile({
    required String username,
    required double healthPercent,
    required int streakDays,
    required String equippedSkin,
  }) async {
    if (_myId.isEmpty) return;
    try {
      await _client.from('profiles').upsert({
        'id': _myId,
        'username': username,
        'health_percent': healthPercent.clamp(0.0, 1.0),
        'streak_days': streakDays,
        'equipped_skin': equippedSkin,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('SupabaseFriendsService.syncProfile: $e');
    }
  }

  // --- Interne ---

  LeaderboardEntry _entry(Map<String, dynamic> p) => LeaderboardEntry(
        userId: (p['id'] as String?) ?? '',
        username: (p['username'] as String?) ?? '',
        healthPercent: ((p['health_percent'] as num?) ?? 1.0).toDouble(),
        streakDays: (p['streak_days'] as int?) ?? 0,
        equippedSkin: (p['equipped_skin'] as String?) ?? '',
      );

  /// Abonnement temps réel : toute évolution des demandes me concernant
  /// (nouvelle demande, acceptation) rafraîchit la pastille en direct.
  void _subscribe() {
    try {
      _channel = _client
          .channel('public:friendships:$_myId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'friendships',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'addressee',
              value: _myId,
            ),
            callback: (_) => refresh(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('SupabaseFriendsService.subscribe: $e');
    }
  }
}

/// Bootstrap du backend : tente Supabase si configuré, sinon laisse le mock.
/// Appelé une fois au démarrage, avant `runApp`.
Future<void> initFriendsBackend() async {
  if (!SupabaseConfig.isConfigured) {
    debugPrint('Supabase non configuré — service mock conservé.');
    return;
  }
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // La « clé publishable » du dashboard = l'ancienne clé anon.
      publishableKey: SupabaseConfig.anonKey,
    );
    final service = SupabaseFriendsService();
    await service.init();
    friendsService = service;
    debugPrint('Backend Supabase actif (uid: ${service.myCode}).');
  } catch (e) {
    debugPrint('Échec init Supabase, repli sur le mock: $e');
  }
}
