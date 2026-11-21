"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const {RegistrationPolicyError} = require("./habit_registration_policy");
const {SERVER_CATALOG} = require("./official_habit_catalog");

const PILOT_IDS = new Set(["hidr_001", "bien_007", "alim_004"]);
const ID = /^[A-Za-z0-9_-]{16,128}$/;
const USER_ID = /^[A-Za-z0-9_-]{1,128}$/;
const MAX_DIFFICULT_PENALTY = 25;

function validateCancellation(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new RegistrationPolicyError("invalid-argument", "Solicitud inválida.");
  }
  const {habitId, attemptId, operationId, maxPenalty} = data;
  if (!PILOT_IDS.has(habitId)) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Hábito fuera del piloto de cancelación."
    );
  }
  if (typeof attemptId !== "string" || !ID.test(attemptId) ||
      typeof operationId !== "string" || !ID.test(operationId) ||
      !Number.isSafeInteger(maxPenalty) || maxPenalty < 0 ||
      maxPenalty > MAX_DIFFICULT_PENALTY ||
      Object.keys(data).some((name) =>
        !["habitId", "attemptId", "operationId", "maxPenalty"].includes(name))) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Identificadores o límite de cobro inválidos."
    );
  }
  return {habitId, attemptId, operationId, maxPenalty};
}

function calculateCancellation({user, habit, attempt, catalog, attemptId,
  maxPenalty}) {
  if (!user || !habit || !attempt || !catalog) {
    throw new RegistrationPolicyError("not-found", "Intento inexistente.");
  }
  if (habit.latestAttemptId !== attemptId ||
      habit.lastAttemptId !== attemptId ||
      habit.latestStatus !== "inProgress" ||
      habit.lastStatus !== "inProgress" ||
      attempt.status !== "inProgress") {
    throw new RegistrationPolicyError(
      "failed-precondition", "El intento ya no está activo."
    );
  }
  const balance = user.habitCoins ?? 0;
  const version = user.habitMutationVersion ?? 0;
  if (![balance, version].every((value) =>
    Number.isSafeInteger(value) && value >= 0) ||
    balance > 1000000000 || version >= 999999999) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Economía o versión inválidas."
    );
  }
  const penalty = catalog.difficulty === "Difícil" ?
    Math.min(balance, MAX_DIFFICULT_PENALTY) : 0;
  if (penalty > maxPenalty) {
    throw new RegistrationPolicyError(
      "failed-precondition", "La penalización excede lo confirmado."
    );
  }
  return {
    penalty, balanceAfter: balance - penalty,
    versionAfter: version + 1,
  };
}

async function cancelDemoHabit({db, uid, data}) {
  if (typeof uid !== "string" || !USER_ID.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  const ids = validateCancellation(data);
  const catalog = SERVER_CATALOG[ids.habitId];
  const userRef = db.collection("users").doc(uid);
  const habitRef = userRef.collection("user_habits").doc(ids.habitId);
  const attemptRef = habitRef.collection("attempts").doc(ids.attemptId);
  const operationRef = userRef.collection("habit_cancellation_operations")
    .doc(ids.operationId);

  return db.runTransaction(async (tx) => {
    const [operationSnap, userSnap, habitSnap, attemptSnap] =
      await Promise.all([
        tx.get(operationRef), tx.get(userRef), tx.get(habitRef),
        tx.get(attemptRef),
      ]);
    if (operationSnap.exists) {
      const saved = operationSnap.data();
      if (saved.habitId !== ids.habitId ||
          saved.attemptId !== ids.attemptId ||
          saved.maxPenalty !== ids.maxPenalty) {
        throw new RegistrationPolicyError(
          "already-exists", "El ID pertenece a otra cancelación."
        );
      }
      return {...saved.result, alreadyProcessed: true};
    }
    if (!userSnap.exists || !habitSnap.exists || !attemptSnap.exists) {
      throw new RegistrationPolicyError("not-found", "Intento inexistente.");
    }
    const outcome = calculateCancellation({
      user: userSnap.data(), habit: habitSnap.data(),
      attempt: attemptSnap.data(), catalog, attemptId: ids.attemptId,
      maxPenalty: ids.maxPenalty,
    });
    const result = {
      habitId: ids.habitId, attemptId: ids.attemptId,
      chargedCoins: outcome.penalty, balanceAfter: outcome.balanceAfter,
    };
    tx.update(attemptRef, {
      status: "cancelled", cancellationPenalty: outcome.penalty,
      cancelledAt: FieldValue.serverTimestamp(),
    });
    tx.update(habitRef, {
      latestStatus: "cancelled", lastStatus: "cancelled",
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(userRef, {
      habitCoins: outcome.balanceAfter,
      habitMutationVersion: outcome.versionAfter,
      ...(outcome.penalty > 0 ? {habitCancellation: {
        habitId: ids.habitId, attemptId: ids.attemptId,
        version: outcome.versionAfter,
      }} : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.create(operationRef, {
      habitId: ids.habitId, attemptId: ids.attemptId,
      maxPenalty: ids.maxPenalty, result,
      createdAt: FieldValue.serverTimestamp(),
    });
    return {...result, alreadyProcessed: false};
  });
}

module.exports = {
  MAX_DIFFICULT_PENALTY,
  validateCancellation,
  calculateCancellation,
  cancelDemoHabit,
};
