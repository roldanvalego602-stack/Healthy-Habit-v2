import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:healthy_habit/servicios/profile_photo_service.dart';
import 'package:healthy_habit/páginas/perfil/profile_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rechaza archivos vacíos y formatos ilegibles', () {
    expect(
      () => ProfilePhotoService.prepareJpeg(Uint8List(0)),
      throwsA(isA<ProfilePhotoException>()),
    );
    expect(
      () => ProfilePhotoService.prepareJpeg(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<ProfilePhotoException>()),
    );
  });

  test('convierte imagen PNG a JPEG y reduce dimensiones grandes', () {
    final original = img.Image(width: 1600, height: 1100);
    img.fill(original, color: img.ColorRgb8(20, 140, 90));
    final png = Uint8List.fromList(img.encodePng(original));
    final jpeg = ProfilePhotoService.prepareJpeg(png);
    expect(jpeg[0], 0xFF);
    expect(jpeg[1], 0xD8);
    final prepared = img.decodeJpg(jpeg);
    expect(prepared, isNotNull);
    expect(prepared!.width, lessThanOrEqualTo(1024));
    expect(prepared.height, lessThanOrEqualTo(1024));
  });

  test('rechaza fotos pequeñas que no pueden usarse como avatar', () {
    final tiny = img.Image(width: 12, height: 12);
    final bytes = Uint8List.fromList(img.encodePng(tiny));
    expect(
      () => ProfilePhotoService.prepareJpeg(bytes),
      throwsA(isA<ProfilePhotoException>()),
    );
  });

  test('explica códigos de Firebase en lugar de un error genérico', () {
    final cases = <String, String>{
      'unauthorized': 'permiso',
      'bucket-not-found': 'bucket',
      'quota-exceeded': 'límite',
      'unauthenticated': 'sesión',
    };
    for (final entry in cases.entries) {
      final error = ProfilePhotoService.explainFirebaseError(
        FirebaseException(plugin: 'firebase_storage', code: entry.key),
        stage: 'subida a Storage',
      );
      expect(error.message.toLowerCase(),
          contains(entry.value), reason: entry.key);
      expect(error.code, entry.key);
    }
  });

  test('identifica fallas de red al subir la fotografía', () {
    final issue = ProfilePhotoService.explainFirebaseError(
      FirebaseException(
        plugin: 'firebase_storage', code: 'retry-limit-exceeded',
      ),
      stage: 'subida a Storage',
    );
    expect(issue.code, 'retry-limit-exceeded');
    expect(issue.message.toLowerCase(), contains('conexión'));
  });

  testWidgets('sin foto muestra un icono de respaldo',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HealthyProfileAvatar(photoUrl: '', size: 88),
        ),
      ),
    );
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('URL malformada no bloquea la pantalla',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HealthyProfileAvatar(photoUrl: 'archivo-local.jpg'),
        ),
      ),
    );
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
