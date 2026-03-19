// Smoke tests adaptés à l'application Jaune.
// Ces tests n'utilisent pas le compteur par défaut de Flutter.
// Ils mockent les SharedPreferences et vérifient quelques interactions UI basiques.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaune/main.dart';

void main() {
  // Ensure Flutter bindings are initialized for widget tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Provide an empty/mock SharedPreferences to avoid platform channels during tests.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke: affiche éléments principaux', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // Attendre que l'arbre se stabilise (loadModels() peut être appelé en initState).
    await tester.pumpAndSettle();

    // Vérifier la présence d'éléments clés de l'UI.
    expect(find.text('Calendrier'), findsOneWidget);
    expect(find.text('Simuler +1 jour'), findsOneWidget);
    // Le bouton central affiche un emoji bière
    expect(find.text('🍻'), findsOneWidget);
    // L'icône d'info haut droite doit être présente
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('Taper sur la bière incrémente le nombre de conso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Le badge de conso commence à '0'
    expect(find.text('0'), findsOneWidget);

    // Tap sur l'emoji bière (le GestureDetector est centré dessus)
    await tester.tap(find.text('🍻'));
    // Pump pour appliquer setState déclenché par _addConso
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Maintenant on attend que le texte passe à '1'
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Bouton "Remettre full" remet les consommations à 0', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Incrémenter d'abord
    await tester.tap(find.text('🍻'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('1'), findsOneWidget);

    // Trouver et taper sur le bouton 'Remettre full'
    await tester.tap(find.text('Remettre full'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Le badge devrait être revenu à 0
    expect(find.text('0'), findsOneWidget);
  });
}
