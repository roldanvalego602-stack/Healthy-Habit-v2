import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/guia/guide_screen_routes.dart';
import 'package:healthy_habit/guia/guide_step.dart';
import 'package:healthy_habit/guia/guide_target.dart';
import 'package:healthy_habit/guia/healthy_guide_overlay.dart';

void main() {
  test('cuatro pantallas tienen recorridos completos y objetivos distintos', () {
    for (final section in HealthyGuideScreenRoutes.supported) {
      final steps = HealthyGuideScreenRoutes.forSection(section);
      expect(steps.length, 4, reason: section);
      expect(steps.every((s) => s.targetKey != null), isTrue,
          reason: section);
      expect(steps.map((s) => s.targetKey).toSet().length, steps.length,
          reason: section);
      expect(steps.every((s) =>
          s.title.isNotEmpty && s.description.isNotEmpty), isTrue,
          reason: section);
      for (var i = 0; i < steps.length; i++) {
        expect(steps[i].targetKey,
            HealthyGuideTargets.forSectionStep(section, i));
      }
    }
    expect(HealthyGuideScreenRoutes.forSection('inexistente'), isEmpty);
  });

  test('no se capturan datos privados ni elementos de compra', () {
    final profile = HealthyGuideScreenRoutes.forSection('perfil');
    expect(profile.every((step) => !step.extract), isTrue);
    final store = HealthyGuideScreenRoutes.forSection('tienda');
    expect(store.where((step) => step.extract).length, 1);
    expect(store[1].extract, isTrue);
    expect(store[2].extract, isFalse);
    expect(store[3].extract, isFalse);
  });

  testWidgets('recorrido completo con objetivos no montados sigue navegable',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('Pantalla cargando'))),
    ));
    final context = tester.element(find.byType(Scaffold));
    final done = HealthyGuideOverlay.show(context,
      sectionTitle: 'Catálogo',
      steps: HealthyGuideScreenRoutes.forSection('catalogo'),
    );
    await tester.pump();
    expect(find.text('Secciones del catálogo'), findsOneWidget);
    expect(find.textContaining('no esté visible'), findsOneWidget);
    for (final title in [
      'Busca información',
      'Filtra por etiquetas',
      'Orden y presentación',
    ]) {
      await tester.tap(find.text('Siguiente'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(title), findsOneWidget);
    }
    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    await done;
    expect(find.text('Secciones del catálogo'), findsNothing);
  });

  testWidgets('el overlay se puede cerrar en una pantalla compacta',
      (tester) async {
    await tester.view.physicalSize = const Size(340, 470);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('Pantalla compacta'))),
    ));
    final context = tester.element(find.byType(Scaffold));
    final done = HealthyGuideOverlay.show(context,
      sectionTitle: 'Perfil',
      steps: HealthyGuideScreenRoutes.forSection('perfil'));
    await tester.pump();
    final button = find.byTooltip('Cerrar guía');
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(470));
    await tester.tap(button);
    await tester.pump();
    await done;
    expect(find.text('Tu identidad en Healthy Habit'), findsNothing);
  });

  testWidgets('objetivo montado se reconoce sin ejecutar su acción',
      (tester) async {
    final target = HealthyGuideTargets.catalogSearch;
    var presses = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Center(child: ElevatedButton(
        key: target,
        onPressed: () => presses++,
        child: const Text('Control real'),
      )),
    )));
    final context = tester.element(find.byType(Scaffold));
    final done = HealthyGuideOverlay.show(context, steps: [
      HealthySpotlightStep(
        title: 'Búsqueda guiada', description: 'Solo explicación.',
        icon: Icons.search, targetKey: target),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Búsqueda guiada'), findsOneWidget);
    expect(presses, 0);
    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    await done;
    expect(presses, 0);
  });
}
