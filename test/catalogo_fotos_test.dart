import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/catalogo/datos/catalogo_datos.dart';
import 'package:healthy_habit/páginas/catalogo/modelos/catalogo_item.dart';

void main() {
  final all = <CatalogoItem>[
    ...alimentosCatalogo,
    ...ejerciciosCatalogo,
    ...consejosCatalogo,
  ];

  const photos = <String, String>{
    'avena': 'avena.jpg',
    'huevo': 'huevo.jpg',
    'lentejas': 'lentejas.jpg',
    'sentadillas': 'sentadillas.jpg',
    'plancha': 'plancha.jpg',
    'caminar': 'caminar.jpg',
    'dormir_mejor': 'dormir_mejor.jpg',
    'prevenir_caidas': 'prevenir_caidas.jpg',
    'pausas_activas': 'pausas_activas.jpg',
  };

  test('cada fotografía del ZIP pertenece a la ficha correcta', () {
    expect(all.length, 28);
    expect(all.where((item) => item.imagen.isNotEmpty), hasLength(9));
    for (final entry in photos.entries) {
      final items = all.where((item) => item.id == entry.key).toList();
      expect(items, hasLength(1), reason: entry.key);
      expect(items.first.imagen,
          'assets/images/catalogo/${entry.value}');
    }
  });

  test('el catálogo conserva las fichas y categorías existentes', () {
    expect(alimentosCatalogo.length, 12);
    expect(ejerciciosCatalogo.length, 10);
    expect(consejosCatalogo.length, 6);
    expect(all.every((item) =>
        item.titulo.isNotEmpty &&
        item.descripcion.isNotEmpty &&
        (item.imagen.isEmpty || item.imagen.endsWith('.jpg'))), isTrue);
  });
}
