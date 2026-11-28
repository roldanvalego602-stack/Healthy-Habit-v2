"use strict";
const assert=require("node:assert/strict");
const test=require("node:test");
const {reserveHabitEvidence}=require("../habit_evidence_reservation");

function fixture() {
  const uid="usuario_reserva_beta_12345";
  const habitId="alim_001";
  const attemptId="intento_reserva_1234567890";
  const userRef=`users/${uid}`;
  const habitRef=`${userRef}/user_habits/${habitId}`;
  const attemptRef=`${habitRef}/attempts/${attemptId}`;
  const docs=new Map([
    [userRef,{xp:50,habitCoins:25}],
    [habitRef,{latestAttemptId:attemptId,latestStatus:"inProgress"}],
    [attemptRef,{habitId,status:"inProgress"}],
  ]);
  const db={
    collection:name=>({doc:id=>node(name+"/"+id)}),
    runTransaction:async fn=>fn({
      get:async ref=>({exists:docs.has(ref.path),data:()=>docs.get(ref.path)}),
      create:(ref,data)=>{assert.equal(docs.has(ref.path),false);docs.set(ref.path,data);},
      set:(ref,data,opts)=>docs.set(ref.path,{
        ...(opts?.merge?docs.get(ref.path):{}),...data,
      }),
    }),
  };
  function node(x) {
    return {path:x,collection:name=>({doc:id=>node(x+"/"+name+"/"+id)})};
  }
  return {db,docs,uid,habitId,attemptId};
}

test("doce fotos como máximo por día, idempotentes, sin premios", async () => {
  const f=fixture();
  const now=new Date("2026-11-27T18:00:00Z");
  const base={habitId:f.habitId,attemptId:f.attemptId};
  for(let i=0;i<12;i++) {
    const data={...base,operationId:"operation_quota_123456_"+i};
    const r=await reserveHabitEvidence({
      db:f.db,uid:f.uid,data,now,dailyQuota:12,
    });
    assert.equal(r.alreadyReserved,false);
  }
  const repeat=await reserveHabitEvidence({
    db:f.db,uid:f.uid,data:{...base,operationId:"operation_quota_123456_0"},
    now,dailyQuota:12,
  });
  assert.equal(repeat.alreadyReserved,true);
  await assert.rejects(reserveHabitEvidence({
    db:f.db,uid:f.uid,data:{...base,operationId:"operation_quota_123456_99"},
    now,dailyQuota:12,
  }),e=>e.code==="resource-exhausted");
  assert.equal(f.docs.get(`users/${f.uid}`).habitCoins,25);
  assert.equal(f.docs.get(`users/${f.uid}`).xp,50);
});

test("el consentimiento remoto no se modifica al reintentar", async () => {
  const f=fixture();
  const now=new Date("2026-11-27T18:00:00Z");
  const base={habitId:f.habitId,attemptId:f.attemptId,
    operationId:"consent_operation_123456"};
  await reserveHabitEvidence({
    db:f.db,uid:f.uid,data:{...base,visionConsent:false},
    now,dailyQuota:12,
  });
  await assert.rejects(reserveHabitEvidence({
    db:f.db,uid:f.uid,data:{...base,visionConsent:true},
    now,dailyQuota:12,
  }),error=>error.code==="already-exists");
  assert.equal(f.docs.get(
    `users/${f.uid}/habit_evidence_reservations/${base.operationId}`)
    .visionConsent,false);
  const allowed=await reserveHabitEvidence({
    db:f.db,uid:f.uid,data:{...base,visionConsent:false},
    now,dailyQuota:12,
  });
  assert.equal(allowed.alreadyReserved,true);
});

test("una foto de otro intento se rechaza antes de consumir cuota", async () => {
  const f=fixture();
  const data={habitId:f.habitId,attemptId:"intento_ajeno_123456789",
    operationId:"operation_other_1234567"};
  await assert.rejects(reserveHabitEvidence({
    db:f.db,uid:f.uid,data,dailyQuota:12,
  }),e=>e.code==="not-found");
  assert.equal([...f.docs.keys()].some(x=>x.includes("daily_limits")),false);
});
