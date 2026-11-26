"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {validateActivation, validateOfficialActivation, validateActivationState} =
  require("../habit_activation_transaction");
const {SERVER_CATALOG} = require("../official_habit_catalog");
const {RegistrationPolicyError} = require("../habit_registration_policy");

const catalog = SERVER_CATALOG.alim_004;
const state = {
  user: {xp: 100, habitCoins: 80, habitSlots: 3, habitMutationVersion: 0},
  activeCount: 1, habit: null, previousAttempt: null,
  catalog, now: new Date("2026-11-21T12:00:00Z"),
};

test("solo admite tres hábitos e IDs válidos sin campos arbitrarios", () => {
  for (const habitId of ["hidr_001", "bien_007", "alim_004"]) {
    assert.equal(validateActivation({
      habitId, attemptId: "new_attempt_00001",
      operationId: "new_operation_00001",
    }).habitId, habitId);
  }
  for (const data of [
    {habitId: "alim_001", attemptId: "new_attempt_00001",
      operationId: "new_operation_00001"},
    {habitId: "alim_004", attemptId: "x/y",
      operationId: "new_operation_00001"},
    {habitId: "alim_004", attemptId: "new_attempt_00001",
      operationId: "new_operation_00001", xp: 999},
  ]) {
    assert.throws(() => validateActivation(data), RegistrationPolicyError);
  }
});

test("el nivel de desbloqueo se deriva de XP del servidor", () => {
  const ok = validateActivationState(state);
  assert.equal(ok.attemptNumber, 1);
  assert.equal(ok.versionAfter, 1);
  assert.equal(ok.coinsAfter, 80);
  assert.throws(() => validateActivationState({
    ...state, user: {...state.user, xp: 90},
  }), RegistrationPolicyError);
  assert.throws(() => validateActivationState({
    ...state, catalog: SERVER_CATALOG.bien_007,
  }), RegistrationPolicyError);
});

test("el límite de espacios y el saldo impiden activaciones indebidas", () => {
  assert.throws(() => validateActivationState({
    ...state, activeCount: 3,
  }), RegistrationPolicyError);
  assert.throws(() => validateActivationState({
    ...state, user: {...state.user, habitSlots: -1},
  }), RegistrationPolicyError);
  assert.throws(() => validateActivationState({
    ...state, user: {...state.user, habitCoins: -100},
  }), RegistrationPolicyError);
});

test("un hábito anterior activo o en enfriamiento se rechaza", () => {
  assert.throws(() => validateActivationState({
    ...state, habit: {latestStatus: "inProgress"},
  }), RegistrationPolicyError);
  assert.throws(() => validateActivationState({
    ...state, previousAttempt: {status: "inProgress"},
  }), RegistrationPolicyError);
  assert.throws(() => validateActivationState({
    ...state, previousAttempt: {
      status: "completed", attemptNumber: 1,
      availableAgainAt: new Date("2026-11-22T00:00:00Z"),
    },
  }), RegistrationPolicyError);
  assert.equal(validateActivationState({
    ...state, previousAttempt: {
      status: "completed", attemptNumber: 1,
      availableAgainAt: new Date("2026-11-20T00:00:00Z"),
    },
  }).attemptNumber, 2);
});

test("una versión o secuencia alterada se rechaza antes de escribir", () => {
  assert.throws(() => validateActivationState({
    ...state, user: {...state.user, habitMutationVersion: -1},
  }), RegistrationPolicyError);
  assert.throws(() => validateActivationState({
    ...state, previousAttempt: {attemptNumber: -4},
  }), RegistrationPolicyError);
});

test("la activación oficial permite los 36 hábitos sin cambiar el piloto", () => {
  assert.equal(Object.keys(SERVER_CATALOG).length, 36);
  for (const habitId of Object.keys(SERVER_CATALOG)) {
    const payload = {
      habitId, attemptId: "official_attempt_0001",
      operationId: "official_operation_0001",
    };
    assert.deepEqual(validateOfficialActivation(payload), payload);
    if (!["hidr_001", "bien_007", "alim_004"].includes(habitId)) {
      assert.throws(() => validateActivation(payload), RegistrationPolicyError);
    }
    for (const injected of ["xp", "habitCoins", "uid", "level"]) {
      assert.throws(() => validateOfficialActivation({
        ...payload, [injected]: 99999,
      }), RegistrationPolicyError);
    }
  }
});

test("la activación oficial admite configuración interactiva no económica", () => {
  const base = {
    habitId: "hidr_003", attemptId: "official_attempt_0001",
    operationId: "official_operation_0001",
  };
  const samples = [
    {type: "manual", target: 1, unit: "vez"},
    {type: "hydration", target: 2000, unit: "ml"},
    {type: "counter", target: 7, unit: "vasos"},
    {type: "steps", target: 10000, unit: "pasos"},
    {type: "timer", target: 60, unit: "segundos"},
    {type: "stopwatch", target: 180, unit: "segundos"},
    {type: "breathing", target: 180, unit: "segundos"},
    {type: "pomodoro", target: 1500, unit: "segundos"},
  ];
  for (const interaction of samples) {
    const request = {...base, interaction};
    assert.deepEqual(validateOfficialActivation(request), request);
    assert.throws(() => validateActivation(request),
      RegistrationPolicyError,
      "El piloto limitado a tres no acepta herramientas nuevas");
  }
});

test("herramientas manipuladas nunca pueden introducir economía ni metas libres", () => {
  const base = {
    habitId: "hidr_003", attemptId: "official_attempt_0001",
    operationId: "official_operation_0001",
  };
  const invalid = [
    {type: "counter", target: 1, unit: "vasos", xp: 999},
    {type: "timer", target: 100, unit: "minutos"},
    {type: "hydration", target: 100, unit: "pasos"},
    {type: "steps", target: 86401, unit: "pasos"},
    {type: "counter", target: 0, unit: "vasos"},
    {type: "counter", target: 1.5, unit: "vasos"},
    {type: "counter", target: 1, unit: "<script>"},
    {type: "manual", target: 5, unit: "vez"},
    {type: "counter", target: 1, unit: "vasos", value: 9999},
  ];
  for (const interaction of invalid) {
    assert.throws(() => validateOfficialActivation({...base, interaction}),
      RegistrationPolicyError);
  }
});
