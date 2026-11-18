import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthy_habit/tema/healthy_theme.dart';
import 'package:healthy_habit/páginas/logros/logros_screen.dart';
import 'package:healthy_habit/páginas/logros/logros_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await HealthyThemeController.instance.select(ThemeMode.light);
  });

  final items = <LogroVista>[
    const LogroVista(
      definicion: LogroDefinicion(
        id: 'test', nombre: 'Logro de prueba',
        descripcion: 'Comprueba la adaptación del tema en pantalla pequeña.',
        meta: 3, tipo: 'racha', icono: Icons.stars_rounded,
        rareza: RarezaLogro.especial,
      ),
      progreso: 1,
    ),
  ];

  Future<void> render(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(AnimatedBuilder(
      animation: HealthyThemeController.instance,
      builder: (context, _) => MaterialApp(
        theme: HealthyThemes.light(),
        darkTheme: HealthyThemes.dark(),
        themeMode: HealthyThemeController.instance.mode,
        home: Scaffold(
          body: LogrosColeccion(items: items),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('logros no desbordan en tema claro ni oscuro', (tester) async {
    await render(tester);
    expect(find.byKey(const Key('logros-resumen')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await HealthyThemeController.instance.select(ThemeMode.dark);
    await tester.pump();
    expect(find.byKey(const Key('logros-resumen')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await HealthyThemeController.instance.select(ThemeMode.light);
  });
}
