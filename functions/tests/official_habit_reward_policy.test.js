"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {SERVER_CATALOG} = require("../official_habit_catalog");
const {RegistrationPolicyError} = require("../habit_registration_policy");
const {
  parseOfficialRegistration,
  planOfficialReward,
} = require("../official_habit_reward_policy");

function input(habitId) {
  return {
    habitId,
    attemptId: "attempt_0000000001",
    operationId: "operation_00000001",
  };
}
function state(habitId, overrides = {}) {
  const catalog = SERVER_CATALOG[habitId];
  return {
    data: input(habitId),
    user: {xp: 0, habitCoins: 100, claimedLevelRewards: []},
    attempt: {
      habitId, status: "inProgress", progress: 0,
      target: catalog.target, xpEarned: 0,
      frequencyType: catalog.frequencyType,
      registrationsPerPeriod: catalog.registrationsPerPeriod,
    },
    periodCount: 0,
    ...overrides,
  };
}

test("los 36 hábitos calculan XP desde el catálogo, no desde el cliente", () => {
  assert.equal(Object.keys(SERVER_CATALOG).length, 36);
  for (const [habitId, catalog] of Object.entries(SERVER_CATALOG)) {
    const reward = planOfficialReward(state(habitId));
    assert.equal(reward.habitId, habitId);
    assert.equal(reward.xpAwarded, catalog.xp, habitId);
    assert.equal(reward.xp, catalog.xp, habitId);
    assert.equal(reward.attemptXp, catalog.xp, habitId);
    assert.equal(reward.progress, 1, habitId);
    assert.equal(reward.periodCount, 1, habitId);
  }
});

test("peticiones cliente no pueden escoger XP, monedas, logros o progreso", () => {
  for (const bad of [
    {...input("alim_001"), xp: 9999},
    {...input("alim_001"), xpAwarded: 9999},
    {...input("alim_001"), habitCoins: 9999},
    {...input("alim_001"), progress: 7},
    {...input("alim_001"), uid: "otro_usuario"},
    {...input("alim_001"), evidenceVerified: true},
    {...input("alim_001"), operationId: "short"},
    {...input("alim_001"), attemptId: "../otro"},
    {...input("fake_001")},
  ]) {
    assert.throws(
      () => parseOfficialRegistration(bad), RegistrationPolicyError
    );
  }
  assert.equal(parseOfficialRegistration(input("bien_009")).habitId,
    "bien_009");
});

test("se aplica el cupo del periodo oficial en los 36 hábitos", () => {
  for (const [habitId, catalog] of Object.entries(SERVER_CATALOG)) {
    const valid = state(habitId);
    assert.throws(
      () => planOfficialReward({
        ...valid, periodCount: catalog.registrationsPerPeriod,
      }), /límite/
    );
    if (catalog.registrationsPerPeriod > 1) {
      const second = planOfficialReward({...valid, periodCount: 1});
      assert.equal(second.periodCount, 2);
    }
  }
});

test("rechaza intentos completos, inválidos o de otro hábito", () => {
  const valid = state("hidr_001");
  for (const attempt of [
    {...valid.attempt, status: "completed"},
    {...valid.attempt, habitId: "alim_001"},
    {...valid.attempt, target: 100000},
    {...valid.attempt, progress: valid.attempt.target},
    {...valid.attempt, frequencyType: "weekly"},
    {...valid.attempt, registrationsPerPeriod: 999},
  ]) {
    assert.throws(() => planOfficialReward({...valid, attempt}));
  }
});

test("los premios de nivel se calculan una vez y no se vuelven a conceder", () => {
  const valid = state("bien_007", {
    user: {xp: 90, habitCoins: 100, claimedLevelRewards: []},
  });
  const result = planOfficialReward(valid);
  assert.equal(result.xpAwarded, 20);
  assert.equal(result.xp, 110);
  assert.equal(result.level, 2);
  assert.equal(result.coinsAwarded, 25);
  assert.equal(result.coins, 125);
  assert.deepEqual(result.claimedLevelRewards, [2]);

  const alreadyClaimed = planOfficialReward({
    ...valid, user: {...valid.user, claimedLevelRewards: [2]},
  });
  assert.equal(alreadyClaimed.coinsAwarded, 0);
  assert.equal(alreadyClaimed.coins, 100);
});

test("los campos económicos malformados se rechazan sin modificarlos", () => {
  const valid = state("alim_004");
  for (const user of [
    {...valid.user, xp: -1},
    {...valid.user, habitCoins: 0.5},
    {...valid.user, claimedLevelRewards: [2, 2]},
    {...valid.user, claimedLevelRewards: [999]},
    {...valid.user, claimedLevelRewards: "2"},
  ]) {
    assert.throws(() => planOfficialReward({...valid, user}));
  }
});

test("el cálculo no cambia el estado persistido recibido", () => {
  const valid = state("alim_001");
  const original = JSON.stringify(valid);
  planOfficialReward(valid);
  assert.equal(JSON.stringify(valid), original);
});
