import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/guia/guide_choreography.dart';
import 'package:healthy_habit/guia/guide_fx_theme.dart';
import 'package:healthy_habit/guia/guide_step.dart';
import 'package:healthy_habit/guia/healthy_guide_overlay.dart';

void main() {
  test('Cosmos solo cambia el aspecto de los efectos', () {
    final cosmos = GuideFxTheme.fromAppearance(
      cosmos: true, dark: true, christmas: false);
    final standard = GuideFxTheme.fromAppearance(
      cosmos: false, dark: false, christmas: false);
    final christmas = GuideFxTheme.fromAppearance(
      cosmos: false, dark: false, christmas: true);
    expect(cosmos.cosmos, isTrue);
    expect(standard.cosmos, isFalse);
    expect(cosmos.accent, isNot(standard.accent));
    expect(christmas.accent, isNot(cosmos.accent));
    expect(cosmos.background, isNot(Colors.white));
  });

  test('el painter repinta al cambiar paso, progreso o paleta', () {
    final fx = GuideFxTheme.fromAppearance(
      cosmos: false, dark: false, christmas: false);
    final nextFx = GuideFxTheme.fromAppearance(
      cosmos: true, dark: true, christmas: false);
    final first = GuideChoreographyPainter(
      target: const Rect.fromLTWH(20, 30, 180, 68),
      phase: 0,
      intro: 0,
      fx: fx,
      motion: true,
    );
    final next = GuideChoreographyPainter(
      target: const Rect.fromLTWH(20, 30, 180, 68),
      phase: .5,
      intro: .7,
      fx: nextFx,
      motion: true,
    );
    expect(next.shouldRepaint(first), isTrue);
  });

  test('el painter no falla sin objetivo o en modo estático', () {
    final fx = GuideFxTheme.fromAppearance(
      cosmos: true, dark: true, christmas: false);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final empty = GuideChoreographyPainter(
      target: null, phase: 0, intro: 1, fx: fx, motion: false);
    empty.paint(canvas, const Size(320, 600));
    final staticPainter = GuideChoreographyPainter(
      target: const Rect.fromLTWH(35, 110, 140, 80),
      phase: 0, intro: 1, fx: fx, motion: false);
    staticPainter.paint(canvas, const Size(320, 600));
    recorder.endRecording().dispose();
  });

  testWidgets('la guía cambia de paso y conserva sus controles',
      (tester) async {
    final first = GlobalKey();
    final second = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Column(children: [
        SizedBox(key: first, width: 180, height: 70,
          child: const Text('Elemento A')),
        SizedBox(key: second, width: 180, height: 70,
          child: const Text('Elemento B')),
      ])),
    ));
    final context = tester.element(find.byType(Scaffold));
    final finished = HealthyGuideOverlay.show(context, steps: [
      HealthySpotlightStep(
        title: 'Introducción',
        description: 'Esta es la primera explicación.',
        icon: Icons.flag, targetKey: first),
      HealthySpotlightStep(
        title: 'Continuación',
        description: 'Aquí se explica el segundo elemento.',
        icon: Icons.info, targetKey: second),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('Introducción'), findsOneWidget);
    expect(find.byType(GuideChoreographyPainter), findsNothing);
    expect(find.byWidgetPredicate((w) =>
        w is CustomPaint && w.painter is GuideChoreographyPainter),
      findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Continuación'), findsOneWidget);
    expect(find.text('Aquí se explica el segundo elemento.'), findsOneWidget);
    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    await finished;
    expect(find.text('Continuación'), findsNothing);
  });

  testWidgets('reducir movimiento desactiva transiciones del texto',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(body: SizedBox(
        key: key, width: 120, height: 60, child: const Text('Objetivo'))),
    )));
    final context = tester.element(find.byType(Scaffold));
    final finished = HealthyGuideOverlay.show(context, steps: [
      HealthySpotlightStep(
        title: 'Sin movimiento',
        description: 'La interfaz permanece accesible.',
        icon: Icons.accessibility, targetKey: key),
    ]);
    await tester.pump();
    // Comprueba que el overlay raíz reciba el MediaQuery de la ruta.
    final guideContext = tester.element(find.text('Sin movimiento'));
    expect(MediaQuery.of(guideContext).disableAnimations, isTrue);
    expect(MediaQuery.sizeOf(guideContext), tester.view.physicalSize /
        tester.view.devicePixelRatio);
    final switches = tester.widgetList<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher));
    expect(switches.any((w) => w.duration == Duration.zero), isTrue);
    final finishButton = find.widgetWithText(FilledButton, 'Finalizar');
    expect(tester.getRect(finishButton).bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height /
            tester.view.devicePixelRatio));
    await tester.tap(finishButton);
    await tester.pump();
    await finished;
  });
}
