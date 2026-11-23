"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {BONUS, isSecretTestEnvironment, claimSecretTestBonus} =
  require("../secret_test_bonus");

function fakeDatabase(startBalance = 120) {
  const user = {exists: true, data: () => ({habitCoins: balance})};
  let balance = startBalance;
  let claimed = false;
  let writes = 0;
  const db = {
    collection(collection) {
      return {doc(uid) {return {collection, uid};}};
    },
    runTransaction(callback) {
      return callback({
        async get(ref) {
          return ref.collection === "users"
            ? user : {exists: claimed};
        },
        update(ref, data) {
          assert.equal(ref.collection, "users");
          balance = data.habitCoins;
          writes++;
        },
        create(ref, data) {
          assert.equal(ref.collection, "secret_test_bonus_claims");
          assert.equal(data.amount, BONUS);
          claimed = true;
        },
      });
    },
  };
  return {db, getBalance: () => balance, getWrites: () => writes};
}

test("el premio secreto solo se habilita en el emulador del proyecto demo", () => {
  assert.equal(isSecretTestEnvironment({
    FUNCTIONS_EMULATOR: "true", GCLOUD_PROJECT: "demo-healthy-habit",
  }), true);
  for (const env of [
    {FUNCTIONS_EMULATOR: "true", GCLOUD_PROJECT: "healthy-habit"},
    {FUNCTIONS_EMULATOR: "false", GCLOUD_PROJECT: "demo-healthy-habit"},
    {GCLOUD_PROJECT: "demo-healthy-habit"},
    {},
  ]) {
    assert.equal(isSecretTestEnvironment(env), false);
  }
});

test("el premio acredita exactamente 1000 monedas una sola vez", async () => {
  const mock = fakeDatabase(120);
  const first = await claimSecretTestBonus({
    db: mock.db, uid: "jugador1",
  });
  assert.equal(first.awarded, true);
  assert.equal(first.amount, 1000);
  assert.equal(first.newBalance, 1120);
  assert.equal(mock.getBalance(), 1120);
  const second = await claimSecretTestBonus({
    db: mock.db, uid: "jugador1",
  });
  assert.equal(second.awarded, false);
  assert.equal(second.alreadyClaimed, true);
  assert.equal(mock.getBalance(), 1120);
  assert.equal(mock.getWrites(), 1);
});

test("rechaza saldo malformado o usuario sin identidad", async () => {
  await assert.rejects(() => claimSecretTestBonus({
    db: fakeDatabase(1.5).db, uid: "jugador",
  }));
  await assert.rejects(() => claimSecretTestBonus({
    db: fakeDatabase(100).db, uid: "",
  }));
});
