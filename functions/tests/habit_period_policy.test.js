"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  utcPeriodKey, checkPeriodRegistration, HabitPeriodError,
} = require("../habit_period_policy");
const {SERVER_CATALOG} = require("../official_habit_catalog");

test("el periodo diario cambia a medianoche UTC", () => {
  assert.equal(
    utcPeriodKey(new Date("2026-11-21T23:59:59Z"), "daily"),
    "day_2026-11-21"
  );
  assert.equal(
    utcPeriodKey(new Date("2026-11-22T00:00:00Z"), "daily"),
    "day_2026-11-22"
  );
});

test("la semana UTC comienza el lunes incluso al cambiar de año", () => {
  assert.equal(
    utcPeriodKey(new Date("2027-01-01T09:00:00Z"), "weekly"),
    "week_2026-12-28"
  );
  assert.equal(
    utcPeriodKey(new Date("2027-01-03T23:59:00Z"), "weekly"),
    "week_2026-12-28"
  );
  assert.equal(
    utcPeriodKey(new Date("2027-01-04T00:00:00Z"), "weekly"),
    "week_2027-01-04"
  );
});

test("un hábito diario de dos registros admite dos, pero no tres", () => {
  const habit = SERVER_CATALOG.bien_007;
  assert.equal(habit.registrationsPerPeriod, 2);
  assert.deepEqual(checkPeriodRegistration({
    catalog: habit, currentCount: 1, progress: 4,
  }), {
    periodLimit: 2, periodCountAfter: 2,
    progressAfter: 5, completed: false,
  });
  assert.throws(() => checkPeriodRegistration({
    catalog: habit, currentCount: 2, progress: 4,
  }), HabitPeriodError);
});

test("un hábito semanal usa su límite real del catálogo", () => {
  const habit = SERVER_CATALOG.alim_004;
  assert.equal(habit.frequencyType, "weekly");
  assert.equal(habit.registrationsPerPeriod, 3);
  assert.equal(checkPeriodRegistration({
    catalog: habit, currentCount: 2, progress: 11,
  }).completed, true);
  assert.throws(() => checkPeriodRegistration({
    catalog: habit, currentCount: 3, progress: 11,
  }), HabitPeriodError);
});

test("rechaza frecuencias, conteos y fechas inválidos", () => {
  assert.throws(() => utcPeriodKey(new Date("invalid"), "daily"),
    HabitPeriodError);
  assert.throws(() => utcPeriodKey(new Date(), "monthly"), HabitPeriodError);
  assert.throws(() => checkPeriodRegistration({
    catalog: SERVER_CATALOG.alim_001,
    currentCount: -1, progress: 0,
  }), HabitPeriodError);
  assert.throws(() => checkPeriodRegistration({
    catalog: SERVER_CATALOG.alim_001,
    currentCount: 0, progress: 7,
  }), HabitPeriodError);
});
