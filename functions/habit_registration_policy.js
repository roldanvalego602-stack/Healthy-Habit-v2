"use strict";

// Solo catálogo oficial: no permite rutas arbitrarias ni IDs de documentos
// usados para acceder a otros usuarios.
const OFFICIAL_ID = /^(?:alim|hidr|ener|bien)_00[1-9]$/;
const DOCUMENT_ID = /^[A-Za-z0-9_-]{1,128}$/;

class RegistrationPolicyError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "RegistrationPolicyError";
    this.code = code;
  }
}

function validateRegistrationRequest(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new RegistrationPolicyError("invalid-argument", "Solicitud inválida.");
  }
  const {habitId, attemptId} = data;
  if (typeof habitId !== "string" || !OFFICIAL_ID.test(habitId)) {
    throw new RegistrationPolicyError(
      "invalid-argument", "El hábito no es oficial."
    );
  }
  if (typeof attemptId !== "string" || !DOCUMENT_ID.test(attemptId)) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Identificador de intento inválido."
    );
  }
  return {habitId, attemptId};
}

function registrationEligibility({habit, attempt, attemptId}) {
  // Los datos se leen de Firestore mediante Firebase Admin; no de la
  // solicitud del usuario. Esto NO verifica que se realizó la actividad.
  if (!habit || !attempt) {
    throw new RegistrationPolicyError("not-found", "Intento inexistente.");
  }
  const latestId = habit.latestAttemptId ?? habit.lastAttemptId;
  if (latestId !== attemptId ||
      habit.latestStatus !== "inProgress" ||
      attempt.status !== "inProgress") {
    throw new RegistrationPolicyError(
      "failed-precondition", "El intento ya no está activo."
    );
  }
  const {progress, target} = attempt;
  if (!Number.isSafeInteger(progress) || progress < 0 ||
      !Number.isSafeInteger(target) || target < 1 || target > 1000000) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Progreso almacenado inválido."
    );
  }
  if (progress >= target) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Este intento ya alcanzó su objetivo."
    );
  }
  return Object.freeze({
    eligible: true,
    currentProgress: progress,
    target,
    remaining: target - progress,
    nextCompletes: progress + 1 >= target,
  });
}

module.exports = {
  validateRegistrationRequest,
  registrationEligibility,
  RegistrationPolicyError,
};
