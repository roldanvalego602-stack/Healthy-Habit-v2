import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/páginas/tienda/healthy_ufo_skin_art.dart';
import '../../lib/páginas/tienda/shop_daily_rotation.dart';
import '../../lib/páginas/tienda/shop_rarity.dart';
import '../../lib/páginas/tienda/shop_service.dart';

void main() {
  test('mezcla diaria: 9 fijos, 7 rotativos y 4 especiales sin repetidos', () {
    final current = ShopDailyRotation.forDay('2026-11-27');
    final tomorrow = ShopDailyRotation.forDay('2026-11-28');
    expect(current.itemIds.length, 20);
    expect(current.itemIds.toSet().length, 20);
    expect(current.itemIds.take(9), tomorrow.itemIds.take(9));
    expect(current.itemIds.skip(9).toList(),
        isNot(tomorrow.itemIds.skip(9).toList()));
    expect(current.itemIds.every((id) =>
      isShopItemVisible(id) && shopItemById(id)!.price > 0), isTrue);
    expect(current.offerId, isNotNull);
  });

  test('fecha de corte UTC−06:00 y cotización limitada a backend', () {
    expect(ShopDailyRotation.dayFor(DateTime.utc(2026, 11, 28, 5, 59)),
        '2026-11-27');
    expect(ShopDailyRotation.dayFor(DateTime.utc(2026, 11, 28, 6)),
        '2026-11-28');
    final daily = ShopDailyRotation.forDay('2026-11-27');
    final offer = shopItemById(daily.offerId!)!;
    expect(daily.priceFor(offer, authoritative: true),
        (offer.price * 80) ~/ 100);
    expect(daily.priceFor(offer, authoritative: false), offer.price);
  });

  test('los nueve aspectos OVNI usan la ranura independiente', () {
    expect(HealthyUfoSkinArt.ids.length, 9);
    for (final id in HealthyUfoSkinArt.ids) {
      final item = shopItemById(id);
      expect(item, isNotNull);
      expect(item!.category, 'OVNI');
      expect(item.slot, 'ufo_skin');
      expect(item.price, greaterThan(0));
      expect(rarityFor(item), isNot(ShopRarity.comun));
    }
    expect(shopItemById('skin_titan_secret')?.price, 0);
    expect(isShopItemVisible('skin_titan_secret'), isFalse);
  });

  testWidgets('miniatura vectorial dibuja sin archivos extra',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(
        child: HealthyUfoSkinArt(id: 'ufo_carrot', size: 100)))));
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
