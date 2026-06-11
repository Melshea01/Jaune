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

import 'package:jaune/l10n/gen/app_localizations.dart';
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

    // Libellé localisé : le test passe quelle que soit la locale du runner
    final BuildContext context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.calendarTitle), findsOneWidget);
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
    // 1er pump : le setState s'applique et la transition du badge démarre ;
    // 2e pump : la transition (250 ms) se termine ;
    // 3e pump : l'AnimatedSwitcher purge l'ancien enfant au frame suivant
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));

    expect(consoBadge().data, '1');

    await flushPendingTimers(tester);
  });
}
