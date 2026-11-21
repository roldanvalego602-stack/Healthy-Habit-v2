import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/catalogo/catalogo_media.dart';
import 'package:healthy_habit/páginas/catalogo/datos/catalogo_datos.dart';

void main() {
  testWidgets('ficha sin foto usa una ilustración integrada', (tester) async {
    final item = alimentosCatalogo.firstWhere((item) => item.id == 'manzana');
    expect(item.imagen, isEmpty);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CatalogoMedia(item: item, altura: 130)),
    ));
    expect(find.byType(Image), findsNothing);
    expect(find.byType(CatalogoMedia), findsOneWidget);
    expect(find.byIcon(Icons.eco_rounded), findsWidgets);
  });

  testWidgets('tarjeta puede compartir transición con detalle', (tester) async {
    final item = ejerciciosCatalogo.firstWhere(
      (item) => item.id == 'flexiones_pared');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CatalogoMedia(item: item, altura: 120, usarHero: true),
      ),
    ));
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'catalogo-flexiones_pared');
  });

  testWidgets('icono para consejo de sueño es reconocible', (tester) async {
    final item = consejosCatalogo.firstWhere(
      (item) => item.id == 'dormir_mejor');
    expect(CatalogoMedia.icono(item), Icons.bedtime_rounded);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CatalogoMedia(item: item, altura: 190)),
    ));
    expect(find.byType(CatalogoMedia), findsOneWidget);
  });
}
