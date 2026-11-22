"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  validateCancellation, validateOfficialCancellation, calculateCancellation,
} = require("../habit_cancellation_transaction");
const {SERVER_CATALOG} = require("../official_habit_catalog");
const {RegistrationPolicyError} = require("../habit_registration_policy");

const data = {habitId: "bien_007", attemptId: "attempt_valid_0001",
  operationId: "cancel_valid_0001", maxPenalty: 25};
const state = {
  user: {habitCoins: 40, habitMutationVersion: 2},
  habit: {lastAttemptId: data.attemptId,
    latestAttemptId: data.attemptId,
    lastStatus: "inProgress", latestStatus: "inProgress"},
  attempt: {status: "inProgress"},
  catalog: SERVER_CATALOG.bien_007,
  attemptId: data.attemptId,
  maxPenalty: 25,
};

test("valida IDs y exige máximo de penalización confirmado", () => {
  assert.deepEqual(validateCancellation(data), data);
  for (const request of [
    {...data, maxPenalty: 26},
    {...data, maxPenalty: -1},
    {...data, maxPenalty: "25"},
    {...data, habitId: "alim_001"},
    {...data, xp: 1000},
    {...data, operationId: "../wrong"},
  ]) assert.throws(() => validateCancellation(request),
    RegistrationPolicyError);
});

test("difícil descuenta máximo 25 o saldo disponible sin deuda", () => {
  assert.deepEqual(calculateCancellation(state), {
    penalty: 25, balanceAfter: 15, versionAfter: 3,
  });
  assert.deepEqual(calculateCancellation({
    ...state, user: {...state.user, habitCoins: 12},
  }), {penalty: 12, balanceAfter: 0, versionAfter: 3});
});

test("moderar o sencillo no implica sanción por cancelación", () => {
  for (const catalog of [
    SERVER_CATALOG.alim_004, SERVER_CATALOG.hidr_001,
  ]) {
    assert.equal(calculateCancellation({
      ...state, catalog, maxPenalty: 0,
    }).penalty, 0);
  }
});

test("rechaza cuando el cobro supera lo confirmado", () => {
  assert.throws(() => calculateCancellation({
    ...state, maxPenalty: 15,
  }), RegistrationPolicyError);
});

test("no permite cancelar intentos finalizados, ajenos o antiguos", () => {
  for (const override of [
    {habit: {...state.habit, lastAttemptId: "another"}},
    {habit: {...state.habit, latestStatus: "completed"}},
    {attempt: {status: "cancelled"}},
  ]) {
    assert.throws(() => calculateCancellation({...state, ...override}),
      RegistrationPolicyError);
  }
});

test("rechaza economía inconsistente antes de efectuar descuentos", () => {
  for (const user of [{habitCoins: -1}, {habitCoins: NaN},
    {habitCoins: 20.5}, {habitCoins: 10, habitMutationVersion: -2}]) {
    assert.throws(() => calculateCancellation({
      ...state, user,
    }), RegistrationPolicyError);
  }
});

test("la cancelación oficial cubre 36 hábitos, con penalización según dificultad", () => {
  assert.equal(Object.keys(SERVER_CATALOG).length, 36);
  for (const [habitId, catalog] of Object.entries(SERVER_CATALOG)) {
    const request = {...data, habitId};
    assert.deepEqual(validateOfficialCancellation(request), request);
    if (!["hidr_001", "bien_007", "alim_004"].includes(habitId)) {
      assert.throws(() => validateCancellation(request),
        RegistrationPolicyError);
    }
    const outcome = calculateCancellation({...state, catalog});
    assert.equal(outcome.penalty,
      catalog.difficulty === "Difícil" ? 25 : 0, habitId);
    for (const field of ["xp", "habitCoins", "uid", "status"]) {
      assert.throws(() => validateOfficialCancellation({
        ...request, [field]: 9999,
      }), RegistrationPolicyError);
    }
  }
});
