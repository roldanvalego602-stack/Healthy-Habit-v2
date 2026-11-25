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
    const summary = {
      scanned: 0,
      counts: {
        valid: 0, orphan: 0, inconsistent: 0, expired: 0,
        recentUnreserved: 0, invalidPath: 0,
      },
      findings: [],
      complete: false,
    };
    let pageToken;
    const seen = new Set();
    const maxPages = 100;
    for (let page = 0; page < maxPages; page++) {
      const report = await auditOrphanEvidence({
        db: getFirestore(app, "default"),
        bucket: getStorage(app).bucket(
          "demo-healthy-habit.firebasestorage.app"
        ),
        limit: 100, pageToken,
      });
      summary.scanned += report.scanned;
      for (const [key, value] of Object.entries(report.counts)) {
        summary.counts[key] += value;
      }
      summary.findings.push(...report.findings);
      if (!report.hasMore) {
        summary.complete = true;
        break;
      }
      if (!report.nextPageToken || seen.has(report.nextPageToken)) {
        throw new Error("Paginación inválida o repetida en Storage Emulator.");
      }
      seen.add(report.nextPageToken);
      pageToken = report.nextPageToken;
    }
    console.log(JSON.stringify(summary, null, 2));
    if (!summary.complete) {
      throw new Error("Auditoría parcial: límite de 100 páginas alcanzado.");
    }
  } finally {
    await deleteApp(app);
  }
})().catch((error) => {
  console.error("Error al auditar:", error.message);
  process.exitCode = 1;
});
