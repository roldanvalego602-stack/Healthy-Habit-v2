import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/ranking_screen.dart';
import 'package:healthy_habit/tema/healthy_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await HealthyThemeController.instance.load();
  });

  Future<void> pumpRanking(
    WidgetTester tester, {
    required Size size,
    required ThemeMode mode,
    required bool compact,
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await HealthyThemeController.instance.select(mode);
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.light(),
      darkTheme: HealthyThemes.dark(),
      themeMode: mode,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
            child: Row(
              children: [
                Expanded(child: RankingPodiumCard(
                  rank: 2,
                  name: 'Nombre de usuario deliberadamente muy largo',
                  xp: 275,
                  compact: compact,
                )),
              ],
            ),
          ),
        ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('podio compacto de 320dp no produce overflow con texto grande',
      (tester) async {
    await pumpRanking(tester,
      size: const Size(320, 640),
      mode: ThemeMode.dark,
      compact: true,
      scale: 1.4,
    );
    expect(find.textContaining('Nombre de usuario'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('podio ancho respeta modo claro con nombre largo',
      (tester) async {
    await pumpRanking(tester,
      size: const Size(800, 700),
      mode: ThemeMode.light,
      compact: false,
    );
    expect(find.textContaining('275 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
