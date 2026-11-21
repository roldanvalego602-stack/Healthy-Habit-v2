"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  validateRegistrationRequest, registrationEligibility,
  RegistrationPolicyError,
} = require("../habit_registration_policy");

const active = {
  habit: {latestAttemptId: "attempt-1", latestStatus: "inProgress"},
  attempt: {status: "inProgress", progress: 2, target: 3},
  attemptId: "attempt-1",
};

test("acepta solo identificadores oficiales y de intentos seguros", () => {
  assert.deepEqual(validateRegistrationRequest({
    habitId: "hidr_001", attemptId: "a1-2026",
  }), {habitId: "hidr_001", attemptId: "a1-2026"});
  for (const data of [
    null, {}, {habitId: "../users", attemptId: "a1"},
    {habitId: "demo-water", attemptId: "a1"},
    {habitId: "hidr_001", attemptId: "x/y"},
    {habitId: "hidr_010", attemptId: "a1"},
  ]) {
    assert.throws(() => validateRegistrationRequest(data),
      RegistrationPolicyError);
  }
});

test("informa progreso real y finalización sin conceder recompensas", () => {
  const result = registrationEligibility(active);
  assert.deepEqual(result, {
    eligible: true, currentProgress: 2, target: 3,
    remaining: 1, nextCompletes: true,
  });
  assert.equal(Object.hasOwn(result, "xp"), false);
  assert.equal(Object.hasOwn(result, "habitCoins"), false);
});

test("rechaza intentos anteriores o cancelados", () => {
  for (const parameters of [
    {...active, attemptId: "other"},
    {...active, habit: {...active.habit, latestStatus: "completed"}},
    {...active, attempt: {...active.attempt, status: "cancelled"}},
    {...active, habit: null},
    {...active, attempt: null},
  ]) {
    assert.throws(() => registrationEligibility(parameters),
      RegistrationPolicyError);
  }
});

test("rechaza objetivos completados y progreso alterado", () => {
  for (const attempt of [
    {status: "inProgress", progress: 3, target: 3},
    {status: "inProgress", progress: -1, target: 3},
    {status: "inProgress", progress: 2.3, target: 3},
    {status: "inProgress", progress: 0, target: 0},
    {status: "inProgress", progress: 0, target: 1000001},
  ]) {
    assert.throws(() => registrationEligibility({...active, attempt}),
      RegistrationPolicyError);
  }
});
