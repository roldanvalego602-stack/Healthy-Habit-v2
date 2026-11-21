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

  async function seedMulti(uid, habitId) {
    const catalog = require("../official_habit_catalog").SERVER_CATALOG[habitId];
    const ref = db.collection("users").doc(uid);
    const habit = ref.collection("user_habits").doc(habitId);
    const attempt = habit.collection("attempts").doc("attempt-1");
    const batch = db.batch();
    batch.set(ref, {
      xp: 0, currentXp: 0, level: 1,
      habitCoins: 100, claimedLevelRewards: [],
    });
    batch.set(habit, {
      title: catalog.title,
      latestAttemptId: "attempt-1", lastAttemptId: "attempt-1",
      latestStatus: "inProgress", lastStatus: "inProgress",
      frequencyType: catalog.frequencyType,
    });
    batch.set(attempt, {
      status: "inProgress", progress: 0, target: catalog.target,
      xpEarned: 0, frequencyType: catalog.frequencyType,
      registrationsPerPeriod: catalog.registrationsPerPeriod,
    });
    await batch.commit();
    return {ref, habit, attempt};
  }

  function inputMulti(uid, habitId, operationId, now = fixedDay) {
    return {
      db, uid, now,
      data: {habitId, attemptId: "attempt-1", operationId},
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
    const periods = await attempt.collection("registration_periods").get();
    assert.equal(logs.size, 1);
    assert.equal(operations.size, 1);
    assert.equal(days.size, 1);
    assert.equal(periods.size, 1);
    assert.equal(periods.docs[0].data().count, 1);
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

  test("dos días distintos generan contadores separados sin duplicar XP", async () => {
    const uid = "integration-next-period";
    const {ref, attempt} = await seed(uid);
    const first = await registerDemoHabit(input(
      uid, "integration_period_0001", fixedDay
    ));
    const second = await registerDemoHabit(input(
      uid, "integration_period_0002", new Date("2026-11-22T13:00:00Z")
    ));
    assert.equal(first.progress, 1);
    assert.equal(second.progress, 2);
    assert.equal((await ref.get()).data().xp, 20);
    const counters = await attempt.collection("registration_periods").get();
    assert.equal(counters.size, 2);
    for (const doc of counters.docs) assert.equal(doc.data().count, 1);
  });

  test("una marca diaria previa conserva el bloqueo sin contador", async () => {
    const uid = "integration-legacy-day";
    const {ref, attempt} = await seed(uid);
    await attempt.collection("registration_days")
      .doc("2026-11-21").create({operationId: "legacy_record_0001"});
    await assert.rejects(registerDemoHabit(input(
      uid, "integration_legacy_0001"
    )));
    assert.equal((await ref.get()).data().xp, 0);
    assert.equal((await attempt.collection("registration_periods").get()).size, 0);
  });

  test("una segunda petición no altera el contador del mismo periodo", async () => {
    const uid = "integration-counter-race";
    const {ref, attempt} = await seed(uid);
    const results = await Promise.allSettled([
      registerDemoHabit(input(uid, "integration_counter_0001")),
      registerDemoHabit(input(uid, "integration_counter_0002")),
    ]);
    assert.equal(results.filter((x) => x.status === "fulfilled").length, 1);
    assert.equal((await ref.get()).data().xp, 10);
    const counters = await attempt.collection("registration_periods").get();
    assert.equal(counters.size, 1);
    assert.equal(counters.docs[0].data().count, 1);
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

  test("hábito de dos registros diarios rechaza el tercero en Firestore", async () => {
    const uid = "integration-double-daily";
    const {ref, attempt} = await seedMulti(uid, "bien_007");
    const first = await registerDemoHabit(inputMulti(
      uid, "bien_007", "double_daily_000001"
    ));
    const second = await registerDemoHabit(inputMulti(
      uid, "bien_007", "double_daily_000002"
    ));
    assert.equal(first.periodCount, 1);
    assert.equal(second.periodCount, 2);
    await assert.rejects(registerDemoHabit(inputMulti(
      uid, "bien_007", "double_daily_000003"
    )));
    assert.equal((await ref.get()).data().xp, 20);
    assert.equal((await attempt.collection("logs").get()).size, 2);
    assert.equal((await attempt.collection("registration_days").get()).size, 0);
    const period = await attempt.collection("registration_periods")
      .doc("day_2026-11-21").get();
    assert.equal(period.data().count, 2);
  });

  test("hábito semanal limita tres registros y cambia el lunes UTC", async () => {
    const uid = "integration-triple-weekly";
    const {ref, attempt} = await seedMulti(uid, "alim_004");
    for (let n = 1; n <= 3; n++) {
      const result = await registerDemoHabit(inputMulti(
        uid, "alim_004", `triple_weekly_000${n}`
      ));
      assert.equal(result.periodCount, n);
    }
    await assert.rejects(registerDemoHabit(inputMulti(
      uid, "alim_004", "triple_weekly_0004"
    )));
    const monday = await registerDemoHabit(inputMulti(
      uid, "alim_004", "triple_weekly_0005",
      new Date("2026-11-23T13:00:00Z")
    ));
    assert.equal(monday.periodCount, 1);
    assert.equal(monday.registrationPeriod, "week_2026-11-23");
    assert.equal((await ref.get()).data().xp, 40);
    assert.equal((await attempt.collection("logs").get()).size, 4);
  });

  test("dos registros concurrentes llenan el cupo diario sin sobrepasarlo", async () => {
    const uid = "integration-multidaily-race";
    const {ref, attempt} = await seedMulti(uid, "bien_007");
    const parallel = await Promise.allSettled([
      registerDemoHabit(inputMulti(
        uid, "bien_007", "parallel_daily_0001"
      )),
      registerDemoHabit(inputMulti(
        uid, "bien_007", "parallel_daily_0002"
      )),
    ]);
    const accepted = parallel.filter((x) => x.status === "fulfilled");
    // Firestore puede abortar una de las operaciones por contención;
    // ninguna ejecución permite más de dos recompensas.
    assert.ok(accepted.length >= 1);
    if (accepted.length === 1) {
      await registerDemoHabit(inputMulti(
        uid, "bien_007", "parallel_daily_0003"
      ));
    }
    await assert.rejects(registerDemoHabit(inputMulti(
      uid, "bien_007", "parallel_daily_0004"
    )));
    assert.equal((await ref.get()).data().xp, 20);
    assert.equal((await attempt.collection("logs").get()).size, 2);
    const counter = await attempt.collection("registration_periods")
      .doc("day_2026-11-21").get();
    assert.equal(counter.data().count, 2);
  });


  test("zona Monterrey: medianoche UTC conserva el mismo día local", async () => {
    const uid = "integration-monterrey-calendar";
    const {ref, habit, attempt} = await seedMulti(uid, "bien_007");
    await Promise.all([
      ref.update({calendarTimeZone: "America/Monterrey"}),
      habit.update({calendarTimeZone: "America/Monterrey"}),
      attempt.update({calendarTimeZone: "America/Monterrey"}),
    ]);
    const first = await registerDemoHabit(inputMulti(
      uid, "bien_007", "local_calendar_0001",
      new Date("2026-11-22T01:00:00Z")
    ));
    const second = await registerDemoHabit(inputMulti(
      uid, "bien_007", "local_calendar_0002",
      new Date("2026-11-22T03:00:00Z")
    ));
    assert.equal(first.registrationPeriod, "day_2026-11-21");
    assert.equal(second.registrationPeriod, "day_2026-11-21");
    assert.equal(second.periodStreak, 1);
    await assert.rejects(registerDemoHabit(inputMulti(
      uid, "bien_007", "local_calendar_0003",
      new Date("2026-11-22T04:00:00Z")
    )));
    assert.equal((await ref.get()).data().xp, 20);
    assert.equal((await attempt.get()).data().periodStreak, 1);
    assert.equal((await attempt.collection("registration_periods").get()).size, 1);
  });

  test("el hábito moderado conserva racha tras una semana omitida", async () => {
    const uid = "integration-weekly-grace";
    const {ref, attempt} = await seedMulti(uid, "alim_004");
    await attempt.update({
      lastCompletedPeriod: "week_2026-11-02", periodStreak: 4,
      gracePeriodsUsed: 0,
    });
    for (let n = 1; n <= 2; n++) {
      await registerDemoHabit(inputMulti(
        uid, "alim_004", `weekly_grace_000${n}`
      ));
      assert.equal((await attempt.get()).data().periodStreak, 4);
    }
    const complete = await registerDemoHabit(inputMulti(
      uid, "alim_004", "weekly_grace_0003"
    ));
    assert.equal(complete.periodStreak, 5);
    const state = (await attempt.get()).data();
    assert.equal(state.lastCompletedPeriod, "week_2026-11-16");
    assert.equal(state.gracePeriodsUsed, 1);
    assert.equal((await ref.get()).data().xp, 30);
    assert.equal((await attempt.collection("logs").get()).size, 3);
  });

  test("el hábito difícil no concede gracia tras un día omitido", async () => {
    const uid = "integration-no-difficult-grace";
    const {ref, attempt} = await seedMulti(uid, "bien_007");
    await attempt.update({
      lastCompletedPeriod: "day_2026-11-19", periodStreak: 4,
      gracePeriodsUsed: 0,
    });
    await registerDemoHabit(inputMulti(
      uid, "bien_007", "difficult_no_grace_0001"
    ));
    const completed = await registerDemoHabit(inputMulti(
      uid, "bien_007", "difficult_no_grace_0002"
    ));
    assert.equal(completed.periodStreak, 1);
    assert.equal((await attempt.get()).data().gracePeriodsUsed, 0);
    assert.equal((await ref.get()).data().xp, 20);
  });

}
