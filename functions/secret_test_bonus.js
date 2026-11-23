"use strict";

const {FieldValue} = require("firebase-admin/firestore");

const BONUS = 1000;
const REQUIRED_PROJECT = "demo-healthy-habit";

function isSecretTestEnvironment(env) {
  return env.FUNCTIONS_EMULATOR === "true" &&
    env.GCLOUD_PROJECT === REQUIRED_PROJECT;
}

// Acredita exactamente una recompensa por cuenta. El cliente nunca decide
// el monto. El documento de control y el saldo cambian en una transacción.
async function claimSecretTestBonus({db, uid}) {
  if (typeof uid !== "string" || uid.length < 1 || uid.length > 128) {
    throw new Error("Usuario de prueba inválido.");
  }
  const userRef = db.collection("users").doc(uid);
  const claimRef = db.collection("secret_test_bonus_claims").doc(uid);
  return db.runTransaction(async (transaction) => {
    const claim = await transaction.get(claimRef);
    if (claim.exists) {
      return {awarded: false, amount: 0, alreadyClaimed: true};
    }
    const user = await transaction.get(userRef);
    if (!user.exists) throw new Error("Cuenta de prueba no encontrada.");
    const balance = user.data().habitCoins;
    if (!Number.isSafeInteger(balance) || balance < 0 ||
        balance > 1000000000 - BONUS) {
      throw new Error("Saldo inválido para recompensa de prueba.");
    }
    transaction.update(userRef, {habitCoins: balance + BONUS});
    transaction.create(claimRef, {
      uid,
      amount: BONUS,
      createdAt: FieldValue.serverTimestamp(),
      source: "easter_egg_emulator_demo",
    });
    return {
      awarded: true, amount: BONUS, alreadyClaimed: false,
      newBalance: balance + BONUS,
    };
  });
}

module.exports = {BONUS, isSecretTestEnvironment, claimSecretTestBonus};
