"use strict";

// Servicio local explícito: ejecuta la limpieza cada minuto mientras
// permanezca abierto. No se despliega ni crea tareas en Firebase real.
if (process.env.GCLOUD_PROJECT !== "demo-healthy-habit" ||
    !process.env.FIRESTORE_EMULATOR_HOST ||
    !process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
  throw new Error("El vigilante solo funciona con emuladores demo.");
}
const {initializeApp, deleteApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {purgeExpiredEvidence} = require("../habit_evidence_cleanup");

const app = initializeApp({
  projectId: "demo-healthy-habit",
  storageBucket: "demo-healthy-habit.firebasestorage.app",
}, "vigilante-evidencias-demo");
const db = getFirestore(app, "default");
const bucket = getStorage(app).bucket(
  "demo-healthy-habit.firebasestorage.app"
);
let running = false;
let stopped = false;

async function sweep() {
  if (running || stopped) return;
  running = true;
  try {
    let scanned = 0;
    let removed = 0;
    let rounds = 0;
    do {
      ({scanned, removed} = await purgeExpiredEvidence({
        db, bucket, limit: 50,
      }));
      rounds++;
      if (scanned > 0 && removed === 0) {
        throw new Error("Hay reservas inválidas; revisión manual requerida.");
      }
    } while (scanned === 50 && rounds < 20 && !stopped);
    if (scanned === 50 && rounds >= 20) {
      throw new Error("Límite de lotes alcanzado; revisión manual requerida.");
    }
  } catch (error) {
    console.error("Limpieza del laboratorio falló:", error.message);
  } finally {
    running = false;
  }
}

const interval = setInterval(sweep, 60 * 1000);
void sweep();

async function close() {
  if (stopped) return;
  stopped = true;
  clearInterval(interval);
  // Dejar que una limpieza en curso finalice antes de cerrar Admin SDK.
  while (running) {
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  await deleteApp(app);
}
process.once("SIGINT", () => { void close().then(() => process.exit(0)); });
process.once("SIGTERM", () => { void close().then(() => process.exit(0)); });
console.log("Limpieza periódica demo activa. Detén con Ctrl+C.");
