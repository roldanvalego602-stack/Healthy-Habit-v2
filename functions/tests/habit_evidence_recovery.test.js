"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {uploadReservedEvidence} = require("../habit_evidence_upload");

const uid = "usuario_demo_recuperacion_12345";
const habitId = "alim_001";
const attemptId = "intento_recuperacion_12345";
const operationId = "operacion_recuperacion_1234";
const bytes = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9pz7wAAAAASUVORK5CYII=",
  "base64"
);
const data = {
  habitId, attemptId, operationId,
  contentType: "image/png", imageBase64: bytes.toString("base64"),
};
const now = new Date("2026-11-25T23:00:00Z");

function setup({exists = true, savedBytes = bytes, startedMinutesAgo = 6}) {
  const path = `habit-evidence/${uid}/${attemptId}/${operationId}`;
  const reservationRef = {kind: "reservation"};
  const operationRef = {kind: "operation"};
  const state = {
    uid, habitId, attemptId, operationId, storagePath: path,
    status: "uploading",
    expiresAt: {toMillis: () => now.getTime() + 3600000},
    uploadStartedAt: {toMillis: () =>
      now.getTime() - startedMinutesAgo * 60000},
  };
  const changes = [];
  const tx = {
    async get(ref) {
      return ref === reservationRef
        ? {exists: true, data: () => ({...state})}
        : {exists: false};
    },
    update(ref, patch) {
      assert.equal(ref, reservationRef);
      changes.push(patch);
      Object.assign(state, patch);
    },
  };
  const db = {
    collection(name) {
      assert.equal(name, "users");
      return {doc(id) {
        assert.equal(id, uid);
        return {collection(inner) {
          return {doc(key) {
            if (inner === "habit_evidence_reservations") {
              assert.equal(key, operationId);
              return reservationRef;
            }
            assert.equal(inner, "registration_operations");
            return operationRef;
          }};
        }};
      }};
    },
    async runTransaction(fn) {return fn(tx);},
  };
  const file = {
    async exists() {return [exists];},
    async getMetadata() {
      return [{size: String(savedBytes.length), contentType: "image/png"}];
    },
    async download() {return [savedBytes];},
    async save() {throw Error("Nunca reescribir en recuperación");},
  };
  const bucket = {file(filePath) {
    assert.equal(filePath, path);
    return file;
  }};
  return {db, bucket, state, changes};
}

test("recuperación: fotografía existente confirma subida sin sobrescribirla", async () => {
  const fixture = setup({});
  const result = await uploadReservedEvidence({
    ...fixture, uid, data, now,
  });
  assert.equal(result.alreadyUploaded, true);
  assert.equal(result.storagePath, fixture.state.storagePath);
  assert.equal(fixture.state.status, "uploaded");
  assert.deepEqual(fixture.changes.map((change) => change.status),
    ["recovering", "uploaded"]);
});

test("recuperación: sin objeto libera reserva para reintento", async () => {
  const fixture = setup({exists: false});
  await assert.rejects(uploadReservedEvidence({
    ...fixture, uid, data, now,
  }), (error) => error.code === "aborted");
  assert.equal(fixture.state.status, "pending");
  assert.deepEqual(fixture.changes.map((change) => change.status),
    ["recovering", "pending"]);
});

test("recuperación: archivo distinto permanece bloqueado", async () => {
  const changed = Buffer.from(bytes);
  changed[changed.length - 9] ^= 1;
  const fixture = setup({savedBytes: changed});
  await assert.rejects(uploadReservedEvidence({
    ...fixture, uid, data, now,
  }), (error) => error.code === "already-exists");
  assert.equal(fixture.state.status, "recovering");
});

test("recuperación: no interfiere con una subida reciente", async () => {
  const fixture = setup({startedMinutesAgo: 1});
  await assert.rejects(uploadReservedEvidence({
    ...fixture, uid, data, now,
  }), (error) => error.code === "aborted");
  assert.equal(fixture.state.status, "uploading");
  assert.equal(fixture.changes.length, 0);
});
