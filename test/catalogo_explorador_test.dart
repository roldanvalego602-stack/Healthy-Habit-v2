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
      items: ejerciciosCatalogo, etiqueta: 'Piernas').single.id,
      'sentadillas');
    expect(CatalogoExplorador.filtrar(
      items: consejosCatalogo, etiqueta: 'Sueño').single.id,
      'dormir_mejor');
  });

  test('prioriza proteína por cantidades registradas, no por etiquetas', () {
    final result = CatalogoExplorador.filtrar(
      items: alimentosCatalogo, orden: OrdenCatalogo.proteina);
    expect(result.map((e) => e.id).toList(),
      ['avena', 'huevo', 'lentejas']);
  });

  test('prioriza grasas en orden numérico descendente', () {
    final result = CatalogoExplorador.filtrar(
      items: alimentosCatalogo, orden: OrdenCatalogo.grasas);
    expect(result.map((e) => e.id).toList(),
      ['huevo', 'avena', 'lentejas']);
  });

  test('la fibra faltante no se inventa y queda al final', () {
    final result = CatalogoExplorador.filtrar(
      items: alimentosCatalogo, orden: OrdenCatalogo.fibra);
    expect(result.map((e) => e.id).toList(),
      ['avena', 'lentejas', 'huevo']);
    expect(CatalogoExplorador.nutriente(result.last, 'Fibra'), isNull);
  });

  test('las agrupaciones usan solo metadatos existentes', () {
    expect(CatalogoExplorador.grupoAlimento(alimentosCatalogo.first),
      'Cereales integrales');
    expect(CatalogoExplorador.grupoExploracion(ejerciciosCatalogo.first),
      'Piernas y glúteos');
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
}
