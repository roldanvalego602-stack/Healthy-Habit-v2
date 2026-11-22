import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_motion.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Lite muestra inmediatamente la tarjeta y no bloquea acciones',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HealthyMotionCard(
          child: ElevatedButton(
            onPressed: () => taps++,
            child: const Text('Canjear'),
          ),
        ),
      ),
    ));
    expect(find.text('Canjear'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    await tester.tap(find.text('Canjear'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Normal permite entrada breve y no genera animaciones infinitas',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HealthyMotionCard(
          child: SizedBox(width: 100, height: 80, child: Text('Tarjeta')),
        ),
      ),
    ));
    expect(find.text('Tarjeta'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('la racha se muestra estática en Lite y no desaparece',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HealthyStreakNumber(
          days: 7,
          style: TextStyle(fontSize: 18),
        ),
      ),
    ));
    expect(find.text('7 días'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });

  testWidgets('Normal enfatiza la racha solo durante el cambio',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HealthyStreakNumber(
          days: 8,
          style: TextStyle(fontSize: 18),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('8 días'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Lite muestra XP exacta inmediatamente', (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyCountUp(
        value: 1280,
        suffix: ' XP acumulados',
        style: TextStyle(fontSize: 18),
      )),
    ));
    expect(find.text('1280 XP acumulados'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });

  testWidgets('Normal termina el contador de XP en el valor real',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyCountUp(
        value: 350,
        suffix: ' XP acumulados',
        style: TextStyle(fontSize: 18),
      )),
    ));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('350 XP acumulados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
