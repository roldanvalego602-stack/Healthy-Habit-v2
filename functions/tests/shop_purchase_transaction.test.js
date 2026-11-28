"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {SHOP_PRICES} = require("../official_shop_catalog");
const {shopDayFor, dailyShop} = require("../shop_daily_rotation");
const {validateShopPurchase, calculatePurchase} =
  require("../shop_purchase_transaction");
const {RegistrationPolicyError} =
  require("../habit_registration_policy");

test("todos los artículos y sus precios coinciden con Flutter", () => {
  const dart = fs.readFileSync(path.resolve(__dirname,
    "../../lib/páginas/tienda/shop_service.dart"), "utf8");
  const entries = [...dart.matchAll(
    /ShopItem\(\s*'([^']+)'[\s\S]*?,\s*(\d+)\s*,\s*(?:emoji:|slot:|\))/g
  )].map((match) => [match[1], Number(match[2])]);
  assert.equal(entries.length, 73);
  assert.equal(new Set(entries.map(([id]) => id)).size, 73);
  assert.deepEqual(SHOP_PRICES, Object.fromEntries(entries));
  assert.equal(Object.values(SHOP_PRICES).filter((price) => price === 0).length, 3);
});

test("la solicitud solo acepta un artículo pagado y una operación segura", () => {
  const valid = {itemId: "leaf_crown", operationId: "purchase_operation_0001"};
  assert.deepEqual(validateShopPurchase(valid), valid);
  for (const data of [
    {...valid, itemId: "sunglasses"},
    {...valid, itemId: "skin_titan_secret"},
    {...valid, itemId: "nonexistent"},
    {...valid, operationId: "x/y"},
    {...valid, amount: 1},
    {...valid, price: 0},
    {...valid, coins: 1000},
    null, [],
  ]) assert.throws(() => validateShopPurchase(data), RegistrationPolicyError);
});

test("el saldo y el inventario se calculan de forma determinista", () => {
  const result = calculatePurchase({
    user: {habitCoins: 250, shopInventory: ["cap"]}, itemId: "leaf_crown",
  });
  assert.equal(result.price, 180);
  assert.equal(result.balanceAfter, 70);
  assert.deepEqual(result.inventoryAfter, ["cap", "leaf_crown"]);
});

test("el pago exacto deja saldo cero pero nunca negativo", () => {
  assert.equal(calculatePurchase({
    user: {habitCoins: 180}, itemId: "leaf_crown",
  }).balanceAfter, 0);
  assert.throws(() => calculatePurchase({
    user: {habitCoins: 179}, itemId: "leaf_crown",
  }), RegistrationPolicyError);
});

test("no se permite comprar de nuevo el mismo artículo", () => {
  assert.throws(() => calculatePurchase({
    user: {habitCoins: 1000, shopInventory: ["leaf_crown"]},
    itemId: "leaf_crown",
  }), RegistrationPolicyError);
});

test("economía e inventario corrompidos se rechazan antes de escribir", () => {
  for (const user of [
    {habitCoins: -1},
    {habitCoins: 25.2},
    {habitCoins: "1000"},
    {habitCoins: 1000000001},
    {habitCoins: 1000, shopInventory: "leaf_crown"},
    {habitCoins: 1000, shopInventory: ["leaf_crown", "leaf_crown"]},
    {habitCoins: 1000, shopInventory: [12]},
  ]) assert.throws(() => calculatePurchase({
    user, itemId: "leaf_hoodie",
  }), RegistrationPolicyError);
});

test("los artículos gratuitos siguen disponibles sin transacción de compra", () => {
  assert.equal(SHOP_PRICES.sunglasses, 0);
  assert.equal(SHOP_PRICES.bandana, 0);
  for (const itemId of ["sunglasses", "bandana"]) {
    assert.throws(() => validateShopPurchase({
      itemId, operationId: "free_operation_0001",
    }), RegistrationPolicyError);
  }
});

test("el artículo streak_guard sigue siendo único hasta diseñar su consumo", () => {
  assert.equal(SHOP_PRICES.streak_guard, 300);
  assert.throws(() => calculatePurchase({
    user: {habitCoins: 500, shopInventory: ["streak_guard"]},
    itemId: "streak_guard",
  }), RegistrationPolicyError);
});
