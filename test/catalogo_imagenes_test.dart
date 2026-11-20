import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/catalogo/datos/catalogo_datos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final items = [
    ...alimentosCatalogo,
    ...ejerciciosCatalogo,
    ...consejosCatalogo,
  ];

  test('los nueve artículos apuntan a imágenes JPG locales únicas', () async {
    expect(items.length, 9);
    expect(items.map((e) => e.imagen).toSet().length, items.length);

    for (final item in items) {
      expect(item.imagen, startsWith('assets/images/catalogo/'));
      expect(item.imagen.toLowerCase(), endsWith('.jpg'));
      final bytes = await rootBundle.load(item.imagen);
      expect(bytes.lengthInBytes, greaterThan(0), reason: item.id);
    }
  });

  testWidgets('las nueve fotografías se pueden renderizar en Flutter',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final item in items) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 180,
              child: Image.asset(
                item.imagen,
                key: ValueKey(item.id),
                fit: BoxFit.cover,
                semanticsLabel: item.titulo,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(item.id)), findsOneWidget);
      expect(tester.takeException(), isNull, reason: item.id);
    }
  });
}
