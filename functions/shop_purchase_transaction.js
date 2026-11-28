"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const {RegistrationPolicyError} = require("./habit_registration_policy");
const {SHOP_PRICES} = require("./official_shop_catalog");
const {dailyPrice} = require("./shop_daily_rotation");

const USER_ID = /^[A-Za-z0-9_-]{1,128}$/;
const OPERATION_ID = /^[A-Za-z0-9_-]{16,128}$/;
const MAX_BALANCE = 1000000000;

function validateShopPurchase(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new RegistrationPolicyError("invalid-argument", "Solicitud inválida.");
  }
  const {itemId, operationId, shopDay} = data;
  if (typeof itemId !== "string" ||
      !Object.hasOwn(SHOP_PRICES, itemId)) {
    throw new RegistrationPolicyError("invalid-argument", "Artículo desconocido.");
  }
  if (typeof operationId !== "string" ||
      !OPERATION_ID.test(operationId) ||
      Object.keys(data).some((key) =>
        !["itemId", "operationId", "shopDay"].includes(key)) ||
      (shopDay !== undefined && (typeof shopDay !== "string" ||
        !/^\d{4}-\d{2}-\d{2}$/.test(shopDay)))) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Identificador o campos de compra inválidos."
    );
  }
  if (!Number.isSafeInteger(SHOP_PRICES[itemId]) || SHOP_PRICES[itemId] <= 0) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Los artículos gratuitos no se compran."
    );
  }
  return shopDay === undefined ? {itemId, operationId} :
    {itemId, operationId, shopDay};
}

function calculatePurchase({user, itemId, shopDay, now = new Date()}) {
  if (!user || !Object.hasOwn(SHOP_PRICES, itemId)) {
    throw new RegistrationPolicyError("not-found", "Artículo o perfil inexistente.");
  }
  let cost = SHOP_PRICES[itemId];
  if (shopDay !== undefined) {
    try {
      cost = dailyPrice(itemId, shopDay,
        {now, enforceAvailability: true});
    } catch (error) {
      throw new RegistrationPolicyError(
        "failed-precondition", error.message);
    }
  } else if (process.env.HH_SHOP_DAILY_REQUIRED === "enabled") {
    throw new RegistrationPolicyError("failed-precondition",
      "Esta versión de la tienda requiere la fecha de la oferta.");
  }
  const balance = user.habitCoins;
  const inventory = user.shopInventory ?? [];
  if (!Number.isSafeInteger(balance) || balance < 0 || balance > MAX_BALANCE ||
      !Array.isArray(inventory) ||
      !inventory.every((id) => typeof id === "string") ||
      new Set(inventory).size !== inventory.length) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Economía o inventario inválidos."
    );
  }
  if (!Number.isSafeInteger(cost) || cost <= 0) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Artículo no comprable."
    );
  }
  if (inventory.includes(itemId)) {
    throw new RegistrationPolicyError("already-exists", "Ya tienes este artículo.");
  }
  if (balance < cost) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Habit Coins insuficientes."
    );
  }
  return Object.freeze({
    price: cost, balanceAfter: balance - cost, inventoryAfter: [...inventory, itemId],
  });
}

async function purchaseDemoShopItem({db, uid, data}) {
  if (typeof uid !== "string" || !USER_ID.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  const {itemId, operationId, shopDay} = validateShopPurchase(data);
  const userRef = db.collection("users").doc(uid);
  const operationRef = userRef.collection("shop_purchase_operations")
    .doc(operationId);
  return db.runTransaction(async (tx) => {
    // Transacción de Admin SDK: siempre leer antes de escribir.
    const [operationSnap, userSnap] = await Promise.all([
      tx.get(operationRef), tx.get(userRef),
    ]);
    if (operationSnap.exists) {
      const previous = operationSnap.data();
      if (previous.itemId !== itemId) {
        throw new RegistrationPolicyError(
          "already-exists", "La operación pertenece a otro artículo."
        );
      }
      return {...previous.result, alreadyProcessed: true};
    }
    if (!userSnap.exists) {
      throw new RegistrationPolicyError("not-found", "Perfil inexistente.");
    }
    const outcome = calculatePurchase({
      user: userSnap.data(), itemId, shopDay,
    });
    const result = {
      itemId, price: outcome.price, balanceAfter: outcome.balanceAfter,
    };
    tx.update(userRef, {
      habitCoins: outcome.balanceAfter,
      shopInventory: outcome.inventoryAfter,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.create(operationRef, {
      itemId, result, createdAt: FieldValue.serverTimestamp(),
    });
    return {...result, alreadyProcessed: false};
  });
}

module.exports = {
  validateShopPurchase, calculatePurchase, purchaseDemoShopItem,
};
