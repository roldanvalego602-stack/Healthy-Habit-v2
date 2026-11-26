import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/healthy_vision_demo_screen.dart';
import 'package:healthy_habit/servicios/healthy_vision_debug_service.dart';

void main() {
  testWidgets('el laboratorio no se expone en una compilación normal',
      (tester) async {
    expect(HealthyVisionDebugService.enabled, isFalse);
    await tester.pumpWidget(const MaterialApp(
      home: HealthyVisionDemoScreen(),
    ));
    expect(find.text('Esta demostración solo está disponible en modo debug.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('vision-demo-camera')), findsNothing);
    expect(find.byKey(const ValueKey('vision-demo-gallery')), findsNothing);
  });
}
