"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const {RegistrationPolicyError} = require("./habit_registration_policy");

const ID = /^[A-Za-z0-9_-]{16,128}$/;
const HABIT = /^(?:alim|hidr|ener|bien)_00[1-9]$/;
const MAX_SIZE = 250 * 1024;

function validImage(buffer, mime) {
  if (!Buffer.isBuffer(buffer) || buffer.length < 12 ||
      buffer.length > MAX_SIZE) return false;
  if (mime === "image/jpeg") {
    return buffer[0] === 0xff && buffer[1] === 0xd8 &&
      buffer[2] === 0xff && buffer[buffer.length - 2] === 0xff &&
      buffer[buffer.length - 1] === 0xd9;
  }
  if (mime === "image/png") {
    return buffer.subarray(0, 8).equals(
      Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])
    ) && buffer.subarray(buffer.length - 8, buffer.length - 4)
      .equals(Buffer.from("IEND"));
  }
  if (mime === "image/webp") {
    return buffer.subarray(0, 4).toString() === "RIFF" &&
      buffer.subarray(8, 12).toString() === "WEBP";
  }
  return false;
}

// Vincula una imagen privada ya subida a un registro confirmado.
// Nunca modifica el saldo, el XP, el progreso ni la verificación del hábito.
async function attachHabitEvidence({db, bucket, uid, data, now = new Date()}) {
  if (typeof uid !== "string" || !ID.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  if (!data || typeof data !== "object" || Array.isArray(data) ||
      Object.keys(data).some((key) =>
        !["habitId", "attemptId", "operationId"].includes(key)) ||
      typeof data.habitId !== "string" || !HABIT.test(data.habitId) ||
      typeof data.attemptId !== "string" || !ID.test(data.attemptId) ||
      typeof data.operationId !== "string" || !ID.test(data.operationId)) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Identificadores de evidencia inválidos."
    );
  }
  if (!(now instanceof Date) || !Number.isFinite(now.getTime())) {
    throw new TypeError("Fecha inválida.");
  }
  const userRef = db.collection("users").doc(uid);
  const reservationRef = userRef.collection("habit_evidence_reservations")
    .doc(data.operationId);
  const operationRef = userRef.collection("registration_operations")
    .doc(data.operationId);
  const logRef = userRef.collection("user_habits").doc(data.habitId)
    .collection("attempts").doc(data.attemptId)
    .collection("logs").doc(data.operationId);
  const path = `habit-evidence/${uid}/${data.attemptId}/${data.operationId}`;

  const [reservationSnap, operationSnap, logSnap] = await Promise.all([
    reservationRef.get(), operationRef.get(), logRef.get(),
  ]);
  if (!reservationSnap.exists || !operationSnap.exists || !logSnap.exists) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Reserva y registro confirmado obligatorios."
    );
  }
  const reservation = reservationSnap.data();
  const operation = operationSnap.data();
  if (reservation.uid !== uid || reservation.habitId !== data.habitId ||
      reservation.attemptId !== data.attemptId ||
      reservation.operationId !== data.operationId ||
      reservation.storagePath !== path ||
      operation.habitId !== data.habitId ||
      operation.attemptId !== data.attemptId ||
      logSnap.data().userId !== uid) {
    throw new RegistrationPolicyError(
      "permission-denied", "La evidencia no pertenece al registro."
    );
  }
  if (reservation.status === "attached" &&
      logSnap.data().evidencePath === path) {
    return {attached: true, alreadyAttached: true, verified: false};
  }
  if (reservation.status !== "pending" ||
      !reservation.expiresAt?.toMillis ||
      reservation.expiresAt.toMillis() <= now.getTime()) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Reserva vencida o cerrada."
    );
  }

  // El servidor, no el cliente, inspecciona el objeto que realmente existe.
  const file = bucket.file(path);
  let metadata, bytes;
  try {
    [metadata] = await file.getMetadata();
    [bytes] = await file.download();
  } catch (error) {
    if (error.code === 404) {
      throw new RegistrationPolicyError("not-found", "Imagen no encontrada.");
    }
    throw error;
  }
  const mime = metadata.contentType;
  const bytesReported = Number(metadata.size);
  if (!["image/jpeg", "image/png", "image/webp"].includes(mime) ||
      !Number.isSafeInteger(bytesReported) ||
      bytesReported !== bytes.length || !validImage(bytes, mime)) {
    throw new RegistrationPolicyError(
      "invalid-argument", "La imagen no coincide con su tipo o tamaño."
    );
  }

  return db.runTransaction(async (tx) => {
    const [reservationCurrent, logCurrent, operationCurrent] =
      await Promise.all([
        tx.get(reservationRef), tx.get(logRef), tx.get(operationRef),
      ]);
    if (!reservationCurrent.exists || !logCurrent.exists ||
        !operationCurrent.exists) {
      throw new RegistrationPolicyError(
        "failed-precondition", "La reserva o el registro desaparecieron."
      );
    }
    const stored = reservationCurrent.data();
    const log = logCurrent.data();
    const op = operationCurrent.data();
    if (stored.uid !== uid || stored.habitId !== data.habitId ||
        stored.attemptId !== data.attemptId ||
        stored.operationId !== data.operationId ||
        stored.storagePath !== path ||
        op.habitId !== data.habitId || op.attemptId !== data.attemptId ||
        log.userId !== uid) {
      throw new RegistrationPolicyError(
        "permission-denied", "La relación de evidencia cambió."
      );
    }
    if (stored.status === "attached" && log.evidencePath === path) {
      return {attached: true, alreadyAttached: true, verified: false};
    }
    if (stored.status !== "pending" || log.hasEvidence === true ||
        !stored.expiresAt?.toMillis ||
        stored.expiresAt.toMillis() <= now.getTime()) {
      throw new RegistrationPolicyError(
        "failed-precondition", "Reserva expirada o evidencia ya vinculada."
      );
    }
    tx.update(logRef, {
      hasEvidence: true, evidencePath: path, evidenceContentType: mime,
      evidenceSize: bytesReported, evidenceVerified: false,
      evidenceExpiresAt: stored.expiresAt,
      evidenceAttachedAt: FieldValue.serverTimestamp(),
    });
    tx.update(reservationRef, {
      status: "attached", attachedAt: FieldValue.serverTimestamp(),
    });
    return {attached: true, alreadyAttached: false, verified: false};
  });
}

module.exports = {attachHabitEvidence, validImage};
