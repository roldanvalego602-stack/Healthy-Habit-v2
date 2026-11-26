"use strict";

// Desplegar únicamente este codebase. No importar functions/index.js.
const {onCall, HttpsError} = require("firebase-functions/v2/https");
// Mantener liviana la carga durante discovery de Firebase CLI.
// Admin, Firestore y Vision se inicializan únicamente al recibir una solicitud.
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
  // Solo sesiones de Healthy Habit con un token App Check válido.
  enforceAppCheck: true,
}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Inicia sesión en Healthy Habit.");
  }
  if (!request.app) {
    throw new HttpsError("permission-denied", "App Check requerido.");
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
  // Cuotas global y por UID en una misma transacción: evita gasto ilimitado.
  const USER_DAILY_LIMIT = 3;
  const GLOBAL_DAILY_LIMIT = 100;
  const COOLDOWN_MS = 60000;
  const today = new Date().toISOString().slice(0, 10);
  const resetAtMillis = Date.parse(today + "T00:00:00.000Z") + 86400000;
  const database = getPilotDb();
  const quotaRef = database.collection("_vision_preview_pilot_limits").doc(uid);
  const globalRef = database.collection("_vision_preview_global_limits").doc(today);
  const quota = await database.runTransaction(async (tx) => {
    const [userDoc, globalDoc] = await Promise.all([
      tx.get(quotaRef), tx.get(globalRef),
    ]);
    const prior = userDoc.data() || {};
    const total = globalDoc.data()?.count || 0;
    const count = prior.day === today ? (prior.count || 0) : 0;
    const now = Date.now();
    const nextAllowedAtMillis = (prior.lastAtMillis || 0) + COOLDOWN_MS;
    if (total >= GLOBAL_DAILY_LIMIT) {
      throw new HttpsError("resource-exhausted",
          "Se alcanzó el cupo global del servicio por hoy.", {
            reason: "global-limit", remaining: 0,
            dailyLimit: USER_DAILY_LIMIT, retryAtMillis: resetAtMillis,
          });
    }
    if (count >= USER_DAILY_LIMIT) {
      throw new HttpsError("resource-exhausted",
          "Alcanzaste el cupo diario. Intenta mañana (UTC).", {
            reason: "daily-limit", remaining: 0,
            dailyLimit: USER_DAILY_LIMIT, retryAtMillis: resetAtMillis,
          });
    }
    if (now < nextAllowedAtMillis) {
      throw new HttpsError("resource-exhausted",
          "Espera un minuto entre análisis.", {
            reason: "cooldown", remaining: USER_DAILY_LIMIT - count,
            dailyLimit: USER_DAILY_LIMIT,
            retryAtMillis: nextAllowedAtMillis,
          });
    }
    tx.set(quotaRef, {
      day: today, count: count + 1, lastAtMillis: now,
      updatedAt: fieldValue.serverTimestamp(),
    });
    tx.set(globalRef, {
      count: total + 1, updatedAt: fieldValue.serverTimestamp(),
    }, {merge: true});
    return {
      remaining: USER_DAILY_LIMIT - count - 1,
      dailyLimit: USER_DAILY_LIMIT,
      nextAllowedAtMillis: now + COOLDOWN_MS, resetAtMillis,
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
