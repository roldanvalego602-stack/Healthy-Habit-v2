import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/catalogo/catalogo_explorador.dart';
import 'package:healthy_habit/páginas/catalogo/datos/catalogo_datos.dart';

void main() {
  test('busca sin acentos y combina palabras', () {
    final result = CatalogoExplorador.filtrar(
      items: alimentosCatalogo, consulta: 'proteina vegetal');
    expect(result.map((e) => e.id), contains('lentejas'));
  });

  test('filtra etiquetas de ejercicio y de descanso', () {
    expect(CatalogoExplorador.filtrar(
      items: ejerciciosCatalogo, etiqueta: 'Piernas')
        .map((item) => item.id), contains('sentadillas'));
    expect(CatalogoExplorador.filtrar(
      items: consejosCatalogo, etiqueta: 'Sueño')
        .map((item) => item.id), contains('dormir_mejor'));
  });

  test('prioriza proteína por cantidades registradas, no por etiquetas', () {
    final result = CatalogoExplorador.filtrar(
      items: alimentosCatalogo, orden: OrdenCatalogo.proteina);
    expect(result.take(3).map((e) => e.id).toList(),
      ['avena', 'huevo', 'lentejas']);
    expect(result.length, 12);
  });

  test('prioriza grasas en orden numérico descendente', () {
    final result = CatalogoExplorador.filtrar(
      items: alimentosCatalogo, orden: OrdenCatalogo.grasas);
    expect(result.take(3).map((e) => e.id).toList(),
      ['huevo', 'avena', 'lentejas']);
  });

  test('la fibra faltante no se inventa y queda al final', () {
    final result = CatalogoExplorador.filtrar(
      items: alimentosCatalogo, orden: OrdenCatalogo.fibra);
    expect(result.take(2).map((e) => e.id).toList(),
      ['avena', 'lentejas']);
    expect(CatalogoExplorador.nutriente(result.last, 'Fibra'), isNull);
  });

  test('las agrupaciones usan solo metadatos existentes', () {
    expect(CatalogoExplorador.grupoAlimento(alimentosCatalogo.first),
      'Cereales integrales');
    expect(CatalogoExplorador.grupoExploracion(ejerciciosCatalogo.first),
      'Tren inferior');
    expect(CatalogoExplorador.grupoExploracion(consejosCatalogo.first),
      'Sueño y recuperación');
  });

  test('filtrado por etiqueta y búsqueda no produce falsos positivos', () {
    final result = CatalogoExplorador.filtrar(
      items: alimentosCatalogo,
      etiqueta: 'Proteína',
      consulta: 'inexistente');
    expect(result, isEmpty);
  });

  test('todas las vistas se mantienen disponibles', () {
    expect(VistaCatalogo.values.length, 4);
    expect(CatalogoExplorador.filtros(ejerciciosCatalogo).first, 'Todos');
  });
  test('el catálogo ampliado cubre grupos del plato y ejercicio', () {
    expect(alimentosCatalogo.length, 12);
    expect(ejerciciosCatalogo.length, 10);
    expect(consejosCatalogo.length, 6);
    final groups = alimentosCatalogo
        .map(CatalogoExplorador.grupoPlato).toSet();
    expect(groups, containsAll([
      'Frutas y verduras', 'Cereales',
      'Leguminosas y origen animal',
    ]));
    final zonas = ejerciciosCatalogo
        .map(CatalogoExplorador.zonaEjercicio).toSet();
    expect(zonas, containsAll([
      'Tren superior', 'Tren inferior', 'Zona media', 'Flexibilidad',
    ]));
  });

  test('filtra brazos, flexibilidad y recuperación con contenido real', () {
    expect(CatalogoExplorador.filtrar(
      items: ejerciciosCatalogo, etiqueta: 'Brazos')
      .map((item) => item.id), contains('flexiones_pared'));
    expect(CatalogoExplorador.filtrar(
      items: ejerciciosCatalogo, etiqueta: 'Flexibilidad')
      .map((item) => item.id), contains('movilidad_cadera'));
    expect(CatalogoExplorador.filtrar(
      items: consejosCatalogo, etiqueta: 'Recuperación')
      .map((item) => item.id), contains('recuperacion_actividad'));
  });

  test('ningún alimento nuevo inventa macros medidos', () {
    for (final item in alimentosCatalogo.skip(3)) {
      expect(CatalogoExplorador.nutriente(item, 'Proteína'), isNull);
      expect(CatalogoExplorador.nutriente(item, 'Grasas'), isNull);
    }
  });

  test('identificadores únicos y metadatos de fuente en todas las fichas', () {
    final catalog = [
      ...alimentosCatalogo, ...ejerciciosCatalogo, ...consejosCatalogo,
    ];
    expect(catalog.map((item) => item.id).toSet().length, catalog.length);
    for (final item in catalog) {
      expect(item.titulo.trim(), isNotEmpty);
      expect(item.fuenteUrl.startsWith('https://'), isTrue);
      expect(item.precauciones, isNotEmpty);
      expect(item.pasos, isNotEmpty);
    }
  });

}
