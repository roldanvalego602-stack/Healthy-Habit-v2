"use strict";

// Integración real contra Firestore y Storage Emulator; prohibido producción.
const test = require("node:test");
const assert = require("node:assert/strict");
const {initializeApp, deleteApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {reserveHabitEvidence} = require("../habit_evidence_reservation");
const {uploadReservedEvidence} = require("../habit_evidence_upload");
const {registerDemoHabit} = require("../habit_registration_transaction");
const {attachHabitEvidence} = require("../habit_evidence_attachment");
const {getEvidenceStatus} = require("../habit_evidence_status");
const {purgeExpiredEvidence} = require("../habit_evidence_cleanup");

const PROJECT = "demo-healthy-habit";
const HOST = "127.0.0.1";
const PNG = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9pz7wAAAAASUVORK5CYII=",
  "base64",
);
function requireSafeEmulators() {
  assert.equal(process.env.GCLOUD_PROJECT, PROJECT,
    "Este laboratorio solo usa el proyecto demo.");
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, HOST + ":8080");
  assert.equal(process.env.FIREBASE_STORAGE_EMULATOR_HOST, HOST + ":9199");
  assert.ok(process.env.FIREBASE_AUTH_EMULATOR_HOST);
}

test("fotografía: reserva, subida, registro, asociación, reintento y borrado", async () => {
  requireSafeEmulators();
  const app = initializeApp({
    projectId: PROJECT, storageBucket: PROJECT + ".firebasestorage.app",
  }, "habit-evidence-flow-integration");
  const db = getFirestore(app, "default");
  const bucket = getStorage(app).bucket(PROJECT + ".firebasestorage.app");
  const uid = "evidence_flow_" + Date.now() + "_" +
    Math.random().toString(36).slice(2, 8);
  const userRef = db.collection("users").doc(uid);
  const habitId = "hidr_001";
  const attemptId = "attempt_evidence_123456789";
  const operationId = "operation_evidence_123456789";
  const path = `habit-evidence/${uid}/${attemptId}/${operationId}`;
  const now = new Date();
  const payload = {habitId, attemptId, operationId};
  try {
    const habitRef = userRef.collection("user_habits").doc(habitId);
    const attemptRef = habitRef.collection("attempts").doc(attemptId);
    await userRef.set({
      xp:0,currentXp:0,level:1,habitCoins:100,claimedLevelRewards:[],
    });
    await habitRef.set({
      title:"Beber agua al despertar", latestAttemptId:attemptId,
      lastAttemptId:attemptId,latestStatus:"inProgress",
      lastStatus:"inProgress",frequencyType:"daily",
    });
    await attemptRef.set({
      habitId,status:"inProgress",progress:0,target:7,
      xpEarned:0,frequencyType:"daily",registrationsPerPeriod:1,
    });

    const reserved = await reserveHabitEvidence({
      db,uid,data:payload,now,dailyQuota:12,
    });
    assert.equal(reserved.alreadyReserved,false);
    assert.equal(reserved.storagePath,path);
    assert.equal((await reserveHabitEvidence({
      db,uid,data:payload,now,dailyQuota:12,
    })).alreadyReserved,true);

    const data={...payload,contentType:"image/png",
      imageBase64:PNG.toString("base64")};
    const uploaded=await uploadReservedEvidence({
      db,bucket,uid,data,now,
    });
    assert.equal(uploaded.verified,false);
    assert.equal((await bucket.file(path).exists())[0],true);
    const repeatedUpload=await uploadReservedEvidence({
      db,bucket,uid,data,now,
    });
    assert.equal(repeatedUpload.alreadyUploaded,true);

    const registered=await registerDemoHabit({
      db,uid,data:payload,now,
    });
    assert.equal(registered.alreadyProcessed,false);
    assert.equal(registered.xpAwarded,10);
    assert.equal((await registerDemoHabit({
      db,uid,data:payload,now,
    })).alreadyProcessed,true);

    const attached=await attachHabitEvidence({
      db,bucket,uid,data:payload,now,
    });
    assert.equal(attached.attached,true);
    assert.equal(attached.verified,false);
    assert.equal((await attachHabitEvidence({
      db,bucket,uid,data:payload,now,
    })).alreadyAttached,true);
    const status=await getEvidenceStatus({db,uid,data:payload,now});
    assert.deepEqual(status,{
      status:"attached",attached:true,contentVerified:false,
    });
    const logRef=attemptRef.collection("logs").doc(operationId);
    const log=(await logRef.get()).data();
    assert.equal(log.evidenceVerified,false);
    assert.equal(log.hasEvidence,true);
    assert.equal(log.evidencePath,path);
    assert.equal((await userRef.get()).data().xp,10);
    assert.equal((await userRef.get()).data().habitCoins,100);

    const cleaned=await purgeExpiredEvidence({
      db,bucket,now:new Date(now.getTime()+2*3600000),limit:50,
    });
    assert.ok(cleaned.removed>=1);
    assert.equal((await bucket.file(path).exists())[0],false);
    const purged=(await logRef.get()).data();
    assert.equal(purged.hasEvidence,false);
    assert.equal(purged.evidenceVerified,false);
    assert.equal(purged.xpEarned,10);
    assert.equal((await userRef.get()).data().xp,10);
    assert.equal((await userRef.get()).data().habitCoins,100);
  } finally {
    await db.recursiveDelete(userRef);
    await bucket.file(path).delete({ignoreNotFound:true});
    await deleteApp(app);
  }
});
