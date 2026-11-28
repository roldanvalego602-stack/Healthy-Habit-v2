"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  HABIT_PROFILE, validateRequest, imageFormatValid,
  interpretation, EvidenceAssessmentError, assessAttachedEvidence,
} = require("./evidence_assessment");

const uid = "usuario_de_beta";
const ids = {habitId:"alim_001",
  attemptId:"attempt_test_12345678",operationId:"operation_test_123456"};
const path = `habit-evidence/${uid}/${ids.attemptId}/${ids.operationId}`;

test("categorías conservadoras: no se evalúan todos los hábitos", () => {
  assert.equal(HABIT_PROFILE.alim_001,"fruit_vegetable");
  assert.equal(HABIT_PROFILE.bien_001,undefined);
  assert.equal(HABIT_PROFILE.ener_001,undefined);
});

test("no recibe etiquetas, premios ni rutas desde el cliente", () => {
  assert.deepEqual(validateRequest(uid,ids),ids);
  for(const injection of [
    {xpAwarded:999},{coinsAwarded:50},{labels:["apple"]},
    {storagePath:"habit-evidence/other"},{uid:"otro"},
  ]) {
    assert.throws(()=>validateRequest(uid,{...ids,...injection}),
      EvidenceAssessmentError);
  }
  assert.throws(()=>validateRequest(uid,{...ids,attemptId:"x/y"}));
});

test("el clasificador solo afirma coincidencia visual", () => {
  const match=interpretation("fruit_vegetable",[
    {labelAnnotations:[{description:"Apple",score:0.94}]},
    {localizedObjectAnnotations:[]},
  ]);
  assert.equal(match.status,"visual_match_only");
  assert.equal(match.imageVerified,false);
  assert.equal(match.contentVerified,false);
  assert.equal(match.xpAwarded,0);
  const noMatch=interpretation("hydration",[
    {labelAnnotations:[{description:"Screenshot",score:0.99}]},
    {localizedObjectAnnotations:[]},
  ]);
  assert.equal(noMatch.status,"inconclusive");
});

test("rechaza bytes arbitrarios y tipos falsificados", () => {
  const png=Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9pz7wAAAAASUVORK5CYII=",
    "base64");
  assert.equal(imageFormatValid(png,"image/png"),true);
  assert.equal(imageFormatValid(png,"image/jpeg"),false);
  assert.equal(imageFormatValid(Buffer.from("not an image"),"image/png"),false);
});

function fakeDb({owner=uid, status="attached", supported=true,
    hasEvidence=true, visionConsent=true,
    expires=Date.now()+3600000, alreadyDone=null}={}) {
  const docs=new Map();
  const reservationRef=`users/${uid}/habit_evidence_reservations/${ids.operationId}`;
  const logRef=`users/${uid}/user_habits/${ids.habitId}/attempts/${ids.attemptId}/logs/${ids.operationId}`;
  const assessmentRef=`users/${uid}/habit_evidence_assessments/${ids.operationId}`;
  docs.set(reservationRef,{
    uid:owner, ...ids, storagePath:path, status,
    visionConsent, expiresAt:{toMillis:()=>expires},
  });
  docs.set(logRef,{userId:uid,evidencePath:path,
    hasEvidence,evidenceSize:90});
  if(alreadyDone)docs.set(assessmentRef,{state:"done",result:alreadyDone});
  const db={
    collection:(name)=>({doc:(id)=>node(name+"/"+id)}),
    runTransaction:async fn=>fn({
      get:async ref=>({exists:docs.has(ref.path),data:()=>docs.get(ref.path)}),
      set:(ref,data)=>docs.set(ref.path,{...docs.get(ref.path),...data}),
      update:(ref,data)=>docs.set(ref.path,{...docs.get(ref.path),...data}),
    }),
  };
  function node(x) {
    return {path:x,collection:(name)=>({doc:id=>node(x+"/"+name+"/"+id)}),
      get:async()=>({exists:docs.has(x),data:()=>docs.get(x)}),
      update:async data=>docs.set(x,{...docs.get(x),...data})};
  }
  return {db,docs};
}
const testField={serverTimestamp:()=>new Date()};
test("sin vínculo del servidor no lee ni analiza fotografías", async () => {
  const f=fakeDb({owner:"otra_cuenta"});
  let reads=0;
  const bucket={file:()=>{reads++;throw Error("no debería leer");}};
  await assert.rejects(assessAttachedEvidence({
    db:f.db,bucket,vision:{},uid,data:ids,fieldValue:testField,
  }), e=>e.code==="permission-denied");
  assert.equal(reads,0);
});

test("sin consentimiento en la reserva el proveedor jamás accede a la foto", async () => {
  const f=fakeDb({visionConsent:false});
  let reads=0;
  await assert.rejects(assessAttachedEvidence({
    db:f.db,bucket:{file:()=>{reads++;throw Error("NO");}},
    vision:{},uid,data:ids,fieldValue:testField,
  }),e=>e.code==="permission-denied");
  assert.equal(reads,0);
});

test("resultado guardado se reutiliza sin volver a pagar Vision", async () => {
  const saved={status:"visual_match_only",contentVerified:false,
    imageVerified:false,xpAwarded:0,coinsAwarded:0};
  const f=fakeDb({alreadyDone:saved});
  const answer=await assessAttachedEvidence({
    db:f.db,bucket:{file:()=>{throw Error("no lectura");}},
    vision:{},uid,data:ids,fieldValue:testField,
  });
  assert.deepEqual(answer,{...saved,cached:true});
});

test("analiza un objeto real de Storage sin premiar ni duplicar llamadas", async () => {
  const bytes=Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9pz7wAAAAASUVORK5CYII=",
    "base64");
  const f=fakeDb();
  const logKey=`users/${uid}/user_habits/${ids.habitId}/attempts/${ids.attemptId}/logs/${ids.operationId}`;
  f.docs.set(logKey,{...f.docs.get(logKey),evidenceSize:bytes.length});
  const fixedNow=new Date("2026-11-27T18:00:00Z");
  let calls=0;
  const vision={
    labelDetection:async()=>{calls++;return [{
      labelAnnotations:[{description:"Apple",score:.96}],
    }];},
    objectLocalization:async()=>{calls++;return [{
      localizedObjectAnnotations:[],
    }];},
  };
  const bucket={file:actual=>{
    assert.equal(actual,path);
    return {
      getMetadata:async()=>[{size:String(bytes.length),
        contentType:"image/png"}],
      download:async()=>[bytes],
    };
  }};
  const first=await assessAttachedEvidence({
    db:f.db,bucket,vision,uid,data:ids,fieldValue:testField,now:fixedNow,
  });
  assert.equal(first.status,"visual_match_only");
  assert.equal(first.contentVerified,false);
  assert.equal(first.xpAwarded,0);
  assert.equal(first.coinsAwarded,0);
  assert.equal(calls,2);
  assert.equal(f.docs.get(logKey).evidenceVisualStatus,"visual_match_only");
  assert.equal(f.docs.get(logKey).evidenceContentVerified,false);
  const again=await assessAttachedEvidence({
    db:f.db,bucket,vision,uid,data:ids,fieldValue:testField,now:fixedNow,
  });
  assert.equal(again.cached,true);
  assert.equal(calls,2);
});

test("hábitos no compatibles no invocan Cloud Vision", async () => {
  const f=fakeDb();
  const other={...ids,habitId:"ener_001"};
  // Registro y reserva correspondientes al nuevo hábito.
  for(const [k,v]of [...f.docs.entries()]) {
    f.docs.set(k.replace("alim_001","ener_001"),{
      ...v,habitId:"ener_001",
    });
  }
  const answer=await assessAttachedEvidence({
    db:f.db,bucket:{file:()=>{throw Error("no usar Vision");}},
    vision:{},uid,data:other,fieldValue:testField,
  });
  assert.equal(answer.status,"unsupported_habit");
  assert.equal(answer.xpAwarded,0);
});
