import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/catalogo/detalles/catalogo_detalle_interactivo.dart';
import 'package:healthy_habit/páginas/catalogo/datos/catalogo_datos.dart';

void main() {
  testWidgets('alimentos con datos muestran sus gramos existentes', (tester) async {
    final item = alimentosCatalogo.firstWhere((e) => e.id == 'avena');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: ResumenNutricionalCatalogo(item: item),
      )),
    ));
    expect(find.text('16.9 g'), findsOneWidget);
    expect(find.text('6.9 g'), findsOneWidget);
    expect(find.textContaining('100 g de avena seca'), findsOneWidget);
  });

  testWidgets('los alimentos sin macros no muestran números inventados',
      (tester) async {
    final item = alimentosCatalogo.firstWhere((e) => e.id == 'manzana');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ResumenNutricionalCatalogo(item: item)),
    ));
    expect(find.textContaining('no tiene valores nutricionales'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('la guía de ejercicio avanza, retrocede y puede reiniciarse',
      (tester) async {
    final item = ejerciciosCatalogo.firstWhere(
      (e) => e.id == 'flexiones_pared');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GuiaPasosCatalogo(item: item)),
    ));
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    // TextButton.icon puede crear una subclase de TextButton: byType
    // exige coincidencia exacta y no la encuentra. Verificamos por tipo.
    final anterior = find.byWidgetPredicate(
      (widget) => widget is TextButton &&
          widget.onPressed == null,
      description: 'botón Anterior deshabilitado al inicio',
    );
    expect(anterior, findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 3'), findsOneWidget);
    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 3'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 3 de 3'), findsOneWidget);
    await tester.tap(find.text('Repetir'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 3'), findsOneWidget);
  });

  testWidgets('el recorrido educativo no muestra recompensas XP',
      (tester) async {
    final item = ejerciciosCatalogo.firstWhere(
      (e) => e.id == 'sentadillas');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GuiaPasosCatalogo(item: item)),
    ));
    expect(find.textContaining('no concede XP'), findsOneWidget);
  });
}
