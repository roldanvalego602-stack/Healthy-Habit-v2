"use strict";

// Prueba de extremo a extremo: exige Firestore y Storage Emulator.
// No ejecutarla en un proyecto real ni añadirla al suite unitario normal.
const test = require("node:test");
const assert = require("node:assert/strict");
const {initializeApp, deleteApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {purgeExpiredEvidence} = require("../habit_evidence_cleanup");

const PROJECT = "demo-healthy-habit";
const BUCKET = PROJECT + ".firebasestorage.app";
const PNG = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9pz7wAAAAASUVORK5CYII=",
  "base64"
);

test("emuladores: purga objetos vencidos, referencias y respeta subidas recientes", async () => {
  assert.equal(process.env.GCLOUD_PROJECT, PROJECT);
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST);
  assert.ok(process.env.FIREBASE_STORAGE_EMULATOR_HOST);
  assert.ok(process.env.FIREBASE_AUTH_EMULATOR_HOST);

  const app = initializeApp({
    projectId: PROJECT, storageBucket: BUCKET,
  }, "evidence-cleanup-integration");
  const db = getFirestore(app, "default");
  const bucket = getStorage(app).bucket(BUCKET);
  const uid = "cleanup_test_" + Date.now() + "_" +
    Math.random().toString(36).slice(2, 9);
  const userRef = db.collection("users").doc(uid);
  const habitId = "alim_001";
  const attemptId = "cleanup_attempt_123456789";
  const attemptRef = userRef.collection("user_habits").doc(habitId)
    .collection("attempts").doc(attemptId);
  const now = new Date();
  const past = Timestamp.fromMillis(now.getTime() - 15 * 60 * 1000);
  const future = Timestamp.fromMillis(now.getTime() + 60 * 60 * 1000);
  const recent = Timestamp.fromMillis(now.getTime() - 30 * 1000);
  const old = Timestamp.fromMillis(now.getTime() - 10 * 60 * 1000);

  async function seed(operationId, {status, expiresAt = past,
    uploadStartedAt, withFile = true, withLog = false}) {
    const path = `habit-evidence/${uid}/${attemptId}/${operationId}`;
    const reservationRef = userRef.collection("habit_evidence_reservations")
      .doc(operationId);
    const logRef = attemptRef.collection("logs").doc(operationId);
    await reservationRef.set({
      uid, habitId, attemptId, operationId, storagePath: path, status,
      expiresAt, ...(uploadStartedAt ? {uploadStartedAt} : {}),
    });
    if (withLog) {
      await logRef.set({
        userId: uid, hasEvidence: true, evidenceVerified: false,
        evidencePath: path, evidenceSize: PNG.length, xpEarned: 10,
      });
    }
    if (withFile) {
      await bucket.file(path).save(PNG, {
        resumable: false, contentType: "image/png",
      });
    }
    return {path, reservationRef, logRef};
  }

  try {
    await userRef.set({xp: 90, habitCoins: 60});
    const attached = await seed("cleanup_attached_123456", {
      status: "attached", withLog: true,
    });
    const pending = await seed("cleanup_pending_1234567", {
      status: "pending", withFile: false,
    });
    const active = await seed("cleanup_uploading_12345", {
      status: "uploading", uploadStartedAt: recent,
    });
    const retained = await seed("cleanup_future_123456789", {
      status: "uploaded", expiresAt: future,
    });

    const first = await purgeExpiredEvidence({db, bucket, now, limit: 50});
    assert.equal(first.scanned, 3);
    assert.equal(first.removed, 2);
    assert.equal((await attached.reservationRef.get()).exists, false);
    assert.equal((await pending.reservationRef.get()).exists, false);
    assert.equal((await bucket.file(attached.path).exists())[0], false);
    const log = (await attached.logRef.get()).data();
    assert.equal(log.hasEvidence, false);
    assert.equal(log.evidenceVerified, false);
    assert.equal(Object.hasOwn(log, "evidencePath"), false);
    assert.equal(log.xpEarned, 10);
    assert.equal((await userRef.get()).data().xp, 90);
    assert.equal((await userRef.get()).data().habitCoins, 60);
    assert.equal((await active.reservationRef.get()).exists, true);
    assert.equal((await bucket.file(active.path).exists())[0], true);
    assert.equal((await retained.reservationRef.get()).exists, true);
    assert.equal((await bucket.file(retained.path).exists())[0], true);

    // Cuando el bloqueo se vuelve antiguo, la misma purga lo limpia.
    await active.reservationRef.update({uploadStartedAt: old});
    const second = await purgeExpiredEvidence({db, bucket, now, limit: 50});
    assert.equal(second.scanned, 1);
    assert.equal(second.removed, 1);
    assert.equal((await active.reservationRef.get()).exists, false);
    assert.equal((await bucket.file(active.path).exists())[0], false);

    const third = await purgeExpiredEvidence({db, bucket, now, limit: 50});
    assert.deepEqual(third, {scanned: 0, removed: 0});
  } finally {
    // No eliminar referencias de una ejecución anterior ni usuarios ajenos.
    await db.recursiveDelete(userRef);
    const [files] = await bucket.getFiles({
      prefix: `habit-evidence/${uid}/`,
    });
    await Promise.all(files.map((file) => file.delete({ignoreNotFound: true})));
    await deleteApp(app);
  }
});
