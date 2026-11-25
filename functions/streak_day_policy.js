"use strict";

// La racha diaria solo avanza por registros validados en el servidor.
// No se toman como prueba los campos de racha que escribe Flutter.
const {localDay} = require("./habit_calendar_policy");

function dateNumber(day) {
  if (typeof day !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    throw new TypeError("Día de racha inválido.");
  }
  const n = Date.parse(day + "T00:00:00Z");
  if (!Number.isFinite(n) || new Date(n).toISOString().slice(0, 10) !== day) {
    throw new TypeError("Fecha de racha imposible.");
  }
  return Math.floor(n / 86400000);
}

function rewardCoins(streak) {
  if (!Number.isSafeInteger(streak) || streak < 1) {
    throw new TypeError("Racha inválida.");
  }
  // Una recompensa diaria por fecha verificada; techo de 200 monedas.
  if (streak >= 180) return 200;
  if (streak >= 120) return 175;
  if (streak >= 90) return 150;
  if (streak >= 60) return 125;
  if (streak >= 45) return 100;
  if (streak >= 30) return 80;
  if (streak >= 21) return 60;
  if (streak >= 14) return 45;
  if (streak >= 7) return 30;
  if (streak >= 4) return 20;
  if (streak >= 2) return 15;
  return 10;
}

// Solo compatibilidad con premios YA emitidos antes del nuevo balance.
// No debe utilizarse para crear días nuevos.
function legacyRewardCoins(streak) {
  if (!Number.isSafeInteger(streak) || streak < 1) {
    throw new TypeError("Racha inválida.");
  }
  if (streak >= 7) return 5;
  if (streak >= 4) return 4;
  if (streak >= 2) return 3;
  return 2;
}

function planVerifiedDay({previousDay = null, previousStreak = 0,
  previousBest = 0, now, timeZone = "UTC"}) {
  const day = localDay(now, timeZone);
  if (!Number.isSafeInteger(previousStreak) || previousStreak < 0 ||
      !Number.isSafeInteger(previousBest) || previousBest < 0) {
    throw new TypeError("Historial inválido.");
  }
  const elapsed = previousDay == null
    ? null : dateNumber(day) - dateNumber(previousDay);
  if (elapsed !== null && elapsed < 0) {
    throw new TypeError("La fecha no puede retroceder.");
  }
  if (elapsed === 0) {
    return {day, streak: Math.max(previousStreak, 1),
      best: Math.max(previousBest, previousStreak, 1),
      rewardCoins: rewardCoins(Math.max(previousStreak, 1)),
      isNewDay: false};
  }
  const streak = elapsed === 1 ? previousStreak + 1 : 1;
  return {day, streak, best: Math.max(previousBest, streak),
    rewardCoins: rewardCoins(streak), isNewDay: true};
}

module.exports = {rewardCoins, legacyRewardCoins, planVerifiedDay};
