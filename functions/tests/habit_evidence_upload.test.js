"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {uploadReservedEvidence} = require("../habit_evidence_upload");

const uid = "usuario_de_pruebas_123456";
const base = {
  habitId: "alim_001",
  attemptId: "attempt_prueba_123456",
  operationId: "evidence_prueba_123456",
};
const png = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9pz7wAAAAASUVORK5CYII=",
  "base64"
);

test("subida: rechaza datos económicos, tipos y contenido inválidos", async () => {
  for (const changes of [
    {xp: 500},
    {contentType: "text/plain"},
    {imageBase64: "no es base64"},
    {imageBase64: Buffer.alloc(250 * 1024 + 1).toString("base64")},
    {attemptId: "../otro"},
  ]) {
    await assert.rejects(uploadReservedEvidence({
      uid,
      data: {
        ...base, imageBase64: png.toString("base64"),
        contentType: "image/png", ...changes,
      },
    }), (error) => error.code === "invalid-argument");
  }
});

test("subida: rechaza fotografías no reservadas antes de acceder al bucket", async () => {
  await assert.rejects(uploadReservedEvidence({
    uid,
    data: {
      ...base, imageBase64: png.toString("base64"), contentType: "image/png",
    },
    db: {
      collection: () => ({
        doc: () => ({
          collection: () => ({doc: () => ({})}),
        }),
      }),
      runTransaction: async (callback) => callback({
        get: async () => ({exists: false}),
      }),
    },
  }), (error) => error.code === "failed-precondition");
});
