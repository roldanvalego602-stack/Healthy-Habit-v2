"use strict";

const {createHash, randomBytes, randomInt, timingSafeEqual} = require("node:crypto");
const {Timestamp, FieldValue} = require("firebase-admin/firestore");
const {validateChoice, getAvailableChallengeOptions} = require("./evidence_policy");

const CHALLENGE_TTL_MS = 5 * 60 * 1000;
const MAX_FAILED_ATTEMPTS = 3;
const MAX_CODE_LENGTH = 6;

class ChallengeError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "ChallengeError";
    this.code = code;
  }
}

function requireId(value, name) {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) {
    throw new ChallengeError("invalid-argument", `Identificador ${name} no válido.`);
  }
  return value;
}

function requireObject(objectId) {
  if (!validateChoice(objectId)) {
    throw new ChallengeError("invalid-argument", "Elige uno de los objetos disponibles.");
  }
  return objectId;
}

function getChallengeDocId(habitId, attemptId) {
  return createHash("sha256").update(JSON.stringify([habitId, attemptId])).digest("hex");
}

function digest(code, salt) {
  return createHash("sha256").update(`${salt}:${code}`, "utf8").digest("hex");
}

function createChallengeSpec(now = Date.now()) {
  const code = String(randomInt(0, 1000000)).padStart(MAX_CODE_LENGTH, "0");
  const salt = randomBytes(16).toString("hex");
  return {
    code,
    salt,
    codeHash: digest(code, salt),
    expiresAtMs: now + CHALLENGE_TTL_MS,
  };
}

function compareCode(candidate, salt, codeHash) {
  if (typeof candidate !== "string" || !/^\d{6}$/.test(candidate) ||
      typeof salt !== "string" || !/^[a-f0-9]{32}$/.test(salt) ||
      typeof codeHash !== "string" || !/^[a-f0-9]{64}$/.test(codeHash)) return false;
  const actual = Buffer.from(digest(candidate, salt), "hex");
  const expected = Buffer.from(codeHash, "hex");
  return timingSafeEqual(actual, expected);
}

function challengeRef(db, uid, habitId, attemptId) {
  return db.collection("users").doc(uid).collection("evidence_challenges")
    .doc(getChallengeDocId(habitId, attemptId));
}

/**
 * Requires Firestore Emulator during local development. The generated code is
 * returned ONLY when the challenge is newly created. There is one active
 * challenge per user/habit/attempt; retries cannot fetch its original code.
 */
async function startEvidenceChallenge({db, uid, habitId, attemptId, objectId, now = Date.now()}) {
  requireId(uid, "de usuario");
  requireId(habitId, "de hábito");
  requireId(attemptId, "de intento");
  requireObject(objectId);
  const userRef = db.collection("users").doc(uid);
  const habitRef = userRef.collection("user_habits").doc(habitId);
  const attemptRef = habitRef.collection("attempts").doc(attemptId);
  const ref = challengeRef(db, uid, habitId, attemptId);
  const spec = createChallengeSpec(now);

  return db.runTransaction(async (tx) => {
    const [habit, attempt, existing] = await Promise.all([
      tx.get(habitRef), tx.get(attemptRef), tx.get(ref),
    ]);
    if (!habit.exists || !attempt.exists ||
        attempt.data().status !== "inProgress") {
      throw new ChallengeError("failed-precondition", "El hábito o intento no está activo.");
    }
    if (existing.exists) {
      const prev = existing.data();
      const expiryMs = prev.expiresAt?.toMillis?.() ?? 0;
      if (prev.state === "active" && expiryMs > now &&
          (prev.failedAttempts ?? 0) < MAX_FAILED_ATTEMPTS) {
        throw new ChallengeError(
          "failed-precondition",
          "Ya existe un desafío vigente. Úsalo o espera a que caduque.",
        );
      }
    }
    tx.set(ref, {
      uid,
      habitId,
      attemptId,
      objectId,
      salt: spec.salt,
      codeHash: spec.codeHash,
      state: "active",
      failedAttempts: 0,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(spec.expiresAtMs),
      consumedAt: null,
    });
    return {
      challengeId: ref.id,
      objectId,
      code: spec.code,
      expiresAt: new Date(spec.expiresAtMs).toISOString(),
      options: getAvailableChallengeOptions(),
      explanation: "Código para una foto de esta sesión. Aún no verifica la actividad.",
    };
  });
}

/**
 * Test-only step for the initial development flow. Checking a *typed* code
 * never verifies an image, session freshness, or earns XP. The production
 * image-verification path must OCR the captured image server-side and consume
 * the challenge atomically with verification instead.
 */
async function checkEvidenceChallengeCode({
  db, uid, habitId, attemptId, challengeId, code, now = Date.now(),
}) {
  requireId(uid, "de usuario");
  requireId(habitId, "de hábito");
  requireId(attemptId, "de intento");
  const ref = challengeRef(db, uid, habitId, attemptId);
  if (typeof challengeId !== "string" || challengeId !== ref.id) {
    throw new ChallengeError("invalid-argument", "Desafío incorrecto.");
  }
  if (typeof code !== "string" || !/^\d{6}$/.test(code)) {
    throw new ChallengeError("invalid-argument", "El código debe tener seis dígitos.");
  }
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new ChallengeError("not-found", "Desafío no encontrado.");
    }
    const data = snap.data();
    if (data.uid !== uid || data.habitId !== habitId ||
        data.attemptId !== attemptId) {
      throw new ChallengeError("permission-denied", "Desafío no autorizado.");
    }
    if (data.state !== "active") {
      throw new ChallengeError("failed-precondition", "Desafío utilizado o bloqueado.");
    }
    if ((data.expiresAt?.toMillis?.() ?? 0) <= now) {
      throw new ChallengeError("deadline-exceeded", "El desafío caducó.");
    }
    const failures = data.failedAttempts ?? 0;
    if (failures >= MAX_FAILED_ATTEMPTS) {
      throw new ChallengeError("resource-exhausted", "Demasiados intentos.");
    }
    const matched = compareCode(code, data.salt, data.codeHash);
    if (matched) {
      tx.update(ref, {state: "consumed", consumedAt: FieldValue.serverTimestamp()});
      return {
        codeMatched: true,
        imageVerified: false,
        xpAwarded: 0,
        note: "Código válido, pero todavía no se ha analizado ninguna fotografía.",
      };
    }
    const updatedAttempts = failures + 1;
    tx.update(ref, {
      failedAttempts: updatedAttempts,
      ...(updatedAttempts >= MAX_FAILED_ATTEMPTS ? {state: "locked"} : {}),
    });
    return {
      codeMatched: false,
      imageVerified: false,
      xpAwarded: 0,
      attemptsRemaining: MAX_FAILED_ATTEMPTS - updatedAttempts,
    };
  });
}

module.exports = {
  ChallengeError,
  CHALLENGE_TTL_MS,
  MAX_FAILED_ATTEMPTS,
  createChallengeSpec,
  compareCode,
  getChallengeDocId,
  startEvidenceChallenge,
  checkEvidenceChallengeCode,
};
