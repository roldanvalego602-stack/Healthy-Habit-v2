"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const {
  validateRegistrationRequest,
  registrationEligibility,
  RegistrationPolicyError,
} = require("./habit_registration_policy");

// El catálogo oficial está replicado desde Dart y cubre 36 hábitos.
// La transacción sigue limitada a hidr_001 mientras se implementan
// las reglas de frecuencia para los otros 35 hábitos.
const {SERVER_CATALOG} = require("./official_habit_catalog");
const PILOT_IDS = new Set(["hidr_001"]);
const LEVELS = Object.freeze([
  [0, 0], [100, 25], [250, 25], [450, 25], [700, 50],
  [1000, 50], [1350, 50], [1750, 50], [2200, 75],
  [2700, 75], [3250, 75], [3850, 75], [4500, 100],
  [5200, 100], [5950, 100], [6750, 100], [7600, 150],
  [8500, 150], [9500, 150], [10500, 300],
]);
const OPERATION_ID = /^[A-Za-z0-9_-]{16,128}$/;

function validateDemoRegistration(data) {
  const ids = validateRegistrationRequest(data);
  if (!Object.hasOwn(SERVER_CATALOG, ids.habitId) ||
      !PILOT_IDS.has(ids.habitId)) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Hábito aún no habilitado para el piloto."
    );
  }
  if (typeof data.operationId !== "string" ||
      !OPERATION_ID.test(data.operationId)) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Identificador de operación inválido."
    );
  }
  // Sin fotografías, archivos, montos, objetivos ni progreso suministrados.
  if (Object.keys(data).some((key) =>
    !["habitId", "attemptId", "operationId"].includes(key))) {
    throw new RegistrationPolicyError(
      "invalid-argument", "La solicitud contiene campos no admitidos."
    );
  }
  return {...ids, operationId: data.operationId};
}

function levelForXp(xp) {
  let number = 1;
  for (let i = 0; i < LEVELS.length; i++) {
    if (xp >= LEVELS[i][0]) number = i + 1;
  }
  return number;
}

function calculateRegistrationReward({user, attempt, catalog}) {
  if (!user || !attempt || !catalog) {
    throw new RegistrationPolicyError("not-found", "Estado incompleto.");
  }
  const previousXp = user.xp ?? user.currentXp ?? 0;
  const coins = user.habitCoins ?? 0;
  const earnedXp = attempt.xpEarned ?? 0;
  if (![previousXp, coins, earnedXp].every((value) =>
    Number.isSafeInteger(value) && value >= 0) ||
    previousXp > 999999990 || coins > 999999999 ||
    earnedXp > 999999990) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Economía almacenada inválida."
    );
  }
  const previousRewards = user.claimedLevelRewards ?? [];
  if (!Array.isArray(previousRewards) || !previousRewards.every(
    (value) => Number.isSafeInteger(value) && value >= 2 && value <= 20
  )) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Historial de niveles inválido."
    );
  }
  const xpAwarded = 10; // Registro sin evidencia, no verificación visual.
  const xp = previousXp + xpAwarded;
  const before = levelForXp(previousXp);
  const level = levelForXp(xp);
  const claimed = new Set(previousRewards);
  let coinsAwarded = 0;
  for (let n = before + 1; n <= level; n++) {
    if (!claimed.has(n)) {
      claimed.add(n);
      coinsAwarded += LEVELS[n - 1][1];
    }
  }
  return Object.freeze({
    xpAwarded, xp, level, coinsAwarded,
    coins: coins + coinsAwarded,
    claimedLevelRewards: [...claimed].sort((a, b) => a - b),
    attemptXp: earnedXp + xpAwarded,
  });
}

function utcDay(date) {
  if (!(date instanceof Date) || !Number.isFinite(date.getTime())) {
    throw new TypeError("Fecha inválida.");
  }
  return date.toISOString().slice(0, 10);
}

async function registerDemoHabit({db, uid, data, now = new Date()}) {
  if (typeof uid !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  const ids = validateDemoRegistration(data);
  const catalog = SERVER_CATALOG[ids.habitId];
  const date = utcDay(now);
  const userRef = db.collection("users").doc(uid);
  const habitRef = userRef.collection("user_habits").doc(ids.habitId);
  const attemptRef = habitRef.collection("attempts").doc(ids.attemptId);
  const operationRef = userRef.collection("registration_operations")
    .doc(ids.operationId);
  const dayRef = attemptRef.collection("registration_days").doc(date);
  const logRef = attemptRef.collection("logs").doc(ids.operationId);

  return db.runTransaction(async (tx) => {
    // TODAS las lecturas van antes de las escrituras.
    const [operationSnap, userSnap, habitSnap, attemptSnap, daySnap] =
      await Promise.all([
        tx.get(operationRef), tx.get(userRef), tx.get(habitRef),
        tx.get(attemptRef), tx.get(dayRef),
      ]);
    if (operationSnap.exists) {
      const existing = operationSnap.data();
      if (existing.habitId !== ids.habitId ||
          existing.attemptId !== ids.attemptId) {
        throw new RegistrationPolicyError(
          "already-exists", "La operación ya pertenece a otro intento."
        );
      }
      return {...existing.result, alreadyProcessed: true};
    }
    if (!userSnap.exists || !habitSnap.exists || !attemptSnap.exists) {
      throw new RegistrationPolicyError("not-found", "Intento inexistente.");
    }
    const habit = habitSnap.data();
    const attempt = attemptSnap.data();
    const eligible = registrationEligibility({
      habit, attempt, attemptId: ids.attemptId,
    });
    if (attempt.target !== catalog.target ||
        habit.frequencyType !== catalog.frequencyType ||
        attempt.frequencyType !== catalog.frequencyType ||
        attempt.registrationsPerPeriod !== catalog.registrationsPerPeriod) {
      throw new RegistrationPolicyError(
        "failed-precondition", "La configuración no coincide con el catálogo."
      );
    }
    if (daySnap.exists) {
      throw new RegistrationPolicyError(
        "failed-precondition", "Ya registraste este hábito hoy (UTC)."
      );
    }
    const reward = calculateRegistrationReward({
      user: userSnap.data(), attempt, catalog,
    });
    const progress = eligible.currentProgress + 1;
    const completed = progress === catalog.target;
    const result = {
      habitId: ids.habitId, attemptId: ids.attemptId, progress,
      target: catalog.target, completed,
      xpAwarded: reward.xpAwarded,
      coinsAwarded: reward.coinsAwarded, level: reward.level,
      registrationDateUtc: date,
    };
    tx.create(dayRef, {
      operationId: ids.operationId, createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(logRef, {
      habitId: ids.habitId, attemptId: ids.attemptId,
      habitTitle: catalog.title, category: catalog.category,
      xpEarned: reward.xpAwarded, progressAfter: progress,
      goal: catalog.target, completed, hasEvidence: false,
      userId: uid, createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(attemptRef, {
      progress, xpEarned: reward.attemptXp,
      updatedAt: FieldValue.serverTimestamp(),
      ...(completed ? {
        status: "completed", completedAt: FieldValue.serverTimestamp(),
      } : {}),
    });
    tx.update(habitRef, {
      latestProgress: progress, latestTarget: catalog.target,
      latestStatus: completed ? "completed" : "inProgress",
      ...(completed ? {lastStatus: "completed"} : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(userRef, {
      xp: reward.xp, currentXp: reward.xp, level: reward.level,
      habitCoins: reward.coins,
      claimedLevelRewards: reward.claimedLevelRewards,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.create(operationRef, {
      habitId: ids.habitId, attemptId: ids.attemptId,
      result, createdAt: FieldValue.serverTimestamp(),
    });
    return {...result, alreadyProcessed: false};
  });
}

module.exports = {
  SERVER_CATALOG,
  LEVELS,
  validateDemoRegistration,
  calculateRegistrationReward,
  levelForXp,
  utcDay,
  registerDemoHabit,
};
