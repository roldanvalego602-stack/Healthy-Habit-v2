"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  validateDemoRegistration,
  calculateRegistrationReward,
  levelForXp,
  registerDemoHabit,
} = require("../habit_registration_transaction");
const {RegistrationPolicyError} = require("../habit_registration_policy");

class FakeRef {
  constructor(db, path) { this.db = db; this.path = path; }
  collection(name) { return new FakeRef(this.db, `${this.path}/${name}`); }
  doc(id) { return new FakeRef(this.db, `${this.path}/${id}`); }
}
class FakeFirestore {
  constructor(documents) {
    this.docs = new Map(Object.entries(documents));
  }
  collection(name) { return new FakeRef(this, name); }
  async runTransaction(task) {
    const writes = [];
    const tx = {
      get: async (ref) => ({
        exists: this.docs.has(ref.path),
        data: () => this.docs.get(ref.path),
      }),
      create: (ref, data) => writes.push({type: "create", ref, data}),
      update: (ref, data) => writes.push({type: "update", ref, data}),
    };
    const result = await task(tx);
    // Emula commit atómico y documenta que las validaciones pasan
    // antes de modificar datos persistidos.
    for (const write of writes) {
      if (write.type === "create" && this.docs.has(write.ref.path)) {
        throw new Error("already exists");
      }
      if (write.type === "update" && !this.docs.has(write.ref.path)) {
        throw new Error("not found");
      }
    }
    for (const write of writes) {
      if (write.type === "create") {
        this.docs.set(write.ref.path, write.data);
      } else {
        this.docs.set(write.ref.path, {
          ...this.docs.get(write.ref.path), ...write.data,
        });
      }
    }
    return result;
  }
}

function seededDb({progress = 0, xp = 0} = {}) {
  return new FakeFirestore({
    "users/alice": {
      xp, currentXp: xp, habitCoins: 100,
      claimedLevelRewards: [],
    },
    "users/alice/user_habits/hidr_001": {
      title: "Beber agua al despertar",
      latestAttemptId: "attempt-1",
      lastAttemptId: "attempt-1",
      latestStatus: "inProgress",
      lastStatus: "inProgress",
      frequencyType: "daily",
    },
    "users/alice/user_habits/hidr_001/attempts/attempt-1": {
      status: "inProgress", progress, target: 7,
      xpEarned: 10 * progress, frequencyType: "daily",
      registrationsPerPeriod: 1,
    },
  });
}
const args = {
  uid: "alice",
  data: {
    habitId: "hidr_001",
    attemptId: "attempt-1",
    operationId: "operation_00000001",
  },
  now: new Date("2026-11-21T13:00:00Z"),
};

function seededMultiDb(habitId) {
  const catalog = require("../official_habit_catalog").SERVER_CATALOG[habitId];
  const prefix = `users/alice/user_habits/${habitId}`;
  return new FakeFirestore({
    "users/alice": {
      xp: 0, currentXp: 0, habitCoins: 100,
      claimedLevelRewards: [],
    },
    [prefix]: {
      title: catalog.title, latestAttemptId: "attempt-1",
      lastAttemptId: "attempt-1", latestStatus: "inProgress",
      lastStatus: "inProgress", frequencyType: catalog.frequencyType,
    },
    [`${prefix}/attempts/attempt-1`]: {
      status: "inProgress", progress: 0, target: catalog.target,
      xpEarned: 0, frequencyType: catalog.frequencyType,
      registrationsPerPeriod: catalog.registrationsPerPeriod,
    },
  });
}

function multiArgs(habitId, suffix, now = args.now) {
  return {
    uid: "alice", now,
    data: {habitId, attemptId: "attempt-1",
      operationId: `multi_registration_${suffix}`},
  };
}

test("solo admite el piloto sin montos ni evidencias del cliente", () => {
  assert.deepEqual(validateDemoRegistration(args.data), args.data);
  for (const data of [
    {...args.data, xpAwarded: 999},
    {...args.data, hasEvidence: true},
    {...args.data, operationId: "../wrong"},
    {...args.data, habitId: "alim_001"},
  ]) {
    assert.throws(() => validateDemoRegistration(data),
      RegistrationPolicyError);
  }
});

test("el cálculo respeta los umbrales de XP y monedas", () => {
  assert.equal(levelForXp(99), 1);
  assert.equal(levelForXp(100), 2);
  assert.equal(levelForXp(10500), 20);
  const earned = calculateRegistrationReward({
    user: {xp: 90, habitCoins: 100, claimedLevelRewards: []},
    attempt: {xpEarned: 30},
    catalog: {target: 7},
  });
  assert.equal(earned.xp, 100);
  assert.equal(earned.level, 2);
  assert.equal(earned.coinsAwarded, 25);
  assert.equal(earned.coins, 125);
  assert.deepEqual(earned.claimedLevelRewards, [2]);
});

test("registra progreso y recompensa una sola vez", async () => {
  const db = seededDb();
  const first = await registerDemoHabit({db, ...args});
  assert.equal(first.alreadyProcessed, false);
  assert.equal(first.progress, 1);
  assert.equal(first.xpAwarded, 10);
  assert.equal(db.docs.get("users/alice").xp, 10);
  assert.equal(db.docs.get("users/alice").habitCoins, 100);
  assert.equal(db.docs.get(
    "users/alice/user_habits/hidr_001/attempts/attempt-1"
  ).progress, 1);
  const repeated = await registerDemoHabit({db, ...args});
  assert.equal(repeated.alreadyProcessed, true);
  assert.equal(repeated.progress, first.progress);
  assert.equal(db.docs.get("users/alice").xp, 10);
});

test("no permite segundo registro el mismo día con otra operación", async () => {
  const db = seededDb();
  await registerDemoHabit({db, ...args});
  await assert.rejects(registerDemoHabit({
    db, ...args,
    data: {...args.data, operationId: "operation_00000002"},
  }), RegistrationPolicyError);
  assert.equal(db.docs.get("users/alice").xp, 10);
});

test("completa el intento y sincroniza el estado del hábito", async () => {
  const db = seededDb({progress: 6, xp: 90});
  const result = await registerDemoHabit({db, ...args});
  assert.equal(result.completed, true);
  assert.equal(result.coinsAwarded, 25);
  assert.equal(db.docs.get("users/alice").habitCoins, 125);
  assert.equal(db.docs.get(
    "users/alice/user_habits/hidr_001"
  ).latestStatus, "completed");
  assert.equal(db.docs.get(
    "users/alice/user_habits/hidr_001/attempts/attempt-1"
  ).status, "completed");
});

test("rechaza intento cancelado antes de crear registros", async () => {
  const db = seededDb();
  db.docs.get("users/alice/user_habits/hidr_001/attempts/attempt-1")
    .status = "cancelled";
  await assert.rejects(registerDemoHabit({db, ...args}),
    RegistrationPolicyError);
  assert.equal(db.docs.size, 3);
  assert.equal(db.docs.get("users/alice").xp, 0);
});

test("no permite reutilizar el ID para un intento diferente", async () => {
  const db = seededDb();
  await registerDemoHabit({db, ...args});
  await assert.rejects(registerDemoHabit({
    db, ...args,
    data: {...args.data, attemptId: "attempt-2"},
  }), RegistrationPolicyError);
  assert.equal(db.docs.get("users/alice").xp, 10);
});

test("rechaza un objetivo manipulado que difiere del catálogo", async () => {
  const db = seededDb();
  db.docs.get("users/alice/user_habits/hidr_001/attempts/attempt-1")
    .target = 999;
  await assert.rejects(registerDemoHabit({db, ...args}),
    RegistrationPolicyError);
  assert.equal(db.docs.size, 3);
});


test("la transacción crea contador de periodo con un solo registro", async () => {
  const db = seededDb();
  const result = await registerDemoHabit({db, ...args});
  const periodPath =
    "users/alice/user_habits/hidr_001/attempts/attempt-1/" +
    "registration_periods/day_2026-11-21";
  assert.equal(result.registrationPeriod, "day_2026-11-21");
  assert.equal(result.periodCount, 1);
  assert.equal(db.docs.get(periodPath).count, 1);
  await registerDemoHabit({db, ...args});
  assert.equal(db.docs.get(periodPath).count, 1);
});

test("un segundo día habilita exactamente otro registro en el piloto", async () => {
  const db = seededDb();
  await registerDemoHabit({db, ...args});
  const result = await registerDemoHabit({
    db, ...args,
    data: {...args.data, operationId: "operation_00000002"},
    now: new Date("2026-11-22T13:00:00Z"),
  });
  assert.equal(result.progress, 2);
  assert.equal(result.periodCount, 1);
  assert.equal(db.docs.get("users/alice").xp, 20);
  assert.equal(db.docs.get(
    "users/alice/user_habits/hidr_001/attempts/attempt-1/" +
    "registration_periods/day_2026-11-22"
  ).count, 1);
});

test("un contador de periodo inválido bloquea recompensas", async () => {
  const db = seededDb();
  db.docs.set(
    "users/alice/user_habits/hidr_001/attempts/attempt-1/" +
    "registration_periods/day_2026-11-21",
    {count: -1}
  );
  await assert.rejects(registerDemoHabit({db, ...args}),
    RegistrationPolicyError);
  assert.equal(db.docs.get("users/alice").xp, 0);
});


test("dos registros diarios son válidos, el tercero se bloquea", async () => {
  const db = seededMultiDb("bien_007");
  const first = await registerDemoHabit({
    db, ...multiArgs("bien_007", "daily_0001"),
  });
  const second = await registerDemoHabit({
    db, ...multiArgs("bien_007", "daily_0002"),
  });
  assert.equal(first.periodCount, 1);
  assert.equal(second.periodCount, 2);
  assert.equal(second.progress, 2);
  await assert.rejects(registerDemoHabit({
    db, ...multiArgs("bien_007", "daily_0003"),
  }), RegistrationPolicyError);
  assert.equal(db.docs.get("users/alice").xp, 20);
  const prefix = "users/alice/user_habits/bien_007/attempts/attempt-1/";
  assert.equal(db.docs.get(prefix +
    "registration_periods/day_2026-11-21").count, 2);
  assert.equal([...db.docs.keys()].filter((x) =>
    x.startsWith(prefix + "registration_days/")).length, 0);
});

test("un día nuevo reinicia el contador del hábito doble", async () => {
  const db = seededMultiDb("bien_007");
  await registerDemoHabit({db, ...multiArgs("bien_007", "reset_0001")});
  await registerDemoHabit({db, ...multiArgs("bien_007", "reset_0002")});
  const next = await registerDemoHabit({db, ...multiArgs(
    "bien_007", "reset_0003", new Date("2026-11-22T13:00:00Z"),
  )});
  assert.equal(next.periodCount, 1);
  assert.equal(db.docs.get("users/alice").xp, 30);
});

test("tres registros semanales son válidos y el cuarto se bloquea", async () => {
  const db = seededMultiDb("alim_004");
  for (let n = 1; n <= 3; n++) {
    const result = await registerDemoHabit({db, ...multiArgs(
      "alim_004", `weekly_000${n}`,
    )});
    assert.equal(result.periodCount, n);
    assert.equal(result.registrationPeriod, "week_2026-11-16");
  }
  await assert.rejects(registerDemoHabit({db, ...multiArgs(
    "alim_004", "weekly_0004",
  )}), RegistrationPolicyError);
  assert.equal(db.docs.get("users/alice").xp, 30);
});

test("una semana nueva admite tres registros adicionales", async () => {
  const db = seededMultiDb("alim_004");
  for (let n = 1; n <= 3; n++) {
    await registerDemoHabit({db, ...multiArgs(
      "alim_004", `weeka_000${n}`,
    )});
  }
  const result = await registerDemoHabit({db, ...multiArgs(
    "alim_004", "weekb_0001", new Date("2026-11-23T13:00:00Z"),
  )});
  assert.equal(result.periodCount, 1);
  assert.equal(result.registrationPeriod, "week_2026-11-23");
  assert.equal(result.progress, 4);
  assert.equal(db.docs.get("users/alice").xp, 40);
});

test("operación duplicada del hábito semanal no añade otro registro", async () => {
  const db = seededMultiDb("alim_004");
  const req = multiArgs("alim_004", "idempotent_0001");
  const first = await registerDemoHabit({db, ...req});
  const retry = await registerDemoHabit({db, ...req});
  assert.equal(first.periodCount, 1);
  assert.equal(retry.alreadyProcessed, true);
  assert.equal(db.docs.get("users/alice").xp, 10);
});


test("el día local de Monterrey no cambia al llegar medianoche UTC", async () => {
  const db = seededMultiDb("bien_007");
  for (const key of ["users/alice", "users/alice/user_habits/bien_007",
    "users/alice/user_habits/bien_007/attempts/attempt-1"]) {
    db.docs.get(key).calendarTimeZone = "America/Monterrey";
  }
  const first = await registerDemoHabit({db, ...multiArgs(
    "bien_007", "local_0001", new Date("2026-11-22T01:00:00Z"),
  )});
  const second = await registerDemoHabit({db, ...multiArgs(
    "bien_007", "local_0002", new Date("2026-11-22T03:00:00Z"),
  )});
  assert.equal(first.registrationPeriod, "day_2026-11-21");
  assert.equal(second.registrationPeriod, "day_2026-11-21");
  assert.equal(second.periodStreak, 1);
  assert.equal(db.docs.get("users/alice/user_habits/bien_007/" +
    "attempts/attempt-1").periodStreak, 1);
  await assert.rejects(registerDemoHabit({db, ...multiArgs(
    "bien_007", "local_0003", new Date("2026-11-22T04:00:00Z"),
  )}), RegistrationPolicyError);
  assert.equal(db.docs.get("users/alice").xp, 20);
});

test("el hábito difícil reinicia la racha sin periodo de gracia", async () => {
  const db = seededMultiDb("bien_007");
  const path = "users/alice/user_habits/bien_007/attempts/attempt-1";
  db.docs.get(path).lastCompletedPeriod = "day_2026-11-19";
  db.docs.get(path).periodStreak = 4;
  await registerDemoHabit({db, ...multiArgs("bien_007", "no_grace_0001")});
  assert.equal(db.docs.get(path).periodStreak, 4);
  const last = await registerDemoHabit({
    db, ...multiArgs("bien_007", "no_grace_0002"),
  });
  assert.equal(last.periodStreak, 1);
  assert.equal(db.docs.get(path).periodStreak, 1);
  assert.equal(db.docs.get(path).gracePeriodsUsed, 0);
  assert.equal(db.docs.get("users/alice").xp, 20);
});

test("el hábito moderado tolera una semana omitida al completar tres registros", async () => {
  const db = seededMultiDb("alim_004");
  const path = "users/alice/user_habits/alim_004/attempts/attempt-1";
  db.docs.get(path).lastCompletedPeriod = "week_2026-11-02";
  db.docs.get(path).periodStreak = 4;
  for (let n = 1; n <= 2; n++) {
    await registerDemoHabit({
      db, ...multiArgs("alim_004", `week_grace_000${n}`),
    });
    assert.equal(db.docs.get(path).periodStreak, 4);
  }
  const result = await registerDemoHabit({
    db, ...multiArgs("alim_004", "week_grace_0003"),
  });
  assert.equal(result.periodStreak, 5);
  assert.equal(db.docs.get(path).lastCompletedPeriod, "week_2026-11-16");
  assert.equal(db.docs.get(path).gracePeriodsUsed, 1);
  assert.equal(db.docs.get("users/alice").xp, 30);
});

test("el hábito moderado reinicia la racha al exceder una semana de gracia", async () => {
  const db = seededMultiDb("alim_004");
  const path = "users/alice/user_habits/alim_004/attempts/attempt-1";
  db.docs.get(path).lastCompletedPeriod = "week_2026-10-26";
  db.docs.get(path).periodStreak = 6;
  for (let n = 1; n <= 3; n++) {
    await registerDemoHabit({
      db, ...multiArgs("alim_004", `reset_week_000${n}`),
    });
  }
  assert.equal(db.docs.get(path).periodStreak, 1);
  assert.equal(db.docs.get(path).gracePeriodsUsed, 1);
});

test("rechaza zonas distintas entre perfil, hábito e intento", async () => {
  const db = seededMultiDb("alim_004");
  db.docs.get("users/alice/user_habits/alim_004/attempts/attempt-1")
    .calendarTimeZone = "America/Monterrey";
  await assert.rejects(registerDemoHabit({db, ...multiArgs(
    "alim_004", "conflict_0001",
  )}), RegistrationPolicyError);
  assert.equal(db.docs.get("users/alice").xp, 0);
});


test("rechaza UTC implícito si el perfil ya tiene calendario local", async () => {
  const db = seededMultiDb("alim_004");
  db.docs.get("users/alice").calendarTimeZone = "America/Monterrey";
  await assert.rejects(registerDemoHabit({db, ...multiArgs(
    "alim_004", "implicit_utc_0001",
  )}), RegistrationPolicyError);
  assert.equal(db.docs.get("users/alice").xp, 0);
});
