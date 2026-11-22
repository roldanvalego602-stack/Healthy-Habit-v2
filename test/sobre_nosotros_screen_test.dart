import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/sesion/sobre_nosotros_screen.dart';

void main() {
  testWidgets('Sobre nosotros muestra contenido institucional y su identidad', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SobreNosotrosScreen()));
    expect(find.text('Sobre nosotros'), findsOneWidget);
    expect(find.text('¿Por qué nació Healthy Habit?'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Constancia y progreso visible'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Constancia y progreso visible'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Nuestra identidad'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nuestra identidad'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Creación de nuestro logo'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Creación de nuestro logo'), findsOneWidget);
  });

  testWidgets('No publica correos y teléfonos ficticios', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SobreNosotrosScreen()));
    await tester.scrollUntilVisible(
      find.text('Los canales oficiales de contacto aún no están configurados.'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('correo@ejemplo.com'), findsNothing);
    expect(find.text('+52 000 000 0000'), findsNothing);
  });
}
