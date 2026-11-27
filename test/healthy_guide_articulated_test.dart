import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/guia/assistant_guide_character.dart';
import 'package:healthy_habit/guia/guide_animated_limbs.dart';
import 'package:healthy_habit/guia/guide_character_pose.dart';
import 'package:healthy_habit/guia/guide_gesture.dart';

void main() {
  const accent = Color(0xFF63E6BE);
  const bounds = Size(100, 120);

  test('los brazos admiten todos los gestos y ambas orientaciones', () {
    for (final gesture in HealthyGuideGesture.values) {
      for (final left in [false, true]) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        GuideLimbPainter(
          gesture: gesture,
          phase: .35,
          motion: true,
          facesLeft: left,
          accent: accent,
        ).paint(canvas, bounds);
        recorder.endRecording().dispose();
      }
    }
  });

  test('en modo Lite las extremidades mantienen una pose estática', () {
    for (final gesture in HealthyGuideGesture.values) {
      final initial = GuideLimbPainter(
        gesture: gesture, phase: 0,
        motion: false, facesLeft: false, accent: accent);
      final same = GuideLimbPainter(
        gesture: gesture, phase: 0,
        motion: false, facesLeft: false, accent: accent);
      expect(same.shouldRepaint(initial), isFalse);
    }
  });

  test('los brazos se repintan al cambiar de gesto u orientación', () {
    const initial = GuideLimbPainter(
      gesture: HealthyGuideGesture.greet,
      phase: 0,
      motion: true,
      facesLeft: false,
      accent: accent,
    );
    const newGesture = GuideLimbPainter(
      gesture: HealthyGuideGesture.point,
      phase: 0,
      motion: true,
      facesLeft: false,
      accent: accent,
    );
    const newOrientation = GuideLimbPainter(
      gesture: HealthyGuideGesture.greet,
      phase: 0,
      motion: true,
      facesLeft: true,
      accent: accent,
    );
    expect(newGesture.shouldRepaint(initial), isTrue);
    expect(newOrientation.shouldRepaint(initial), isTrue);
  });

  testWidgets('Mr Healthy contiene un rig gráfico para brazos',
      (tester) async {
    final phase = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1));
    addTearDown(phase.dispose);
    const pose = GuideCharacterPose(
      position: Offset(25, 40),
      size: Size(100, 120),
      leanRadians: 0,
      facesLeft: false,
      pointsUp: true,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Stack(children: [
        AssistantGuideCharacter(
          pose: pose,
          motion: false,
          phase: phase,
          stepIndex: 0,
          gesture: HealthyGuideGesture.greet,
        ),
      ]),
    )));
    expect(find.byType(GuideAnimatedLimbs), findsOneWidget);
    final limbs = tester.widget<GuideAnimatedLimbs>(
      find.byType(GuideAnimatedLimbs));
    expect(limbs.motion, isFalse);
    expect(limbs.gesture, HealthyGuideGesture.greet);
    expect(find.byKey(const ValueKey('guide-articulated-limbs')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cambiar pose actualiza manos sin recrear mascota',
      (tester) async {
    final phase = AnimationController(
      vsync: tester, duration: const Duration(seconds: 1));
    addTearDown(phase.dispose);
    const pose = GuideCharacterPose(
      position: Offset(20, 20),
      size: Size(94, 110),
      leanRadians: 0,
      facesLeft: true,
      pointsUp: false,
    );
    Widget app(HealthyGuideGesture gesture) => MaterialApp(
      home: Scaffold(body: Stack(children: [
        AssistantGuideCharacter(
          pose: pose, motion: false, phase: phase,
          stepIndex: 0, gesture: gesture),
      ])),
    );
    await tester.pumpWidget(app(HealthyGuideGesture.point));
    expect(tester.widget<GuideAnimatedLimbs>(
        find.byType(GuideAnimatedLimbs)).gesture,
      HealthyGuideGesture.point);
    await tester.pumpWidget(app(HealthyGuideGesture.celebrate));
    expect(tester.widget<GuideAnimatedLimbs>(
        find.byType(GuideAnimatedLimbs)).gesture,
      HealthyGuideGesture.celebrate);
    expect(find.byType(AssistantGuideCharacter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
