import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/guia/guide_controller.dart';
import 'package:healthy_habit/guia/guide_step.dart';
import 'package:healthy_habit/guia/healthy_guide_overlay.dart';
import 'package:healthy_habit/guia/guide_spotlight_painter.dart';

void main() {
  test('el controlador recorre, retrocede y finaliza sin exceder límites', () {
    final controller = HealthyGuideController(3);
    expect(controller.index, 0);
    controller.previous();
    expect(controller.index, 0);
    controller.next();
    expect(controller.index, 1);
    controller.next();
    expect(controller.index, 2);
    controller.next();
    expect(controller.active, isFalse);
    controller.next();
    expect(controller.index, 2);
    controller.dispose();
  });

  test('el spotlight repinta cuando cambia el objetivo o la fase', () {
    const first = HealthyGuideSpotlightPainter(
      target: Rect.fromLTWH(20, 30, 100, 40),
      phase: 0,
      accent: Colors.green,
    );
    const second = HealthyGuideSpotlightPainter(
      target: Rect.fromLTWH(20, 30, 100, 40),
      phase: .5,
      accent: Colors.green,
    );
    expect(first.shouldRepaint(second), isTrue);
  });

  testWidgets('la guía destaca un objetivo y permite cerrar', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(
        child: SizedBox(key: key, width: 140, height: 60,
          child: const Text('Elemento importante')),
      )),
    ));
    final context = tester.element(find.byType(Scaffold));
    final future = HealthyGuideOverlay.show(context,
      steps: [
        HealthySpotlightStep(
          title: 'Objetivo principal',
          description: 'Aquí aparece el elemento que queremos explicar.',
          icon: Icons.help_outline,
          targetKey: key,
        ),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Objetivo principal'), findsOneWidget);
    expect(find.text('Elemento importante'), findsOneWidget);
    expect(find.byType(ModalBarrier), findsWidgets);
    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    await future;
    expect(find.text('Objetivo principal'), findsNothing);
  });

  testWidgets('puede navegar adelante y atrás sin tocar botones de fondo',
      (tester) async {
    var backgroundPressed = 0;
    final firstKey = GlobalKey();
    final secondKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Column(children: [
        ElevatedButton(
          key: firstKey, onPressed: () => backgroundPressed++,
          child: const Text('Acción real'),
        ),
        SizedBox(
          key: secondKey, height: 50,
          child: const Text('Segundo objetivo'),
        ),
      ])),
    ));
    final context = tester.element(find.byType(Scaffold));
    final future = HealthyGuideOverlay.show(context,
      steps: [
        HealthySpotlightStep(
          title: 'Primero', description: 'No activar.',
          icon: Icons.flag, targetKey: firstKey),
        HealthySpotlightStep(
          title: 'Segundo', description: 'Continuación.',
          icon: Icons.info, targetKey: secondKey),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Segundo'), findsOneWidget);
    await tester.tap(find.text('Anterior'));
    await tester.pump();
    expect(find.text('Primero'), findsOneWidget);
    expect(backgroundPressed, 0);
    await tester.tap(find.byTooltip('Cerrar guía'));
    await tester.pump();
    await future;
    expect(backgroundPressed, 0);
  });
}
