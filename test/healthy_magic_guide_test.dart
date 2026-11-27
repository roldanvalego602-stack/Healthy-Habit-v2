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
    await tester.tap(find.byTooltip('Explícame esta pantalla'));
    await tester.pumpAndSettle();
    expect(find.text('Guía mágica · Tienda'), findsOneWidget);
    expect(find.text('Tus Habit Coins'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Artículos y categorías'), findsOneWidget);
    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Tus Habit Coins'), findsOneWidget);
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.text('Guía mágica · Tienda'), findsNothing);
  });
}
