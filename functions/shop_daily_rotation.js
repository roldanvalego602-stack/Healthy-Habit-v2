"use strict";

const {SHOP_PRICES} = require("./official_shop_catalog");

// No se venden secretos ni artículos retirados; se conservan sus IDs.
const RETIRED_SHOP_IDS = new Set([
  "crown", "mint_aura", "elite_avatar", "banner", "avatar_frame",
  "streak_guard", "mint_scarf", "bandana", "cape", "pixel_glasses",
  "cat_ears", "skin_titan_secret",
]);
const FIXED = Object.freeze([
  "cap",
  "sports_headband",
  "water_bottle",
  "wellness_medal",
  "reaction_like",
  "banner_gradient_yellow_pink",
  "banner_gradient_blue_pink",
  "paper_sailor_hat",
  "frame_emerald",
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

function seedFor(value) {
  let value32 = 2166136261 >>> 0;
  for (const character of value) {
    value32 = Math.imul(value32 ^ character.charCodeAt(0),
      16777619) >>> 0;
  }
  return value32 || 1;
}

function nextSeed(value32) {
  value32 = (value32 ^ (value32 << 13)) >>> 0;
  value32 = (value32 ^ (value32 >>> 17)) >>> 0;
  return (value32 ^ (value32 << 5)) >>> 0;
}

function ordered(ids, day, family) {
  const sorted = ids.sort();
  let seed = seedFor(day + ":" + family);
  for (let i = sorted.length - 1; i > 0; i--) {
    seed = nextSeed(seed);
    const j = seed % (i + 1);
    [sorted[i], sorted[j]] = [sorted[j], sorted[i]];
  }
  return sorted;
}

function dailyShop(day) {
  if (typeof day !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    throw new TypeError("Fecha comercial inválida.");
  }
  const eligible = Object.keys(SHOP_PRICES).filter((id) =>
    !RETIRED_SHOP_IDS.has(id) && SHOP_PRICES[id] > 0);
  const special = (id) => id.startsWith("ufo_") || SPECIAL.has(id);
  const fixed = FIXED.filter((id) => eligible.includes(id));
  const regular = ordered(eligible.filter((id) =>
    !special(id) && !FIXED.includes(id)), day, "rotating").slice(0, 7);
  const specials = ordered(eligible.filter(special), day, "special").slice(0, 4);
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
