"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  assertOfficialRequest, createOfficialHabitDispatcher,
} = require("../official_beta_dispatcher");

const ids = Object.freeze({
  habitId: "alim_001",
  attemptId: "attempt_1234567890",
  operationId: "operation_1234567890",
});

test("rechaza operaciones desconocidas y sesiones sin UID", () => {
  assert.throws(() => assertOfficialRequest({
    action: "grant", uid: "alice", data: ids,
  }), {code: "invalid-argument"});
  assert.throws(() => assertOfficialRequest({
    action: "register", uid: "", data: ids,
  }), {code: "unauthenticated"});
});

test("rechaza campos económicos, progreso y evidencia verificada suministrados por el cliente", () => {
  for (const key of ["xp", "xpAwarded", "habitCoins", "coinsAwarded",
    "level", "progress", "rewardCoins", "evidenceVerified"]) {
    assert.throws(() => assertOfficialRequest({
      action: "register", uid: "alice", data: {...ids, [key]: 999},
    }), {code: "invalid-argument"}, key);
  }
});

test("rechaza identificadores faltantes y datos de tipo incorrecto", () => {
  assert.throws(() => assertOfficialRequest({
    action: "activate", uid: "alice", data: null,
  }), {code: "invalid-argument"});
  assert.throws(() => assertOfficialRequest({
    action: "activate", uid: "alice", data: {habitId: ids.habitId},
  }), {code: "invalid-argument"});
});

test("delegación no calcula XP y conserva identificador original", async () => {
  const called = [];
  const dispatch = createOfficialHabitDispatcher({
    activate: async (payload) => {called.push(["activate", payload]); return {ok: true};},
    cancel: async (payload) => {called.push(["cancel", payload]); return {ok: true};},
    register: async (payload) => {called.push(["register", payload]); return {ok: true};},
  });
  const db = {runTransaction() {}};
  for (const action of ["activate", "cancel", "register"]) {
    assert.deepEqual(await dispatch({action, uid: "alice", data: ids, db}), {ok: true});
  }
  assert.deepEqual(called.map(([action]) => action), ["activate", "cancel", "register"]);
  for (const [, payload] of called) {
    assert.equal(payload.uid, "alice");
    assert.equal(payload.db, db);
    assert.equal(payload.data.operationId, ids.operationId);
    assert.equal(Object.hasOwn(payload.data, "xp"), false);
  }
});

test("rechaza un cliente que intente suministrar un Firestore inválido", async () => {
  const dispatch = createOfficialHabitDispatcher({
    activate: async () => ({}), cancel: async () => ({}), register: async () => ({}),
  });
  await assert.rejects(
    dispatch({action: "register", uid: "alice", data: ids, db: {}}),
    /Firestore de servidor/
  );
});
