"use strict";

// No forma parte del npm test unitario. Ejecutar exclusivamente con:
// firebase emulators:exec --config firebase.emulator.json \
//   --project demo-healthy-habit --only firestore \
//   "cd functions && npm run test:integration"
const test = require("node:test");
const assert = require("node:assert/strict");
const {initializeApp, deleteApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {registerDemoHabit, registerOfficialHabitTransaction} =
  require("../habit_registration_transaction");
const {lockDemoHabitCalendar} = require("../habit_calendar_activation");
const {activateDemoHabit, activateOfficialHabitTransaction} =
  require("../habit_activation_transaction");
const {cancelDemoHabit, cancelOfficialHabitTransaction} =
  require("../habit_cancellation_transaction");
const {purchaseDemoShopItem} = require("../shop_purchase_transaction");

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


  test("bloqueo de calendario antes del registro, con rechazo de cambio posterior", async () => {
    const uid = "integration-calendar-lock";
    const {ref, habit, attempt} = await seedMulti(uid, "bien_007");
    const params = {db, uid, data: {
      habitId: "bien_007", attemptId: "attempt-1",
      timeZone: "America/Monterrey",
    }};
    const lock = await lockDemoHabitCalendar(params);
    assert.equal(lock.alreadyConfigured, false);
    const retry = await lockDemoHabitCalendar(params);
    assert.equal(retry.alreadyConfigured, true);
    for (const snapshot of [await ref.get(), await habit.get(),
      await attempt.get()]) {
      assert.equal(snapshot.data().calendarTimeZone, "America/Monterrey");
    }
    const result = await registerDemoHabit(inputMulti(
      uid, "bien_007", "calendar_lock_operation_001",
      new Date("2026-11-22T01:00:00Z")
    ));
    assert.equal(result.registrationPeriod, "day_2026-11-21");
    await assert.rejects(lockDemoHabitCalendar({
      ...params, data: {...params.data, timeZone: "UTC"},
    }));
    assert.equal((await attempt.get()).data().progress, 1);
    assert.equal((await ref.get()).data().xp, 10);
  });

  test("la activación rechaza intentos con registros existentes", async () => {
    const uid = "integration-calendar-history";
    const {ref, attempt} = await seedMulti(uid, "alim_004");
    await registerDemoHabit(inputMulti(
      uid, "alim_004", "historical_registration_001"
    ));
    await assert.rejects(lockDemoHabitCalendar({
      db, uid, data: {habitId: "alim_004", attemptId: "attempt-1",
        timeZone: "America/Monterrey"},
    }));
    assert.equal((await attempt.get()).data().calendarTimeZone, undefined);
    assert.equal((await ref.get()).data().xp, 10);
  });

  test("dos bloqueos concurrentes de zonas distintas no se mezclan", async () => {
    const uid = "integration-calendar-race";
    const {ref, habit, attempt} = await seedMulti(uid, "alim_004");
    const options = ["America/Monterrey", "UTC"];
    const outcome = await Promise.allSettled(options.map((timeZone) =>
      lockDemoHabitCalendar({db, uid, data: {
        habitId: "alim_004", attemptId: "attempt-1", timeZone,
      }})));
    assert.equal(outcome.filter((o) => o.status === "fulfilled").length, 1);
    const values = [
      (await ref.get()).data().calendarTimeZone,
      (await habit.get()).data().calendarTimeZone,
      (await attempt.get()).data().calendarTimeZone,
    ];
    assert.equal(new Set(values).size, 1);
    assert.ok(options.includes(values[0]));
  });


  async function seedActivation(uid, {slots = 3, xp = 100} = {}) {
    const ref = db.collection("users").doc(uid);
    await ref.set({
      xp, currentXp: xp, habitCoins: 100,
      habitSlots: slots, habitMutationVersion: 0,
      claimedLevelRewards: [],
      calendarTimeZone: "America/Monterrey",
    });
    return ref;
  }

  function activationArgs(uid, habitId, attemptId, operationId) {
    return {db, uid, data: {habitId, attemptId, operationId}};
  }

  test("activación real crea un intento y admite reintento sin doble cargo", async () => {
    const uid = "integration-activation-first";
    const user = await seedActivation(uid);
    const req = activationArgs(
      uid, "alim_004", "activation_attempt_0001",
      "activation_operation_0001"
    );
    const first = await activateDemoHabit(req);
    const retry = await activateDemoHabit(req);
    assert.equal(first.alreadyProcessed, false);
    assert.equal(retry.alreadyProcessed, true);
    assert.equal(retry.attemptId, first.attemptId);
    const state = (await user.get()).data();
    assert.equal(state.habitCoins, 100);
    assert.equal(state.habitMutationVersion, 1);
    const habit = user.collection("user_habits").doc("alim_004");
    const attempt = habit.collection("attempts").doc(first.attemptId);
    assert.equal((await attempt.get()).data().status, "inProgress");
    assert.equal((await attempt.get()).data().target, 12);
    assert.equal((await attempt.get()).data().calendarTimeZone,
      "America/Monterrey");
    assert.equal((await habit.get()).data().latestAttemptId, first.attemptId);
    assert.equal((await user.collection("habit_activation_operations").get()).size, 1);
  });

  test("dos activaciones simultáneas no pueden ocupar el mismo espacio", async () => {
    const uid = "integration-activation-slots";
    const user = await seedActivation(uid, {slots: 1, xp: 11000});
    const outcomes = await Promise.allSettled([
      activateDemoHabit(activationArgs(uid, "alim_004",
        "activation_attempt_0002", "activation_operation_0002")),
      activateDemoHabit(activationArgs(uid, "bien_007",
        "activation_attempt_0003", "activation_operation_0003")),
    ]);
    assert.equal(outcomes.filter((x) => x.status === "fulfilled").length, 1);
    assert.equal((await user.collection("user_habits").get()).size, 1);
    assert.equal((await user.get()).data().habitMutationVersion, 1);
    assert.equal((await user.collection("habit_activation_operations").get()).size, 1);
  });

  test("no activa hábitos difíciles sin nivel ni altera economía", async () => {
    const uid = "integration-activation-level";
    const user = await seedActivation(uid, {xp: 0});
    await assert.rejects(activateDemoHabit(activationArgs(
      uid, "bien_007", "activation_attempt_0004",
      "activation_operation_0004"
    )));
    assert.equal((await user.get()).data().habitMutationVersion, 0);
    assert.equal((await user.get()).data().habitCoins, 100);
    assert.equal((await user.collection("user_habits").get()).size, 0);
  });

  test("la activación y el primer registro usan el mismo calendario", async () => {
    const uid = "integration-activation-to-registration";
    const user = await seedActivation(uid, {xp: 100});
    await activateDemoHabit(activationArgs(
      uid, "alim_004", "activation_attempt_0005",
      "activation_operation_0005"
    ));
    const result = await registerDemoHabit({
      db, uid, now: new Date("2026-11-23T03:00:00Z"),
      data: {habitId: "alim_004", attemptId: "activation_attempt_0005",
        operationId: "registration_after_activation_0005"},
    });
    assert.equal(result.registrationPeriod, "week_2026-11-16");
    assert.equal(result.calendarTimeZone, "America/Monterrey");
    assert.equal((await user.get()).data().xp, 110);
  });


  function cancellationArgs(uid, habitId, attemptId, operationId,
    maxPenalty = 25) {
    return {db, uid, data: {habitId, attemptId, operationId, maxPenalty}};
  }

  test("cancelación difícil cobra una vez y rechaza registrar después", async () => {
    const uid = "integration-cancel-difficult";
    const user = await seedActivation(uid, {xp: 11000});
    await activateDemoHabit(activationArgs(
      uid, "bien_007", "cancel_attempt_0001",
      "cancel_activation_0001"
    ));
    const req = cancellationArgs(
      uid, "bien_007", "cancel_attempt_0001",
      "cancel_operation_0001"
    );
    const first = await cancelDemoHabit(req);
    const retry = await cancelDemoHabit(req);
    assert.equal(first.chargedCoins, 25);
    assert.equal(retry.alreadyProcessed, true);
    assert.equal(retry.chargedCoins, 25);
    assert.equal((await user.get()).data().habitCoins, 75);
    assert.equal((await user.get()).data().habitMutationVersion, 2);
    const habit = user.collection("user_habits").doc("bien_007");
    const attempt = habit.collection("attempts").doc("cancel_attempt_0001");
    assert.equal((await habit.get()).data().latestStatus, "cancelled");
    assert.equal((await attempt.get()).data().cancellationPenalty, 25);
    await assert.rejects(registerDemoHabit({
      db, uid, now: fixedDay, data: {
        habitId: "bien_007", attemptId: "cancel_attempt_0001",
        operationId: "registration_after_cancel_0001",
      },
    }));
    assert.equal((await user.get()).data().xp, 11000);
  });

  test("cancelación moderada no cobra Habit Coins", async () => {
    const uid = "integration-cancel-moderate";
    const user = await seedActivation(uid);
    await activateDemoHabit(activationArgs(
      uid, "alim_004", "cancel_attempt_0002",
      "cancel_activation_0002"
    ));
    const result = await cancelDemoHabit(cancellationArgs(
      uid, "alim_004", "cancel_attempt_0002",
      "cancel_operation_0002", 0
    ));
    assert.equal(result.chargedCoins, 0);
    assert.equal((await user.get()).data().habitCoins, 100);
    assert.equal((await user.get()).data().habitMutationVersion, 2);
  });

  test("dos cancelaciones simultáneas de distinto ID solo descuentan una vez", async () => {
    const uid = "integration-cancel-race";
    const user = await seedActivation(uid, {xp: 11000});
    await activateDemoHabit(activationArgs(
      uid, "bien_007", "cancel_attempt_0003",
      "cancel_activation_0003"
    ));
    const result = await Promise.allSettled([
      cancelDemoHabit(cancellationArgs(
        uid, "bien_007", "cancel_attempt_0003",
        "cancel_race_operation_0001"
      )),
      cancelDemoHabit(cancellationArgs(
        uid, "bien_007", "cancel_attempt_0003",
        "cancel_race_operation_0002"
      )),
    ]);
    assert.equal(result.filter((x) => x.status === "fulfilled").length, 1);
    assert.equal((await user.get()).data().habitCoins, 75);
    assert.equal((await user.collection("habit_cancellation_operations").get()).size, 1);
  });

  test("cancelación exige respetar el máximo confirmado", async () => {
    const uid = "integration-cancel-confirmation";
    const user = await seedActivation(uid, {xp: 11000});
    await activateDemoHabit(activationArgs(
      uid, "bien_007", "cancel_attempt_0004",
      "cancel_activation_0004"
    ));
    await assert.rejects(cancelDemoHabit(cancellationArgs(
      uid, "bien_007", "cancel_attempt_0004",
      "cancel_operation_0004", 10
    )));
    assert.equal((await user.get()).data().habitCoins, 100);
    assert.equal((await user.get()).data().habitMutationVersion, 1);
    assert.equal((await user.collection("habit_cancellation_operations").get()).size, 0);
  });


  function purchaseArgs(uid, itemId, operationId) {
    return {db, uid, data: {itemId, operationId}};
  }

  test("compra real en Admin SDK: descuento, inventario y reintento idempotente", async () => {
    const uid = "integration-shop-purchase";
    const ref = db.collection("users").doc(uid);
    await ref.set({xp: 0, habitCoins: 500, shopInventory: ["cap"]});
    const args = purchaseArgs(uid, "crown", "shop_operation_00001");
    const first = await purchaseDemoShopItem(args);
    const retry = await purchaseDemoShopItem(args);
    assert.equal(first.alreadyProcessed, false);
    assert.equal(first.price, 180);
    assert.equal(first.balanceAfter, 320);
    assert.equal(retry.alreadyProcessed, true);
    assert.equal(retry.balanceAfter, 320);
    const user = (await ref.get()).data();
    assert.equal(user.habitCoins, 320);
    assert.deepEqual(user.shopInventory, ["cap", "crown"]);
    assert.equal((await ref.collection("shop_purchase_operations").get()).size, 1);
    await assert.rejects(purchaseDemoShopItem(purchaseArgs(
      uid, "cape", "shop_operation_00001"
    )));
    assert.equal((await ref.get()).data().habitCoins, 320);
  });

  test("dos compras simultáneas del mismo artículo no cobran dos veces", async () => {
    const uid = "integration-shop-same-item";
    const ref = db.collection("users").doc(uid);
    await ref.set({habitCoins: 500, shopInventory: []});
    const results = await Promise.allSettled([
      purchaseDemoShopItem(purchaseArgs(uid, "crown", "shop_same_00000001")),
      purchaseDemoShopItem(purchaseArgs(uid, "crown", "shop_same_00000002")),
    ]);
    assert.equal(results.filter((x) => x.status === "fulfilled").length, 1);
    const user = (await ref.get()).data();
    assert.equal(user.habitCoins, 320);
    assert.deepEqual(user.shopInventory, ["crown"]);
    assert.equal((await ref.collection("shop_purchase_operations").get()).size, 1);
  });

  test("dos compras distintas no pueden gastar dos veces el mismo saldo", async () => {
    const uid = "integration-shop-balance-race";
    const ref = db.collection("users").doc(uid);
    await ref.set({habitCoins: 200, shopInventory: []});
    const results = await Promise.allSettled([
      purchaseDemoShopItem(purchaseArgs(uid, "crown", "shop_race_00000001")),
      purchaseDemoShopItem(purchaseArgs(uid, "cape", "shop_race_00000002")),
    ]);
    assert.equal(results.filter((x) => x.status === "fulfilled").length, 1);
    const user = (await ref.get()).data();
    assert.equal(user.habitCoins,
      200 - (user.shopInventory.includes("crown") ? 180 : 200));
    assert.equal(user.shopInventory.length, 1);
    assert.equal((await ref.collection("shop_purchase_operations").get()).size, 1);
  });

  test("compras de otros usuarios no afectan su economía ni su inventario", async () => {
    const owner = db.collection("users").doc("integration-shop-owner");
    const buyer = db.collection("users").doc("integration-shop-buyer");
    await Promise.all([
      owner.set({habitCoins: 500, shopInventory: []}),
      buyer.set({habitCoins: 300, shopInventory: []}),
    ]);
    await purchaseDemoShopItem(purchaseArgs(
      "integration-shop-buyer", "crown", "shop_private_000001"
    ));
    assert.equal((await owner.get()).data().habitCoins, 500);
    assert.deepEqual((await owner.get()).data().shopInventory, []);
    assert.equal((await buyer.get()).data().habitCoins, 120);
    assert.deepEqual((await buyer.get()).data().shopInventory, ["crown"]);
  });

  test("artículos gratuitos, inventario inválido y falta de saldo no compran", async () => {
    const uid = "integration-shop-reject";
    const ref = db.collection("users").doc(uid);
    await ref.set({habitCoins: 50, shopInventory: []});
    for (const [itemId, operationId] of [
      ["crown", "shop_reject_000001"],
      ["sunglasses", "shop_reject_000002"],
      ["not-in-catalog", "shop_reject_000003"],
    ]) {
      await assert.rejects(purchaseDemoShopItem(
        purchaseArgs(uid, itemId, operationId)
      ));
    }
    assert.equal((await ref.get()).data().habitCoins, 50);
    assert.equal((await ref.collection("shop_purchase_operations").get()).size, 0);
    await ref.update({shopInventory: ["crown", "crown"], habitCoins: 500});
    await assert.rejects(purchaseDemoShopItem(
      purchaseArgs(uid, "cape", "shop_reject_000004")
    ));
    assert.equal((await ref.get()).data().habitCoins, 500);
  });


  // Motor oficial: real Firestore Emulator, sin endpoint ni proyecto real.
  async function seedOfficial(uid, habitId, {xp = 0, coins = 100,
    progress = 0} = {}) {
    const {SERVER_CATALOG} = require("../official_habit_catalog");
    const catalog = SERVER_CATALOG[habitId];
    const docs = await seedMulti(uid, habitId);
    await Promise.all([
      docs.ref.update({
        xp, currentXp: xp, level: xp >= 100 ? 2 : 1,
        habitCoins: coins,
      }),
      docs.attempt.update({
        habitId, progress, xpEarned: progress * catalog.xp,
      }),
    ]);
    return docs;
  }

  function officialInput(uid, habitId, operationId, now = fixedDay) {
    return {
      db, uid, now,
      data: {habitId, attemptId: "attempt-1", operationId},
    };
  }

  test("motor oficial: Firestore acredita los 36 hábitos una vez", async () => {
    const {SERVER_CATALOG} = require("../official_habit_catalog");
    const ids = Object.keys(SERVER_CATALOG);
    assert.equal(ids.length, 36);
    for (const habitId of ids) {
      const uid = `integration-official-${habitId}`;
      const {ref, attempt} = await seedOfficial(uid, habitId);
      const operationId = `official_register_${habitId}_0001`;
      const input = officialInput(uid, habitId, operationId);
      const result = await registerOfficialHabitTransaction(input);
      const retry = await registerOfficialHabitTransaction(input);
      const xp = SERVER_CATALOG[habitId].xp;
      assert.equal(result.xpAwarded, xp, habitId);
      assert.equal(retry.alreadyProcessed, true, habitId);
      assert.equal((await ref.get()).data().xp, xp, habitId);
      assert.equal((await attempt.get()).data().progress, 1, habitId);
      assert.equal((await attempt.collection("logs").get()).size, 1, habitId);
      assert.equal((await ref.collection("registration_operations").get()).size,
        1, habitId);
      assert.equal((await attempt.collection("registration_periods").get()).size,
        1, habitId);
    }
  });

  test("motor oficial: concurrencia con IDs distintos no duplica XP diarios", async () => {
    const uid = "integration-official-concurrency";
    const {ref, attempt} = await seedOfficial(uid, "alim_001");
    const outcomes = await Promise.allSettled([
      registerOfficialHabitTransaction(officialInput(
        uid, "alim_001", "official_race_first_0001"
      )),
      registerOfficialHabitTransaction(officialInput(
        uid, "alim_001", "official_race_second_0002"
      )),
    ]);
    assert.equal(outcomes.filter((o) => o.status === "fulfilled").length, 1);
    assert.equal((await ref.get()).data().xp, 10);
    assert.equal((await attempt.get()).data().progress, 1);
    assert.equal((await attempt.collection("logs").get()).size, 1);
    assert.equal((await ref.collection("registration_operations").get()).size, 1);
  });

  test("motor oficial: concurrencia con el mismo ID es idempotente", async () => {
    const uid = "integration-official-same-id";
    const {ref, attempt} = await seedOfficial(uid, "bien_007");
    const input = officialInput(
      uid, "bien_007", "official_identical_0001"
    );
    const outcomes = await Promise.allSettled([
      registerOfficialHabitTransaction(input),
      registerOfficialHabitTransaction(input),
    ]);
    assert.ok(outcomes.some((o) => o.status === "fulfilled"));
    assert.equal((await ref.get()).data().xp, 20);
    assert.equal((await attempt.get()).data().progress, 1);
    assert.equal((await attempt.collection("logs").get()).size, 1);
    assert.equal((await ref.collection("registration_operations").get()).size, 1);
  });

  test("motor oficial: un nivel cruzado paga 25 monedas una sola vez", async () => {
    const uid = "integration-official-level";
    const {ref, attempt} = await seedOfficial(uid, "bien_007", {xp: 90});
    const input = officialInput(
      uid, "bien_007", "official_level_bonus_0001"
    );
    const first = await registerOfficialHabitTransaction(input);
    const repeat = await registerOfficialHabitTransaction(input);
    assert.equal(first.coinsAwarded, 25);
    assert.equal(repeat.alreadyProcessed, true);
    assert.equal((await ref.get()).data().xp, 110);
    assert.equal((await ref.get()).data().habitCoins, 125);
    assert.deepEqual((await ref.get()).data().claimedLevelRewards, [2]);
    assert.equal((await attempt.collection("logs").get()).size, 1);
  });

  test("motor oficial: inyección económica no altera estado", async () => {
    const uid = "integration-official-payload";
    const {ref, attempt} = await seedOfficial(uid, "alim_001");
    for (const key of ["xp", "habitCoins", "progress", "evidenceVerified"]) {
      await assert.rejects(registerOfficialHabitTransaction({
        ...officialInput(uid, "alim_001", `official_bad_${key}_0001`),
        data: {
          ...officialInput(uid, "alim_001", `official_bad_${key}_0001`).data,
          [key]: 99999,
        },
      }));
    }
    assert.equal((await ref.get()).data().xp, 0);
    assert.equal((await ref.get()).data().habitCoins, 100);
    assert.equal((await attempt.get()).data().progress, 0);
    assert.equal((await attempt.collection("logs").get()).size, 0);
  });

  test("motor oficial: intento cancelado no puede recibir premios", async () => {
    const uid = "integration-official-cancelled";
    const {ref, attempt} = await seedOfficial(uid, "alim_001");
    await attempt.update({status: "cancelled"});
    await assert.rejects(registerOfficialHabitTransaction(officialInput(
      uid, "alim_001", "official_cancelled_0001"
    )));
    assert.equal((await ref.get()).data().xp, 0);
    assert.equal((await attempt.collection("logs").get()).size, 0);
  });

  test("motor oficial: activa y cancela los 36 hábitos con reintentos", async () => {
    const {SERVER_CATALOG} = require("../official_habit_catalog");
    const ids = Object.keys(SERVER_CATALOG);
    assert.equal(ids.length, 36);
    for (const habitId of ids) {
      const uid = `integration-lifecycle-${habitId}`;
      const user = await seedActivation(uid, {xp: 11000});
      const attemptId = `official_attempt_${habitId}_01`;
      const activateParams = {
        db, uid,
        data: {
          habitId, attemptId,
          operationId: `official_activation_${habitId}_01`,
        },
      };
      const activated = await activateOfficialHabitTransaction(activateParams);
      const activationRetry =
        await activateOfficialHabitTransaction(activateParams);
      assert.equal(activated.alreadyProcessed, false, habitId);
      assert.equal(activationRetry.alreadyProcessed, true, habitId);
      const habitRef = user.collection("user_habits").doc(habitId);
      const attemptRef = habitRef.collection("attempts").doc(attemptId);
      assert.equal((await attemptRef.get()).data().status, "inProgress",
        habitId);
      assert.equal((await attemptRef.get()).data().target,
        SERVER_CATALOG[habitId].target, habitId);
      const cancelParams = {
        db, uid,
        data: {
          habitId, attemptId,
          operationId: `official_cancel_${habitId}_01`,
          maxPenalty: 25,
        },
      };
      const cancelled = await cancelOfficialHabitTransaction(cancelParams);
      const cancellationRetry =
        await cancelOfficialHabitTransaction(cancelParams);
      assert.equal(cancelled.alreadyProcessed, false, habitId);
      assert.equal(cancellationRetry.alreadyProcessed, true, habitId);
      assert.equal((await attemptRef.get()).data().status, "cancelled",
        habitId);
      const penalty = SERVER_CATALOG[habitId].difficulty === "Difícil" ? 25 : 0;
      assert.equal(cancelled.chargedCoins, penalty, habitId);
      assert.equal((await user.get()).data().habitCoins, 100 - penalty,
        habitId);
      assert.equal((await user.get()).data().habitMutationVersion, 2,
        habitId);
      assert.equal((await user.collection("habit_activation_operations").get()).size,
        1, habitId);
      assert.equal((await user.collection("habit_cancellation_operations").get()).size,
        1, habitId);
    }
  });

  test("motor oficial: dos activaciones simultáneas respetan un solo cupo", async () => {
    const uid = "integration-official-activation-race";
    const user = await seedActivation(uid, {slots: 1, xp: 11000});
    const payloads = [
      {habitId: "alim_001", attemptId: "official_attempt_race_01",
        operationId: "official_activation_race_01"},
      {habitId: "ener_002", attemptId: "official_attempt_race_02",
        operationId: "official_activation_race_02"},
    ];
    const outcomes = await Promise.allSettled(payloads.map((data) =>
      activateOfficialHabitTransaction({db, uid, data})));
    assert.equal(outcomes.filter((o) => o.status === "fulfilled").length, 1);
    assert.equal((await user.collection("user_habits").get()).size, 1);
    assert.equal((await user.get()).data().habitMutationVersion, 1);
  });

}
