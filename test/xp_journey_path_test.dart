import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/niveles/xp_journey_path.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpPath(
    WidgetTester tester, {
    required int currentLevel,
    required HealthyVisualMode mode,
    ThemeMode brightness = ThemeMode.dark,
    Size size = const Size(320, 760),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await HealthyVisualController.instance.select(mode);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: brightness,
      home: Scaffold(
        body: ListView(
          children: [
            XpJourneyPath(
              currentLevel: currentLevel,
              claimedRewards: const {2},
            ),
          ],
        ),
      ),
    ));
    await tester.pump();
  }

  List<XpJourneyTrackPainter> painters(WidgetTester tester) =>
      tester.widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<XpJourneyTrackPainter>()
          .toList();

  Color firstColor(WidgetTester tester, int level) {
    final container = tester.widget<Container>(
      find.byKey(ValueKey('xp-path-card-$level')),
    );
    final gradient = (container.decoration! as BoxDecoration).gradient!
        as LinearGradient;
    return gradient.colors.first;
  }

  testWidgets('la línea desciende hasta el nivel real y no enciende futuros',
      (tester) async {
    await pumpPath(
      tester, currentLevel: 4, mode: HealthyVisualMode.normal,
    );
    final atStart = painters(tester);
    expect(atStart.length, 20);
    expect(atStart[3].upper, lessThan(1));
    final lockedBefore = firstColor(tester, 5);

    await tester.pump(const Duration(milliseconds: 350));
    final partial = painters(tester);
    expect(partial[0].lower, greaterThan(0));
    expect(partial[3].upper, lessThan(1));

    await tester.pump(const Duration(seconds: 4));
    final complete = painters(tester);
    expect(complete[3].upper, 1);
    expect(complete[3].lower, 0);
    expect(complete[4].upper, 0);
    expect(firstColor(tester, 5), lockedBefore);
    expect(firstColor(tester, 4), isNot(lockedBefore));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lite aparece totalmente revelado sin esperar animación',
      (tester) async {
    await pumpPath(
      tester,
      currentLevel: 3,
      mode: HealthyVisualMode.lite,
      brightness: ThemeMode.light,
    );
    final track = painters(tester);
    expect(track[2].upper, 1);
    expect(track[3].upper, 0);
    expect(find.byKey(const ValueKey('xp-journey-node-20')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });

  testWidgets('nivel inicial enciende solo la primera parada',
      (tester) async {
    await pumpPath(
      tester, currentLevel: 1, mode: HealthyVisualMode.normal,
    );
    final track = painters(tester);
    expect(track.length, 20);
    expect(track[0].lower, 0);
    expect(track[1].upper, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('las veinte tarjetas caben en móvil de 320dp',
      (tester) async {
    await pumpPath(
      tester,
      currentLevel: 10,
      mode: HealthyVisualMode.lite,
    );
    expect(find.byKey(const Key('xp-journey-path')), findsOneWidget);
    expect(painters(tester).length, 20);
    expect(tester.takeException(), isNull);
  });
}
