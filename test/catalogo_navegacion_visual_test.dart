import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/catalogo/catalogo_screen.dart';

void main() {
  testWidgets('al seleccionar el plato se oculta todo el encabezado '
      'y se presenta la primera ficha', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CatalogoScreen()));
    await tester.tap(find.byIcon(Icons.hub));
    await tester.pumpAndSettle();

    expect(find.text('Explora por grupos del plato'), findsOneWidget);
    expect(find.text('Toca una sección del plato'), findsOneWidget);

    await tester.tap(find.text('Cereales').first);
    await tester.pumpAndSettle();

    expect(find.text('Explora por grupos del plato'), findsNothing);
    expect(find.text('Toca una sección del plato'), findsNothing);
    expect(find.byKey(const ValueKey('explorar-regresar')), findsOneWidget);
    expect(find.byKey(const ValueKey('explorar-item-avena')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('explorar-regresar')));
    await tester.pumpAndSettle();
    expect(find.text('Explora por grupos del plato'), findsOneWidget);
  });
}
