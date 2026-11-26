"use strict";

// Contrato compartido para la futura migración a operaciones oficiales.
// No expone Cloud Functions ni habilita rutas de producción por sí mismo.
const {RegistrationPolicyError} = require("./habit_registration_policy");

const ALLOWED_ACTIONS = Object.freeze({
  activate: "activateOfficialHabitTransaction",
  cancel: "cancelOfficialHabitTransaction",
  register: "registerOfficialHabitTransaction",
});

function assertOfficialRequest({action, uid, data}) {
  if (!Object.hasOwn(ALLOWED_ACTIONS, action)) {
    throw new RegistrationPolicyError("invalid-argument", "Operación no admitida.");
  }
  if (typeof uid !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Inicia sesión.");
  }
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new RegistrationPolicyError("invalid-argument", "Solicitud inválida.");
  }
  if (typeof data.habitId !== "string" ||
      typeof data.attemptId !== "string" ||
      typeof data.operationId !== "string") {
    throw new RegistrationPolicyError(
      "invalid-argument", "Faltan identificadores de operación."
    );
  }
  // No confiar en valores económicos proporcionados por clientes.
  const forbidden = ["xp", "xpAwarded", "habitCoins", "coinsAwarded",
    "level", "progress", "rewardCoins", "evidenceVerified"];
  if (forbidden.some((key) => Object.hasOwn(data, key))) {
    throw new RegistrationPolicyError(
      "invalid-argument", "La solicitud contiene datos económicos no autorizados."
    );
  }
  return {uid, data};
}

function createOfficialHabitDispatcher({activate, cancel, register}) {
  if (![activate, cancel, register].every((fn) => typeof fn === "function")) {
    throw new TypeError("Faltan transacciones oficiales.");
  }
  const operations = {activate, cancel, register};
  return async function dispatch({action, db, uid, data}) {
    if (!db || typeof db.runTransaction !== "function") {
      throw new TypeError("Se requiere Firestore de servidor.");
    }
    const validated = assertOfficialRequest({action, uid, data});
    return operations[action]({db, ...validated});
  };
}

module.exports = {ALLOWED_ACTIONS, assertOfficialRequest, createOfficialHabitDispatcher};
