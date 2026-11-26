"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {validateChallengeClaim, calculateVerifiedClaim,
  claimVerifiedChallenge} = require("../challenge_claim_transaction");
const {RegistrationPolicyError} = require("../habit_registration_policy");

const challenge = Object.freeze({
  status: "completed",
  demoSeed: false, progressVerified: true,
  progressSource: "habit_records",
  currentProgress: 7, totalProgress: 7,
  xpReward: 80, hcReward: 25,
});
const attestation = Object.freeze({
  uid: "alice", challengeId: "challenge_123",
  source: "official_habit_registration", status: "verified",
  progressVerified: true, currentProgress: 7, totalProgress: 7,
  xpReward: 80, hcReward: 25,
});
const user = Object.freeze({
  xp: 50, currentXp: 50, habitCoins: 100,
  claimedLevelRewards: [],
});

test("rechaza datos arbitrarios, precios y XP suministrados por Flutter", () => {
  assert.equal(validateChallengeClaim({challengeId: "challenge_123"}), "challenge_123");
  for (const data of [
    {}, null, [], {challengeId: "../users/other"},
    {challengeId: "challenge_123", xpReward: 999999},
    {challengeId: "challenge_123", uid: "someone"},
  ]) assert.throws(() => validateChallengeClaim(data), RegistrationPolicyError);
});

test("no concede premios de desafíos de demostración ni progreso no verificado", () => {
  for (const changed of [
    {demoSeed: true}, {progressVerified: false},
    {progressSource: "client"}, {status: "available"},
    {currentProgress: 6}, {totalProgress: 0},
    {hcReward: 999999}, {xpReward: -1},
  ]) assert.throws(() => calculateVerifiedClaim({...challenge, ...changed}, user),
    RegistrationPolicyError);
});

test("suma recompensas de niveles sin duplicarlas y sincroniza XP", () => {
  const outcome = calculateVerifiedClaim(challenge, user);
  assert.equal(outcome.xp, 130);
  assert.equal(outcome.level, 2);
  assert.equal(outcome.habitCoins, 150);
  assert.equal(outcome.coinsAwarded, 50);
  assert.deepEqual(outcome.claimedLevelRewards, [2]);
  const claimed = calculateVerifiedClaim(challenge, {
    xp: 50, currentXp: 50, habitCoins: 100, claimedLevelRewards: [2],
  });
  assert.equal(claimed.habitCoins, 125);
  assert.equal(claimed.coinsAwarded, 25);
});

test("rechaza estados económicos corruptos y desbordamientos", () => {
  for (const broken of [
    {habitCoins: -1}, {xp: 20.5}, {currentXp: 1},
    {claimedLevelRewards: [2, 2]},
    {claimedLevelRewards: "2"}, {habitCoins: 1000000001},
  ]) assert.throws(() => calculateVerifiedClaim(challenge, {...user, ...broken}),
    RegistrationPolicyError);
});

function fakeDb(initial) {
  const docs = new Map(Object.entries(initial));
  return {
    docs,
    collection(name) {
      const ref = (path) => ({
        path,
        collection(sub) { return ref(path + "/" + sub); },
        doc(id) { return ref(path + "/" + id); },
      });
      return ref(name);
    },
    async runTransaction(fn) {
      const writes = [];
      const tx = {
        async get(ref) {
          return {exists: docs.has(ref.path), data: () => docs.get(ref.path)};
        },
        update(ref, data) { writes.push({path: ref.path, data}); },
      };
      const result = await fn(tx);
      for (const w of writes) docs.set(w.path, {...docs.get(w.path), ...w.data});
      return result;
    },
  };
}

test("bloquea desafíos heredados sin constancia independiente del servidor", async () => {
  const db = fakeDb({
    "users/alice": {...user},
    "users/alice/challenges/challenge_123": {...challenge},
  });
  await assert.rejects(claimVerifiedChallenge({
    db, uid: "alice", data: {challengeId: "challenge_123"},
  }), {code: "failed-precondition"});
  assert.equal(db.docs.get("users/alice").habitCoins, 100);
  assert.equal(db.docs.get("users/alice/challenges/challenge_123").status,
    "completed");
});

test("bloquea constancias adulteradas, cruzadas o que no respaldan la recompensa", async () => {
  for (const changed of [
    {uid: "other"}, {challengeId: "other"}, {status: "draft"},
    {source: "client"}, {progressVerified: false},
    {currentProgress: 6}, {totalProgress: 5},
    {xpReward: 150}, {hcReward: 50},
  ]) {
    const db = fakeDb({
      "users/alice": {...user},
      "users/alice/challenges/challenge_123": {...challenge},
      "system/challenge_attestations/users/alice/challenges/challenge_123":
        {...attestation, ...changed},
    });
    await assert.rejects(claimVerifiedChallenge({
      db, uid: "alice", data: {challengeId: "challenge_123"},
    }), {code: "failed-precondition"});
    assert.equal(db.docs.get("users/alice").habitCoins, 100);
  }
});

test("reclamación atómica marca claimed y un segundo intento no vuelve a acreditar", async () => {
  const db = fakeDb({
    "users/alice": {...user},
    "users/alice/challenges/challenge_123": {...challenge},
    "system/challenge_attestations/users/alice/challenges/challenge_123":
      {...attestation},
  });
  const args = {db, uid: "alice", data: {challengeId: "challenge_123"}};
  const result = await claimVerifiedChallenge(args);
  assert.equal(result.coinsAwarded, 50);
  assert.equal(db.docs.get("users/alice").habitCoins, 150);
  assert.equal(db.docs.get("users/alice/challenges/challenge_123").status, "claimed");
  await assert.rejects(claimVerifiedChallenge(args), {code: "already-exists"});
  assert.equal(db.docs.get("users/alice").habitCoins, 150);
});
