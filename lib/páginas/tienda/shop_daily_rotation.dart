import 'shop_service.dart';

/// Muestra diaria común para todas las cuentas; solo determina merchandising.
/// En compras beta/demo el servidor recalcula fecha, selección y precio.
/// Zona comercial fija UTC-06:00, sin depender del reloj de la zona del teléfono.
class ShopDailyRotation {
  const ShopDailyRotation._(this.dayKey, this.itemIds, this.offerId);

  final String dayKey;
  final List<String> itemIds;
  final String? offerId;

  static const int slots = 20;
  static const int fixedSlots = 9; // 45 %
  static const int rotatingSlots = 7; // 35 %
  static const int specialSlots = 4; // 20 %
  static const int discountPercent = 20;

  static const fixedIds = <String>[
    'cap',
    'sports_headband',
    'water_bottle',
    'wellness_medal',
    'reaction_like',
    'banner_gradient_yellow_pink',
    'banner_gradient_blue_pink',
    'paper_sailor_hat',
    'frame_emerald',
  ];

  static const _special = <String>{
    'theme_cosmos', 'skin_christmas_cartoon', 'golden_aura',
    'stellar_aura', 'avatar_snowman', 'frame_arcane', 'frame_cyber',
  };

  static String dayFor(DateTime utcNow) {
    final local = utcNow.toUtc().subtract(const Duration(hours: 6));
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static bool _isSpecial(ShopItem item) =>
      item.id.startsWith('ufo_') || _special.contains(item.id);

  static int _seed(String value) {
    var value32 = 2166136261;
    for (final unit in value.codeUnits) {
      value32 = ((value32 ^ unit) * 16777619) & 0xffffffff;
    }
    return value32 == 0 ? 1 : value32;
  }

  static int _next(int value32) {
    value32 = (value32 ^ (value32 << 13)) & 0xffffffff;
    value32 = (value32 ^ (value32 >> 17)) & 0xffffffff;
    return (value32 ^ (value32 << 5)) & 0xffffffff;
  }

  static List<ShopItem> _rotate(
      List<ShopItem> pool, String day, String family) {
    final sorted = List<ShopItem>.from(pool)
      ..sort((a, b) => a.id.compareTo(b.id));
    var seed = _seed('$day:$family');
    for (var i = sorted.length - 1; i > 0; i--) {
      seed = _next(seed);
      final j = seed % (i + 1);
      final hold = sorted[i];
      sorted[i] = sorted[j];
      sorted[j] = hold;
    }
    return sorted;
  }

  static ShopDailyRotation forDay(String day, {List<ShopItem>? catalog}) {
    final all = (catalog ?? shopCatalog)
        .where((item) => item.price > 0 && isShopItemVisible(item.id))
        .toList();
    final fixed = [for (final id in fixedIds)
      ...all.where((item) => item.id == id)];
    final rotating = all.where((item) =>
        !_isSpecial(item) && !fixedIds.contains(item.id)).toList();
    final special = all.where(_isSpecial).toList();

    final regular = _rotate(rotating, day, 'rotating')
        .take(rotatingSlots).toList();
    final specials = _rotate(special, day, 'special')
        .take(specialSlots).toList();
    final selected = <ShopItem>[
      ...fixed.take(fixedSlots),
      ...regular,
      ...specials,
    ];
    final offer = regular.isNotEmpty ? regular.first.id :
        (specials.isNotEmpty ? specials.first.id : null);
    return ShopDailyRotation._(
      day,
      List.unmodifiable(selected.map((item) => item.id)),
      offer,
    );
  }

  static ShopDailyRotation today([DateTime? now]) =>
      forDay(dayFor(now ?? DateTime.now()));

  bool contains(String id) => itemIds.contains(id);
  bool isOffer(String id) => id == offerId;
  int priceFor(ShopItem item, {required bool authoritative}) {
    if (!authoritative || !isOffer(item.id)) return item.price;
    return (item.price * (100 - discountPercent)) ~/ 100;
  }
}
