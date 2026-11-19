import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_float.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget demo({bool tickerEnabled = true}) => MaterialApp(
    home: Scaffold(
      body: TickerMode(
        enabled: tickerEnabled,
        child: const Center(
          child: HealthyFloat(
            distance: 4,
            child: Text('Racha activa'),
          ),
        ),
      ),
    ),
  );

  testWidgets('Normal anima sin alterar el tamaño ni ocultar el contenido',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    await tester.pumpWidget(demo());
    final before = tester.getSize(find.text('Racha activa'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Racha activa'), findsOneWidget);
    expect(tester.getSize(find.text('Racha activa')), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Lite se mantiene estático y permite pumpAndSettle',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    await tester.pumpWidget(demo());
    await tester.pumpAndSettle();
    expect(find.text('Racha activa'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });

  testWidgets('TickerMode inactivo detiene la flotación',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    await tester.pumpWidget(demo(tickerEnabled: false));
    await tester.pumpAndSettle();
    expect(find.text('Racha activa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reducir movimiento en Android evita animación continua',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Scaffold(
            body: HealthyFloat(child: Text('Sin movimiento')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sin movimiento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
