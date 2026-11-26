"use strict";

// Laboratorio exclusivo de Firestore Emulator: NUNCA usar contra producción.
// Prueba directamente transacciones Admin SDK (las callables beta permanecen
// bloqueadas por App Check y allowlist hasta que se habilite la beta real).
const test = require("node:test");
const assert = require("node:assert/strict");
const {initializeApp, deleteApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {SHOP_PRICES} = require("../official_shop_catalog");
const {purchaseDemoShopItem} = require("../shop_purchase_transaction");
const {SHOP_SLOTS, changeShopAppearance} =
  require("../shop_appearance_transaction");
const {RegistrationPolicyError} =
  require("../habit_registration_policy");

const PROJECT = "demo-healthy-habit";
const EXPECTED_HOST = "127.0.0.1:8080";

function requireIsolatedEmulator() {
  assert.equal(process.env.GCLOUD_PROJECT, PROJECT);
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, EXPECTED_HOST,
    "Solo se admite Firestore Emulator LOCAL");
}

test("catálogo completo: compras únicas, montos oficiales y equipamiento", async () => {
  requireIsolatedEmulator();
  const app = initializeApp({projectId: PROJECT}, "shop-all-items-emulator");
  try {
    const db = getFirestore(app, "default"); // distinta de (default)
    const uid = "shop_test_" + Date.now() + "_" +
      Math.random().toString(36).slice(2, 11);
    const ref = db.collection("users").doc(uid);
    const items = Object.entries(SHOP_PRICES);
    assert.equal(items.length, 62);
    const initialCoins = 50000;
    await ref.set({uid, habitCoins: initialCoins,
      shopInventory: [], shopEquipped: {}});
    let spent = 0;
    let purchased = 0;
    for (const [itemId, price] of items) {
      if (price === 0) continue;
      const data = {itemId, operationId:
        "buy_operation_" + String(purchased).padStart(16, "0")};
      const first = await purchaseDemoShopItem({db, uid, data});
      assert.equal(first.alreadyProcessed, false, itemId);
      assert.equal(first.price, price, itemId);
      const again = await purchaseDemoShopItem({db, uid, data});
      assert.equal(again.alreadyProcessed, true, itemId);
      assert.equal(again.balanceAfter, first.balanceAfter, itemId);
      await assert.rejects(purchaseDemoShopItem({db, uid, data: {
        itemId, operationId: "duplicate_item_" +
          String(purchased).padStart(16, "0"),
      }}), RegistrationPolicyError);
      spent += price;
      purchased++;
    }
    assert.equal(purchased, 60);
    const bought = (await ref.get()).data();
    assert.equal(bought.habitCoins, initialCoins - spent);
    assert.equal(bought.shopInventory.length, 60);
    assert.equal(new Set(bought.shopInventory).size, 60);

    // No se pueden transferir IDs comprados ni manipular la economía.
    await assert.rejects(purchaseDemoShopItem({db, uid, data: {
      itemId: "crown", operationId: "inject_operation_000001", price: 1,
    }}), RegistrationPolicyError);

    let equipped = 0;
    for (const itemId of Object.keys(SHOP_SLOTS)) {
      const change = await changeShopAppearance({db, uid,
        data: {action: "equip", itemId}});
      assert.equal(change.equipped[SHOP_SLOTS[itemId]], itemId);
      const repeat = await changeShopAppearance({db, uid,
        data: {action: "equip", itemId}});
      assert.equal(repeat.unchanged, true, itemId);
      equipped++;
    }
    assert.ok(equipped > 40);
    const beforeReset = (await ref.get()).data();
    const reset = await changeShopAppearance({db, uid,
      data: {action: "reset"}});
    assert.ok(Object.keys(reset.equipped)
      .every((slot) => slot.startsWith("perfil_")));
    const afterReset = (await ref.get()).data();
    assert.equal(afterReset.habitCoins, beforeReset.habitCoins);
    assert.deepEqual(afterReset.shopInventory, beforeReset.shopInventory);
    assert.ok(Object.keys(afterReset.shopEquipped)
      .every((slot) => slot.startsWith("perfil_")));
    assert.equal((await changeShopAppearance({db, uid,
      data: {action: "reset"}})).unchanged, true);
  } finally {
    await deleteApp(app);
  }
});

test("tienda: no se compra gratis, sin saldo ni con datos inyectados", async () => {
  requireIsolatedEmulator();
  const app = initializeApp({projectId: PROJECT}, "shop-invalid-emulator");
  try {
    const db = getFirestore(app, "default");
    const uid = "shop_invalid_" + Date.now();
    await db.collection("users").doc(uid).set({
      habitCoins: 10, shopInventory: [], shopEquipped: {},
    });
    for (const itemId of ["sunglasses", "bandana", "crown"]) {
      await assert.rejects(purchaseDemoShopItem({db, uid, data: {
        itemId, operationId: "forbidden_purchase_0001",
      }}), RegistrationPolicyError);
    }
    await assert.rejects(changeShopAppearance({db, uid, data: {
      action: "equip", itemId: "crown",
    }}), RegistrationPolicyError);
    await assert.rejects(changeShopAppearance({db, uid, data: {
      action: "equip", itemId: "crown", coins: 1,
    }}), RegistrationPolicyError);
    const user = (await db.collection("users").doc(uid).get()).data();
    assert.equal(user.habitCoins, 10);
    assert.deepEqual(user.shopInventory, []);
  } finally {
    await deleteApp(app);
  }
});
