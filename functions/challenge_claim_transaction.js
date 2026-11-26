"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const {RegistrationPolicyError} = require("./habit_registration_policy");
const {levelForXp} = require("./habit_registration_transaction");

const IDENTIFIER = /^[A-Za-z0-9_-]{1,128}$/;
const MAX_XP = 1000000000;
const LEVEL_COINS = Object.freeze({
  2: 25, 3: 25, 4: 25, 5: 50, 6: 50, 7: 50, 8: 50,
  9: 75, 10: 75, 11: 75, 12: 75, 13: 100, 14: 100,
  15: 100, 16: 100, 17: 150, 18: 150, 19: 150, 20: 300,
});

function validateChallengeClaim(data) {
  if (!data || typeof data !== "object" || Array.isArray(data) ||
      Object.keys(data).length !== 1 ||
      typeof data.challengeId !== "string" ||
      !IDENTIFIER.test(data.challengeId)) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Identificador de desafío inválido."
    );
  }
  return data.challengeId;
}

function calculateVerifiedClaim(challenge, user) {
  if (!challenge || challenge.demoSeed !== false ||
      challenge.progressVerified !== true ||
      challenge.progressSource !== "habit_records" ||
      challenge.status !== "completed" ||
      !Number.isSafeInteger(challenge.currentProgress) ||
      !Number.isSafeInteger(challenge.totalProgress) ||
      challenge.totalProgress < 1 ||
      challenge.currentProgress < challenge.totalProgress) {
    throw new RegistrationPolicyError(
      "failed-precondition",
      "El desafío no tiene progreso acreditado por el servidor."
    );
  }
  // Los premios autoritativos deben provenir de un documento que ningún
  // cliente pueda crear ni modificar. No permitir metadatos autodeclarados.
  if (!Number.isSafeInteger(challenge.xpReward) ||
      challenge.xpReward < 0 || challenge.xpReward > 150 ||
      !Number.isSafeInteger(challenge.hcReward) ||
      challenge.hcReward < 0 || challenge.hcReward > 50) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Recompensa del desafío inválida."
    );
  }
  const xpBefore = user?.xp;
  const currentXp = user?.currentXp ?? xpBefore;
  const coins = user?.habitCoins;
  const claimed = user?.claimedLevelRewards ?? [];
  if (!Number.isSafeInteger(xpBefore) || xpBefore < 0 ||
      !Number.isSafeInteger(currentXp) || currentXp !== xpBefore ||
      !Number.isSafeInteger(coins) || coins < 0 ||
      !Array.isArray(claimed) || claimed.some((n) =>
        !Number.isSafeInteger(n) || n < 2 || n > 20) ||
      new Set(claimed).size !== claimed.length) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Estado económico del usuario inválido."
    );
  }
  const xp = xpBefore + challenge.xpReward;
  const oldLevel = levelForXp(xpBefore);
  const level = levelForXp(xp);
  const nextClaims = new Set(claimed);
  let levelCoins = 0;
  for (let n = oldLevel + 1; n <= level; n++) {
    if (!nextClaims.has(n)) {
      nextClaims.add(n);
      levelCoins += LEVEL_COINS[n] ?? 0;
    }
  }
  const balance = coins + challenge.hcReward + levelCoins;
  if (!Number.isSafeInteger(xp) || xp > MAX_XP ||
      !Number.isSafeInteger(balance) || balance > MAX_XP) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Límite de recompensas excedido."
    );
  }
  return Object.freeze({
    xp, level, habitCoins: balance,
    claimedLevelRewards: [...nextClaims].sort((a, b) => a - b),
    xpAwarded: challenge.xpReward,
    coinsAwarded: challenge.hcReward + levelCoins,
  });
}

async function claimVerifiedChallenge({db, uid, data}) {
  if (typeof uid !== "string" || !IDENTIFIER.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Inicia sesión.");
  }
  const challengeId = validateChallengeClaim(data);
  const userRef = db.collection("users").doc(uid);
  const challengeRef = userRef.collection("challenges").doc(challengeId);
  return db.runTransaction(async (tx) => {
    const [challengeSnap, userSnap] = await Promise.all([
      tx.get(challengeRef), tx.get(userRef),
    ]);
    if (!challengeSnap.exists || !userSnap.exists) {
      throw new RegistrationPolicyError("not-found", "Desafío o usuario inexistente.");
    }
    const challenge = challengeSnap.data();
    if (challenge.status === "claimed") {
      throw new RegistrationPolicyError(
        "already-exists", "Esta recompensa ya fue reclamada."
      );
    }
    const reward = calculateVerifiedClaim(challenge, userSnap.data());
    tx.update(userRef, {
      xp: reward.xp, currentXp: reward.xp, level: reward.level,
      habitCoins: reward.habitCoins,
      claimedLevelRewards: reward.claimedLevelRewards,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(challengeRef, {
      status: "claimed", claimedAt: FieldValue.serverTimestamp(),
    });
    return {
      challengeId, xpAwarded: reward.xpAwarded,
      coinsAwarded: reward.coinsAwarded, level: reward.level,
    };
  });
}

module.exports = {
  validateChallengeClaim, calculateVerifiedClaim, claimVerifiedChallenge,
};
