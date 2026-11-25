"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {validImage, attachHabitEvidence} =
  require("../habit_evidence_attachment");
const {purgeExpiredEvidence} = require("../habit_evidence_cleanup");

const png = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9pz7wAAAAASUVORK5CYII=",
  "base64"
);

test("evidencias: rechazar contenido incorrecto, MIME falso y exceso de tamaño", () => {
  assert.equal(validImage(png, "image/png"), true);
  assert.equal(validImage(png, "image/jpeg"), false);
  assert.equal(validImage(Buffer.alloc(0), "image/png"), false);
  assert.equal(validImage(Buffer.alloc(250 * 1024 + 1), "image/png"), false);
  assert.equal(validImage(Buffer.from("esto no es foto".repeat(3)),
    "image/png"), false);
  const modified = Buffer.from(png);
  modified[modified.length - 6] = 0;
  assert.equal(validImage(modified, "image/png"), false);
});

test("evidencias: asociación rechaza IDs y campos económicos sin tocar Firestore", async () => {
  await assert.rejects(attachHabitEvidence({
    uid: "usuario_de_pruebas_123456",
    data: {habitId: "alim_001", attemptId: "attempt_prueba_123456",
      operationId: "evidence_prueba_123456", xp: 99},
    now: new Date(),
  }), (error) => error.code === "invalid-argument");
  await assert.rejects(attachHabitEvidence({
    uid: "usuario_de_pruebas_123456",
    data: {habitId: "alim_001", attemptId: "bad",
      operationId: "evidence_prueba_123456"},
    now: new Date(),
  }), (error) => error.code === "invalid-argument");
});

test("evidencias: limpieza no se ejecuta fuera del proyecto demo y emuladores", async () => {
  const beforeProject = process.env.GCLOUD_PROJECT;
  const beforeFirestore = process.env.FIRESTORE_EMULATOR_HOST;
  const beforeStorage = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
  try {
    process.env.GCLOUD_PROJECT = "proyecto-real";
    await assert.rejects(purgeExpiredEvidence({
      db: {}, bucket: {},
    }), /emuladores demo/);
  } finally {
    if (beforeProject === undefined) delete process.env.GCLOUD_PROJECT;
    else process.env.GCLOUD_PROJECT = beforeProject;
    if (beforeFirestore === undefined) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else process.env.FIRESTORE_EMULATOR_HOST = beforeFirestore;
    if (beforeStorage === undefined) {
      delete process.env.FIREBASE_STORAGE_EMULATOR_HOST;
    } else process.env.FIREBASE_STORAGE_EMULATOR_HOST = beforeStorage;
  }
});
