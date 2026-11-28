"use strict";
const assert=require("node:assert/strict");
const test=require("node:test");
const {betaEvidenceCleanupReady}=
  require("../beta_evidence_schedule_policy");
const {purgeExpiredEvidence}=require("../habit_evidence_cleanup");

const ready={
  GCLOUD_PROJECT:"cloud-firestore-d8c61",
  HH_BETA_HABITS_ENABLED:"true",
  HH_BETA_RULES_VERIFIED:"true",
  HH_BETA_EVIDENCE_ENABLED:"true",
  HH_BETA_EVIDENCE_CLEANUP_ENABLED:"true",
};

test("la limpieza real requiere todas las banderas y ningún emulador", () => {
  assert.equal(betaEvidenceCleanupReady(ready),true);
  for(const disabled of Object.keys(ready)) {
    assert.equal(betaEvidenceCleanupReady({...ready,[disabled]:"false"}),
      false,disabled);
  }
  assert.equal(betaEvidenceCleanupReady({
    ...ready,FIRESTORE_EMULATOR_HOST:"127.0.0.1:8080",
  }),false);
  assert.equal(betaEvidenceCleanupReady({
    ...ready,FIREBASE_STORAGE_EMULATOR_HOST:"127.0.0.1:9199",
  }),false);
  assert.equal(betaEvidenceCleanupReady({
    ...ready,GCLOUD_PROJECT:"demo-healthy-habit",
  }),false);
});

test("la función de purga rechaza la beta no auditada antes de tocar Storage", async () => {
  let accessed=false;
  const bucket={file:()=>{accessed=true;throw Error("NO");}};
  await assert.rejects(purgeExpiredEvidence({
    db:{collectionGroup:()=>{accessed=true;throw Error("NO");}},
    bucket,allowProduction:true,
    env:{...ready,HH_BETA_RULES_VERIFIED:"false"},
  }),/emuladores demo o beta auditada/);
  assert.equal(accessed,false);
});
