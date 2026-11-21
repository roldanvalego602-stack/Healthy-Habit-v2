"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const {validateRegistrationRequest, RegistrationPolicyError} =
  require("./habit_registration_policy");
const {registrationEligibility} = require("./habit_registration_policy");
const {SERVER_CATALOG} = require("./official_habit_catalog");
const {validateTimeZone, HabitCalendarError} =
  require("./habit_calendar_policy");

// Solo para ensayos con calendarios locales en el emulador.
// hidr_001 conserva el calendario UTC y las marcas diarias históricas.
const LOCAL_CALENDAR_PILOTS = new Set(["bien_007", "alim_004"]);

function validateCalendarLockRequest(data) {
  const ids = validateRegistrationRequest(data);
  if (!LOCAL_CALENDAR_PILOTS.has(ids.habitId)) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Este hábito no admite cambiar su calendario."
    );
  }
  if (Object.keys(data).some((key) =>
    !["habitId", "attemptId", "timeZone"].includes(key))) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Campos no permitidos en la configuración."
    );
  }
  try {
    validateTimeZone(data.timeZone);
  } catch (error) {
    if (error instanceof HabitCalendarError) {
      throw new RegistrationPolicyError("invalid-argument", error.message);
    }
    throw error;
  }
  return {...ids, timeZone: data.timeZone};
}

async function lockDemoHabitCalendar({db, uid, data}) {
  if (typeof uid !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  const {habitId, attemptId, timeZone} = validateCalendarLockRequest(data);
  const userRef = db.collection("users").doc(uid);
  const habitRef = userRef.collection("user_habits").doc(habitId);
  const attemptRef = habitRef.collection("attempts").doc(attemptId);

  return db.runTransaction(async (tx) => {
    const [userSnap, habitSnap, attemptSnap] = await Promise.all([
      tx.get(userRef), tx.get(habitRef), tx.get(attemptRef),
    ]);
    if (!userSnap.exists || !habitSnap.exists || !attemptSnap.exists) {
      throw new RegistrationPolicyError("not-found", "Intento inexistente.");
    }
    const user = userSnap.data();
    const habit = habitSnap.data();
    const attempt = attemptSnap.data();
    registrationEligibility({habit, attempt, attemptId});

    const existingZones = [
      user.calendarTimeZone, habit.calendarTimeZone,
      attempt.calendarTimeZone,
    ].filter((zone) => zone !== undefined && zone !== null);
    if (existingZones.some((zone) => zone !== timeZone)) {
      throw new RegistrationPolicyError(
        "failed-precondition", "El calendario ya está fijado en otra zona."
      );
    }

    // Repetir el mismo bloqueo no modifica la configuración.
    if (existingZones.length === 3) {
      return {habitId, attemptId, timeZone, alreadyConfigured: true};
    }

    // No migrar intentos con avances: podrían tener registros históricos
    // en periodos UTC que se cobrarían otra vez con otra clave local.
    if (attempt.progress !== 0 || (attempt.xpEarned ?? 0) !== 0 ||
        (attempt.periodStreak ?? 0) !== 0 ||
        attempt.lastCompletedPeriod != null ||
        attempt.gracePeriodsUsed != null) {
      throw new RegistrationPolicyError(
        "failed-precondition", "El intento ya tiene historial; no se migra."
      );
    }
    const catalog = SERVER_CATALOG[habitId];
    if (attempt.target !== catalog.target ||
        habit.frequencyType !== catalog.frequencyType ||
        attempt.frequencyType !== catalog.frequencyType ||
        attempt.registrationsPerPeriod !== catalog.registrationsPerPeriod) {
      throw new RegistrationPolicyError(
        "failed-precondition", "La configuración no coincide con el catálogo."
      );
    }

    tx.update(userRef, {
      calendarTimeZone: timeZone,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(habitRef, {
      calendarTimeZone: timeZone,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(attemptRef, {
      calendarTimeZone: timeZone,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return {habitId, attemptId, timeZone, alreadyConfigured: false};
  });
}

module.exports = {
  LOCAL_CALENDAR_PILOTS,
  validateCalendarLockRequest,
  lockDemoHabitCalendar,
};
