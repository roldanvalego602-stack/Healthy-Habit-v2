"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {TITLES, validateTitleSelection, selectProfileTitle} =
  require("../profile_title_transaction");
const {RegistrationPolicyError} =
  require("../habit_registration_policy");

function sandbox(initial) {
  const docs = new Map(Object.entries(initial));
  const reference = (path) => ({
    path,
    collection(segment) {
      return collection(path + "/" + segment);
    },
  });
  const collection = (path) => ({
    doc(id) {return reference(path + "/" + id);},
  });
  const db = {
    collection,
    async runTransaction(handler) {
      const tx = {
        async get(ref) {
          return {exists: docs.has(ref.path), data: () => docs.get(ref.path)};
        },
        update(ref, payload) {
          docs.set(ref.path, {...docs.get(ref.path), ...payload});
        },
      };
      return handler(tx);
    },
  };
  return {db, docs};
}

test("solo admite identificadores del catálogo, nunca niveles o saldos enviados", () => {
  assert.equal(Object.keys(TITLES).length, 8);
  assert.equal(validateTitleSelection({titleId: "novato"}), "novato");
  for (const request of [
    {}, {titleId: "premium_inventado"}, {titleId: "novato", level: 999},
    {titleId: "novato", xp: 99999}, null, [], "novato",
  ]) assert.throws(() => validateTitleSelection(request),
    RegistrationPolicyError);
});

test("selección de título de nivel requiere nivel actual del servidor", async () => {
  const {db, docs} = sandbox({
    "users/alice": {level: 2, habitCoins: 100, profileTitle: "Semilla saludable"},
  });
  await assert.rejects(selectProfileTitle({
    db, uid: "alice", data: {titleId: "cultivador"},
  }), RegistrationPolicyError);
  docs.set("users/alice", {...docs.get("users/alice"), level: 3});
  const result = await selectProfileTitle({
    db, uid: "alice", data: {titleId: "cultivador"},
  });
  assert.equal(result.unchanged, false);
  assert.equal(docs.get("users/alice").profileTitle, "Cultivador de constancia");
  assert.equal(docs.get("users/alice").habitCoins, 100);
  assert.equal((await selectProfileTitle({
    db, uid: "alice", data: {titleId: "cultivador"},
  })).unchanged, true);
});

test("eventos públicos antiguos no bastan para títulos con insignia", async () => {
  const {db, docs} = sandbox({
    "users/alice": {level: 50, habitCoins: 3000},
    "public_profiles/alice/activity_events/primera_meta": {
      kind: "achievement_unlocked", achievementId: "primera_meta",
    },
  });
  await assert.rejects(selectProfileTitle({
    db, uid: "alice", data: {titleId: "primera_meta"},
  }), RegistrationPolicyError);
  const path = "system/title_attestations/users/alice/titles/primera_meta";
  docs.set(path, {
    uid: "alice", titleId: "primera_meta",
    badgeId: "primera_meta", verified: true,
  });
  assert.equal((await selectProfileTitle({
    db, uid: "alice", data: {titleId: "primera_meta"},
  })).name, "Primer paso cumplido");
});

test("constancia falsa o de otra cuenta nunca concede título", async () => {
  const path = "system/title_attestations/users/alice/titles/festival";
  const {db, docs} = sandbox({
    "users/alice": {level: 10},
    [path]: {uid: "bob", titleId: "festival",
      badgeId: "festival_participant_2026", verified: true},
  });
  await assert.rejects(selectProfileTitle({
    db, uid: "alice", data: {titleId: "festival"},
  }), RegistrationPolicyError);
  docs.set(path, {...docs.get(path), uid: "alice", verified: false});
  await assert.rejects(selectProfileTitle({
    db, uid: "alice", data: {titleId: "festival"},
  }), RegistrationPolicyError);
});
