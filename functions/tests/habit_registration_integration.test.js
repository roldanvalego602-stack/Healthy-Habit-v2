"use strict";

// No forma parte del npm test unitario. Ejecutar exclusivamente con:
// firebase emulators:exec --config firebase.emulator.json \
//   --project demo-healthy-habit --only firestore \
//   "cd functions && npm run test:integration"
const test = require("node:test");
const assert = require("node:assert/strict");
const {initializeApp, deleteApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {registerDemoHabit} = require("../habit_registration_transaction");

if (!process.env.FIRESTORE_EMULATOR_HOST ||
    process.env.GCLOUD_PROJECT !== "demo-healthy-habit") {
  test("seguridad: integración solo en emulador demo", () => {
    assert.fail("Inicia Firestore Emulator con --project demo-healthy-habit.");
  });
} else {
  const app = initializeApp({projectId: "demo-healthy-habit"},
    "habit-registration-integration");
  const db = getFirestore(app, "default");
  const fixedDay = new Date("2026-11-21T13:00:00.000Z");

  test.after(async () => {
    await deleteApp(app);
  });

  async function seed(uid, {progress = 0, xp = 0, coins = 100} = {}) {
    const ref = db.collection("users").doc(uid);
    const habit = ref.collection("user_habits").doc("hidr_001");
    const attempt = habit.collection("attempts").doc("attempt-1");
    const batch = db.batch();
    batch.set(ref, {
      xp, currentXp: xp, level: xp >= 100 ? 2 : 1,
      habitCoins: coins, claimedLevelRewards: [],
    });
    batch.set(habit, {
      title: "Beber agua al despertar",
      latestAttemptId: "attempt-1", lastAttemptId: "attempt-1",
      latestStatus: "inProgress", lastStatus: "inProgress",
      frequencyType: "daily",
    });
    batch.set(attempt, {
      status: "inProgress", progress, target: 7, xpEarned: progress * 10,
      frequencyType: "daily", registrationsPerPeriod: 1,
    });
    await batch.commit();
    return {ref, habit, attempt};
  }

  function input(uid, operationId, now = fixedDay) {
    return {
      db, uid, now,
      data: {habitId: "hidr_001", attemptId: "attempt-1", operationId},
    };
  }

  test("transacción real: registro atómico y reintento sin nuevos XP", async () => {
    const uid = "integration-idempotence";
    const {ref, attempt} = await seed(uid);
    const parameters = input(uid, "integration_same_0001");
    const first = await registerDemoHabit(parameters);
    const retry = await registerDemoHabit(parameters);

    assert.equal(first.alreadyProcessed, false);
    assert.equal(retry.alreadyProcessed, true);
    assert.equal(retry.progress, first.progress);
    assert.equal((await ref.get()).data().xp, 10);
    assert.equal((await attempt.get()).data().progress, 1);

    const logs = await attempt.collection("logs").get();
    const operations = await ref.collection("registration_operations").get();
    const days = await attempt.collection("registration_days").get();
    assert.equal(logs.size, 1);
    assert.equal(operations.size, 1);
    assert.equal(days.size, 1);
  });

  test("simultaneidad real: dos IDs el mismo día conceden a lo sumo 10 XP", async () => {
    const uid = "integration-race";
    const {ref, attempt} = await seed(uid);
    const outcomes = await Promise.allSettled([
      registerDemoHabit(input(uid, "integration_race_0001")),
      registerDemoHabit(input(uid, "integration_race_0002")),
    ]);
    const accepted = outcomes.filter((item) => item.status === "fulfilled");
    const denied = outcomes.filter((item) => item.status === "rejected");
    assert.equal(accepted.length, 1);
    assert.equal(denied.length, 1);
    assert.equal((await ref.get()).data().xp, 10);
    assert.equal((await attempt.get()).data().progress, 1);
    assert.equal((await attempt.collection("logs").get()).size, 1);
    assert.equal((await ref.collection("registration_operations").get()).size, 1);
  });

  test("simultaneidad del mismo ID: jamás genera un segundo cobro", async () => {
    const uid = "integration-same-operation";
    const {ref, attempt} = await seed(uid);
    const parameters = input(uid, "integration_identical_0001");
    const outcomes = await Promise.allSettled([
      registerDemoHabit(parameters), registerDemoHabit(parameters),
    ]);
    const successful = outcomes.filter((x) => x.status === "fulfilled");
    assert.ok(successful.length >= 1);
    assert.equal((await ref.get()).data().xp, 10);
    assert.equal((await attempt.get()).data().progress, 1);
    assert.equal((await attempt.collection("logs").get()).size, 1);
    assert.equal((await ref.collection("registration_operations").get()).size, 1);
  });

  test("cruce de nivel y finalización se confirman juntos", async () => {
    const uid = "integration-completion";
    const {ref, habit, attempt} = await seed(uid, {progress: 6, xp: 90});
    const result = await registerDemoHabit(input(uid, "integration_final_0001"));
    assert.equal(result.completed, true);
    assert.equal(result.coinsAwarded, 25);
    const userData = (await ref.get()).data();
    assert.equal(userData.xp, 100);
    assert.equal(userData.habitCoins, 125);
    assert.deepEqual(userData.claimedLevelRewards, [2]);
    assert.equal((await habit.get()).data().latestStatus, "completed");
    assert.equal((await attempt.get()).data().status, "completed");
    await assert.rejects(registerDemoHabit(
      input(uid, "integration_final_0002", new Date("2026-11-22T13:00:00Z"))
    ));
    assert.equal((await ref.get()).data().xp, 100);
  });

  test("no permite operar sobre el intento de otro usuario", async () => {
    const owner = await seed("integration-owner");
    await seed("integration-attacker");
    await owner.attempt.update({progress: 3});
    const result = await registerDemoHabit(input(
      "integration-attacker", "integration_private_0001"
    ));
    assert.equal(result.progress, 1);
    assert.equal((await owner.attempt.get()).data().progress, 3);
  });
}
