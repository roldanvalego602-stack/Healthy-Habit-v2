"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {rewardCoins, legacyRewardCoins, planVerifiedDay} = require("../streak_day_policy");

function plan(previousDay, previousStreak, date, zone = "America/Monterrey") {
  return planVerifiedDay({
    previousDay, previousStreak, previousBest: 4,
    now: new Date(date), timeZone: zone,
  });
}

test("un registro oficial inicia un día en uno y genera premio pequeño", () => {
  const p = plan(null, 0, "2026-11-22T16:00:00Z");
  assert.deepEqual([p.day, p.streak, p.best, p.rewardCoins, p.isNewDay],
    ["2026-11-22", 1, 4, 10, true]);
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

test("premios escalonados entre 10 y 200 monedas", () => {
  const days = [1, 2, 3, 4, 6, 7, 13, 14, 20, 21, 29,
    30, 44, 45, 59, 60, 89, 90, 119, 120, 179, 180, 1000];
  assert.deepEqual(days.map(rewardCoins),
    [10, 15, 15, 20, 20, 30, 30, 45, 45, 60, 60,
      80, 80, 100, 100, 125, 125, 150, 150, 175, 175, 200, 200]);
  for (let i = 1; i <= 1000; i++) {
    assert.ok(rewardCoins(i) >= 10 && rewardCoins(i) <= 200);
  }
  assert.deepEqual([1, 2, 4, 7].map(legacyRewardCoins), [2, 3, 4, 5]);
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
