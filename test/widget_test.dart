// Smoke tests adaptés à l'application Jaune.
//
// NB : le citron est animé en continu (Ticker 60 fps + AnimationControllers
// en repeat) — `pumpAndSettle` ne converge donc jamais. On utilise pump()
// avec des durées explicites, et chaque test se termine par un long pump
// pour purger les timers en attente (réactions du citron, toasts XP,
// fondu audio après le son de conso).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaune/main.dart';

/// Purge les timers différés (toasts ~4s, réaction citron 3s, bulle audio 8s)
Future<void> flushPendingTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 15));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // SharedPreferences mockées : pas de canaux de plateforme en test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke : affiche les éléments principaux', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Calendrier'), findsOneWidget);
    expect(find.text('🍻'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    await flushPendingTimers(tester);
  });

  testWidgets('Taper sur la bière incrémente la conso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 900));

    Text consoBadge() =>
        tester.widget<Text>(find.byKey(const Key('conso-count')));
    expect(consoBadge().data, '0');

    await tester.tap(find.text('🍻'));
    await tester.pump(const Duration(seconds: 1));

    expect(consoBadge().data, '1');

    await flushPendingTimers(tester);
  });
}
