"use strict";
function betaEvidenceCleanupReady(env = process.env) {
  const project = env.GCLOUD_PROJECT || env.GCP_PROJECT;
  return project === "cloud-firestore-d8c61" &&
    env.HH_BETA_HABITS_ENABLED === "true" &&
    env.HH_BETA_RULES_VERIFIED === "true" &&
    env.HH_BETA_EVIDENCE_ENABLED === "true" &&
    env.HH_BETA_EVIDENCE_CLEANUP_ENABLED === "true" &&
    !env.FIRESTORE_EMULATOR_HOST &&
    !env.FIREBASE_STORAGE_EMULATOR_HOST;
}
module.exports = {betaEvidenceCleanupReady};
