"use strict";

const {SHOP_PRICES} = require("./official_shop_catalog");

// No se venden secretos ni artículos retirados; se conservan sus IDs.
const RETIRED_SHOP_IDS = new Set([
  "crown", "mint_aura", "elite_avatar", "banner", "avatar_frame",
  "streak_guard", "mint_scarf", "bandana", "cape", "pixel_glasses",
  "cat_ears", "skin_titan_secret",
]);
const SPECIAL = new Set([
  "theme_cosmos", "skin_christmas_cartoon", "golden_aura",
  "stellar_aura", "avatar_snowman", "frame_arcane", "frame_cyber",
]);

function shopDayFor(now = new Date()) {
  if (!(now instanceof Date) || !Number.isFinite(now.getTime())) {
    throw new TypeError("Fecha de tienda inválida.");
  }
  return new Date(now.getTime() - 6 * 60 * 60 * 1000)
    .toISOString().slice(0, 10);
}

function hash(value) {
  let n = 0;
  for (const character of value) {
    n = (Math.imul(n, 31) + character.charCodeAt(0)) & 0x7fffffff;
  }
  return n;
}

function ordered(ids, day) {
  return ids.sort((a, b) => hash(day + ":" + a) - hash(day + ":" + b) ||
    a.localeCompare(b, "en"));
}

function dailyShop(day) {
  if (typeof day !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    throw new TypeError("Fecha comercial inválida.");
  }
  const eligible = Object.keys(SHOP_PRICES).filter((id) =>
    !RETIRED_SHOP_IDS.has(id) && SHOP_PRICES[id] > 0);
  const special = (id) => id.startsWith("ufo_") || SPECIAL.has(id);
  const fixed = eligible.filter((id) => !special(id) && SHOP_PRICES[id] <= 150)
    .sort().slice(0, 9);
  const regular = ordered(eligible.filter((id) =>
    !special(id) && SHOP_PRICES[id] > 150), day).slice(0, 7);
  const specials = ordered(eligible.filter(special), day).slice(0, 4);
  const itemIds = [...fixed, ...regular, ...specials];
  const offerId = regular[0] || specials[0] || null;
  return Object.freeze({dayKey: day, itemIds: Object.freeze(itemIds), offerId,
    fixedCount: fixed.length, rotatingCount: regular.length,
    specialCount: specials.length});
}

function dailyPrice(itemId, day, {now = new Date(), enforceAvailability = false} = {}) {
  if (!Object.hasOwn(SHOP_PRICES, itemId) || !(SHOP_PRICES[itemId] > 0) ||
      RETIRED_SHOP_IDS.has(itemId)) {
    throw new TypeError("Artículo no comercializable.");
  }
  if (day !== shopDayFor(now)) {
    throw new RangeError("La oferta caducó; actualiza la tienda.");
  }
  const today = dailyShop(day);
  if (enforceAvailability && !today.itemIds.includes(itemId)) {
    throw new RangeError("El artículo no está en la selección del día.");
  }
  const base = SHOP_PRICES[itemId];
  return today.offerId === itemId ? Math.floor(base * 80 / 100) : base;
}

module.exports = {RETIRED_SHOP_IDS, shopDayFor, dailyShop, dailyPrice};
