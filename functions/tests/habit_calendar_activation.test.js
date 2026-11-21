"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {lockDemoHabitCalendar, validateCalendarLockRequest} =
  require("../habit_calendar_activation");
const {RegistrationPolicyError} =
  require("../habit_registration_policy");

class Ref {
  constructor(db, path) { this.db = db; this.path = path; }
  collection(name) { return new Ref(this.db, this.path + "/" + name); }
  doc(name) { return new Ref(this.db, this.path + "/" + name); }
}
class FakeDb {
  constructor(habitId = "bien_007") {
    const {SERVER_CATALOG} = require("../official_habit_catalog");
    const catalog = SERVER_CATALOG[habitId];
    const base = "users/alice/user_habits/" + habitId;
    this.docs = new Map([
      ["users/alice", {}],
      [base, {latestAttemptId: "attempt-1",
        latestStatus: "inProgress", frequencyType: catalog.frequencyType}],
      [base + "/attempts/attempt-1", {
        status: "inProgress", progress: 0, target: catalog.target,
        xpEarned: 0, frequencyType: catalog.frequencyType,
        registrationsPerPeriod: catalog.registrationsPerPeriod,
      }],
    ]);
  }
  collection(name) { return new Ref(this, name); }
  async runTransaction(fn) {
    const writes = [];
    const tx = {
      get: async (ref) => ({
        exists: this.docs.has(ref.path),
        data: () => this.docs.get(ref.path),
      }),
      update: (ref, data) => writes.push([ref.path, data]),
    };
    const result = await fn(tx);
    for (const [path, data] of writes) {
      this.docs.set(path, {...this.docs.get(path), ...data});
    }
    return result;
  }
}
function request(habitId = "bien_007", timeZone = "America/Monterrey") {
  return {db: new FakeDb(habitId), uid: "alice", data: {
    habitId, attemptId: "attempt-1", timeZone,
  }};
}

test("se fija la misma zona en perfil, hábito e intento de forma atómica", async () => {
  const args = request();
  const first = await lockDemoHabitCalendar(args);
  assert.equal(first.alreadyConfigured, false);
  for (const p of ["users/alice", "users/alice/user_habits/bien_007",
    "users/alice/user_habits/bien_007/attempts/attempt-1"]) {
    assert.equal(args.db.docs.get(p).calendarTimeZone, "America/Monterrey");
  }
  const retry = await lockDemoHabitCalendar(args);
  assert.equal(retry.alreadyConfigured, true);
});

test("rechaza una zona distinta después de fijar el calendario", async () => {
  const args = request();
  await lockDemoHabitCalendar(args);
  await assert.rejects(lockDemoHabitCalendar({
    ...args, data: {...args.data, timeZone: "UTC"},
  }), RegistrationPolicyError);
  assert.equal(args.db.docs.get("users/alice").calendarTimeZone,
    "America/Monterrey");
});

test("no migra progreso, XP ni rachas anteriores", async () => {
  for (const changes of [{progress: 1}, {xpEarned: 10},
    {periodStreak: 2}, {lastCompletedPeriod: "day_2026-11-20"}]) {
    const args = request();
    const ref = "users/alice/user_habits/bien_007/attempts/attempt-1";
    Object.assign(args.db.docs.get(ref), changes);
    await assert.rejects(lockDemoHabitCalendar(args),
      RegistrationPolicyError);
    assert.equal(args.db.docs.get("users/alice").calendarTimeZone, undefined);
  }
});

test("no acepta rutas arbitrarias ni cambios de hidr_001", () => {
  for (const data of [
    {habitId: "hidr_001", attemptId: "attempt-1", timeZone: "UTC"},
    {habitId: "bien_007", attemptId: "attempt-1", timeZone: "Mars/Olympus"},
    {habitId: "bien_007", attemptId: "../users", timeZone: "UTC"},
    {habitId: "bien_007", attemptId: "attempt-1",
      timeZone: "UTC", xpAwarded: 100},
  ]) {
    assert.throws(() => validateCalendarLockRequest(data),
      RegistrationPolicyError);
  }
});

test("no concede XP, monedas ni registros al fijar el calendario", async () => {
  const args = request("alim_004", "America/Monterrey");
  await lockDemoHabitCalendar(args);
  const attempt = args.db.docs.get(
    "users/alice/user_habits/alim_004/attempts/attempt-1"
  );
  assert.equal(attempt.progress, 0);
  assert.equal(attempt.xpEarned, 0);
  assert.equal(args.db.docs.size, 3);
});
