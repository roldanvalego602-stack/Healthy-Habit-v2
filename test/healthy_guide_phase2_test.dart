import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/guia/assistant_guide_character.dart';
import 'package:healthy_habit/guia/guide_character_pose.dart';
import 'package:healthy_habit/guia/guide_pointer.dart';
import 'package:healthy_habit/guia/guide_step.dart';
import 'package:healthy_habit/guia/healthy_guide_overlay.dart';

void main() {
  test('la mascota permanece dentro del área segura', () {
    const screen = Size(390, 844);
    const safeArea = EdgeInsets.only(top: 48, bottom: 34);
    const card = Rect.fromLTWH(16, 560, 358, 230);
    const target = Rect.fromLTWH(44, 210, 220, 72);
    final pose = GuideCharacterPose.resolve(
      viewport: screen,
      safeArea: safeArea,
      explanation: card,
      target: target,
    );
    expect(pose.bounds.left, greaterThanOrEqualTo(8));
    expect(pose.bounds.right, lessThanOrEqualTo(screen.width - 8));
    expect(pose.bounds.top, greaterThanOrEqualTo(safeArea.top + 50));
    expect(pose.bounds.bottom,
        lessThanOrEqualTo(screen.height - safeArea.bottom - 8));
    expect(pose.bounds.overlaps(target), isFalse);
    expect(pose.bounds.overlaps(card), isFalse);
  });

  test('mantiene límites en una pantalla angosta', () {
    final pose = GuideCharacterPose.resolve(
      viewport: const Size(320, 640),
      safeArea: const EdgeInsets.only(top: 24, bottom: 24),
      target: const Rect.fromLTWH(44, 94, 242, 60),
      explanation: const Rect.fromLTWH(16, 365, 288, 245),
      characterSize: const Size(72, 86),
    );
    expect(pose.bounds.left, greaterThanOrEqualTo(8));
    expect(pose.bounds.right, lessThanOrEqualTo(312));
    expect(pose.bounds.bottom, lessThanOrEqualTo(608));
  });

  test('la dirección del personaje cambia con el objetivo', () {
    final left = GuideCharacterPose.resolve(
      viewport: const Size(430, 900),
      safeArea: const EdgeInsets.only(top: 44, bottom: 30),
      target: const Rect.fromLTWH(20, 180, 82, 70),
      explanation: const Rect.fromLTWH(12, 590, 406, 250),
    );
    final right = GuideCharacterPose.resolve(
      viewport: const Size(430, 900),
      safeArea: const EdgeInsets.only(top: 44, bottom: 30),
      target: const Rect.fromLTWH(328, 180, 78, 70),
      explanation: const Rect.fromLTWH(12, 590, 406, 250),
    );
    expect(left.bounds.overlaps(const Rect.fromLTWH(20, 180, 82, 70)),
        isFalse);
    expect(right.bounds.overlaps(const Rect.fromLTWH(328, 180, 78, 70)),
        isFalse);
    expect(left.facesLeft, isNot(right.facesLeft));
  });

  test('la línea solicita repintado al cambiar de objetivo', () {
    final pose = GuideCharacterPose.resolve(
      viewport: const Size(400, 800),
      safeArea: EdgeInsets.zero,
      target: const Rect.fromLTWH(30, 150, 100, 50),
      explanation: const Rect.fromLTWH(10, 500, 380, 250),
    );
    final previous = GuidePointerPainter(
      pose: pose,
      target: const Rect.fromLTWH(30, 150, 100, 50),
      progress: 0,
      accent: Colors.green,
    );
    final next = GuidePointerPainter(
      pose: pose,
      target: const Rect.fromLTWH(240, 150, 100, 50),
      progress: 0.5,
      accent: Colors.green,
    );
    expect(next.shouldRepaint(previous), isTrue);
  });

  testWidgets('la guía presenta la mascota y se mueve al segundo objetivo',
      (tester) async {
    final first = GlobalKey();
    final second = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Column(children: [
        SizedBox(key: first, width: 100, height: 56,
          child: const Text('Primer objetivo')),
        const SizedBox(height: 240),
        SizedBox(key: second, width: 100, height: 56,
          child: const Text('Segundo objetivo')),
      ])),
    ));
    final context = tester.element(find.byType(Scaffold));
    final done = HealthyGuideOverlay.show(context, steps: [
      HealthySpotlightStep(title: 'Paso uno', description: 'Primero.',
        icon: Icons.flag, targetKey: first),
      HealthySpotlightStep(title: 'Paso dos', description: 'Segundo.',
        icon: Icons.help, targetKey: second),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    expect(find.byType(AssistantGuideCharacter), findsOneWidget);
    expect(find.text('Paso uno'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('Paso dos'), findsOneWidget);
    expect(find.byType(AssistantGuideCharacter), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar guía'));
    await tester.pump();
    await done;
    expect(find.byType(AssistantGuideCharacter), findsNothing);
  });

  testWidgets('con movimiento reducido la mascota no se anima',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: SizedBox(
          key: key, height: 90,
          child: const Text('Sin animaciones'),
        )),
      ),
    ));
    final context = tester.element(find.byType(Scaffold));
    final done = HealthyGuideOverlay.show(context, steps: [
      HealthySpotlightStep(title: 'Accesible',
        description: 'Respeta reducir movimiento.',
        icon: Icons.accessibility, targetKey: key),
    ]);
    await tester.pump();
    expect(find.byType(AssistantGuideCharacter), findsOneWidget);
    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    await done;
  });
}
