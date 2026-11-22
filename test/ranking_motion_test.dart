import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/ranking_screen.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget firstPlace() => const MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(
        width: 320,
        child: RankingPodiumCard(
          rank: 1,
          name: 'Participante de prueba',
          xp: 1280,
          compact: true,
        ),
      )),
    ),
  );

  testWidgets('primera posición flota sin alterar layout en Normal',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    await tester.pumpWidget(firstPlace());
    final box = find.byType(RankingPodiumCard);
    final original = tester.getSize(box);
    await tester.pump(const Duration(milliseconds: 480));
    expect(tester.getSize(box), original);
    expect(find.text('#1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Lite elimina el movimiento pero mantiene los datos',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    await tester.pumpWidget(firstPlace());
    await tester.pumpAndSettle();
    expect(find.text('Participante de prueba'), findsOneWidget);
    expect(find.text('1280 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });
}
