import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:healthy_habit/páginas/catalogo/catalogo_explorador.dart';
import 'package:healthy_habit/páginas/catalogo/catalogo_selector_bienestar.dart';
import 'package:healthy_habit/páginas/catalogo/datos/bebidas_catalogo.dart';
import 'package:healthy_habit/páginas/catalogo/detalles/catalogo_resumen.dart';
import 'package:healthy_habit/páginas/catalogo/datos/catalogo_datos.dart';

void main() {
  test('las bebidas tienen grupos de jarra y no macros inventadas', () {
    expect(bebidasCatalogo.length, 7);
    expect(
      CatalogoExplorador.grupoExploracion(
        bebidasCatalogo.firstWhere((e) => e.id == 'agua_natural')),
      'Agua simple',
    );
    final ids = bebidasCatalogo.map((e) => e.id).toSet();
    expect(ids.length, bebidasCatalogo.length);
    for (final bebida in bebidasCatalogo) {
      expect(bebida.detalles['Grupo de bebida'], isNotNull);
      expect(CatalogoExplorador.nutriente(bebida, 'Proteína'), isNull);
    }
  });

  testWidgets('tocar la jarra selecciona y deselecciona un grupo', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: StatefulBuilder(builder: (context, update) {
        return JarraBuenBeberCatalogo(
          seleccionado: selected,
          onSeleccionar: (value) => update(() => selected = value),
        );
      }),
    )));
    await tester.tap(find.byKey(const ValueKey('jarra-Agua simple')));
    await tester.pump();
    expect(selected, 'Agua simple');
    await tester.tap(find.byKey(const ValueKey('jarra-Agua simple')));
    await tester.pump();
    expect(selected, isNull);
  });

  testWidgets('el explorador de bienestar permite elegir objetivo',
      (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: StatefulBuilder(builder: (context, update) =>
        SelectorBienestarCatalogo(
          seleccionado: selected,
          onSeleccionar: (value) => update(() => selected = value),
        ),
      ),
    )));
    await tester.tap(find.byKey(
      const ValueKey('wellness-Sueño y recuperación')));
    await tester.pump();
    expect(selected, 'Sueño y recuperación');
  });

  testWidgets('el resumen muestra solo información de la ficha',
      (tester) async {
    final item = alimentosCatalogo.firstWhere((i) => i.id == 'avena');
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(height: 620,
        child: ResumenFichaCatalogo(item: item)),
    )));
    expect(find.textContaining('Cereal integral'), findsOneWidget);
    await tester.tap(find.text('Datos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('16.9 g'), findsOneWidget);
  });
}
