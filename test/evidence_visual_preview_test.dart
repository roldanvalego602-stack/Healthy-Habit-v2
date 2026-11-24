import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/evidence_demo_service.dart';

void main() {
  test('permite mostrar coincidencia visual sin declarar verificación', () {
    final result = DemoVisualPreview.fromMap({
      'status': 'visual_match_only',
      'message': 'Coincidencia orientativa',
      'labels': [
        {'name': 'Water bottle', 'score': 0.91},
      ],
      'imageVerified': false,
      'xpAwarded': 0,
      'coinsAwarded': 0,
    });
    expect(result.labels.single.name, 'Water bottle');
    expect(result.labels.single.confidence, 0.91);
  });

  test('rechaza cualquier respuesta que pretenda conceder XP', () {
    for (final xp in [1, 15, 20]) {
      expect(() => DemoVisualPreview.fromMap({
        'status': 'visual_match_only',
        'message': 'No importa',
        'labels': [],
        'imageVerified': false,
        'xpAwarded': xp,
        'coinsAwarded': 0,
      }), throwsFormatException);
    }
  });

  test('rechaza respuesta marcada como verificada', () {
    expect(() => DemoVisualPreview.fromMap({
      'status': 'visual_match_only',
      'message': 'No importa',
      'labels': [],
      'imageVerified': true,
      'xpAwarded': 0,
      'coinsAwarded': 0,
    }), throwsFormatException);
  });

  test('servicio rechaza imágenes demasiado grandes sin llamar al servidor',
      () async {
    var called = false;
    final service = EvidenceDemoService(call: (_, __) async {
      called = true;
      return {};
    });
    await expectLater(
      service.previewPhoto(Uint8List(250 * 1024 + 1), 'hydration'),
      throwsFormatException,
    );
    expect(called, isFalse);
  });
}
