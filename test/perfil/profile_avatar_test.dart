import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/páginas/perfil/profile_avatar.dart';

void main() {
  testWidgets('avatar naturaleza se muestra sin foto ni Storage', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyProfileAvatar(
        photoUrl: null,
        preset: 'naturaleza',
      )),
    ));
    expect(find.byIcon(Icons.spa_rounded), findsOneWidget);
  });

  testWidgets('avatar hidratación utiliza su propio icono', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyProfileAvatar(
        photoUrl: '',
        preset: 'agua',
      )),
    ));
    expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
  });

  testWidgets('un identificador desconocido usa avatar clásico', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyProfileAvatar(
        photoUrl: '',
        preset: 'avatar-no-disponible',
      )),
    ));
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });
}
