import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/catalogo/catalogo_comparacion.dart';
import 'package:healthy_habit/páginas/catalogo/datos/catalogo_datos.dart';

void main() {
  testWidgets('comparación de alimentos distingue cifras y datos ausentes',
      (tester) async {
    final avena = alimentosCatalogo.firstWhere((i) => i.id == 'avena');
    final manzana = alimentosCatalogo.firstWhere((i) => i.id == 'manzana');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CatalogoComparacion(
          items: [avena, manzana],
          onAbrir: (_) {},
          onQuitar: (_) {},
          onLimpiar: () {},
        ),
      ),
    ));
    expect(find.text('Comparar elementos'), findsOneWidget);
    expect(find.text('16.9 g'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(find.text('Sin dato'), findsWidgets);
  });

  testWidgets('las acciones de comparación notifican la ficha elegida',
      (tester) async {
    final sentadillas = ejerciciosCatalogo.firstWhere(
        (i) => i.id == 'sentadillas');
    final flexiones = ejerciciosCatalogo.firstWhere(
        (i) => i.id == 'flexiones_pared');
    String? opened;
    String? removed;
    var cleared = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CatalogoComparacion(
          items: [sentadillas, flexiones],
          onAbrir: (item) => opened = item.id,
          onQuitar: (item) => removed = item.id,
          onLimpiar: () => cleared = true,
        ),
      ),
    ));
    // Las acciones permanecen en el pie de la tarjeta: no hace falta
    // recorrer su lista interna para interactuar con ellas.
    expect(find.text('Ver ficha'), findsNWidgets(2));
    expect(find.text('Quitar'), findsNWidgets(2));
    await tester.tap(find.text('Ver ficha').first);
    expect(opened, 'sentadillas');
    await tester.tap(find.text('Quitar').first);
    expect(removed, 'sentadillas');
    await tester.tap(find.text('Limpiar'));
    expect(cleared, isTrue);
  });

  testWidgets('no intenta comparar valores clínicos en ejercicios',
      (tester) async {
    final sentadillas = ejerciciosCatalogo.firstWhere(
        (i) => i.id == 'sentadillas');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CatalogoComparacion(
          items: [sentadillas],
          onAbrir: (_) {},
          onQuitar: (_) {},
          onLimpiar: () {},
        ),
      ),
    ));
    expect(find.text('Grupo muscular'), findsOneWidget);
    expect(find.text('Piernas y glúteos'), findsOneWidget);
    expect(find.text('Proteína'), findsNothing);
  });
}
