"use strict";

// Catálogo autorizado del piloto. Fuente: shopCatalog de
// lib/páginas/tienda/shop_service.dart. Sin red ni precios del cliente.
// La prueba de paridad detecta cambios de precios o IDs en Flutter.
const SHOP_PRICES = Object.freeze({
  "avatar_frame": 120,
  "banner": 120,
  "streak_guard": 300,
  "achievement_display": 200,
  "elite_avatar": 140,
  "mint_scarf": 180,
  "sunglasses": 0,
  "bandana": 0,
  "cap": 100,
  "crown": 180,
  "mint_aura": 120,
  "cape": 200,
  "pixel_glasses": 80,
  "cat_ears": 150,
  "sports_headband": 70,
  "leaf_headphones": 140,
  "leaf_hoodie": 200,
  "wellness_medal": 100,
  "water_bottle": 90,
  "leaf_backpack": 170
});

module.exports = {SHOP_PRICES};
