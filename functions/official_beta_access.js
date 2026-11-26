"use strict";

// Puerta de acceso de beta cerrada para las transacciones autoritativas.
// NO modifica Firestore Rules; sin habilitación explícita permanece cerrada.
// El acceso a estas funciones exige App Check, Auth y UID permitido.
const {RegistrationPolicyError} = require("./habit_registration_policy");

const PRODUCTION_PROJECT = "cloud-firestore-d8c61";
const ID = /^[A-Za-z0-9_-]{1,128}$/;

function requireBetaHabitAccess(request, env = process.env) {
  const projectId = env.GCLOUD_PROJECT || env.GCP_PROJECT;
  if (projectId !== PRODUCTION_PROJECT ||
      env.HH_BETA_HABITS_ENABLED !== "true" ||
      env.HH_BETA_RULES_VERIFIED !== "true") {
    throw new RegistrationPolicyError(
      "failed-precondition",
      "Las operaciones oficiales de beta no están habilitadas."
    );
  }
  const uid = request?.auth?.uid;
  if (typeof uid !== "string" || !ID.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Inicia sesión.");
  }
  // La configuración onCall exige enforceAppCheck:true; comprobar aquí
  // también evita llamadas de pruebas o adaptadores que omitan el control.
  if (typeof request?.app?.appId !== "string" ||
      request.app.appId.length === 0) {
    throw new RegistrationPolicyError(
      "permission-denied", "Esta aplicación no está verificada."
    );
  }
  const allowed = (env.HH_BETA_TEST_UIDS || "")
    .split(",").map((value) => value.trim()).filter(Boolean);
  if (!allowed.includes(uid)) {
    throw new RegistrationPolicyError(
      "permission-denied", "Cuenta no autorizada para la beta cerrada."
    );
  }
  return uid;
}

function createBetaHabitHandler({dispatch, action, env = process.env}) {
  if (typeof dispatch !== "function" ||
      !["activate", "cancel", "register"].includes(action)) {
    throw new TypeError("Operación de beta no válida.");
  }
  return async function handle({request, db}) {
    const uid = requireBetaHabitAccess(request, env);
    return dispatch({action, db, uid, data: request.data});
  };
}

module.exports = {requireBetaHabitAccess, createBetaHabitHandler, PRODUCTION_PROJECT};
