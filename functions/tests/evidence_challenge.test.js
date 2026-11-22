"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  CHALLENGE_TTL_MS,
  ChallengeError,
  createChallengeSpec,
  compareCode,
  startEvidenceChallenge,
  checkEvidenceChallengeCode,
} = require("../evidence_challenge");

function fakeDb() {
  const records = new Map();
  const refFor = (path) => ({
    id: path.split("/").at(-1),
    path,
    collection(name) { return collectionFor(path + "/" + name); },
    doc(name) { return refFor(path + "/" + name); },
  });
  const collectionFor = (path) => ({
    doc(id) { return refFor(path + "/" + id); },
  });
  return {
    records,
    collection: collectionFor,
    async runTransaction(callback) {
      const writes = [];
      const tx = {
        async get(ref) {
          const value = records.get(ref.path);
          return {
            exists: value !== undefined,
            data: () => value,
          };
        },
        set(ref, data) { writes.push(() => records.set(ref.path, data)); },
        update(ref, patch) {
          writes.push(() => records.set(ref.path, {...records.get(ref.path), ...patch}));
        },
      };
      const answer = await callback(tx);
      for (const write of writes) write();
      return answer;
    },
  };
}

function setup() {
  const db = fakeDb();
  db.records.set("users/user1/user_habits/water", {title: "Beber agua"});
  db.records.set("users/user1/user_habits/water/attempts/attempt1",
    {status: "inProgress"});
  return {db, uid: "user1", habitId: "water", attemptId: "attempt1"};
}

test("el código generado siempre tiene seis dígitos y vence a los cinco minutos", () => {
  const spec = createChallengeSpec(1000);
  assert.match(spec.code, /^\d{6}$/);
  assert.equal(spec.expiresAtMs, 1000 + CHALLENGE_TTL_MS);
  assert.equal(compareCode(spec.code, spec.salt, spec.codeHash), true);
  assert.equal(compareCode("not-code", spec.salt, spec.codeHash), false);
});

test("solo se emite para un intento activo", async () => {
  const params = setup();
  params.db.records.set(
    "users/user1/user_habits/water/attempts/attempt1",
    {status: "completed"},
  );
  await assert.rejects(
    startEvidenceChallenge({...params, objectId: "spoon", now: 1000}),
    (error) => error instanceof ChallengeError && error.code === "failed-precondition",
  );
});

test("rechaza un objeto fuera de la lista de alternativas", async () => {
  const params = setup();
  await assert.rejects(
    startEvidenceChallenge({...params, objectId: "passport", now: 1000}),
    (error) => error instanceof ChallengeError && error.code === "invalid-argument",
  );
});

test("emite un desafío ligado al hábito e intento sin almacenar el código original", async () => {
  const params = setup();
  const challenge = await startEvidenceChallenge({...params, objectId: "spoon", now: 1000});
  assert.match(challenge.code, /^\d{6}$/);
  assert.equal(challenge.options.length, 5);
  const record = [...params.db.records.values()].find(
    (value) => value && value.codeHash && value.habitId === "water",
  );
  assert.ok(record);
  assert.equal("code" in record, false);
  assert.equal(record.uid, "user1");
  assert.equal(record.objectId, "spoon");
});

test("no revela un desafío vigente al volver a solicitarlo", async () => {
  const params = setup();
  await startEvidenceChallenge({...params, objectId: "spoon", now: 1000});
  await assert.rejects(
    startEvidenceChallenge({...params, objectId: "pen", now: 2000}),
    (error) => error instanceof ChallengeError && error.code === "failed-precondition",
  );
});

test("el código correcto se consume una sola vez sin entregar XP", async () => {
  const params = setup();
  const challenge = await startEvidenceChallenge({...params, objectId: "spoon", now: 1000});
  const input = {...params, challengeId: challenge.challengeId, code: challenge.code};
  const first = await checkEvidenceChallengeCode({...input, now: 2000});
  assert.deepEqual(
    {matched: first.codeMatched, visual: first.imageVerified, xp: first.xpAwarded},
    {matched: true, visual: false, xp: 0},
  );
  await assert.rejects(
    checkEvidenceChallengeCode({...input, now: 3000}),
    (error) => error instanceof ChallengeError && error.code === "failed-precondition",
  );
});

test("tres errores bloquean el desafío sin dar XP", async () => {
  const params = setup();
  const challenge = await startEvidenceChallenge({...params, objectId: "spoon", now: 1000});
  const wrongCode = challenge.code === "000000" ? "000001" : "000000";
  const input = {...params, challengeId: challenge.challengeId, code: wrongCode};
  for (let index = 0; index < 3; index++) {
    const result = await checkEvidenceChallengeCode({...input, now: 2000 + index});
    assert.equal(result.codeMatched, false);
    assert.equal(result.attemptsRemaining, 2 - index);
    assert.equal(result.xpAwarded, 0);
  }
  await assert.rejects(
    checkEvidenceChallengeCode({...input, now: 3000}),
    (error) => error instanceof ChallengeError && error.code === "failed-precondition",
  );
});

test("un desafío caducado no acepta códigos antiguos", async () => {
  const params = setup();
  const challenge = await startEvidenceChallenge({...params, objectId: "spoon", now: 1000});
  await assert.rejects(
    checkEvidenceChallengeCode({
      ...params, challengeId: challenge.challengeId, code: challenge.code,
      now: 1000 + CHALLENGE_TTL_MS,
    }),
    (error) => error instanceof ChallengeError && error.code === "deadline-exceeded",
  );
});

test("otro usuario no puede utilizar el desafío ajeno", async () => {
  const params = setup();
  const challenge = await startEvidenceChallenge({...params, objectId: "spoon", now: 1000});
  await assert.rejects(
    checkEvidenceChallengeCode({
      ...params, uid: "user2", challengeId: challenge.challengeId,
      code: challenge.code, now: 2000,
    }),
    (error) => error instanceof ChallengeError && error.code === "not-found",
  );
});

test("el desafío no permite cambiar el hábito o intento", async () => {
  const params = setup();
  const challenge = await startEvidenceChallenge({...params, objectId: "spoon", now: 1000});
  await assert.rejects(
    checkEvidenceChallengeCode({
      ...params, habitId: "fruit", challengeId: challenge.challengeId,
      code: challenge.code, now: 2000,
    }),
    (error) => error instanceof ChallengeError && error.code === "invalid-argument",
  );
});
