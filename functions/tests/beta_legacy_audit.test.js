"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {parseOptions, classifyProfile} = require("../tools/auditar_legado_beta");

const cutoff = new Date("2026-11-28T06:00:00.000Z");

test("la auditoría no permite cambios, otro proyecto ni un corte sin UTC", () => {
  const required = [
    "--project=cloud-firestore-d8c61", "--database=default",
    "--cutover-utc=2026-11-28T06:00:00Z", "--read-only-confirm",
  ];
  assert.equal(parseOptions(required).databaseId, "default");
  assert.equal(parseOptions([...required, "--limit=4"]).limit, 4);
  for (const args of [
    required.filter((x) => x !== "--read-only-confirm"),
    required.filter((x) => !x.startsWith("--project")),
    required.map((x) => x === "--database=default" ?
      "--database=(default)" : x),
    required.map((x) => x.startsWith("--cutover-utc") ?
      "--cutover-utc=2026-11-28T06:00:00" : x),
    [...required, "--limit=20000"],
  ]) assert.throws(() => parseOptions(args));
});

test("clasifica recompensas históricas sospechosas sin extraer PII", () => {
  const old = classifyProfile({
    habitCoins: 99999, xp: 3000, currentStreak: 22, level: 1,
    profileTitle: "Leyenda saludable",
    shopInventory: ["crown", "crown", "no_existe"],
    email: "secreto@example.test", name: "Nombre Privado",
  }, new Date("2026-11-01T00:00:00Z"), cutoff);
  assert.equal(old.historicalOrUnknown, true);
  assert.equal(old.duplicateInventory, true);
  assert.equal(old.unknownShopItem, true);
  assert.equal(old.invalidBalance, false);
  assert.equal(old.legacyProgress, true);
  assert.equal(old.suspiciousTitle, true);
  assert.equal(JSON.stringify(old).includes("example.test"), false);
  const fresh = classifyProfile({
    habitCoins: 100, xp: 0, level: 1, currentStreak: 0,
    shopInventory: [], shopEquipped: {},
  }, new Date("2026-11-29T00:00:00Z"), cutoff);
  assert.equal(fresh.historicalOrUnknown, false);
  assert.equal(fresh.duplicateInventory, false);
  assert.equal(fresh.unknownShopItem, false);
  assert.equal(fresh.invalidBalance, false);
  assert.equal(fresh.legacyProgress, false);
});
