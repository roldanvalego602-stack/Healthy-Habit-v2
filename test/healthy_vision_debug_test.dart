import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/healthy_vision_preview_panel.dart';
import 'package:healthy_habit/servicios/healthy_vision_debug_service.dart';

void main() {
  test('el laboratorio exige un host local permitido', () {
    expect(HealthyVisionDebugService.validateHost('127.0.0.1'),
        '127.0.0.1');
    expect(HealthyVisionDebugService.validateHost('10.0.2.2'), '10.0.2.2');
    expect(
      () => HealthyVisionDebugService.validateHost('api.example.com'),
      throwsStateError,
    );
    expect(
      () => HealthyVisionDebugService.validateHost('192.168.1.8'),
      throwsStateError,
    );
  });

  testWidgets('el análisis no aparece sin bandera experimental', (tester) async {
    // La ejecución normal de flutter test no incluye HH_VISION_DEBUG.
    expect(HealthyVisionDebugService.enabled, isFalse);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HealthyVisionPreviewPanel(
          image: Uint8List.fromList([1, 2, 3]),
          category: 'Hidratación',
          habitTitle: 'Tomar agua',
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('healthy-vision-debug-panel')),
        findsNothing);
    expect(find.byKey(const ValueKey('healthy-vision-analyze')),
        findsNothing);
  });
}
