"use strict";

const {Timestamp, FieldValue} = require("firebase-admin/firestore");
const {RegistrationPolicyError} = require("./habit_registration_policy");
const {SERVER_CATALOG} = require("./official_habit_catalog");

const ID = /^[A-Za-z0-9_-]{16,128}$/;
const HABIT = /^(?:alim|hidr|ener|bien)_00[1-9]$/;
const RESERVATION_MS = 60 * 60 * 1000;

// Solo Admin SDK y laboratorio. NO acredita XP ni registra un hábito.
async function reserveHabitEvidence({
  db, uid, data, now = new Date(), dailyQuota = null,
}) {
  if (typeof uid !== "string" || !ID.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  if (!data || typeof data !== "object" || Array.isArray(data) ||
      Object.keys(data).some((key) =>
        !["habitId", "attemptId", "operationId"].includes(key)) ||
      typeof data.habitId !== "string" || !HABIT.test(data.habitId) ||
      !Object.hasOwn(SERVER_CATALOG, data.habitId) ||
      typeof data.attemptId !== "string" || !ID.test(data.attemptId) ||
      typeof data.operationId !== "string" || !ID.test(data.operationId)) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Identificadores de reserva inválidos."
    );
  }
  if (!(now instanceof Date) || !Number.isFinite(now.getTime())) {
    throw new TypeError("Fecha del servidor inválida.");
  }

  if (dailyQuota !== null &&
      (!Number.isSafeInteger(dailyQuota) || dailyQuota < 1 ||
       dailyQuota > 30)) {
    throw new TypeError("Cuota de fotos inválida.");
  }
  const userRef = db.collection("users").doc(uid);
  const habitRef = userRef.collection("user_habits").doc(data.habitId);
  const attemptRef = habitRef.collection("attempts").doc(data.attemptId);
  const reservationRef = userRef.collection("habit_evidence_reservations")
    .doc(data.operationId);
  const operationRef = userRef.collection("registration_operations")
    .doc(data.operationId);
  const quotaRef = dailyQuota === null ? null :
    userRef.collection("habit_evidence_daily_limits")
      .doc(now.toISOString().slice(0, 10));
  const path = `habit-evidence/${uid}/${data.attemptId}/${data.operationId}`;

  return db.runTransaction(async (tx) => {
    const [reservation, operation, user, habit, attempt, quotaSnap] =
      await Promise.all([
        tx.get(reservationRef), tx.get(operationRef),
        tx.get(userRef), tx.get(habitRef), tx.get(attemptRef),
        quotaRef ? tx.get(quotaRef) : Promise.resolve(null),
      ]);
    if (reservation.exists) {
      const saved = reservation.data();
      if (saved.uid !== uid || saved.habitId !== data.habitId ||
          saved.attemptId !== data.attemptId ||
          saved.operationId !== data.operationId || saved.storagePath !== path) {
        throw new RegistrationPolicyError(
          "already-exists", "La reserva pertenece a otra operación."
        );
      }
      const expiration = saved.expiresAt?.toMillis?.();
      if (typeof expiration !== "number" || expiration <= now.getTime()) {
        throw new RegistrationPolicyError(
          "failed-precondition", "La reserva ha expirado."
        );
      }
      return {
        storagePath: path,
        operationId: data.operationId,
        expiresAt: saved.expiresAt.toDate().toISOString(),
        alreadyReserved: true,
      };
    }
    if (operation.exists) {
      throw new RegistrationPolicyError(
        "failed-precondition", "El registro ya fue procesado."
      );
    }
    if (!user.exists || !habit.exists || !attempt.exists) {
      throw new RegistrationPolicyError("not-found", "Intento inexistente.");
    }
    const h = habit.data();
    const a = attempt.data();
    if (a.habitId !== data.habitId ||
        a.status !== "inProgress" || h.latestAttemptId !== data.attemptId ||
        h.latestStatus !== "inProgress") {
      throw new RegistrationPolicyError(
        "failed-precondition", "El intento ya no está activo."
      );
    }
    const count = quotaSnap?.exists ? quotaSnap.data().count : 0;
    if (quotaRef && (!Number.isSafeInteger(count) ||
        count < 0 || count >= dailyQuota)) {
      throw new RegistrationPolicyError("resource-exhausted",
        "Límite diario de fotos de beta alcanzado.");
    }
    const expiresAt = Timestamp.fromMillis(now.getTime() + RESERVATION_MS);
    tx.create(reservationRef, {
      uid, habitId: data.habitId, attemptId: data.attemptId,
      operationId: data.operationId, storagePath: path,
      status: "pending", createdAt: FieldValue.serverTimestamp(),
      expiresAt,
    });
    if (quotaRef) {
      tx.set(quotaRef, {count:count+1,
        lastOperationId:data.operationId,
        updatedAt:FieldValue.serverTimestamp()}, {merge:true});
    }
    return {
      storagePath: path,
      operationId: data.operationId,
      expiresAt: expiresAt.toDate().toISOString(),
      alreadyReserved: false,
    };
  });
}

module.exports = {reserveHabitEvidence, RESERVATION_MS};
