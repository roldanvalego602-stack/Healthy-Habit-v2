import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Clasificación REAL de la fotografía con ML Kit, ejecutada en Android.
/// No usa Firebase, no sube la imagen ni altera el progreso del usuario.
class HealthyLocalImageRecognition {
  const HealthyLocalImageRecognition();

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<List<HealthyDetectedLabel>> analyze(Uint8List jpeg) async {
    if (!supported) {
      throw UnsupportedError(
        'El reconocimiento local está disponible en Android.');
    }
    if (jpeg.isEmpty) throw const FormatException('La imagen está vacía.');

    final directory = await Directory.systemTemp.createTemp('healthy_vision_');
    final file = File('${directory.path}/fotografia.jpg');
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.3),
    );
    try {
      await file.writeAsBytes(jpeg, flush: true);
      final labels = await labeler.processImage(
        InputImage.fromFilePath(file.path),
      );
      final ordered = labels.map((label) => HealthyDetectedLabel(
        label.label,
        label.confidence,
      )).toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      return ordered.take(12).toList(growable: false);
    } finally {
      await labeler.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }
}

class HealthyDetectedLabel {
  const HealthyDetectedLabel(this.name, this.confidence);

  final String name;
  final double confidence;
}
