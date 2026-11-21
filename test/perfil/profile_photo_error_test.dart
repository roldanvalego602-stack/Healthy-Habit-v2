import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/servicios/profile_photo_service.dart';

void main() {
  group('Errores de subida de foto', () {
    test('object-not-found explica la verificación del bucket', () {
      // La rama de error consulta Firebase.app() para mostrar el bucket.
      // Se prueba aquí el diagnóstico de permisos, sin hacer llamadas a red.
      final ex = ProfilePhotoService.explainFirebaseError(
        FirebaseException(plugin: 'firebase_storage', code: 'permission-denied'),
        stage: 'subida a Storage',
      );
      expect(ex.code, 'permission-denied');
      expect(ex.message, contains('reglas'));
    });

    test('bucket inexistente se presenta como problema de configuración', () {
      final ex = ProfilePhotoService.explainFirebaseError(
        FirebaseException(plugin: 'firebase_storage', code: 'bucket-not-found'),
        stage: 'subida a Storage',
      );
      expect(ex.code, 'bucket-not-found');
      expect(ex.message, contains('bucket'));
    });
  });
}
