import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Prepara fotografías para el laboratorio de evidencias oficiales.
///
/// Devuelve JPEG re-encodificado, sin reutilizar metadatos EXIF de origen.
/// No se conecta al formulario ni verifica que una fotografía pruebe un hábito.
class PreparedHabitEvidence {
  const PreparedHabitEvidence({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

class HabitEvidenceImagePreparer {
  const HabitEvidenceImagePreparer();

  static const int maxBytes = 250 * 1024;
  static const int maxInputBytes = 12 * 1024 * 1024;
  static const int maxDimension = 1600;

  PreparedHabitEvidence prepare(Uint8List source) {
    if (source.isEmpty || source.lengthInBytes > maxInputBytes) {
      throw const FormatException(
        'La imagen original debe medir entre 1 B y 12 MB.',
      );
    }
    final decoded = img.decodeImage(source);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      throw const FormatException('No se pudo interpretar la fotografía.');
    }
    var image = img.bakeOrientation(decoded);
    // Reducir dimensiones antes de variar la calidad de compresión.
    for (final longest in <int>[1600, 1280, 1024, 800, 640, 480, 320]) {
      final side = image.width > image.height ? image.width : image.height;
      final target = longest < maxDimension ? longest : maxDimension;
      final resized = side > target
          ? img.copyResize(
              image,
              width: image.width >= image.height ? target : null,
              height: image.height > image.width ? target : null,
            )
          : image;
      for (final quality in <int>[82, 72, 62, 50, 38]) {
        final bytes = Uint8List.fromList(img.encodeJpg(
          resized,
          quality: quality,
        ));
        if (bytes.lengthInBytes <= maxBytes) {
          return PreparedHabitEvidence(
            bytes: bytes,
            width: resized.width,
            height: resized.height,
          );
        }
      }
      image = resized;
    }
    throw const FormatException(
      'No fue posible comprimir la imagen a 250 KB.',
    );
  }
}
