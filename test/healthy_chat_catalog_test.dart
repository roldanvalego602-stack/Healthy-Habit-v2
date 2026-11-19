import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/catalogo/datos/catalogo_datos.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_assistant_engine.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_chat_catalog_card.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const engine = HealthyAssistantEngine();
  const profile = <String, dynamic>{};
  const habits = <Map<String, dynamic>>[];

  test('reconoce cada ficha real sin inventar una nueva', () {
    final queries = <String, String>{
      '¿Qué nutrientes tienen las lentejas?': 'lentejas',
      'Muéstrame los beneficios de la avena': 'avena',
      '¿Qué contiene el huevo?': 'huevo',
      '¿Cómo hacer sentadillas?': 'sentadillas',
      '¿Cómo realizar la plancha abdominal?': 'plancha',
      '¿Cómo hacer caminar en casa?': 'caminar',
      'Dime los beneficios de dormir mejor': 'dormir_mejor',
      '¿Cómo prevenir caídas?': 'prevenir_caidas',
      'Háblame de las pausas activas': 'pausas_activas',
    };
    for (final entry in queries.entries) {
      final reply = engine.resolve(entry.key,
        profile: profile, habits: habits);
      expect(reply.card, 'catalog_item', reason: entry.key);
      expect(reply.action, 'catalog_item', reason: entry.key);
      expect(reply.actionArgument, entry.value, reason: entry.key);
      expect(HealthyChatCatalogCard.findById(entry.value), isNotNull);
    }
  });

  test('la respuesta utiliza la descripción y la fuente de la ficha', () {
    final item = alimentosCatalogo.first;
    final reply = engine.resolve('Muéstrame los beneficios de la avena',
      profile: profile, habits: habits);
    expect(reply.text, contains(item.descripcion));
    expect(reply.text, contains(item.beneficios.first));
    expect(reply.text, contains('Precaución:'));
    expect(reply.text, isNot(contains('1000 calorías')));
  });

  test('una pregunta sobre calorías sin cifra documentada no inventa dato', () {
    final reply = engine.resolve('¿Cuántas calorías tiene la avena?',
      profile: profile, habits: habits);
    expect(reply.card, 'catalog_item');
    expect(reply.actionArgument, 'avena');
    expect(reply.text, contains('No voy a estimarlo'));
  });

  test('nutrientes usan únicamente valores del catálogo y su porción', () {
    final reply = engine.resolve('¿Qué nutrientes tienen las lentejas?',
      profile: profile, habits: habits);
    expect(reply.text, contains('Proteína:'));
    expect(reply.text, contains('100 g de lentejas cocidas'));
    expect(reply.text, contains('Composición aproximada'));
  });

  test('catálogo sin ficha específica abre el listado', () {
    final reply = engine.resolve('Abre el catálogo',
      profile: profile, habits: habits);
    expect(reply.action, 'catalog');
    expect(reply.card, 'catalog');
  });

  test('preguntas sin correspondencia no muestran fichas inventadas', () {
    final reply = engine.resolve('¿Qué nutrientes tiene el dragón azul?',
      profile: profile, habits: habits);
    expect(reply.card, isNot('catalog_item'));
  });

  testWidgets('tarjeta permite ver detalles y usa fotografía JPG',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    var opened = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(width: 310,
        child: HealthyChatCatalogCard(
          itemId: 'avena',
          onOpen: (item) => opened = item.id,
        ),
      )),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('catalog-card-avena')),
      findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-photo-avena')),
      findsOneWidget);
    expect(find.text('Avena'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('catalog-open-avena')));
    await tester.pump();
    expect(opened, 'avena');
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });

  test('los nueve artículos están enlazados a JPG en assets', () {
    final items = [
      ...alimentosCatalogo,
      ...ejerciciosCatalogo,
      ...consejosCatalogo,
    ];
    expect(items.length, 9);
    for (final item in items) {
      expect(item.imagen, endsWith('.jpg'));
      expect(item.imagen, startsWith('assets/images/catalogo/'));
    }
  });
}
