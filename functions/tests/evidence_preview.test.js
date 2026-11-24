"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  EvidencePreviewError,
  decodePreviewImage,
  previewFromLabels,
  analyzeEvidencePreview,
  MAX_BYTES,
} = require("../evidence_preview");

// Encabezado JPEG de prueba; el detector siempre es un stub inyectado.
// No se envían imágenes ni se consulta Vision API durante npm test.
const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);

test("acepta una fotografía JPEG pequeña", () => {
  assert.deepEqual(decodePreviewImage(jpeg.toString("base64")), jpeg);
});

test("rechaza imágenes ausentes, dañadas, extra grandes y no soportadas", () => {
  for (const input of ["", "a", "abc*", Buffer.from("texto").toString("base64"),
    Buffer.alloc(MAX_BYTES + 1, 0x42).toString("base64")]) {
    assert.throws(() => decodePreviewImage(input), EvidencePreviewError);
  }
});

test("reconoce objetos visuales simulados sin verificar hábitos ni XP", async () => {
  let calls = 0;
  const result = await analyzeEvidencePreview({
    imageBase64: jpeg.toString("base64"), profileId: "hydration",
  }, {
    detector: async (bytes) => {
      calls++;
      assert.deepEqual(bytes, jpeg);
      return [{name: "Water bottle", score: 0.95}, {name: "Glass", score: 0.81}];
    },
  });
  assert.equal(calls, 1);
  assert.equal(result.status, "visual_match_only");
  assert.equal(result.imageVerified, false);
  assert.equal(result.xpAwarded, 0);
  assert.equal(result.coinsAwarded, 0);
  assert.equal(result.labels.length, 2);
  assert.equal("evidenceId" in result, false);
});

test("si no detecta alimento no inventa una aprobación", () => {
  const result = previewFromLabels("meal", [{name: "Car", score: 0.99}]);
  assert.equal(result.status, "inconclusive");
  assert.equal(result.imageVerified, false);
  assert.equal(result.xpAwarded, 0);
});

test("las coincidencias débiles no se anuncian como compatibles", () => {
  assert.equal(previewFromLabels("fruit_vegetable", [
    {name: "Banana", score: 0.21},
  ]).status, "inconclusive");
});

test("categoría no admitida no llama al detector", async () => {
  let calls = 0;
  await assert.rejects(analyzeEvidencePreview({
    imageBase64: jpeg.toString("base64"),
    profileId: "exercise",
  }, {detector: async () => { calls++; return []; }}), EvidencePreviewError);
  assert.equal(calls, 0);
});
