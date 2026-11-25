import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_streak_items.dart';
import 'package:healthy_habit/páginas/tienda/shop_service.dart';

void main() {
  test('los tres consumibles ilustrados tienen rutas únicas y archivos PNG', () {
    expect(HealthyStreakItems.paths.length, HealthyStreakItem.values.length);
    expect(HealthyStreakItems.paths.values.toSet().length,
        HealthyStreakItem.values.length);

    for (final item in HealthyStreakItem.values) {
      final path = HealthyStreakItems.paths[item]!;
      expect(path, endsWith('.png'));
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(HealthyStreakItems.label(item), isNotEmpty);
    }
  });

  test('streak_guard se conserva retirado hasta implementar el consumo', () {
    expect(shopItemById('streak_guard'), isNotNull);
    expect(isShopItemVisible('streak_guard'), isFalse);
    expect(availableShopItems(null)
        .any((item) => item.id == 'streak_guard'), isFalse);
  });
}
