"use strict";
const assert = require("node:assert/strict");
const test = require("node:test");
const {requireBetaEvidenceAccess, evidenceBucketName} =
  require("../official_beta_evidence_access");
const {getEvidenceStatus, validateEvidenceIdentity} =
  require("../habit_evidence_status");

const env = {
  GCLOUD_PROJECT: "cloud-firestore-d8c61",
  HH_BETA_HABITS_ENABLED: "true",
  HH_BETA_RULES_VERIFIED: "true",
  HH_BETA_TEST_UIDS: "usuario_pruebas",
  HH_BETA_EVIDENCE_ENABLED: "true",
};
const request = {auth: {uid: "usuario_pruebas"}, app: {appId: "app_test"}};
const ids = {
  habitId: "alim_001", attemptId: "attempt_test_12345678",
  operationId: "operation_test_123456",
};
function dbFixture({status = "uploaded", operationId = ids.operationId,
  expire = 9999999999999, attached = false} = {}) {
  const path = `habit-evidence/usuario_pruebas/${ids.attemptId}/${ids.operationId}`;
  const info = {uid: "usuario_pruebas", ...ids,
    operationId, storagePath: path, status,
    expiresAt: {toMillis: () => expire}};
  const docs = new Map([
    [`users/usuario_pruebas/habit_evidence_reservations/${ids.operationId}`,info],
    ...(attached ? [[`users/usuario_pruebas/user_habits/${ids.habitId}/attempts/${ids.attemptId}/logs/${ids.operationId}`,
      {userId:"usuario_pruebas",evidencePath:path}]] : []),
  ]);
  return {collection: (name) => ({doc: (id) => node(name + "/" + id)})};
  function node(path) {
    return {
      collection: (name) => ({doc: (id) => node(path + "/" + name + "/" + id)}),
      get: async () => ({exists: docs.has(path), data: () => docs.get(path)}),
    };
  }
}

test("beta de evidencias exige cuatro barreras independientes", () => {
  assert.equal(requireBetaEvidenceAccess(request, env), "usuario_pruebas");
  for (const change of [
    {HH_BETA_EVIDENCE_ENABLED:"false"},
    {HH_BETA_HABITS_ENABLED:"false"},
    {HH_BETA_RULES_VERIFIED:"false"},
    {GCLOUD_PROJECT:"demo-healthy-habit"},
    {HH_BETA_TEST_UIDS:"otra_cuenta"},
  ]) {
    assert.throws(() => requireBetaEvidenceAccess(request, {...env,...change}));
  }
  assert.throws(() => requireBetaEvidenceAccess({
    auth:request.auth,app:null}, env));
  assert.equal(evidenceBucketName(env.GCLOUD_PROJECT),
    "cloud-firestore-d8c61.firebasestorage.app");
  assert.throws(() => evidenceBucketName("otro-proyecto"));
});

test("estado de evidencia requiere IDs canónicos y no acepta premios cliente", () => {
  assert.deepEqual(validateEvidenceIdentity({
    uid:"usuario_pruebas",data:ids,
  }),ids);
  for(const addition of [
    {xp:20},{verified:true},{imageBase64:"foto"}, {uid:"otra"},
  ]) assert.throws(() => validateEvidenceIdentity({
    uid:"usuario_pruebas",data:{...ids,...addition},
  }));
  assert.throws(() => validateEvidenceIdentity({
    uid:"usuario_pruebas",data:{...ids,attemptId:"../otro"},
  }));
});

test("una reserva subida nunca declara cumplimiento confirmado", async () => {
  const result = await getEvidenceStatus({db: dbFixture({}),
    uid:"usuario_pruebas",data:ids});
  assert.deepEqual(result,{status:"uploaded",attached:false,contentVerified:false});
});

test("la asociación exige registro real del mismo usuario", async () => {
  await assert.rejects(getEvidenceStatus({
    db:dbFixture({status:"attached"}),uid:"usuario_pruebas",data:ids,
  }),error=>error.code==="failed-precondition");
  const result = await getEvidenceStatus({
    db:dbFixture({status:"attached",attached:true}),
    uid:"usuario_pruebas",data:ids,
  });
  assert.deepEqual(result,{status:"attached",attached:true,contentVerified:false});
});

test("reserva expirada no permite afirmar evidencia actual", async () => {
  const result = await getEvidenceStatus({db:dbFixture({expire:1}),
    uid:"usuario_pruebas",data:ids,now:new Date("2026-11-28")});
  assert.equal(result.status,"expired");
  assert.equal(result.attached,false);
});

test("una reserva ausente no se inventa", async () => {
  function emptyDoc() {
    return {
      collection: () => ({doc: () => emptyDoc()}),
      get: async () => ({exists: false}),
    };
  }
  const db = {collection: () => ({doc: () => emptyDoc()})};
  const result = await getEvidenceStatus({
    db, uid: "usuario_pruebas", data: ids,
  });
  assert.equal(result.status, "not_reserved");
});
