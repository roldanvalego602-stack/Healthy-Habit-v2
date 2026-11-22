"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  getAvailableChallengeOptions,
  validateChoice,
  evaluateVisualEvidence,
} = require("../evidence_policy");
const {assessEvidenceImage, detectLabels} = require("../evidence_vision");

test("ofrece alternativas accesibles, no un objeto obligatorio", () => {
  const options = getAvailableChallengeOptions();
  assert.ok(options.length >= 4);
  assert.ok(options.some((o) => o.id === "spoon"));
  assert.ok(options.some((o) => o.id === "paper"));
  assert.ok(validateChoice("cup"));
  assert.equal(validateChoice("passport"), false);
});

test("una foto de agua sin desafío no se acepta como verificación", () => {
  const r = evaluateVisualEvidence({
    profileId: "hydration",
    detections: [{name: "Water", score: 0.98}],
  });
  assert.equal(r.status, "review");
  assert.equal(r.reason, "session_challenge_required");
});

test("contenido y objeto compatible producen coincidencia visual, no aprobación final", () => {
  const r = evaluateVisualEvidence({
    profileId: "hydration",
    challengeObjectId: "spoon",
    detections: [
      {name: "Water bottle", score: 0.94},
      {name: "Spoon", score: 0.82},
    ],
  });
  assert.equal(r.status, "supported");
  assert.equal(r.reason, "visual_match_only");
});

test("rechaza coincidencias de baja confianza sin penalizar al usuario", () => {
  const r = evaluateVisualEvidence({
    profileId: "hydration",
    challengeObjectId: "spoon",
    detections: [
      {name: "Water", score: 0.3},
      {name: "Spoon", score: 0.8},
    ],
  });
  assert.equal(r.status, "review");
  assert.equal(r.reason, "habit_content_not_detected");
});

test("un hábito no soportado requiere revisión, no se inventa una etiqueta", () => {
  const r = evaluateVisualEvidence({
    profileId: "exercise",
    challengeObjectId: "spoon",
    detections: [{name: "Spoon", score: 0.99}],
  });
  assert.equal(r.reason, "unsupported_habit");
});

test("el adaptador combina etiquetas y objetos del detector simulado", async () => {
  const client = {
    labelDetection: async () => [{
      labelAnnotations: [{description: "Water bottle", score: 0.92}],
    }],
    objectLocalization: async () => [{
      localizedObjectAnnotations: [{name: "Spoon", score: 0.85}],
    }],
  };
  const result = await assessEvidenceImage({
    imageBytes: Buffer.from("simulated image"),
    profileId: "hydration",
    challengeObjectId: "spoon",
    visionClient: client,
  });
  assert.equal(result.status, "supported");
});

test("el adaptador limita tamaño antes de llamar a un proveedor externo", async () => {
  await assert.rejects(
    detectLabels(Buffer.alloc(250 * 1024 + 1)),
    TypeError
  );
});
