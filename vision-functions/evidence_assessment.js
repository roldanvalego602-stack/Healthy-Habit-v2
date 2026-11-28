"use strict";

const {createHash} = require("node:crypto");
const {present} = require("./classifier");

const ID = /^[A-Za-z0-9_-]{16,128}$/;
const UID = /^[A-Za-z0-9_-]{1,128}$/;
const MAX_BYTES = 250 * 1024;
const VERSION = "vision-match-1.0";

// Un menú equilibrado, un consumo o una duración no pueden probarse
// solo por la presencia visual de alimentos, agua o utensilios.
const HABIT_PROFILE = Object.freeze({
  alim_001: "fruit_vegetable",
  alim_002: "meal",
  alim_003: "fruit_vegetable",
  alim_005: "meal",
  hidr_001: "hydration",
  hidr_002: "hydration",
  hidr_003: "hydration",
  hidr_004: "hydration",
  hidr_005: "hydration",
  hidr_006: "hydration",
  hidr_007: "hydration",
  hidr_008: "hydration",
  hidr_009: "hydration",
});

class EvidenceAssessmentError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function validateRequest(uid, data) {
  if (typeof uid !== "string" || !UID.test(uid)) {
    throw new EvidenceAssessmentError("unauthenticated", "Sesión inválida.");
  }
  if (!data || typeof data !== "object" || Array.isArray(data) ||
      Object.keys(data).sort().join(",") !==
        "attemptId,habitId,operationId" ||
      typeof data.habitId !== "string" ||
      !/^(?:alim|hidr|ener|bien)_00[1-9]$/.test(data.habitId) ||
      typeof data.attemptId !== "string" || !ID.test(data.attemptId) ||
      typeof data.operationId !== "string" || !ID.test(data.operationId)) {
    throw new EvidenceAssessmentError("invalid-argument",
      "Identificadores de evaluación inválidos.");
  }
  return data;
}

function imageFormatValid(bytes, mime) {
  if (!Buffer.isBuffer(bytes) || bytes.length < 12 ||
      bytes.length > MAX_BYTES) return false;
  if (mime === "image/jpeg") {
    return bytes[0] === 0xff && bytes[1] === 0xd8 &&
      bytes[2] === 0xff && bytes[bytes.length - 2] === 0xff &&
      bytes[bytes.length - 1] === 0xd9;
  }
  if (mime === "image/png") {
    return bytes.subarray(0, 8).equals(Buffer.from(
      "89504e470d0a1a0a", "hex")) &&
      bytes.subarray(bytes.length - 8, bytes.length - 4).toString() === "IEND";
  }
  return mime === "image/webp" &&
      bytes.subarray(0, 4).toString() === "RIFF" &&
      bytes.subarray(8, 12).toString() === "WEBP";
}

function interpretation(profileId, responses) {
  const result = present(profileId, responses);
  const visible = result.status === "visual_match_only";
  return {
    status: visible ? "visual_match_only" : "inconclusive",
    profileId,
    contentVerified: false,
    imageVerified: false,
    xpAwarded: 0,
    coinsAwarded: 0,
    version: VERSION,
    message: visible
      ? "Se reconocieron elementos relacionados con el hábito. "
        + "La imagen no demuestra consumo ni cumplimiento."
      : "El contenido no fue concluyente. Puedes mantener tu "
        + "registro declarado sin penalización.",
  };
}

async function assessAttachedEvidence({
  db, bucket, vision, uid, data, now = new Date(), fieldValue,
}) {
  validateRequest(uid, data);
  if (!(now instanceof Date) || !Number.isFinite(now.getTime()) ||
      !db || !bucket || !vision || !fieldValue) {
    throw new EvidenceAssessmentError("failed-precondition",
      "Servicio de análisis no disponible.");
  }
  const user = db.collection("users").doc(uid);
  const reservationRef = user.collection("habit_evidence_reservations")
    .doc(data.operationId);
  const logRef = user.collection("user_habits").doc(data.habitId)
    .collection("attempts").doc(data.attemptId)
    .collection("logs").doc(data.operationId);
  const assessmentRef = user.collection("habit_evidence_assessments")
    .doc(data.operationId);
  const path = `habit-evidence/${uid}/${data.attemptId}/${data.operationId}`;
  const [reservation, log] = await Promise.all([
    reservationRef.get(), logRef.get(),
  ]);
  if (!reservation.exists || !log.exists) {
    throw new EvidenceAssessmentError("failed-precondition",
      "Primero confirma el registro y la fotografía privada.");
  }
  const saved = reservation.data();
  const savedLog = log.data();
  if (saved.uid !== uid || saved.habitId !== data.habitId ||
      saved.attemptId !== data.attemptId ||
      saved.operationId !== data.operationId ||
      saved.storagePath !== path || saved.status !== "attached" ||
      savedLog.userId !== uid || savedLog.evidencePath !== path ||
      savedLog.hasEvidence !== true) {
    throw new EvidenceAssessmentError("permission-denied",
      "La foto no pertenece a este registro.");
  }
  if (saved.visionConsent !== true) {
    throw new EvidenceAssessmentError("permission-denied",
      "La fotografía no tiene autorización para análisis en nube.");
  }
  const old = await assessmentRef.get();
  if (old.exists && old.data().state === "done") {
    return {...old.data().result, cached: true};
  }
  if (saved.expiresAt?.toMillis?.() <= now.getTime()) {
    throw new EvidenceAssessmentError("failed-precondition",
      "La foto ya expiró; no es necesario volver a fotografiar el hábito.");
  }

  const profileId = HABIT_PROFILE[data.habitId];
  if (!profileId) {
    return {status: "unsupported_habit", profileId: null,
      contentVerified: false, imageVerified: false, xpAwarded: 0,
      coinsAwarded: 0, message: "Este hábito no se puede evaluar "
        + "fiablemente mediante estas categorías visuales."};
  }

  const file = bucket.file(path);
  let metadata, bytes;
  try {
    [metadata] = await file.getMetadata();
    const size = Number(metadata.size);
    if (!Number.isSafeInteger(size) || size < 12 || size > MAX_BYTES ||
        !["image/jpeg", "image/png", "image/webp"].includes(metadata.contentType) ||
        (savedLog.evidenceSize != null && size !== savedLog.evidenceSize)) {
      throw new EvidenceAssessmentError("invalid-argument",
        "Archivo de evidencia inválido.");
    }
    [bytes] = await file.download();
    if (bytes.length !== size ||
        !imageFormatValid(bytes, metadata.contentType)) {
      throw new EvidenceAssessmentError("invalid-argument",
        "El archivo no coincide con el contenido declarado.");
    }
  } catch (error) {
    if (error instanceof EvidenceAssessmentError) throw error;
    if (Number(error.code) === 404) {
      throw new EvidenceAssessmentError("not-found",
        "La fotografía temporal ya no está disponible.");
    }
    throw new EvidenceAssessmentError("unavailable",
      "No se pudo leer la fotografía privada.");
  }
  // El hash se usa únicamente para comprobar el objeto dentro de
  // esta operación. No se publica como identificador global de usuarios.
  const digest = createHash("sha256").update(bytes).digest("hex");
  const quotaRef = user.collection("habit_evidence_vision_limits")
    .doc(now.toISOString().slice(0, 10));
  const lease = await db.runTransaction(async (tx) => {
    const [previous, counter] = await Promise.all([
      tx.get(assessmentRef), tx.get(quotaRef),
    ]);
    if (previous.exists && previous.data().state === "done") {
      return {cached: previous.data().result};
    }
    if (previous.exists && previous.data().state === "processing" &&
        now.getTime() - (previous.data().startedAtMillis || 0) < 120000) {
      throw new EvidenceAssessmentError("aborted",
        "Esta imagen ya se está analizando.");
    }
    const amount = counter.exists ? Number(counter.data().count) : 0;
    const last = counter.exists ? Number(counter.data().lastAtMillis) : 0;
    if (!Number.isSafeInteger(amount) || amount < 0 || amount >= 8) {
      throw new EvidenceAssessmentError("resource-exhausted",
        "Alcanzaste el límite diario de análisis de imágenes.");
    }
    if (now.getTime() - last < 60000) {
      throw new EvidenceAssessmentError("resource-exhausted",
        "Espera un minuto antes de otro análisis.");
    }
    tx.set(quotaRef, {count:amount+1,lastAtMillis:now.getTime(),
      updatedAt:fieldValue.serverTimestamp()}, {merge:true});
    tx.set(assessmentRef, {uid,habitId:data.habitId,
      attemptId:data.attemptId,operationId:data.operationId,
      imageSha256:digest,state:"processing",
      startedAtMillis:now.getTime(),
      updatedAt:fieldValue.serverTimestamp()}, {merge:true});
    return {cached:null};
  });
  if (lease.cached) return {...lease.cached,cached:true};

  try {
    const image = {content: bytes};
    const [[labels],[objects]] = await Promise.all([
      vision.labelDetection({image}), vision.objectLocalization({image}),
    ]);
    const result = interpretation(profileId, [labels, objects]);
    await db.runTransaction(async (tx) => {
      const [current, link] = await Promise.all([
        tx.get(assessmentRef), tx.get(logRef),
      ]);
      if (!current.exists || current.data().imageSha256 !== digest ||
          current.data().state !== "processing" ||
          !link.exists || link.data().evidencePath !== path) {
        throw new EvidenceAssessmentError("aborted",
          "La evidencia cambió durante el análisis.");
      }
      tx.update(assessmentRef, {state:"done",result,
        completedAt:fieldValue.serverTimestamp()});
      tx.update(logRef, {evidenceVisualStatus:result.status,
        evidenceVisualVersion:VERSION,
        evidenceContentVerified:false,
        evidenceAnalyzedAt:fieldValue.serverTimestamp()});
    });
    return {...result, cached:false};
  } catch (error) {
    // No se registra la imagen ni la respuesta íntegra de Cloud Vision.
    await assessmentRef.update({
      state:"failed",updatedAt:fieldValue.serverTimestamp(),
    }).catch(() => {});
    if (error instanceof EvidenceAssessmentError) throw error;
    throw new EvidenceAssessmentError("unavailable",
      "No se pudo completar el análisis visual.");
  }
}

module.exports = {
  HABIT_PROFILE, VERSION, EvidenceAssessmentError,
  validateRequest, imageFormatValid, interpretation, assessAttachedEvidence,
};
