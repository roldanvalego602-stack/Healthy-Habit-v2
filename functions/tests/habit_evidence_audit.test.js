"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {auditOrphanEvidence} = require("../habit_evidence_audit");

const now = new Date("2026-11-25T22:00:00Z");
const uid = "user_demo_1234567890";
const attemptId = "attempt_demo_1234567890";
const op = "operation_demo_1234567890";
const prefix = `habit-evidence/${uid}/${attemptId}/`;
const envKeys = ["GCLOUD_PROJECT", "FIRESTORE_EMULATOR_HOST",
  "FIREBASE_STORAGE_EMULATOR_HOST"];

async function withDemo(fn) {
  const backup = Object.fromEntries(
    envKeys.map((key) => [key, process.env[key]])
  );
  process.env.GCLOUD_PROJECT = "demo-healthy-habit";
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
  process.env.FIREBASE_STORAGE_EMULATOR_HOST = "127.0.0.1:9199";
  try {await fn();} finally {
    for (const key of envKeys) {
      if (backup[key] === undefined) delete process.env[key];
      else process.env[key] = backup[key];
    }
  }
}

test("auditoría: clasifica archivos y no escribe ni elimina", async () => {
  await withDemo(async () => {
    const id2 = "operation_demo_0987654321";
    const id3 = "operation_demo_2222222222";
    const id4 = "operation_demo_3333333333";
    const id5 = "operation_demo_4444444444";
    const entries = [
      [op, {uid, attemptId, operationId: op, storagePath: prefix + op,
        habitId: "alim_001", status: "attached",
        expiresAt: {toMillis: () => now.getTime() + 3600000}}],
      [id2, null],
      [id3, null],
      [id4, {uid, attemptId, operationId: id4,
        storagePath: "wrong/path", habitId: "alim_001",
        status: "uploaded",
        expiresAt: {toMillis: () => now.getTime() + 3600000}}],
      [id5, {uid, attemptId, operationId: id5,
        storagePath: prefix + id5, habitId: "alim_001", status: "uploaded",
        expiresAt: {toMillis: () => now.getTime() - 1000}}],
    ];
    const files = entries.map(([id], i) => ({
      name: prefix + id,
      metadata: {timeCreated: new Date(now.getTime() -
        (i === 2 ? 20000 : 600000)).toISOString()},
      async delete() {throw Error("Auditoría no debe borrar.");},
    }));
    const lookup = new Map(entries);
    const db = {collection(name) {
      assert.equal(name, "users");
      return {doc(id) {
        assert.equal(id, uid);
        return {collection(key) {
          assert.equal(key, "habit_evidence_reservations");
          return {doc(operationId) {
            return {async get() {
              const record = lookup.get(operationId);
              return record ? {exists: true, data: () => record} :
                {exists: false};
            }};
          }};
        }};
      }};
    }};
    const bucket = {async getFiles(query) {
      assert.equal(query.prefix, "habit-evidence/");
      assert.equal(query.maxResults, 100);
      return [files, {pageToken: "next"}];
    }};
    const result = await auditOrphanEvidence({db, bucket, now, limit: 100});
    assert.equal(result.scanned, 5);
    assert.deepEqual(result.counts, {
      valid: 1, orphan: 1, inconsistent: 1, expired: 1,
      recentUnreserved: 1, invalidPath: 0,
    });
    assert.equal(result.hasMore, true);
  });
});

test("auditoría: bloqueada fuera del laboratorio demo", async () => {
  const old = process.env.GCLOUD_PROJECT;
  try {
    process.env.GCLOUD_PROJECT = "proyecto-real";
    await assert.rejects(auditOrphanEvidence({
      db: {}, bucket: {}, now,
    }), /emuladores demo/);
  } finally {
    if (old === undefined) delete process.env.GCLOUD_PROJECT;
    else process.env.GCLOUD_PROJECT = old;
  }
});
