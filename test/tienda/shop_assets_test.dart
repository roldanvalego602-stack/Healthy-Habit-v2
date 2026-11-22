import 'package:flutter_test/flutter_test.dart';

import '../../lib/páginas/tienda/shop_service.dart';
import '../../lib/tema/healthy_asset_catalog.dart';

void main() {
  test('los 8 accesorios gráficos están vinculados al catálogo', () {
    expect(HealthyAssetCatalog.shopImages.length, 8);
    for (final entry in HealthyAssetCatalog.shopImages.entries) {
      final item = shopItemById(entry.key);
      expect(item, isNotNull, reason: entry.key);
      expect(entry.value.endsWith('.png'), isTrue);
      expect(item!.slot, isNotNull);
    }
  });

  test('no hay identificadores duplicados en tienda', () {
    final ids = shopCatalog.map((item) => item.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('nuevos objetos tienen precios y ranuras coherentes', () {
    const expected = <String, (int, String)>{
      'sports_headband': (70, 'cabeza'),
      'leaf_headphones': (140, 'cabeza'),
      'leaf_hoodie': (200, 'torso'),
      'wellness_medal': (100, 'cuello'),
      'water_bottle': (90, 'mano'),
      'leaf_backpack': (170, 'espalda'),
    };
    for (final entry in expected.entries) {
      final item = shopItemById(entry.key)!;
      expect(item.price, entry.value.$1);
      expect(item.slot, entry.value.$2);
    }
  });

  test('los estilos de avatar y banner apuntan a los PNG registrados', () {
    expect(HealthyAssetCatalog.avatars.keys.toSet(),
        {'naturaleza', 'agua', 'energia'});
    expect(HealthyAssetCatalog.banners.keys.toSet(),
        {'Amanecer', 'Bosque', 'Océano'});
    expect(
      [...HealthyAssetCatalog.avatars.values,
        ...HealthyAssetCatalog.banners.values]
          .every((file) => file.endsWith('.png')),
      isTrue,
    );
  });
}
