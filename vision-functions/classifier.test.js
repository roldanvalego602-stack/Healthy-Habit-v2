"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {present} = require("./classifier");

function labels(...values) {
  return [{labelAnnotations: values.map(([description, score]) =>
    ({description, score}))}, {localizedObjectAnnotations: []}];
}

test("una captura del clima no es evidencia de comida", () => {
  const result = present("meal", labels(
      ["Text", 0.96], ["Font", 0.91], ["Screenshot", 0.89],
      ["Electronic device", 0.88], ["Technology", 0.87]));
  assert.equal(result.status, "inconclusive");
  assert.equal(result.xpAwarded, 0);
  assert.equal(result.coinsAwarded, 0);
  assert.equal(result.imageVerified, false);
});

test("una imagen alimentaria puede mostrar coincidencia orientativa", () => {
  const result = present("meal", labels(
      ["Food", 0.94], ["Cereal", 0.80], ["Text", 0.90]));
  assert.equal(result.status, "visual_match_only");
  assert.equal(result.imageVerified, false);
});

test("un vaso o una botella genérica no prueban hidratación", () => {
  const result = present("hydration", labels(
      ["Glass", 0.98], ["Bottle", 0.96], ["Plastic", 0.80]));
  assert.equal(result.status, "inconclusive");
});

test("agua detectada a alta confianza solo produce coincidencia visual", () => {
  const result = present("hydration", labels(["Drinking water", 0.95]));
  assert.equal(result.status, "visual_match_only");
  assert.equal(result.imageVerified, false);
  assert.equal(result.xpAwarded, 0);
});

test("los términos parciales no aprueban contenido ajeno", () => {
  const result = present("meal", labels(["Food photography app", 0.99]));
  assert.equal(result.status, "inconclusive");
});

test("ignora confianza insuficiente y limita etiquetas", () => {
  const values = Array.from({length: 30}, (_, i) => ["Tag " + i, 0.8]);
  values.push(["Fruit", 0.69]);
  const result = present("fruit_vegetable", labels(...values));
  assert.equal(result.labels.length, 12);
  assert.equal(result.status, "inconclusive");
});
