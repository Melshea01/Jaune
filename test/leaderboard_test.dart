// Tests de la fonctionnalité « Classement entre amis » (Phase 1, mock).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaune/models/friend.dart';
import 'package:jaune/services/mock_friends_service.dart';
import 'package:jaune/widgets/mini_health_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('MockFriendsService', () {
    test('précharge des amis et des demandes au premier lancement', () async {
      final svc = MockFriendsService();
      final friends = await svc.friends();
      final requests = await svc.pendingRequests();

      expect(friends, isNotEmpty);
      expect(requests, isNotEmpty);
      expect(svc.pendingCount.value, requests.length);
    });

    test('accepter une demande la déplace vers les amis', () async {
      final svc = MockFriendsService();
      final requests = await svc.pendingRequests();
      final target = requests.first;
      final beforeFriends = (await svc.friends()).length;

      await svc.acceptRequest(target.userId);

      final afterFriends = await svc.friends();
      final afterRequests = await svc.pendingRequests();
      expect(afterFriends.length, beforeFriends + 1);
      expect(afterRequests.any((r) => r.userId == target.userId), isFalse);
      expect(afterFriends.any((f) => f.userId == target.userId), isTrue);
      expect(svc.pendingCount.value, afterRequests.length);
    });

    test('ignorer une demande la supprime silencieusement', () async {
      final svc = MockFriendsService();
      final requests = await svc.pendingRequests();
      final target = requests.first;
      final beforeFriends = (await svc.friends()).length;

      await svc.ignoreRequest(target.userId);

      final afterFriends = await svc.friends();
      final afterRequests = await svc.pendingRequests();
      expect(afterFriends.length, beforeFriends); // aucun nouvel ami
      expect(afterRequests.any((r) => r.userId == target.userId), isFalse);
    });
  });

  group('LeaderboardEntry', () {
    test('le tri par santé décroissante place le plus sain en tête', () {
      final entries = [
        const LeaderboardEntry(
            userId: 'a', username: 'A', healthPercent: 0.4, streakDays: 0),
        const LeaderboardEntry(
            userId: 'b', username: 'B', healthPercent: 0.95, streakDays: 10),
        const LeaderboardEntry(
            userId: 'c', username: 'C', healthPercent: 0.7, streakDays: 3),
      ]..sort((x, y) => y.healthPercent.compareTo(x.healthPercent));

      expect(entries.map((e) => e.username).toList(), ['B', 'C', 'A']);
    });
  });

  testWidgets('MiniHealthBar affiche le pourcentage arrondi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: MiniHealthBar(percent: 0.87, animate: false)),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('87%'), findsOneWidget);
  });
}
