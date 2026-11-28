import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/beta_evidence_service.dart';
import 'package:healthy_habit/servicios/beta_evidence_vision_service.dart';
import 'package:healthy_habit/servicios/beta_habit_gateway.dart';
import 'package:healthy_habit/servicios/habit_evidence_image_preparer.dart';
import 'package:image/image.dart' as img;

void main() {
  test('el servicio de fotos y Vision están apagados por defecto', () {
    expect(BetaHabitGateway.enabled, isFalse);
    expect(BetaEvidenceService.enabled, isFalse);
    expect(BetaEvidenceVisionService.enabled, isFalse);
  });

  test('sin flags, una foto no llega a Firebase', () async {
    const service = BetaEvidenceService();
    await expectLater(
      service.reserve(
        habitId: 'alim_001',
        attemptId: 'intento_prueba_123456789',
        operationId: 'operacion_prueba_123456789',
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      service.status(
        habitId: 'alim_001',
        attemptId: 'intento_prueba_123456789',
        operationId: 'operacion_prueba_123456789',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('las fotos se recodifican como JPEG privado sin datos EXIF', () {
    final source = img.Image(width: 80, height: 80);
    img.fill(source, color: img.ColorRgb8(132, 192, 97));
    final bytes = Uint8List.fromList(img.encodePng(source));
    final prepared = const HabitEvidenceImagePreparer().prepare(bytes);
    expect(prepared.bytes.lengthInBytes, lessThanOrEqualTo(250 * 1024));
    expect(prepared.bytes.sublist(0, 3), [0xff, 0xd8, 0xff]);
    expect(prepared.bytes.sublist(prepared.bytes.length - 2), [0xff, 0xd9]);
    expect(prepared.width, 80);
    expect(prepared.height, 80);
  });

  test('no se exige una imagen o consentimiento para los registros normales', () {
    expect(BetaEvidenceVisionService.enabled, isFalse);
    expect(BetaEvidenceService.maxBytes, 250 * 1024);
    expect(const EvidencePhotoRequired().toString(),
      contains('fotografía original'));
  });
}
