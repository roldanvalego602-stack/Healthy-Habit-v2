"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {rewardCoins, planVerifiedDay} = require("../streak_day_policy");

function plan(previousDay, previousStreak, date, zone = "America/Monterrey") {
  return planVerifiedDay({
    previousDay, previousStreak, previousBest: 4,
    now: new Date(date), timeZone: zone,
  });
}

test("un registro oficial inicia un día en uno y genera premio pequeño", () => {
  const p = plan(null, 0, "2026-11-22T16:00:00Z");
  assert.deepEqual([p.day, p.streak, p.best, p.rewardCoins, p.isNewDay],
    ["2026-11-22", 1, 4, 2, true]);
});

test("avance consecutivo y reinicio tras un día sin actividad", () => {
  assert.equal(plan("2026-11-21", 4, "2026-11-22T16:00:00Z").streak, 5);
  assert.equal(plan("2026-11-19", 4, "2026-11-22T16:00:00Z").streak, 1);
});

test("un segundo registro durante el mismo día no genera otro premio", () => {
  const p = plan("2026-11-22", 3, "2026-11-22T22:00:00Z");
  assert.equal(p.streak, 3);
  assert.equal(p.isNewDay, false);
});

test("el cambio de día respeta zona horaria y no UTC", () => {
  const p = plan("2026-11-21", 1, "2026-11-22T01:30:00Z");
  assert.equal(p.day, "2026-11-21");
  assert.equal(p.isNewDay, false);
});

test("niveles de premio limitados entre dos y cinco monedas", () => {
  assert.deepEqual([1, 2, 3, 4, 6, 7, 1000].map(rewardCoins),
    [2, 3, 3, 4, 4, 5, 5]);
});

test("rechaza rachas y fechas manipuladas", () => {
  for (const n of [0, -1, NaN, 2.3, "99"]) {
    assert.throws(() => rewardCoins(n));
  }
  assert.throws(() => plan("2026-11-29", 4,
    "2026-11-22T16:00:00Z"));
  assert.throws(() => plan("2026-11-31", 4,
    "2026-11-22T16:00:00Z"));
});
