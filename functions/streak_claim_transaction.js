"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const {rewardCoins} = require("./streak_day_policy");

class DailyStreakClaimError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "DailyStreakClaimError";
    this.code = code;
  }
}

function validateClaimDay(day) {
  if (typeof day !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    throw new DailyStreakClaimError("invalid-argument",
      "Fecha del premio inválida.");
  }
  const stamp = Date.parse(day + "T00:00:00.000Z");
  if (!Number.isFinite(stamp) ||
      new Date(stamp).toISOString().slice(0, 10) !== day) {
    throw new DailyStreakClaimError("invalid-argument",
      "Fecha del premio imposible.");
  }
  return day;
}

async function claimDailyStreakRewardTransaction({db, uid, day}) {
  if (typeof uid !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
    throw new DailyStreakClaimError("unauthenticated", "Sesión inválida.");
  }
  validateClaimDay(day);
  const userRef = db.collection("users").doc(uid);
  const dayRef = userRef.collection("daily_streak_days").doc(day);
  return db.runTransaction(async (tx) => {
    const [userSnap, daySnap] = await Promise.all([
      tx.get(userRef), tx.get(dayRef),
    ]);
    if (!userSnap.exists || !daySnap.exists) {
      throw new DailyStreakClaimError("failed-precondition",
        "El día no fue verificado por el servidor.");
    }
    const reward = daySnap.data();
    if (reward.day !== day ||
        !reward.verifiedAt ||
        typeof reward.verifiedAt.toDate !== "function" ||
        !(reward.verifiedAt.toDate() instanceof Date) ||
        !Number.isSafeInteger(reward.streak) || reward.streak < 1 ||
        reward.rewardCoins !== rewardCoins(reward.streak)) {
      throw new DailyStreakClaimError("failed-precondition",
        "Registro de recompensa inconsistente.");
    }
    if (reward.claimed === true) {
      return {day, coinsAwarded: 0, alreadyClaimed: true};
    }
    if (reward.claimed !== false) {
      throw new DailyStreakClaimError("failed-precondition",
        "Estado de reclamación inválido.");
    }
    const amount = rewardCoins(reward.streak);
    const balance = userSnap.data().habitCoins;
    if (!Number.isSafeInteger(balance) || balance < 0 ||
        balance > 1000000000 - amount) {
      throw new DailyStreakClaimError("failed-precondition",
        "Saldo de monedas inválido.");
    }
    tx.update(userRef, {
      habitCoins: balance + amount,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(dayRef, {
      claimed: true,
      claimedAt: FieldValue.serverTimestamp(),
    });
    return {day, coinsAwarded: amount, alreadyClaimed: false};
  });
}

module.exports = {
  claimDailyStreakRewardTransaction,
  DailyStreakClaimError,
  validateClaimDay,
};
