"use strict";

// Política determinista UTC para el piloto. No debe sustituir todavía
// la semántica de fecha local de Flutter ni habilitar registros reales.
class HabitPeriodError extends Error {
  constructor(message) {
    super(message);
    this.name = "HabitPeriodError";
  }
}

function utcPeriodKey(date, frequencyType) {
  if (!(date instanceof Date) || !Number.isFinite(date.getTime())) {
    throw new HabitPeriodError("Fecha UTC inválida.");
  }
  const day = date.toISOString().slice(0, 10);
  if (frequencyType === "daily") return `day_${day}`;
  if (frequencyType === "weekly") {
    // Semana ISO: lunes 00:00 UTC, sin dependencia de locale.
    const monday = new Date(`${day}T00:00:00.000Z`);
    const weekday = (monday.getUTCDay() + 6) % 7;
    monday.setUTCDate(monday.getUTCDate() - weekday);
    return `week_${monday.toISOString().slice(0, 10)}`;
  }
  throw new HabitPeriodError("Frecuencia no compatible.");
}

function checkPeriodRegistration({catalog, currentCount, progress}) {
  if (!catalog ||
      !["daily", "weekly"].includes(catalog.frequencyType) ||
      !Number.isSafeInteger(catalog.registrationsPerPeriod) ||
      catalog.registrationsPerPeriod < 1 ||
      !Number.isSafeInteger(catalog.target) || catalog.target < 1 ||
      !Number.isSafeInteger(currentCount) || currentCount < 0 ||
      !Number.isSafeInteger(progress) || progress < 0 ||
      progress >= catalog.target) {
    throw new HabitPeriodError("Datos del periodo inválidos.");
  }
  if (currentCount >= catalog.registrationsPerPeriod) {
    throw new HabitPeriodError("Ya alcanzaste el límite de este periodo.");
  }
  return Object.freeze({
    periodLimit: catalog.registrationsPerPeriod,
    periodCountAfter: currentCount + 1,
    progressAfter: progress + 1,
    completed: progress + 1 === catalog.target,
  });
}

module.exports = {utcPeriodKey, checkPeriodRegistration, HabitPeriodError};
