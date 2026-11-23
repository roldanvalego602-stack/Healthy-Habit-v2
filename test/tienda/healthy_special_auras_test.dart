import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/tienda/healthy_mascot_outfit.dart';
import 'package:healthy_habit/páginas/tienda/healthy_special_auras.dart';
import 'package:healthy_habit/páginas/tienda/shop_item_artwork.dart';
import 'package:healthy_habit/páginas/tienda/shop_service.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('las nuevas auras tienen precios, categoría y ranura válidos', () {
    for (final (id, price) in [
      ('stellar_aura', 280),
      ('golden_aura', 400),
    ]) {
      final item = shopItemById(id);
      expect(item, isNotNull);
      expect(item!.price, price);
      expect(item.slot, 'aura');
      expect(item.category, 'Especiales');
      expect(isShopItemVisible(id), isTrue);
      expect(availableShopItems(null).any((entry) => entry.id == id), isTrue);
    }
    expect(shopItemById('mint_aura'), isNotNull);
    expect(isShopItemVisible('mint_aura'), isFalse);
  });

  for (final (id, kind, key) in [
    ('stellar_aura', HealthySpecialAura.stellar, 'healthy-aura-estelar'),
    ('golden_aura', HealthySpecialAura.golden, 'healthy-aura-dorada'),
  ]) {
    testWidgets('el efecto $id rodea a la mascota en modo Lite',
        (tester) async {
      await HealthyVisualController.instance.select(HealthyVisualMode.lite);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(
          child: HealthyMascotOutfit(equipped: {
            'aura': id,
            'cabeza': 'leaf_crown',
          }),
        )),
      ));
      expect(find.byType(HealthySpecialAuraEffect), findsOneWidget);
      final aura = tester.widget<HealthySpecialAuraEffect>(
          find.byType(HealthySpecialAuraEffect));
      expect(aura.kind, kind);
      expect(find.byKey(ValueKey(key)), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    });

    testWidgets('la tienda presenta miniatura $id sin cargar PNG',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ShopItemArtwork(
          item: shopItemById(id)!,
        )),
      ));
      expect(find.byType(HealthySpecialAuraThumbnail), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sin aura equipada no aparece ninguno de los efectos',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyMascotOutfit(equipped: {})),
    ));
    expect(find.byType(HealthySpecialAuraEffect), findsNothing);
  });
}
