import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/perfil/informacion_app_screen.dart';
import 'package:healthy_habit/tema/healthy_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('términos y políticas usan colores del tema oscuro',
      (tester) async {
    await HealthyThemeController.instance.select(ThemeMode.dark);
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.dark(),
      home: const InformacionAppScreen(tipo: 'terminos'),
    ));
    expect(find.text('Términos de uso'), findsWidgets);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, HealthyAdaptive.background);
    expect(HealthyAdaptive.isDark, isTrue);
    expect(tester.takeException(), isNull);
    await HealthyThemeController.instance.select(ThemeMode.light);
  });

  testWidgets('todas las páginas de información respetan tema claro',
      (tester) async {
    await HealthyThemeController.instance.select(ThemeMode.light);
    for (final kind in ['acerca', 'terminos', 'privacidad', 'ayuda']) {
      await tester.pumpWidget(MaterialApp(
        theme: HealthyThemes.light(),
        home: InformacionAppScreen(tipo: kind),
      ));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, HealthyAdaptive.background);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('contenido legal no produce overflow en pantalla estrecha',
      (tester) async {
    await HealthyThemeController.instance.select(ThemeMode.dark);
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.dark(),
      home: const InformacionAppScreen(tipo: 'privacidad'),
    ));
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
    await HealthyThemeController.instance.select(ThemeMode.light);
  });
}
