"use strict";

// Desplegar únicamente este codebase. No importar functions/index.js.
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineString} = require("firebase-functions/params");
// Mantener liviana la carga durante discovery de Firebase CLI.
// Admin, Firestore y Vision se inicializan únicamente al recibir una solicitud.
const allowedUid = defineString("HEALTHY_VISION_TEST_UID");
let db;
let fieldValue;
let client;

function getPilotDb() {
  if (!db) {
    const {initializeApp, getApps} = require("firebase-admin/app");
    const {getFirestore, FieldValue} = require("firebase-admin/firestore");
    if (!getApps().length) initializeApp();
    // Healthy Habit usa la base de datos llamada "default", NO "(default)".
    db = getFirestore("default");
    fieldValue = FieldValue;
  }
  return db;
}

function getVisionClient() {
  if (!client) {
    const {ImageAnnotatorClient} = require("@google-cloud/vision");
    client = new ImageAnnotatorClient();
  }
  return client;
}

const MAX_BYTES = 250 * 1024;
const {present} = require("./classifier");
const allowedProfiles = new Set(["hydration", "fruit_vegetable", "meal"]);

function decodeImage(value) {
  if (typeof value !== "string" || value.length < 8 ||
      value.length > Math.ceil(MAX_BYTES / 3) * 4 + 4 ||
      value.length % 4 !== 0 || !/^[A-Za-z0-9+/]+={0,2}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Imagen inválida o demasiado grande.");
  }
  const bytes = Buffer.from(value, "base64");
  if (!bytes.length || bytes.length > MAX_BYTES ||
      bytes.toString("base64") !== value) {
    throw new HttpsError("invalid-argument", "La imagen supera 250 KB.");
  }
  const jpeg = bytes.length >= 3 && bytes[0] === 0xff &&
      bytes[1] === 0xd8 && bytes[2] === 0xff;
  const png = bytes.length >= 8 &&
      bytes.subarray(0, 8).equals(Buffer.from("89504e470d0a1a0a", "hex"));
  const webp = bytes.length >= 12 && bytes.toString("ascii", 0, 4) === "RIFF" &&
      bytes.toString("ascii", 8, 12) === "WEBP";
  if (!jpeg && !png && !webp) {
    throw new HttpsError("invalid-argument", "Imagen no compatible.");
  }
  return bytes;
}

exports.analyzeEvidencePreviewLive = onCall({
  region: "us-central1",
  memory: "512MiB",
  timeoutSeconds: 30,
  maxInstances: 1,
  concurrency: 1,
  // Prueba restringida a un único UID. Requiere App Check antes de
  // habilitar para usuarios generales.
  enforceAppCheck: false,
}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Inicia sesión en Healthy Habit.");
  }
  const permitted = allowedUid.value();
  if (!permitted || uid !== permitted) {
    throw new HttpsError("permission-denied",
        "El piloto está restringido a una cuenta de prueba autorizada.");
  }
  if (!request.data || typeof request.data !== "object" ||
      Array.isArray(request.data) ||
      Object.keys(request.data).sort().join(",") !== "imageBase64,profileId") {
    throw new HttpsError("invalid-argument", "Solicitud inválida.");
  }
  const {imageBase64, profileId} = request.data;
  if (typeof profileId !== "string" || !allowedProfiles.has(profileId)) {
    throw new HttpsError("invalid-argument", "Categoría visual inválida.");
  }
  const bytes = decodeImage(imageBase64);
  // Cuota persistente: se registra solamente el contador, NO la foto.
  // 1 minuto de pausa y 15 intentos por día para el UID permitido.
  const today = new Date().toISOString().slice(0, 10);
  const database = getPilotDb();
  const quotaRef = database.collection("_vision_preview_pilot_limits").doc(uid);
  await database.runTransaction(async (tx) => {
    const doc = await tx.get(quotaRef);
    const prior = doc.data() || {};
    const count = prior.day === today ? (prior.count || 0) : 0;
    const now = Date.now();
    const lastAt = prior.lastAtMillis || 0;
    if (now - lastAt < 60 * 1000 || count >= 15) {
      throw new HttpsError("resource-exhausted",
          "Límite de análisis alcanzado. Espera o prueba mañana.");
    }
    tx.set(quotaRef, {
      day: today, count: count + 1, lastAtMillis: now,
      updatedAt: fieldValue.serverTimestamp(),
    });
  });
  try {
    const visionClient = getVisionClient();
    const image = {content: bytes};
    const [[labels], [objects]] = await Promise.all([
      visionClient.labelDetection({image}),
      visionClient.objectLocalization({image}),
    ]);
    return present(profileId, [labels, objects]);
  } catch (error) {
    // No se registran fotos, credenciales ni respuestas del proveedor.
    console.error("Vision pilot request failed", Number(error?.code) || "unknown");
    throw new HttpsError("unavailable",
        "Vision no pudo analizar la imagen. Intenta más tarde.");
  }
});
