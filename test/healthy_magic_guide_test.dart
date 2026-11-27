import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_magic_guide.dart';

void main() {
  test('todas las secciones del tutorial tienen pasos con contenido', () {
    for (final entry in HealthyMagicGuide.sections.entries) {
      expect(entry.value, isNotEmpty, reason: entry.key);
      for (final step in entry.value) {
        expect(step.title.trim(), isNotEmpty);
        expect(step.description.trim(), isNotEmpty);
      }
    }
  });

  testWidgets('el botón mágico avanza, retrocede y cierra el tutorial',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        floatingActionButton: HealthyMagicGuideButton(section: 'tienda'),
        body: Center(child: Text('Tienda')),
      ),
    ));
    // El OverlayPortal del OVNI se activa después del primer fotograma.
    await tester.pump();
    expect(find.byTooltip('Explícame esta pantalla'), findsOneWidget);
    await tester.tap(find.byTooltip('Explícame esta pantalla'));
    // La animación de flotación es infinita: evitar pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // La tienda usa el recorrido spotlight, no el bottom sheet antiguo.
    expect(find.text('MR. HEALTHY · TIENDA'), findsOneWidget);
    expect(find.text('Saldo y tienda'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    // La animación de flotación es infinita: evitar pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Filtra los artículos'), findsOneWidget);
    await tester.tap(find.text('Anterior'));
    // La animación de flotación es infinita: evitar pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Saldo y tienda'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar guía'));
    // La animación de flotación es infinita: evitar pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('MR. HEALTHY · TIENDA'), findsNothing);
  });
}
