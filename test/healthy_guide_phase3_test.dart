import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/guia/guide_extraction.dart';
import 'package:healthy_habit/guia/guide_step.dart';
import 'package:healthy_habit/guia/healthy_guide_overlay.dart';

// PNG válida y pequeña: evita depender del backend gráfico de pruebas.
// La ruta productiva sigue capturando mediante RepaintBoundary.toImage().
final _previewForTest = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAMAAAADCAIAAADZSiLo'
  'AAAAF0lEQVR4nGNU2lHNwMDAwMDAxAADCBYAJWsBW5KYPuMAAAAASUVORK5CYII=');

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 14 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  expect(finder, findsOneWidget);
}

void main() {
  test('la vista ampliada evita la tarjeta informativa', () {
    const screen = Size(390, 844);
    const card = Rect.fromLTWH(16, 580, 358, 230);
    final rect = guideExtractionDestination(
      viewport: screen,
      safeArea: const EdgeInsets.only(top: 36, bottom: 24),
      explanation: card,
    );
    expect(rect, isNotNull);
    expect(rect!.overlaps(card), isFalse);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(screen.width));
    expect(rect.top, greaterThanOrEqualTo(36));
  });

  test('cuando no hay espacio la extracción se omite', () {
    final rect = guideExtractionDestination(
      viewport: const Size(190, 270),
      safeArea: const EdgeInsets.only(top: 32, bottom: 30),
      explanation: const Rect.fromLTWH(8, 70, 174, 190),
    );
    expect(rect, isNull);
  });

  testWidgets('captura un componente real y muestra copia no interactiva',
      (tester) async {
    final key = GlobalKey();
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 170,
            height: 100,
            child: ElevatedButton(
              onPressed: () => taps++,
              child: const Text('Acción original'),
            ),
          ),
        ),
      )),
    ));
    final context = tester.element(find.byType(Scaffold));
    final done = HealthyGuideOverlay.show(context,
      capture: (_) async => _previewForTest,
      steps: [
      HealthySpotlightStep(
        title: 'Detalle seguro',
        description: 'Imagen visual sin tocar el botón.',
        icon: Icons.zoom_in_rounded,
        targetKey: key,
        extract: true,
      ),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 650));
    await _pumpUntil(tester, find.byType(GuideExtraction));
    expect(find.text('Acción original'), findsOneWidget);
    expect(taps, 0);
    await tester.tap(find.text('Finalizar'));
    await tester.pump(const Duration(milliseconds: 600));
    await done;
    expect(find.byType(GuideExtraction), findsNothing);
    expect(taps, 0);
  });

  testWidgets('sin RepaintBoundary mantiene la explicación y no falla',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(key: key, width: 130, height: 60,
        child: const Text('Sin captura')),
      ),
    ));
    final context = tester.element(find.byType(Scaffold));
    final done = HealthyGuideOverlay.show(context, steps: [
      HealthySpotlightStep(
        title: 'Modo alternativo',
        description: 'Se mantiene el spotlight.',
        icon: Icons.info_outline,
        targetKey: key,
        extract: true,
      ),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    expect(find.text('Modo alternativo'), findsOneWidget);
    expect(find.byType(GuideExtraction), findsNothing);
    await tester.tap(find.byTooltip('Cerrar guía'));
    await tester.pump();
    await done;
  });

  testWidgets('al cambiar de paso devuelve la captura y la retira',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(
        child: RepaintBoundary(
          key: key, child: const SizedBox(
            width: 160, height: 90,
            child: Text('Tarjeta real')),
        ),
      )),
    ));
    final context = tester.element(find.byType(Scaffold));
    final done = HealthyGuideOverlay.show(context,
      capture: (_) async => _previewForTest,
      steps: [
      HealthySpotlightStep(
        title: 'Ampliar', description: 'Vista temporal.',
        icon: Icons.zoom_in, targetKey: key, extract: true),
      const HealthySpotlightStep(
        title: 'Continuar', description: 'Ya no hay captura.',
        icon: Icons.check, targetKey: null),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 600));
    await _pumpUntil(tester, find.byType(GuideExtraction));
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 620));
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.byType(GuideExtraction), findsNothing);
    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    await done;
  });
}
