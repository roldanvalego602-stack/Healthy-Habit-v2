import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthy_habit/tema/healthy_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tema sin preferencia mantiene Claro para compatibilidad', () {
    expect(HealthyThemeController.parse(null), ThemeMode.light);
    expect(HealthyThemeController.parse('cualquier texto'), ThemeMode.light);
  });

  test('interpreta los tres modos y sus etiquetas', () {
    expect(HealthyThemeController.parse('Claro'), ThemeMode.light);
    expect(HealthyThemeController.parse('Oscuro'), ThemeMode.dark);
    expect(HealthyThemeController.parse('Sistema'), ThemeMode.system);
    expect(HealthyThemeController.label(ThemeMode.dark), 'Oscuro');
  });

  test('seleccionar tema persiste localmente y notifica', () async {
    final controller = HealthyThemeController.instance;
    await controller.load();
    var events = 0;
    void onChange() => events++;
    controller.addListener(onChange);
    await controller.select(ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(HealthyThemeController.preferenceKey), 'Oscuro');
    expect(controller.mode, ThemeMode.dark);
    expect(events, 1);
    controller.removeListener(onChange);
    // Devolver al claro para aislar otras pruebas.
    await controller.select(ThemeMode.light);
  });

  testWidgets('tema claro y oscuro cambian colores globales',
      (tester) async {
    final controller = HealthyThemeController.instance;
    await controller.select(ThemeMode.light);
    await tester.pumpWidget(AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        theme: HealthyThemes.light(),
        darkTheme: HealthyThemes.dark(),
        themeMode: controller.mode,
        home: Builder(
          builder: (context) => Text(
            Theme.of(context).brightness.name,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    ));
    expect(find.text('light'), findsOneWidget);
    await controller.select(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(find.text('dark'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await controller.select(ThemeMode.light);
  });
}
