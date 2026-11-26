"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {requireBetaHabitAccess, createBetaHabitHandler, PRODUCTION_PROJECT} =
  require("../official_beta_access");

const enabled = Object.freeze({
  GCLOUD_PROJECT: PRODUCTION_PROJECT,
  HH_BETA_HABITS_ENABLED: "true",
  HH_BETA_RULES_VERIFIED: "true",
  HH_BETA_TEST_UIDS: "user_alice,user_bob",
});
const request = Object.freeze({
  auth: {uid: "user_alice"},
  app: {appId: "1:1096497487747:android:test"},
  data: {habitId: "alim_001", attemptId: "attempt_123456789",
    operationId: "operation_123456789"},
});

test("beta queda cerrada sin configuración, en un proyecto demo o con reglas sin validar", () => {
  for (const env of [
    {},
    {...enabled, GCLOUD_PROJECT: "demo-healthy-habit"},
    {...enabled, HH_BETA_HABITS_ENABLED: "false"},
    {...enabled, HH_BETA_RULES_VERIFIED: "false"},
  ]) {
    assert.throws(() => requireBetaHabitAccess(request, env),
      {code: "failed-precondition"});
  }
});

test("rechaza anonimato, ausencia de App Check o UID ajeno", () => {
  assert.throws(() => requireBetaHabitAccess({...request, auth: null}, enabled),
    {code: "unauthenticated"});
  assert.throws(() => requireBetaHabitAccess({...request, app: null}, enabled),
    {code: "permission-denied"});
  assert.throws(() => requireBetaHabitAccess({
    ...request, auth: {uid: "user_other"},
  }, enabled), {code: "permission-denied"});
  assert.throws(() => requireBetaHabitAccess(request, {
    ...enabled, HH_BETA_TEST_UIDS: "",
  }), {code: "permission-denied"});
});

test("con todas las barreras superadas conserva el UID autenticado", () => {
  assert.equal(requireBetaHabitAccess(request, enabled), "user_alice");
});

test("despacho no se ejecuta si falla la barrera de beta", async () => {
  let count = 0;
  const dispatch = async ({action, uid, data, db}) => {
    count++;
    return {action, uid, data, db};
  };
  const db = {runTransaction() {}};
  const disabledHandler = createBetaHabitHandler({
    dispatch, action: "register", env: {},
  });
  await assert.rejects(disabledHandler({request, db}),
    {code: "failed-precondition"});
  assert.equal(count, 0);
  const activeHandler = createBetaHabitHandler({
    dispatch, action: "register", env: enabled,
  });
  const result = await activeHandler({request, db});
  assert.equal(result.action, "register");
  assert.equal(result.uid, "user_alice");
  assert.equal(result.data.operationId, request.data.operationId);
  assert.equal(result.db, db);
  assert.equal(count, 1);
});

test("no acepta una acción diferente de activar, cancelar o registrar", () => {
  assert.throws(() => createBetaHabitHandler({
    dispatch: async () => {}, action: "grant",
  }), TypeError);
});
