"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const ANSWER = "constancia";
const SKIN_ID = "skin_titan_secret";
const SECRET_ID = "titan_cave_v1";
const DAILY_LIMIT = 5;

function normalizedAnswer(value) {
  if (typeof value !== "string" || value.length > 70) return "";
  return value.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .toLowerCase().trim().replace(/\s+/g, " ");
}

function resolveAttempt({solved, attempts, answer}) {
  if (solved) return {status: "unlocked", award: false};
  if (!Number.isSafeInteger(attempts) || attempts < 0) {
    throw new Error("Contador de intentos inválido.");
  }
  if (attempts >= DAILY_LIMIT) {
    return {status: "locked", award: false};
  }
  if (normalizedAnswer(answer) === ANSWER) {
    return {status: "unlocked", award: true};
  }
  return {status: attempts + 1 >= DAILY_LIMIT ? "locked" : "incorrect",
    award: false};
}

async function claimTitanSecret({db, uid, answer, now = new Date()}) {
  if (typeof uid !== "string" || !/^[a-zA-Z0-9_-]{1,128}$/.test(uid)) {
    throw new Error("Sesión inválida.");
  }
  if (typeof answer !== "string" || answer.length < 1 ||
      answer.length > 70) {
    throw new Error("Respuesta inválida.");
  }
  const day = now.toISOString().slice(0, 10);
  const userRef = db.collection("users").doc(uid);
  const secretRef = db.collection("healthy_secret_rewards").doc(uid + "_" + SECRET_ID);
  const attemptsRef = db.collection("healthy_secret_attempts")
    .doc(uid + "_" + SECRET_ID + "_" + day);

  return db.runTransaction(async (tx) => {
    const [user, secret, attempt] = await Promise.all([
      tx.get(userRef), tx.get(secretRef), tx.get(attemptsRef),
    ]);
    if (!user.exists) throw new Error("No se encontró el perfil.");
    const profile = user.data() || {};
    if (!Array.isArray(profile.shopInventory ?? []) ||
        (profile.shopInventory ?? []).some((id) => typeof id !== "string")) {
      throw new Error("El inventario requiere revisión.");
    }
    const inventory = profile.shopInventory || [];
    if (secret.exists || inventory.includes(SKIN_ID)) {
      return {status: "unlocked", awarded: false, remaining: 0,
        skinId: SKIN_ID};
    }

    const used = attempt.exists ? attempt.data().count : 0;
    const result = resolveAttempt({solved: false, attempts: used, answer});
    if (result.status === "locked" && used >= DAILY_LIMIT) {
      return {status: "locked", awarded: false, remaining: 0};
    }
    tx.set(attemptsRef, {
      uid, day, secretId: SECRET_ID, count: used + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (result.award) {
      tx.create(secretRef, {
        uid, secretId: SECRET_ID, skinId: SKIN_ID,
        unlockedAt: FieldValue.serverTimestamp(),
        kind: "easter_egg",
      });
      tx.update(userRef, {
        shopInventory: FieldValue.arrayUnion(SKIN_ID),
      });
    }
    return {
      status: result.status, awarded: result.award,
      remaining: Math.max(0, DAILY_LIMIT - used - 1),
      ...(result.award ? {skinId: SKIN_ID} : {}),
    };
  });
}

module.exports = {
  SKIN_ID, SECRET_ID, DAILY_LIMIT, normalizedAnswer,
  resolveAttempt, claimTitanSecret,
};
