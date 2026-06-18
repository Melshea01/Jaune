/// Modèles de la fonctionnalité « Classement entre amis ».
///
/// Volontairement minimaux et immuables : ils décrivent uniquement ce qui
/// transite entre le [FriendsService] et l'UI. La couche stockage (mock en
/// Phase 1, Supabase en Phase 2) sérialise depuis/vers ces objets.
library;

/// Une entrée du classement — un ami, ou soi-même ([isMe] == true).
///
/// Le tri du classement se fait sur [healthPercent] décroissant : la
/// modération (barre de vie proche de 100 %) est mise en avant. La flamme
/// ([streakDays]) reste une information secondaire affichée sur la ligne.
class LeaderboardEntry {
  /// Identifiant stable de l'utilisateur (= code ami / auth.uid en P2).
  final String userId;
  final String username;

  /// Pourcentage de santé, borné 0..1 (comme `CharacterProfile.healthPercent`).
  final double healthPercent;

  /// Jours sobres consécutifs (flamme).
  final int streakDays;

  /// Clé du skin équipé ('' = citron classique).
  final String equippedSkin;

  /// Vrai pour la ligne de l'utilisateur courant (mise en avant dans la liste).
  final bool isMe;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.healthPercent,
    required this.streakDays,
    this.equippedSkin = '',
    this.isMe = false,
  });

  LeaderboardEntry copyWith({bool? isMe}) => LeaderboardEntry(
    userId: userId,
    username: username,
    healthPercent: healthPercent,
    streakDays: streakDays,
    equippedSkin: equippedSkin,
    isMe: isMe ?? this.isMe,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'healthPercent': healthPercent,
    'streakDays': streakDays,
    'equippedSkin': equippedSkin,
  };

  static LeaderboardEntry fromJson(Map<String, dynamic> j, {bool isMe = false}) =>
      LeaderboardEntry(
        userId: (j['userId'] as String?) ?? '',
        username: (j['username'] as String?) ?? '',
        healthPercent: ((j['healthPercent'] as num?) ?? 1.0).toDouble(),
        streakDays: (j['streakDays'] as int?) ?? 0,
        equippedSkin: (j['equippedSkin'] as String?) ?? '',
        isMe: isMe,
      );
}

/// Une demande d'ami reçue, en attente de validation manuelle.
///
/// Refus silencieux : « Ignorer » la supprime sans notifier l'expéditeur.
class FriendRequest {
  final String userId;
  final String username;
  final String equippedSkin;
  final DateTime createdAt;

  const FriendRequest({
    required this.userId,
    required this.username,
    this.equippedSkin = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'equippedSkin': equippedSkin,
    'createdAt': createdAt.toIso8601String(),
  };

  static FriendRequest fromJson(Map<String, dynamic> j) => FriendRequest(
    userId: (j['userId'] as String?) ?? '',
    username: (j['username'] as String?) ?? '',
    equippedSkin: (j['equippedSkin'] as String?) ?? '',
    createdAt:
        DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.now(),
  );
}
