"use strict";

// Solo lectura. La salida contiene rutas privadas; úsala localmente.
if (process.env.GCLOUD_PROJECT !== "demo-healthy-habit" ||
    !process.env.FIRESTORE_EMULATOR_HOST ||
    !process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
  throw new Error("Solo es posible auditar los emuladores demo.");
}
const {initializeApp, deleteApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {auditOrphanEvidence} = require("../habit_evidence_audit");

(async () => {
  const app = initializeApp({
    projectId: "demo-healthy-habit",
    storageBucket: "demo-healthy-habit.firebasestorage.app",
  }, "audit-evidence-demo");
  try {
    const report = await auditOrphanEvidence({
      db: getFirestore(app, "default"),
      bucket: getStorage(app).bucket(
        "demo-healthy-habit.firebasestorage.app"
      ),
      limit: 100,
    });
    console.log(JSON.stringify(report, null, 2));
    if (report.hasMore) {
      console.warn("Auditoría parcial: hay más objetos por revisar.");
    }
  } finally {
    await deleteApp(app);
  }
})().catch((error) => {
  console.error("Error al auditar:", error.message);
  process.exitCode = 1;
});
