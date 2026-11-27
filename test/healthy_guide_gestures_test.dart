import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/guia/assistant_guide_character.dart';
import 'package:healthy_habit/guia/guide_character_pose.dart';
import 'package:healthy_habit/guia/guide_gesture.dart';
import 'package:healthy_habit/guia/guide_step.dart';
import 'package:healthy_habit/guia/healthy_guide_overlay.dart';

void main() {
  test('el motor asigna gestos según tipo y posición del paso', () {
    const first = HealthySpotlightStep(
      title: 'Primero', description: 'Saludo.',
      icon: Icons.home, targetKey: null);
    const extract = HealthySpotlightStep(
      title: 'Ampliar', description: 'Inspección.',
      icon: Icons.zoom_in, targetKey: null, extract: true);
    const middle = HealthySpotlightStep(
      title: 'Segundo', description: 'Señalar.',
      icon: Icons.info, targetKey: null);
    const last = HealthySpotlightStep(
      title: 'Final', description: 'Despedida.',
      icon: Icons.check, targetKey: null);
    expect(first.effectiveGesture(0, 4), HealthyGuideGesture.greet);
    expect(extract.effectiveGesture(1, 4), HealthyGuideGesture.inspect);
    expect(middle.effectiveGesture(2, 4), HealthyGuideGesture.point);
    expect(last.effectiveGesture(3, 4), HealthyGuideGesture.farewell);
    const explicit = HealthySpotlightStep(
      title: 'Nivel', description: 'Celebración.',
      icon: Icons.stars, targetKey: null,
      gesture: HealthyGuideGesture.celebrate);
    expect(explicit.effectiveGesture(1, 4),
        HealthyGuideGesture.celebrate);
  });

  test('las poses estáticas respetan desactivación del movimiento', () {
    for (final gesture in HealthyGuideGesture.values) {
      final pose = HealthyGuideMotion.at(
        gesture, .7, .4, enabled: false, direction: -1);
      expect(pose.lift, 0);
      expect(pose.rotation, 0);
      expect(pose.scale, 1);
      expect(pose.signal, 1);
    }
  });

  test('los gestos animados tienen perfiles distintos y deterministas', () {
    final greet = HealthyGuideMotion.at(
      HealthyGuideGesture.greet, .25, 1,
      enabled: true, direction: 1);
    final celebrate = HealthyGuideMotion.at(
      HealthyGuideGesture.celebrate, .25, 1,
      enabled: true, direction: 1);
    final point = HealthyGuideMotion.at(
      HealthyGuideGesture.point, .25, 1,
      enabled: true, direction: -1);
    expect(greet.scale, isNot(celebrate.scale));
    expect(point.rotation, lessThan(0));
    expect(celebrate.lift, lessThanOrEqualTo(0));
    expect(greet.lift, lessThanOrEqualTo(0));
    expect(HealthyGuideMotion.at(HealthyGuideGesture.greet,
      .25, 1, enabled: true, direction: 1).scale, greet.scale);
  });

  testWidgets('el personaje indica el gesto y no recibe toques',
      (tester) async {
    final phase = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 2),
    );
    addTearDown(phase.dispose);
    const pose = GuideCharacterPose(
      position: Offset(20, 40),
      size: Size(92, 108),
      leanRadians: .1,
      facesLeft: false,
      pointsUp: true,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Stack(children: [
        AssistantGuideCharacter(
          pose: pose, motion: false, phase: phase,
          stepIndex: 0, gesture: HealthyGuideGesture.celebrate),
      ]),
    )));
    expect(find.byType(AssistantGuideCharacter), findsOneWidget);
    expect(find.byIcon(Icons.stars_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Mr. Healthy celebra el avance'),
        findsOneWidget);
  });

  testWidgets('al cambiar de paso cambia el gesto en la guía',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: Text('Pantalla de prueba'),
    )));
    final context = tester.element(find.byType(Scaffold));
    final completed = HealthyGuideOverlay.show(context, steps: [
      const HealthySpotlightStep(
        title: 'Bienvenida', description: 'Comenzar.',
        icon: Icons.home, targetKey: null),
      const HealthySpotlightStep(
        title: 'Celebración', description: 'Continuar.',
        icon: Icons.stars, targetKey: null,
        gesture: HealthyGuideGesture.celebrate),
    ]);
    await tester.pump();
    var character = tester.widget<AssistantGuideCharacter>(
      find.byType(AssistantGuideCharacter));
    expect(character.gesture, HealthyGuideGesture.greet);
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 350));
    character = tester.widget<AssistantGuideCharacter>(
      find.byType(AssistantGuideCharacter));
    expect(character.gesture, HealthyGuideGesture.celebrate);
    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    await completed;
  });
}
