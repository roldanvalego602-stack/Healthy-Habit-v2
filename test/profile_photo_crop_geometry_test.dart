import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/perfil/profile_photo_crop_geometry.dart';

void main() {
  test('imagen horizontal: recorte cuadrado centrado', () {
    final rect = ProfilePhotoCropGeometry.sourceRect(
      imageWidth: 1000, imageHeight: 500,
      viewport: 300, zoom: 1, offset: Offset.zero,
    );
    expect(rect, const Rect.fromLTWH(250, 0, 500, 500));
  });

  test('imagen vertical: recorte cuadrado centrado', () {
    final rect = ProfilePhotoCropGeometry.sourceRect(
      imageWidth: 500, imageHeight: 1000,
      viewport: 300, zoom: 1, offset: Offset.zero,
    );
    expect(rect, const Rect.fromLTWH(0, 250, 500, 500));
  });

  test('zoom crea un recorte más pequeño, cuadrado y dentro de la foto', () {
    final rect = ProfilePhotoCropGeometry.sourceRect(
      imageWidth: 1200, imageHeight: 800,
      viewport: 300, zoom: 2.5, offset: const Offset(90, -80),
    );
    expect(rect.width, rect.height);
    expect(rect.width, lessThan(800));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(1200));
    expect(rect.bottom, lessThanOrEqualTo(800));
  });

  test('arrastre extremo permanece dentro de los bordes', () {
    for (final offset in [
      const Offset(-10000, -10000),
      const Offset(10000, 10000),
    ]) {
      final rect = ProfilePhotoCropGeometry.sourceRect(
        imageWidth: 400, imageHeight: 900,
        viewport: 300, zoom: 4, offset: offset,
      );
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(400));
      expect(rect.bottom, lessThanOrEqualTo(900));
    }
  });

  test('rechaza dimensiones y escala inválidas', () {
    expect(() => ProfilePhotoCropGeometry.sourceRect(
      imageWidth: 0, imageHeight: 200,
      viewport: 300, zoom: 1, offset: Offset.zero,
    ), throwsArgumentError);
    expect(() => ProfilePhotoCropGeometry.sourceRect(
      imageWidth: 300, imageHeight: 300,
      viewport: 300, zoom: 0, offset: Offset.zero,
    ), throwsArgumentError);
  });
}
