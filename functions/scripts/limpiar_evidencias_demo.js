"use strict";

// Ejecución manual de limpieza para el laboratorio aislado.
// El procedimiento puede programarse más adelante después de revisar
// permisos de producción, cuota y retención.
if (process.env.GCLOUD_PROJECT !== "demo-healthy-habit" ||
    !process.env.FIRESTORE_EMULATOR_HOST ||
    !process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
  throw new Error("Prohibido ejecutar la limpieza fuera del emulador demo.");
}
const {initializeApp, deleteApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {purgeExpiredEvidence} = require("../habit_evidence_cleanup");

(async () => {
  const app = initializeApp({
    projectId: "demo-healthy-habit",
    storageBucket: "demo-healthy-habit.firebasestorage.app",
  }, "cleanup-evidence-demo");
  try {
    const db = getFirestore(app, "default");
    const bucket = getStorage(app).bucket(
      "demo-healthy-habit.firebasestorage.app"
    );
    let scanned, removed, total = 0;
    let attempts = 0;
    do {
      ({scanned, removed} = await purgeExpiredEvidence({
        db, bucket, limit: 50,
      }));
      total += removed;
      attempts++;
      if (attempts >= 20) {
        throw new Error("Límite de lotes alcanzado. Revisar manualmente.");
      }
      if (scanned > 0 && removed === 0) {
        throw new Error("Reservas inválidas impiden avanzar. Revisar manualmente.");
      }
    } while (scanned === 50);
    console.log("Reservas vencidas limpiadas:", total);
  } finally {
    await deleteApp(app);
  }
})().catch((error) => {
  console.error("No pudo completarse la limpieza demo:", error.message);
  process.exitCode = 1;
});
