"use strict";

// Segunda barrera independiente: una beta habilitada NO habilita fotos
// automáticamente. Tanto la app como el servidor deben estar autorizados.
const {RegistrationPolicyError} = require("./habit_registration_policy");
const {requireBetaHabitAccess, PRODUCTION_PROJECT} =
  require("./official_beta_access");

function requireBetaEvidenceAccess(request, env = process.env) {
  const uid = requireBetaHabitAccess(request, env);
  if (env.HH_BETA_EVIDENCE_ENABLED !== "true") {
    throw new RegistrationPolicyError("failed-precondition",
      "La recepción de evidencias aún no está habilitada.");
  }
  if ((env.GCLOUD_PROJECT || env.GCP_PROJECT) !== PRODUCTION_PROJECT) {
    throw new RegistrationPolicyError("failed-precondition",
      "Proyecto de evidencias no autorizado.");
  }
  return uid;
}

// Nunca aceptar bucket, ruta, UID o importes desde el cliente.
function evidenceBucketName(projectId) {
  if (projectId !== PRODUCTION_PROJECT) {
    throw new RegistrationPolicyError("failed-precondition",
      "Bucket de evidencias no autorizado.");
  }
  return PRODUCTION_PROJECT + ".firebasestorage.app";
}

module.exports = {requireBetaEvidenceAccess, evidenceBucketName};
