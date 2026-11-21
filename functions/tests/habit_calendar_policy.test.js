"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  validateTimeZone, localDay, periodKeyForZone,
  completedPeriodStreak, HabitCalendarError,
} = require("../habit_calendar_policy");

test("una misma hora UTC cae en días diferentes según la zona", () => {
  const instant = new Date("2026-11-22T02:00:00.000Z");
  assert.equal(localDay(instant, "America/Monterrey"), "2026-11-21");
  assert.equal(localDay(instant, "UTC"), "2026-11-22");
  assert.equal(periodKeyForZone(instant, "daily", "America/Monterrey"),
    "day_2026-11-21");
});

test("la semana local cruza la medianoche sin adelantar el lunes", () => {
  const instant = new Date("2026-11-23T03:00:00Z");
  assert.equal(periodKeyForZone(instant, "weekly", "America/Monterrey"),
    "week_2026-11-16");
  assert.equal(periodKeyForZone(instant, "weekly", "UTC"),
    "week_2026-11-23");
});

test("los cambios de horario de verano no alteran la fecha civil", () => {
  assert.equal(localDay(new Date("2026-03-08T09:59:00Z"),
    "America/Los_Angeles"), "2026-03-08");
  assert.equal(localDay(new Date("2026-03-08T10:01:00Z"),
    "America/Los_Angeles"), "2026-03-08");
});

test("las zonas desconocidas se rechazan sin usar zona del dispositivo", () => {
  assert.equal(validateTimeZone("America/Monterrey"), "America/Monterrey");
  for (const zone of ["../UTC", "", "Mars/Olympus", 123, null]) {
    assert.throws(() => validateTimeZone(zone), HabitCalendarError);
  }
});

test("dos registros diarios forman una sola racha cuando se completa el cupo", () => {
  assert.deepEqual(completedPeriodStreak({
    currentKey: "day_2026-11-21", frequency: "daily",
  }), {streak: 1, missedPeriods: 0, graceApplied: 0});
  assert.deepEqual(completedPeriodStreak({
    previousKey: "day_2026-11-21", currentKey: "day_2026-11-22",
    frequency: "daily", previousStreak: 1,
  }), {streak: 2, missedPeriods: 0, graceApplied: 0});
});

test("un periodo de gracia conserva una racha pero no concede recompensas", () => {
  assert.deepEqual(completedPeriodStreak({
    previousKey: "day_2026-11-19", currentKey: "day_2026-11-21",
    frequency: "daily", previousStreak: 4, gracePeriods: 1,
  }), {streak: 5, missedPeriods: 1, graceApplied: 1});
  assert.deepEqual(completedPeriodStreak({
    previousKey: "day_2026-11-18", currentKey: "day_2026-11-21",
    frequency: "daily", previousStreak: 4, gracePeriods: 1,
  }), {streak: 1, missedPeriods: 2, graceApplied: 1});
});

test("las rachas semanales usan semanas ISO, incluso al cruzar el año", () => {
  assert.deepEqual(completedPeriodStreak({
    previousKey: "week_2026-12-21", currentKey: "week_2027-01-04",
    frequency: "weekly", previousStreak: 2, gracePeriods: 1,
  }), {streak: 3, missedPeriods: 1, graceApplied: 1});
});

test("no se puede avanzar dos veces la racha del mismo periodo", () => {
  assert.throws(() => completedPeriodStreak({
    previousKey: "day_2026-11-21", currentKey: "day_2026-11-21",
    frequency: "daily", previousStreak: 2,
  }), HabitCalendarError);
  assert.throws(() => completedPeriodStreak({
    previousKey: "week_2026-11-21", currentKey: "week_2026-11-23",
    frequency: "weekly",
  }), HabitCalendarError);
});
