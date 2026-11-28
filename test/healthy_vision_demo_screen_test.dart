import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/healthy_vision_demo_screen.dart';
import 'package:healthy_habit/servicios/healthy_vision_debug_service.dart';

void main() {
  testWidgets('laboratorio visible sin flags del piloto Cloud',
      (tester) async {
    expect(HealthyVisionDebugService.enabled, isFalse);
    await tester.pumpWidget(const MaterialApp(
      home: HealthyVisionDemoScreen(),
    ));
    expect(find.text('Análisis de imágenes'), findsOneWidget);
    expect(find.byKey(const ValueKey('vision-demo-camera')), findsOneWidget);
    expect(find.byKey(const ValueKey('vision-demo-gallery')), findsOneWidget);
    expect(find.text('Esta demostración solo está disponible en modo debug.'),
        findsNothing);
  });
}
