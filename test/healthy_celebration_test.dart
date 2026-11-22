import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_celebration.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget demo() => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => HealthyCelebration.show(
              context,
              title: '¡Recompensa adquirida!',
              subtitle: 'Accesorio agregado a tu colección.',
              icon: Icons.card_giftcard_rounded,
            ),
            child: const Text('Celebrar'),
          ),
        ),
      ),
    ),
  );

  testWidgets('Normal muestra confirmación con animación finita',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    await tester.pumpWidget(demo());
    await tester.tap(find.text('Celebrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('¡Recompensa adquirida!'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('¡Recompensa adquirida!'), findsNothing);
  });

  testWidgets('Lite conserva el aviso pero elimina el efecto',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    await tester.pumpWidget(demo());
    await tester.tap(find.text('Celebrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('¡Recompensa adquirida!'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });
}
