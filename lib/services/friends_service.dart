import 'package:flutter/foundation.dart';

import '../models/friend.dart';
import 'mock_friends_service.dart';

/// Contrat unique de la fonctionnalité « Classement entre amis ».
///
/// Toute l'UI ne dépend QUE de cette interface. En Phase 1, l'implémentation
/// est [MockFriendsService] (données factices + persistance locale). En
/// Phase 2, on remplace l'instance par `SupabaseFriendsService` sans toucher
/// aux widgets — c'est le point d'injection [friendsService] ci-dessous.
abstract class FriendsService {
  /// Code ami / identifiant de l'utilisateur courant (encodé dans le QR/lien).
  String get myCode;

  /// Amis acceptés, prêts pour le classement (n'inclut PAS soi-même).
  Future<List<LeaderboardEntry>> friends();

  /// Demandes d'amitié reçues, en attente de validation manuelle.
  Future<List<FriendRequest>> pendingRequests();

  /// Compteur observable des demandes en attente — alimente la pastille de
  /// notification du header sans faire transiter de callbacks.
  ValueListenable<int> get pendingCount;

  /// Envoie une demande d'ami à partir d'un code scanné/ouvert via un lien.
  Future<void> sendRequest(String friendCode);

  /// Accepte une demande → amitié bilatérale effective.
  Future<void> acceptRequest(String userId);

  /// Ignore une demande → suppression silencieuse, aucune notification émise.
  Future<void> ignoreRequest(String userId);

  /// Recharge l'état depuis le stockage (à l'ouverture de l'écran).
  Future<void> refresh();

  /// Publie les stats de l'utilisateur courant (pseudo, santé, série, skin)
  /// pour que ses amis voient des valeurs à jour. No-op pour le mock.
  Future<void> syncProfile({
    required String username,
    required double healthPercent,
    required int streakDays,
    required String equippedSkin,
  });
}

/// Point d'injection unique. Phase 1 : mock. Phase 2 : Supabase.
FriendsService friendsService = MockFriendsService();
