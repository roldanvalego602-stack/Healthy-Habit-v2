"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {
  SHOP_SLOTS, validateAppearanceRequest, calculateAppearance,
  changeShopAppearance,
} = require("../shop_appearance_transaction");

test("catálogo de 56 accesorios y sus ranuras coincide con Flutter", () => {
  const dart = fs.readFileSync(path.resolve(__dirname,
    "../../lib/páginas/tienda/shop_service.dart"), "utf8");
  const entries = [...dart.matchAll(
    /ShopItem\(\s*'([^']+)'([\s\S]*?)(?=\n  ShopItem\(|\n\];)/g
  )];
  const slots = {};
  for (const match of entries) {
    const found = match[2].match(/slot:\s*'([^']+)'/);
    if (found) slots[match[1]] = found[1];
  }
  assert.equal(Object.keys(slots).length, 56);
  assert.deepEqual(SHOP_SLOTS, slots);
});

test("rechaza inyección de inventario, ranuras y monedas", () => {
  assert.deepEqual(validateAppearanceRequest({action: "reset"}), {action: "reset"});
  for (const data of [
    {action: "reset", itemId: "crown"},
    {action: "equip", itemId: "streak_guard"},
    {action: "equip", itemId: "../users/bob"},
    {action: "equip", itemId: "crown", habitCoins: 99999},
    {action: "grant", itemId: "crown"},
    null, [],
  ]) assert.throws(() => validateAppearanceRequest(data));
});

test("solo equipa artículos poseídos o gratuitos y restaura sin borrar el perfil", () => {
  const user = {shopInventory: ["crown", "cape", "avatar_frame"],
    shopEquipped: {cabeza: "crown", perfil_marco: "avatar_frame"}};
  assert.throws(() => calculateAppearance(user,
    {action: "equip", itemId: "golden_aura"}));
  assert.deepEqual(calculateAppearance(user,
    {action: "equip", itemId: "sunglasses"}),
  {cabeza: "crown", perfil_marco: "avatar_frame", ojos: "sunglasses"});
  assert.deepEqual(calculateAppearance(user,
    {action: "unequip", itemId: "crown"}),
  {perfil_marco: "avatar_frame"});
  assert.deepEqual(calculateAppearance(user,
    {action: "reset"}),
  {perfil_marco: "avatar_frame"});
});

test("rechaza equipamiento falso en Firestore aunque el artículo exista", () => {
  assert.throws(() => calculateAppearance({
    shopInventory: ["crown"], shopEquipped: {ojos: "crown"},
  }, {action: "reset"}));
});

test("operación en servidor idempotente sobre el estado final", async () => {
  const docs = new Map([["users/alice", {
    shopInventory: ["crown"], shopEquipped: {},
  }]]);
  const db = {
    collection(name) {
      return {doc(id) {return {path: name + "/" + id};}};
    },
    async runTransaction(cb) {
      const tx = {
        async get(ref) {return {
          exists: docs.has(ref.path), data: () => docs.get(ref.path),
        };},
        update(ref, data) {
          docs.set(ref.path, {...docs.get(ref.path), ...data});
        },
      };
      return cb(tx);
    },
  };
  const args = {db, uid: "alice", data: {action: "equip", itemId: "crown"}};
  assert.equal((await changeShopAppearance(args)).unchanged, false);
  assert.equal((await changeShopAppearance(args)).unchanged, true);
  assert.deepEqual(docs.get("users/alice").shopEquipped, {cabeza: "crown"});
});
