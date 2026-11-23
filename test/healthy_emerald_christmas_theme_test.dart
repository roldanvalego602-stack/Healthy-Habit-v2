import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await HealthyThemeController.instance.selectStyle(
      HealthyThemeStyle.original,
    );
  });

  test('Navidad Esmeralda conserva su selección al guardar', () async {
    final controller = HealthyThemeController.instance;
    await controller.selectStyle(HealthyThemeStyle.emeraldChristmas);
    expect(controller.style, HealthyThemeStyle.emeraldChristmas);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(HealthyThemeController.stylePreferenceKey),
        'Navidad Esmeralda');
    expect(HealthyThemeController.parseStyle('desconocido'),
        HealthyThemeStyle.original);
  });

  test('la paleta navideña funciona en claro y oscuro', () async {
    await HealthyThemeController.instance.selectStyle(
      HealthyThemeStyle.emeraldChristmas,
    );
    final light = HealthyThemes.light();
    final dark = HealthyThemes.dark();
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
    expect(HealthyAdaptive.isChristmas, isTrue);
    await HealthyThemeController.instance.selectStyle(
      HealthyThemeStyle.original,
    );
    expect(HealthyAdaptive.isChristmas, isFalse);
  });

  testWidgets('el estilo puede envolverse en MaterialApp', (tester) async {
    await HealthyThemeController.instance.selectStyle(
      HealthyThemeStyle.emeraldChristmas,
    );
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.light(),
      darkTheme: HealthyThemes.dark(),
      home: const Scaffold(body: Text('Healthy Habit')),
    ));
    expect(find.text('Healthy Habit'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await HealthyThemeController.instance.selectStyle(
      HealthyThemeStyle.original,
    );
  });
}
