"use strict";

// Calendario de prueba en el servidor. La zona se fija por intento;
// nunca se acepta como dato de una solicitud de registro.
class HabitCalendarError extends Error {
  constructor(message) {
    super(message);
    this.name = "HabitCalendarError";
  }
}

function validateTimeZone(zone) {
  if (typeof zone !== "string" || zone.length > 64 ||
      !/^[A-Za-z0-9_+/-]+$/.test(zone)) {
    throw new HabitCalendarError("Zona horaria inválida.");
  }
  try {
    new Intl.DateTimeFormat("en-US", {timeZone: zone}).format(0);
  } catch (_) {
    throw new HabitCalendarError("Zona horaria no reconocida.");
  }
  return zone;
}

function localDay(date, zone) {
  if (!(date instanceof Date) || !Number.isFinite(date.getTime())) {
    throw new HabitCalendarError("Fecha inválida.");
  }
  validateTimeZone(zone);
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: zone, year: "numeric", month: "2-digit",
    day: "2-digit", calendar: "gregory",
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map(({type, value}) => [type, value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function periodKeyForZone(date, frequency, zone) {
  const day = localDay(date, zone);
  if (frequency === "daily") return `day_${day}`;
  if (frequency === "weekly") {
    const monday = new Date(`${day}T00:00:00.000Z`);
    const offset = (monday.getUTCDay() + 6) % 7;
    monday.setUTCDate(monday.getUTCDate() - offset);
    return `week_${monday.toISOString().slice(0, 10)}`;
  }
  throw new HabitCalendarError("Frecuencia inválida.");
}

function dateIndex(day) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    throw new HabitCalendarError("Fecha de periodo inválida.");
  }
  const timestamp = Date.parse(`${day}T00:00:00.000Z`);
  if (!Number.isFinite(timestamp) ||
      new Date(timestamp).toISOString().slice(0, 10) !== day) {
    throw new HabitCalendarError("Fecha de periodo imposible.");
  }
  return Math.floor(timestamp / 86400000);
}

function completedPeriodStreak({
  previousKey = null, currentKey, frequency,
  previousStreak = 0, gracePeriods = 0,
}) {
  if (!["daily", "weekly"].includes(frequency) ||
      !Number.isSafeInteger(previousStreak) || previousStreak < 0 ||
      !Number.isSafeInteger(gracePeriods) || gracePeriods < 0 ||
      gracePeriods > 30) {
    throw new HabitCalendarError("Configuración de racha inválida.");
  }
  const prefix = frequency === "daily" ? "day_" : "week_";
  if (typeof currentKey !== "string" || !currentKey.startsWith(prefix)) {
    throw new HabitCalendarError("Periodo actual inválido.");
  }
  const currentIndex = dateIndex(currentKey.slice(prefix.length));
  if (previousKey === null) {
    return {streak: 1, missedPeriods: 0, graceApplied: 0};
  }
  if (typeof previousKey !== "string" || !previousKey.startsWith(prefix)) {
    throw new HabitCalendarError("Periodo anterior inválido.");
  }
  const previousIndex = dateIndex(previousKey.slice(prefix.length));
  const elapsed = currentIndex - previousIndex;
  const unit = frequency === "daily" ? 1 : 7;
  if (elapsed <= 0 || elapsed % unit !== 0) {
    throw new HabitCalendarError("Orden de periodos inválido.");
  }
  const missedPeriods = elapsed / unit - 1;
  const graceApplied = Math.min(missedPeriods, gracePeriods);
  return {
    streak: missedPeriods <= gracePeriods ? previousStreak + 1 : 1,
    missedPeriods,
    graceApplied,
  };
}

module.exports = {
  validateTimeZone, localDay, periodKeyForZone,
  completedPeriodStreak, HabitCalendarError,
};
