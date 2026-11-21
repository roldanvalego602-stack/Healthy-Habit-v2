"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const {RegistrationPolicyError} = require("./habit_registration_policy");
const {SERVER_CATALOG} = require("./official_habit_catalog");
const {levelForXp} = require("./habit_registration_transaction");
const {validateTimeZone, HabitCalendarError} =
  require("./habit_calendar_policy");

const PILOT_IDS = new Set(["hidr_001", "bien_007", "alim_004"]);
const ID = /^[A-Za-z0-9_-]{16,128}$/;
const USER_ID = /^[A-Za-z0-9_-]{1,128}$/;

function validateActivation(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new RegistrationPolicyError("invalid-argument", "Solicitud inválida.");
  }
  const {habitId, attemptId, operationId} = data;
  if (!PILOT_IDS.has(habitId)) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Hábito fuera del piloto de activación."
    );
  }
  if (typeof attemptId !== "string" || !ID.test(attemptId) ||
      typeof operationId !== "string" || !ID.test(operationId) ||
      Object.keys(data).some((name) => ![
        "habitId", "attemptId", "operationId",
      ].includes(name))) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Identificadores o campos de activación inválidos."
    );
  }
  return {habitId, attemptId, operationId};
}

function validateActivationState({
  user, activeCount, habit, previousAttempt, catalog, now,
}) {
  if (!user || !catalog) {
    throw new RegistrationPolicyError("not-found", "Perfil inexistente.");
  }
  const xp = user.xp ?? user.currentXp ?? 0;
  const coins = user.habitCoins ?? 0;
  const slots = user.habitSlots ?? 3;
  const version = user.habitMutationVersion ?? 0;
  if (![xp, coins, slots, version, activeCount].every((n) =>
    Number.isSafeInteger(n) && n >= 0) ||
    slots < 1 || slots > 100 || coins > 1000000000 ||
    xp > 1000000000 || version > 999999999) {
    throw new RegistrationPolicyError(
      "failed-precondition", "El perfil contiene valores inválidos."
    );
  }
  if (activeCount >= slots) {
    throw new RegistrationPolicyError(
      "resource-exhausted", "No hay espacios disponibles."
    );
  }
  if (levelForXp(xp) < catalog.requiredLevel) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Nivel insuficiente para desbloquear el hábito."
    );
  }
  if (coins < catalog.coinCost) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Habit Coins insuficientes."
    );
  }
  if (habit?.latestStatus === "inProgress" ||
      habit?.lastStatus === "inProgress" ||
      previousAttempt?.status === "inProgress") {
    throw new RegistrationPolicyError(
      "already-exists", "El hábito ya tiene un intento activo."
    );
  }
  if (habit?.lastStatus === "completed" && !catalog.repeatable) {
    throw new RegistrationPolicyError(
      "failed-precondition", "El hábito no se puede repetir."
    );
  }
  const available = previousAttempt?.availableAgainAt;
  if (available != null) {
    const availableDate = typeof available.toDate === "function" ?
      available.toDate() : available;
    if (!(availableDate instanceof Date) ||
        !Number.isFinite(availableDate.getTime())) {
      throw new RegistrationPolicyError(
        "failed-precondition", "Fecha de disponibilidad inválida."
      );
    }
    if (availableDate > now) {
      throw new RegistrationPolicyError(
        "failed-precondition", "El hábito sigue en periodo de espera."
      );
    }
  }
  const previousNumber = previousAttempt?.attemptNumber ?? 0;
  if (!Number.isSafeInteger(previousNumber) || previousNumber < 0 ||
      previousNumber >= 999999) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Secuencia de intentos inválida."
    );
  }
  return {
    coinsAfter: coins - catalog.coinCost,
    versionAfter: version + 1,
    attemptNumber: previousNumber + 1,
  };
}

async function activateDemoHabit({db, uid, data, now = new Date()}) {
  if (typeof uid !== "string" || !USER_ID.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  if (!(now instanceof Date) || !Number.isFinite(now.getTime())) {
    throw new RegistrationPolicyError("invalid-argument", "Fecha inválida.");
  }
  const {habitId, attemptId, operationId} = validateActivation(data);
  const catalog = SERVER_CATALOG[habitId];
  const userRef = db.collection("users").doc(uid);
  const habits = userRef.collection("user_habits");
  const habitRef = habits.doc(habitId);
  const attemptRef = habitRef.collection("attempts").doc(attemptId);
  const operationRef = userRef.collection("habit_activation_operations")
    .doc(operationId);

  return db.runTransaction(async (tx) => {
    // Todas las lecturas antes de escrituras; versión y consulta de activos
    // impiden que solicitudes concurrentes superen los espacios.
    const [operationSnap, userSnap, habitSnap, attemptSnap, activeSnap] =
      await Promise.all([
        tx.get(operationRef), tx.get(userRef), tx.get(habitRef),
        tx.get(attemptRef),
        tx.get(habits.where("latestStatus", "==", "inProgress")),
      ]);
    if (operationSnap.exists) {
      const saved = operationSnap.data();
      if (saved.habitId !== habitId || saved.attemptId !== attemptId) {
        throw new RegistrationPolicyError(
          "already-exists", "Esta operación pertenece a otro intento."
        );
      }
      return {...saved.result, alreadyProcessed: true};
    }
    if (!userSnap.exists) {
      throw new RegistrationPolicyError("not-found", "Perfil inexistente.");
    }
    if (attemptSnap.exists) {
      throw new RegistrationPolicyError(
        "already-exists", "El identificador del intento ya existe."
      );
    }
    const user = userSnap.data();
    const habit = habitSnap.exists ? habitSnap.data() : null;
    const previousId = habit?.lastAttemptId ?? null;
    if (previousId != null &&
        (typeof previousId !== "string" ||
         !/^[A-Za-z0-9_-]{1,128}$/.test(previousId))) {
      throw new RegistrationPolicyError(
        "failed-precondition", "Referencia a intento anterior inválida."
      );
    }
    if (previousId === attemptId) {
      throw new RegistrationPolicyError(
        "already-exists", "No se puede reutilizar un intento anterior."
      );
    }
    const previousSnap = previousId ?
      await tx.get(habitRef.collection("attempts").doc(previousId)) : null;
    if (previousId && !previousSnap.exists) {
      throw new RegistrationPolicyError(
        "failed-precondition", "Falta el intento anterior."
      );
    }
    const validated = validateActivationState({
      user, activeCount: activeSnap.size, habit,
      previousAttempt: previousSnap?.data() ?? null,
      catalog, now,
    });
    const timeZone = habitId === "hidr_001" ? "UTC" :
      (user.calendarTimeZone ?? "UTC");
    try {
      validateTimeZone(timeZone);
    } catch (error) {
      if (error instanceof HabitCalendarError) {
        throw new RegistrationPolicyError(
          "failed-precondition", error.message
        );
      }
      throw error;
    }
    if (habitId === "hidr_001" && user.calendarTimeZone &&
        user.calendarTimeZone !== "UTC") {
      throw new RegistrationPolicyError(
        "failed-precondition", "El piloto heredado requiere UTC."
      );
    }
    if (habit?.calendarTimeZone != null &&
        habit.calendarTimeZone !== timeZone) {
      throw new RegistrationPolicyError(
        "failed-precondition", "El hábito conserva otra zona horaria."
      );
    }
    const result = {
      habitId, attemptId, operationId, attemptNumber: validated.attemptNumber,
      timeZone, chargedCoins: catalog.coinCost,
    };
    tx.update(userRef, {
      habitCoins: validated.coinsAfter,
      habitMutationVersion: validated.versionAfter,
      ...(habitId !== "hidr_001" ? {calendarTimeZone: timeZone} : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(habitRef, {
      ...catalog, acquiredAt: FieldValue.serverTimestamp(),
      lastAttemptId: attemptId, latestAttemptId: attemptId,
      lastStatus: "inProgress", latestStatus: "inProgress",
      latestProgress: 0, latestTarget: catalog.target,
      ...(habitId !== "hidr_001" ? {calendarTimeZone: timeZone} : {}),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    tx.create(attemptRef, {
      habitId, status: "inProgress", progress: 0, target: catalog.target,
      attemptNumber: validated.attemptNumber, xpEarned: 0,
      acquiredAt: FieldValue.serverTimestamp(),
      frequencyType: catalog.frequencyType,
      registrationsPerPeriod: catalog.registrationsPerPeriod,
      durationPeriods: catalog.durationPeriods,
      gracePeriods: catalog.gracePeriods, streakEnabled: true,
      periodProgress: 0, streak: 0, longestStreak: 0,
      missedPeriods: 0, pendingRecoveries: 0,
      periodStreak: 0,
      ...(habitId !== "hidr_001" ? {calendarTimeZone: timeZone} : {}),
    });
    tx.create(operationRef, {
      habitId, attemptId, result,
      createdAt: FieldValue.serverTimestamp(),
    });
    return {...result, alreadyProcessed: false};
  });
}

module.exports = {
  validateActivation,
  validateActivationState,
  activateDemoHabit,
};
