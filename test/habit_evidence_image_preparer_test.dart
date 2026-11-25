import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/habit_evidence_image_preparer.dart';
import 'package:image/image.dart' as img;

void main() {
  const preparer = HabitEvidenceImagePreparer();

  test('prepara un JPEG bajo 250 KB con dimensiones limitadas', () {
    final source = img.Image(width: 1800, height: 1200);
    img.fill(source, color: img.ColorRgb8(60, 170, 90));
    final original = Uint8List.fromList(img.encodePng(source));
    final result = preparer.prepare(original);

    expect(result.bytes.lengthInBytes,
        lessThanOrEqualTo(HabitEvidenceImagePreparer.maxBytes));
    expect(result.width, lessThanOrEqualTo(1600));
    expect(result.height, lessThanOrEqualTo(1600));
    expect(result.bytes[0], 0xff);
    expect(result.bytes[1], 0xd8);
    final decoded = img.decodeJpg(result.bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, result.width);
    expect(decoded.height, result.height);
  });

  test('rechaza contenido que no es una fotografía', () {
    expect(
      () => preparer.prepare(Uint8List.fromList([1, 2, 3, 4])),
      throwsFormatException,
    );
  });

  test('rechaza archivo original demasiado grande antes de decodificar', () {
    expect(
      () => preparer.prepare(Uint8List(
          HabitEvidenceImagePreparer.maxInputBytes + 1)),
      throwsFormatException,
    );
  });
}
