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
    const {initializeApp, getApp} = require("firebase-admin/app");
    const {getFirestore, FieldValue} = require("firebase-admin/firestore");
    // Firebase Functions puede registrar apps con nombre y dejar sin crear
    // [DEFAULT]. Por eso getApps().length no garantiza una app predeterminada.
    let app;
    try {
      app = getApp();
    } catch (error) {
      if (error?.code !== "app/no-app") throw error;
      app = initializeApp();
    }
    // Healthy Habit usa la base de datos llamada "default", NO "(default)".
    // Pasar la app explicitamente evita depender de una seleccion implicita.
    db = getFirestore(app, "default");
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
  // Cuota persistente, aplicable a TODOS los intentos aceptados.
  // Incluye rechazos diferenciados para informar el tiempo exacto al cliente.
  const today = new Date().toISOString().slice(0, 10);
  const resetAtMillis = Date.parse(today + "T00:00:00.000Z") + 86400000;
  const database = getPilotDb();
  const quotaRef = database.collection("_vision_preview_pilot_limits").doc(uid);
  const quota = await database.runTransaction(async (tx) => {
    const doc = await tx.get(quotaRef);
    const prior = doc.data() || {};
    const count = prior.day === today ? (prior.count || 0) : 0;
    const now = Date.now();
    const nextAllowedAtMillis = (prior.lastAtMillis || 0) + 60000;
    if (count >= 15) {
      throw new HttpsError("resource-exhausted",
          "Alcanzaste las 15 solicitudes de hoy. Intenta mañana (UTC).", {
            reason: "daily-limit", remaining: 0, dailyLimit: 15,
            retryAtMillis: resetAtMillis,
          });
    }
    if (now < nextAllowedAtMillis) {
      throw new HttpsError("resource-exhausted",
          "Espera un minuto entre análisis.", {
            reason: "cooldown", remaining: 15 - count, dailyLimit: 15,
            retryAtMillis: nextAllowedAtMillis,
          });
    }
    tx.set(quotaRef, {
      day: today, count: count + 1, lastAtMillis: now,
      updatedAt: fieldValue.serverTimestamp(),
    });
    return {
      remaining: 14 - count,
      dailyLimit: 15,
      nextAllowedAtMillis: now + 60000,
      resetAtMillis,
    };
  });
  try {
    const visionClient = getVisionClient();
    const image = {content: bytes};
    const [[labels], [objects]] = await Promise.all([
      visionClient.labelDetection({image}),
      visionClient.objectLocalization({image}),
    ]);
    return {...present(profileId, [labels, objects]), quota};
  } catch (error) {
    // No se registran fotos, credenciales ni respuestas del proveedor.
    console.error("Vision pilot request failed", Number(error?.code) || "unknown");
    throw new HttpsError("unavailable",
        "Vision no pudo analizar la imagen. Intenta más tarde.");
  }
});


// Análisis DE UN OBJETO YA ASOCIADO en Storage privado. El cliente no
// envía etiquetas, porcentajes, rutas, imágenes ni valores de XP.
// Publicación independiente, cerrada por defecto y limitada a testers.
const {
  assessAttachedEvidence, EvidenceAssessmentError,
} = require("./evidence_assessment");

exports.analyzeAttachedHabitEvidenceBeta = onCall({
  region: "us-central1",
  memory: "512MiB",
  timeoutSeconds: 40,
  maxInstances: 1,
  concurrency: 1,
  enforceAppCheck: true,
}, async (request) => {
  const env = process.env;
  if ((env.GCLOUD_PROJECT || env.GCP_PROJECT) !== "cloud-firestore-d8c61" ||
      env.HH_BETA_HABITS_ENABLED !== "true" ||
      env.HH_BETA_RULES_VERIFIED !== "true" ||
      env.HH_BETA_EVIDENCE_ENABLED !== "true" ||
      env.HH_BETA_VISUAL_ANALYSIS_ENABLED !== "true") {
    throw new HttpsError("failed-precondition",
      "El análisis de imágenes no está habilitado para esta beta.");
  }
  const uid = request.auth?.uid;
  if (typeof uid !== "string" || uid.length < 1 ||
      uid.length > 128 || !/^[a-zA-Z0-9_-]+$/.test(uid)) {
    throw new HttpsError("unauthenticated", "Inicia sesión.");
  }
  if (!request.app?.appId) {
    throw new HttpsError("permission-denied",
      "La aplicación no pasó la comprobación de App Check.");
  }
  const allowed = (env.HH_BETA_TEST_UIDS || "").split(",")
    .map((value) => value.trim()).filter(Boolean);
  if (!allowed.includes(uid)) {
    throw new HttpsError("permission-denied",
      "Cuenta no autorizada para la beta cerrada.");
  }
  try {
    const {getStorage} = require("firebase-admin/storage");
    const database = getPilotDb();
    return await assessAttachedEvidence({
      db: database,
      bucket: getStorage().bucket(
        "cloud-firestore-d8c61.firebasestorage.app"),
      vision: getVisionClient(),
      uid, data: request.data,
      fieldValue,
    });
  } catch (error) {
    if (error instanceof EvidenceAssessmentError) {
      throw new HttpsError(error.code, error.message);
    }
    // Nunca registrar contenido, etiquetas, foto ni UID en logs de errores.
    console.error("[vision-evidence-beta]", {
      code: Number(error?.code) || "internal",
    });
    throw new HttpsError("internal",
      "No se pudo analizar la evidencia.");
  }
});
