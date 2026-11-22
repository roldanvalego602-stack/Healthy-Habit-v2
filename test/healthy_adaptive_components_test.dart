import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthy_habit/tema/healthy_theme.dart';
import 'package:healthy_habit/Contenido_del_tema/tarjeta_contenedor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await HealthyThemeController.instance.load();
  });

  test('tokens cambian con tema y conservan contraste', () async {
    final controller = HealthyThemeController.instance;
    await controller.select(ThemeMode.light);
    expect(HealthyAdaptive.background, const Color(0xFFF7F9F8));
    expect(HealthyAdaptive.surface, Colors.white);
    final lightText = HealthyAdaptive.text;

    await controller.select(ThemeMode.dark);
    expect(HealthyAdaptive.background, const Color(0xFF101923));
    expect(HealthyAdaptive.surface, const Color(0xFF1B2935));
    expect(HealthyAdaptive.text, isNot(lightText));
    expect(HealthyAdaptive.water, isNot(const Color(0xFFE8F6FC)));

    await controller.select(ThemeMode.light);
  });

  testWidgets('tarjeta compartida sigue el tema en 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = HealthyThemeController.instance;
    await controller.select(ThemeMode.light);
    await tester.pumpWidget(AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        theme: HealthyThemes.light(),
        darkTheme: HealthyThemes.dark(),
        themeMode: controller.mode,
        home: const Scaffold(
          body: SafeArea(child: TarjetaContenedor(
            child: Text('Hábitos: tarjeta de prueba', softWrap: true),
          )),
        ),
      ),
    ));
    expect(find.text('Hábitos: tarjeta de prueba'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await controller.select(ThemeMode.dark);
    await tester.pump();
    expect(find.text('Hábitos: tarjeta de prueba'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await controller.select(ThemeMode.light);
  });
}
