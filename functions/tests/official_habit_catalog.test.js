"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {SERVER_CATALOG} = require("../official_habit_catalog");

const source = fs.readFileSync(
  path.resolve(__dirname, "../../lib/páginas/habitos/catalogo.dart"),
  "utf8"
);

function readDartCatalog(text) {
  const blocks = [...text.matchAll(/_habit\(\s*([\s\S]*?)\n\s*\),/g)];
  return blocks.map(([, body]) => {
    const fields = {};
    for (const match of body.matchAll(
      /(\w+):\s*(?:'([^']*)'|(\d+)|(true|false))/g
    )) {
      fields[match[1]] = match[2] ??
        (match[3] !== undefined ? Number(match[3]) : match[4] === "true");
    }
    return fields;
  });
}

test("el catálogo Dart y el del servidor contienen los mismos 36 IDs", () => {
  const dart = readDartCatalog(source);
  const ids = dart.map((habit) => habit.id);
  assert.equal(ids.length, 36);
  assert.equal(new Set(ids).size, 36);
  assert.deepEqual(Object.keys(SERVER_CATALOG).sort(), ids.sort());
});

test("categoría, dificultad, objetivos y frecuencia coinciden con Dart", () => {
  for (const habit of readDartCatalog(source)) {
    const record = SERVER_CATALOG[habit.id];
    assert.equal(record.title, habit.title, habit.id);
    assert.equal(record.category, habit.category, habit.id);
    assert.equal(record.difficulty, habit.difficulty, habit.id);
    assert.equal(record.frequencyType, habit.frequencyType, habit.id);
    assert.equal(record.registrationsPerPeriod,
      habit.registrationsPerPeriod, habit.id);
    assert.equal(record.durationPeriods, habit.durationPeriods, habit.id);
    assert.equal(record.target,
      habit.registrationsPerPeriod * habit.durationPeriods, habit.id);
    assert.equal(record.repeatable, habit.repeatable ?? true, habit.id);
    assert.equal(record.cooldownDays, habit.cooldownDays ?? 0, habit.id);
  }
});

test("reglas derivadas de nivel, XP, gracia y coste siguen sincronizadas", () => {
  for (const item of Object.values(SERVER_CATALOG)) {
    assert.ok(["daily", "weekly"].includes(item.frequencyType));
    assert.ok(Number.isSafeInteger(item.target) && item.target > 0);
    assert.equal(item.coinCost, 0);
    const difficulty = item.difficulty;
    assert.equal(item.requiredLevel,
      difficulty === "Sencillo" ? 1 : difficulty === "Moderado" ? 2 : 4);
    assert.equal(item.xp,
      difficulty === "Sencillo" ? 10 : difficulty === "Moderado" ? 15 : 20);
    assert.equal(item.gracePeriods, difficulty === "Difícil" ? 0 : 1);
  }
});

test("el piloto aún no permite escrituras para hábitos nuevos", () => {
  const {validateDemoRegistration} =
    require("../habit_registration_transaction");
  assert.doesNotThrow(() => validateDemoRegistration({
    habitId: "hidr_001", attemptId: "attempt-1",
    operationId: "pilot_attempt_0001",
  }));
  for (const habitId of Object.keys(SERVER_CATALOG)) {
    if (habitId === "hidr_001") continue;
    assert.throws(() => validateDemoRegistration({
      habitId, attemptId: "attempt-1", operationId: "pilot_attempt_0001",
    }), /no habilitado para el piloto/);
  }
});
