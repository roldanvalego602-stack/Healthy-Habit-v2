"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {purgeExpiredEvidence} = require("../habit_evidence_cleanup");

test("purga demo: elimina objeto vencido y desvincula log sin tocar XP", async () => {
  const backup = {
    GCLOUD_PROJECT: process.env.GCLOUD_PROJECT,
    FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST,
    FIREBASE_STORAGE_EMULATOR_HOST: process.env.FIREBASE_STORAGE_EMULATOR_HOST,
  };
  process.env.GCLOUD_PROJECT = "demo-healthy-habit";
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
  process.env.FIREBASE_STORAGE_EMULATOR_HOST = "127.0.0.1:9199";
  const uid = "usuario_demo_123456789";
  const attempt = "intento_demo_123456789";
  const operation = "operacion_demo_123456789";
  const path = `habit-evidence/${uid}/${attempt}/${operation}`;
  const now = new Date("2026-11-25T23:00:00Z");
  const expired = {toMillis: () => now.getTime() - 1000};
  const pathUpdates = [];
  let deleted = 0, reservationDeleted = 0;
  const logRef = {kind: "log"};
  const assessmentRef = {kind: "assessment"};
  const userRef = {
    id: uid, parent: {id: "users"},
    collection(name) {
      if (name === "habit_evidence_assessments") {
        return {doc: (id) => {
          assert.equal(id, operation);
          return assessmentRef;
        }};
      }
      assert.equal(name, "user_habits");
      return {doc: (id) => {
        assert.equal(id, "alim_001");
        return {collection: (name) => {
          assert.equal(name, "attempts");
          return {doc: (id) => {
            assert.equal(id, attempt);
            return {collection: (name) => {
              assert.equal(name, "logs");
              return {doc: (id) => {
                assert.equal(id, operation);
                return logRef;
              }};
            }};
          }};
        }};
      }};
    },
  };
  const reservationData = {
    uid, habitId: "alim_001", attemptId: attempt,
    operationId: operation, storagePath: path,
    status: "attached", expiresAt: expired,
  };
  const reservationRef = {kind: "reservation", parent: {parent: userRef}};
  const db = {
    collectionGroup(name) {
      assert.equal(name, "habit_evidence_reservations");
      return {where: (field, op) => {
        assert.equal(field, "expiresAt");
        assert.equal(op, "<=");
        return {limit: () => ({get: async () => ({
          size: 1, docs: [{id: operation, ref: reservationRef,
            data: () => reservationData}],
        })})};
      }};
    },
    async runTransaction(fn) {
      const tx = {
        async get(ref) {
          if (ref === reservationRef) {
            return {exists: true, data: () => reservationData};
          }
          if (ref === assessmentRef) return {exists: false};
          assert.equal(ref, logRef);
          return {exists: true, data: () => ({evidencePath: path, xp: 10})};
        },
        update(ref, data) {
          assert.equal(ref, logRef);
          pathUpdates.push(data);
        },
        delete(ref) {
          assert.equal(ref, reservationRef);
          reservationDeleted++;
        },
      };
      await fn(tx);
    },
  };
  const bucket = {file: (filePath) => {
    assert.equal(filePath, path);
    return {async delete() {deleted++;}};
  }};
  try {
    const result = await purgeExpiredEvidence({db, bucket, now, limit: 50});
    assert.deepEqual(result, {scanned: 1, removed: 1});
    assert.equal(deleted, 1);
    assert.equal(reservationDeleted, 1);
    assert.equal(pathUpdates.length, 1);
    assert.equal(pathUpdates[0].hasEvidence, false);
    assert.equal(pathUpdates[0].evidenceVerified, false);
    assert.ok(!Object.hasOwn(pathUpdates[0], "xp"));
    assert.ok(!Object.hasOwn(pathUpdates[0], "habitCoins"));
  } finally {
    for (const [key, value] of Object.entries(backup)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
});
