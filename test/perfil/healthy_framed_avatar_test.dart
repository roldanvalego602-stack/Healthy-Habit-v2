import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/perfil/healthy_framed_avatar.dart';

void main() {
  testWidgets('marco rodea al avatar con espacio exterior reservado',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: HealthyFramedAvatar(
            size: 94,
            photoUrl: null,
            preset: 'naturaleza',
            frameAsset:
                'assets/cosmeticos/perfil/marcos/'
                'Marco circular esmeralda con emblema de hojas.png',
          ),
        ),
      ),
    ));

    expect(tester.getSize(find.byKey(
        const Key('healthy-framed-avatar'))), const Size(116, 116));
    expect(find.byType(ClipOval), findsWidgets);
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin marco conserva el diámetro del avatar', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: HealthyFramedAvatar(
          size: 88,
          photoUrl: null,
          preset: 'naturaleza',
        )),
      ),
    ));
    expect(tester.getSize(find.byKey(
        const Key('healthy-framed-avatar'))), const Size(88, 88));
    expect(tester.takeException(), isNull);
  });

  testWidgets('el armario puede usar otro tamaño sin deformar la foto',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: HealthyFramedAvatar(
          size: 60,
          frameOverflow: 9,
          photoUrl: null,
          preset: 'naturaleza',
          frameAsset:
              'assets/cosmeticos/perfil/marcos/'
              'Marco de Perfil Cian Futurista.png',
        )),
      ),
    ));
    expect(tester.getSize(find.byKey(
        const Key('healthy-framed-avatar'))), const Size(78, 78));
    expect(tester.takeException(), isNull);
  });
}
