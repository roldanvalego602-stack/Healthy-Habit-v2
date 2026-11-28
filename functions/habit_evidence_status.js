"use strict";
const {RegistrationPolicyError} = require("./habit_registration_policy");
const {SERVER_CATALOG} = require("./official_habit_catalog");

const ID = /^[A-Za-z0-9_-]{16,128}$/;
const UID = /^[A-Za-z0-9_-]{1,128}$/;

function validateEvidenceIdentity({uid, data}) {
  if (typeof uid !== "string" || !UID.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  if (!data || typeof data !== "object" || Array.isArray(data) ||
      Object.keys(data).sort().join(",") !==
        "attemptId,habitId,operationId" ||
      typeof data.habitId !== "string" ||
      !Object.hasOwn(SERVER_CATALOG, data.habitId) ||
      typeof data.attemptId !== "string" || !ID.test(data.attemptId) ||
      typeof data.operationId !== "string" || !ID.test(data.operationId)) {
    throw new RegistrationPolicyError("invalid-argument",
      "Identificadores de evidencia inválidos.");
  }
  return data;
}

// Respuesta de recuperación sin leer/descargar la foto. No dice que el
// usuario haya consumido alimentos: solo que existe un vínculo oficial.
async function getEvidenceStatus({db, uid, data, now = new Date()}) {
  const ids = validateEvidenceIdentity({uid, data});
  const user = db.collection("users").doc(uid);
  const ref = user.collection("habit_evidence_reservations")
    .doc(ids.operationId);
  const record = await ref.get();
  if (!record.exists) {
    return {status: "not_reserved", attached: false, contentVerified: false};
  }
  const reservation = record.data();
  if (reservation.uid !== uid ||
      reservation.habitId !== ids.habitId ||
      reservation.attemptId !== ids.attemptId ||
      reservation.operationId !== ids.operationId ||
      reservation.storagePath !==
        `habit-evidence/${uid}/${ids.attemptId}/${ids.operationId}`) {
    throw new RegistrationPolicyError("permission-denied",
      "La reserva no pertenece a este registro.");
  }
  const raw = reservation.status;
  if (!["pending", "uploading", "recovering", "uploaded", "attached"]
    .includes(raw)) {
    throw new RegistrationPolicyError("failed-precondition",
      "La reserva tiene un estado inválido.");
  }
  const expires = reservation.expiresAt?.toMillis?.();
  if (typeof expires !== "number" || !Number.isFinite(expires)) {
    throw new RegistrationPolicyError("failed-precondition",
      "La reserva carece de caducidad válida.");
  }
  if (raw !== "attached" && expires <= now.getTime()) {
    return {status: "expired", attached: false, contentVerified: false};
  }
  if (raw === "attached") {
    const log = await user.collection("user_habits").doc(ids.habitId)
      .collection("attempts").doc(ids.attemptId)
      .collection("logs").doc(ids.operationId).get();
    if (!log.exists ||
        log.data().userId !== uid ||
        log.data().evidencePath !== reservation.storagePath) {
      throw new RegistrationPolicyError("failed-precondition",
        "El vínculo de evidencia requiere revisión.");
    }
  }
  return {status: raw, attached: raw === "attached",
    contentVerified: false};
}

module.exports = {validateEvidenceIdentity, getEvidenceStatus};
