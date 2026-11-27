import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/cosmos_interaction_fx.dart';
import 'package:healthy_habit/tema/healthy_celebration.dart';
import 'package:healthy_habit/tema/healthy_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HealthyThemeController.instance.syncCosmos(owned: true, equipped: true);
  });
  tearDown(() {
    HealthyThemeController.instance.syncCosmos(owned: false, equipped: false);
  });

  testWidgets('partículas visibles y finitas sin interceptar toques',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.dark(),
      home: const Scaffold(
        body: SizedBox(
          width: 300, height: 180,
          child: CosmosParticleBurst(effect: CosmosEffect.habit),
        ),
      ),
    ));
    expect(find.byType(CosmosParticleBurst), findsOneWidget);
    expect(find.byType(IgnorePointer), findsWidgets);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('celebración galáctica no altera estado ni datos',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.dark(),
      home: Builder(builder: (context) => Scaffold(
        body: Center(child: FilledButton(
          onPressed: () => HealthyCelebration.show(
            context,
            title: 'Hábito confirmado',
            subtitle: '+10 XP',
            effect: CosmosEffect.habit),
          child: const Text('Celebrar'),
        )),
      )),
    ));
    await tester.tap(find.text('Celebrar'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Hábito confirmado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduce-motion no inicia partículas',
      (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        theme: HealthyThemes.dark(),
        home: const Scaffold(
          body: SizedBox(
            width: 220, height: 90,
            child: CosmosParticleBurst(effect: CosmosEffect.level),
          ),
        ),
      ),
    ));
    expect(find.descendant(
      of: find.byType(CosmosParticleBurst),
      matching: find.byType(CustomPaint),
    ), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nivel confirmado muestra overlay y este se elimina',
      (tester) async {
    late BuildContext shownContext;
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.dark(),
      home: Builder(builder: (context) {
        shownContext = context;
        return const Scaffold(body: Text('Nivel confirmado'));
      }),
    ));
    CosmosLevelOverlay.show(shownContext);
    await tester.pump();
    expect(find.byType(CosmosParticleBurst), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();
    expect(find.byType(CosmosParticleBurst), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
