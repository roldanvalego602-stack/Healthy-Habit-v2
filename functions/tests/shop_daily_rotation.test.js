"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {SHOP_PRICES} = require("../official_shop_catalog");
const {shopDayFor, dailyShop, dailyPrice, RETIRED_SHOP_IDS} =
  require("../shop_daily_rotation");
const {calculatePurchase, validateShopPurchase, validateBetaShopPurchase} =
  require("../shop_purchase_transaction");
const {RegistrationPolicyError} =
  require("../habit_registration_policy");

const now = new Date("2026-11-27T20:05:00.000Z");
const day = shopDayFor(now);

test("rotación estable de 20 espacios: 45 % fijos, 35 % rotativos, 20 % especiales", () => {
  const current = dailyShop(day);
  assert.equal(current.itemIds.length, 20);
  assert.equal(current.fixedCount, 9);
  assert.equal(current.rotatingCount, 7);
  assert.equal(current.specialCount, 4);
  assert.equal(new Set(current.itemIds).size, 20);
  assert.deepEqual(dailyShop(day).itemIds, current.itemIds);
  for (const id of current.itemIds) {
    assert.ok(SHOP_PRICES[id] > 0);
    assert.ok(!RETIRED_SHOP_IDS.has(id));
  }
  const tomorrow = dailyShop("2026-11-28");
  assert.deepEqual(tomorrow.itemIds.slice(0, 9), current.itemIds.slice(0, 9));
  assert.notDeepEqual(tomorrow.itemIds.slice(9), current.itemIds.slice(9));
});

test("fecha comercial con corte a medianoche UTC−06:00", () => {
  assert.equal(shopDayFor(new Date("2026-11-28T05:59:59Z")), "2026-11-27");
  assert.equal(shopDayFor(new Date("2026-11-28T06:00:00Z")), "2026-11-28");
});

test("descuento real del 20 % solo para el artículo seleccionado y ese día", () => {
  const active = dailyShop(day);
  const offer = active.offerId;
  assert.ok(offer);
  assert.equal(dailyPrice(offer, day, {now, enforceAvailability: true}),
    Math.floor(SHOP_PRICES[offer] * 80 / 100));
  const regular = active.itemIds.find((id) => id !== offer);
  assert.equal(dailyPrice(regular, day, {now, enforceAvailability: true}),
    SHOP_PRICES[regular]);
  const result = calculatePurchase({
    user: {habitCoins: 100000, shopInventory: []},
    itemId: offer, shopDay: day, now,
  });
  assert.equal(result.price, Math.floor(SHOP_PRICES[offer] * .8));
  assert.equal(result.balanceAfter, 100000 - result.price);
});

test("no se aceptan precios, descuentos, artículos retirados ni fechas alteradas", () => {
  const offer = dailyShop(day).offerId;
  const request = {itemId: offer, operationId: "daily_purchase_00001",
    shopDay: day};
  assert.deepEqual(validateShopPurchase(request), request);
  assert.throws(() => validateShopPurchase({...request, price: 1}),
    RegistrationPolicyError);
  assert.throws(() => validateShopPurchase({...request, shopDay: "ayer"}),
    RegistrationPolicyError);
  assert.throws(() => validateShopPurchase({...request, itemId: "crown"}),
    RegistrationPolicyError);
  assert.throws(() => calculatePurchase({
    user: {habitCoins: 100000, shopInventory: []},
    itemId: offer, shopDay: "2026-11-26", now,
  }), RegistrationPolicyError);
  const unavailable = Object.keys(SHOP_PRICES).find((id) =>
    SHOP_PRICES[id] > 0 && !RETIRED_SHOP_IDS.has(id) &&
    !dailyShop(day).itemIds.includes(id));
  assert.ok(unavailable);
  assert.throws(() => calculatePurchase({
    user: {habitCoins: 100000, shopInventory: []},
    itemId: unavailable, shopDay: day, now,
  }), RegistrationPolicyError);
});

test("beta exige fecha comercial y preserva el contrato demo heredado", () => {
  const id = dailyShop(day).offerId;
  const payload = {itemId: id, operationId: "beta_shop_operation_0001"};
  assert.deepEqual(validateShopPurchase(payload), payload);
  assert.throws(() => validateBetaShopPurchase(payload),
    RegistrationPolicyError);
  assert.deepEqual(validateBetaShopPurchase({...payload, shopDay: day}),
    {...payload, shopDay: day});
});
