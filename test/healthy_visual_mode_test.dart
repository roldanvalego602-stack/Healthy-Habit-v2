import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:healthy_habit/páginas/perfil/social_action_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Normal es el modo predeterminado y Lite se interpreta sin errores', () {
    expect(HealthyVisualController.parse(null), HealthyVisualMode.normal);
    expect(HealthyVisualController.parse('desconocido'), HealthyVisualMode.normal);
    expect(HealthyVisualController.parse('Lite'), HealthyVisualMode.lite);
    expect(HealthyVisualController.parse('lite'), HealthyVisualMode.lite);
    expect(HealthyVisualController.label(HealthyVisualMode.normal), 'Normal');
  });

  test('la preferencia Lite se guarda y se recupera sin Firebase', () async {
    final controller = HealthyVisualController.instance;
    await controller.select(HealthyVisualMode.normal);
    await controller.load();
    var notifications = 0;
    void onChange() => notifications++;
    controller.addListener(onChange);

    await controller.select(HealthyVisualMode.lite);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(HealthyVisualController.preferenceKey), 'Lite');
    expect(controller.isLite, isTrue);
    expect(notifications, 1);

    // Simular la relectura de preferencias después de elegir otro estado.
    await controller.select(HealthyVisualMode.normal);
    await prefs.setString(HealthyVisualController.preferenceKey, 'Lite');
    await controller.load();
    expect(controller.mode, HealthyVisualMode.lite);
    controller.removeListener(onChange);
    await controller.select(HealthyVisualMode.normal);
  });

  testWidgets('Lite desactiva efectos del botón sin bloquear su toque',
      (tester) async {
    final controller = HealthyVisualController.instance;
    await controller.select(HealthyVisualMode.lite);
    var tapped = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          expect(HealthyVisualEffects.enabled(context), isFalse);
          expect(
            HealthyVisualEffects.duration(context, const Duration(milliseconds: 180)),
            Duration.zero,
          );
          return SocialActionButton(
            label: 'Seguir',
            onPressed: () => tapped++,
          );
        }),
      ),
    ));
    await tester.tap(find.text('Seguir'));
    await tester.pump();
    expect(tapped, 1);
    expect(tester.takeException(), isNull);
    await controller.select(HealthyVisualMode.normal);
  });

  testWidgets('Normal respeta el ajuste de movimiento reducido',
      (tester) async {
    final controller = HealthyVisualController.instance;
    await controller.select(HealthyVisualMode.normal);

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (context) {
          expect(HealthyVisualEffects.enabled(context), isFalse);
          return const SizedBox.shrink();
        }),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
