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

  test('las nueve fotografías existentes apuntan a archivos JPG únicos', () async {
    expect(items.length, 28);
    final photographed = items.where((item) => item.imagen.isNotEmpty).toList();
    expect(photographed, hasLength(9));
    expect(photographed.map((e) => e.imagen).toSet().length, photographed.length);

    for (final item in photographed) {
      expect(item.imagen, startsWith('assets/images/catalogo/'));
      expect(item.imagen.toLowerCase(), endsWith('.jpg'));
      final bytes = await rootBundle.load(item.imagen);
      expect(bytes.lengthInBytes, greaterThan(0), reason: item.id);
    }
  });

  testWidgets('las nueve fotografías existentes se pueden renderizar en Flutter',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final item in items.where((item) => item.imagen.isNotEmpty)) {
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
                semanticLabel: item.titulo,
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
