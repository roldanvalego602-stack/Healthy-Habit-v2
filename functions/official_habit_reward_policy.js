"use strict";

// Política pura y sin permisos de escritura. Base de la futura migración
// a transacciones de servidor: NO es una Cloud Function desplegable.
// Las recompensas se calculan sólo con catálogo oficial y estado persistido.
const {SERVER_CATALOG} = require("./official_habit_catalog");
const {LEVELS, levelForXp} = require("./habit_registration_transaction");
const {RegistrationPolicyError} = require("./habit_registration_policy");
const {checkPeriodRegistration} = require("./habit_period_policy");

const ID = /^[A-Za-z0-9_-]{1,128}$/;
const OPERATION_ID = /^[A-Za-z0-9_-]{16,128}$/;

function requireNonNegativeInt(value, field) {
  if (!Number.isSafeInteger(value) || value < 0 || value > 1000000000) {
    throw new RegistrationPolicyError(
      "failed-precondition", `Valor inválido de ${field}.`
    );
  }
  return value;
}

function parseOfficialRegistration(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new RegistrationPolicyError("invalid-argument", "Solicitud inválida.");
  }
  const allowed = ["habitId", "attemptId", "operationId", "note"];
  if (Object.keys(data).some((field) => !allowed.includes(field)) ||
      typeof data.habitId !== "string" ||
      !Object.hasOwn(SERVER_CATALOG, data.habitId) ||
      typeof data.attemptId !== "string" || !ID.test(data.attemptId) ||
      typeof data.operationId !== "string" ||
      !OPERATION_ID.test(data.operationId)) {
    throw new RegistrationPolicyError(
      "invalid-argument", "Hábito, IDs o campos no permitidos."
    );
  }
  // Texto opcional no económico: sin HTML, imágenes ni recompensas.
  // Los valores se conservan tal como fueron confirmados por el usuario.
  if (data.note !== undefined &&
      (typeof data.note !== "string" || data.note.length > 500 ||
       /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/.test(data.note))) {
    throw new RegistrationPolicyError(
      "invalid-argument", "La nota debe ser texto de hasta 500 caracteres."
    );
  }
  return Object.freeze({
    habitId: data.habitId,
    attemptId: data.attemptId,
    operationId: data.operationId,
    note: data.note ?? "",
  });
}

function planOfficialReward({data, user, attempt, periodCount = 0}) {
  const request = parseOfficialRegistration(data);
  const catalog = SERVER_CATALOG[request.habitId];

  if (!user || !attempt ||
      attempt.habitId !== request.habitId ||
      attempt.status !== "inProgress") {
    throw new RegistrationPolicyError(
      "failed-precondition", "Intento oficial inexistente o inactivo."
    );
  }

  const beforeXp = requireNonNegativeInt(
    user.xp ?? user.currentXp ?? 0, "xp"
  );
  const beforeCoins = requireNonNegativeInt(
    user.habitCoins ?? 0, "habitCoins"
  );
  const earnedXp = requireNonNegativeInt(
    attempt.xpEarned ?? 0, "xpEarned"
  );
  const progress = requireNonNegativeInt(
    attempt.progress ?? 0, "progress"
  );
  const target = requireNonNegativeInt(attempt.target, "target");
  if (target !== catalog.target ||
      attempt.frequencyType !== catalog.frequencyType ||
      attempt.registrationsPerPeriod !== catalog.registrationsPerPeriod) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Intento no coincide con catálogo oficial."
    );
  }

  // El límite por día/semana se controla en una transacción que lea el
  // contador persistido. La política pura NO aplica antirrepetición sola.
  const period = checkPeriodRegistration({
    catalog, currentCount: periodCount, progress,
  });
  const xpAwarded = catalog.xp;
  const newXp = beforeXp + xpAwarded;
  if (newXp > 1000000000) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Límite de XP excedido."
    );
  }
  const beforeLevel = levelForXp(beforeXp);
  const level = levelForXp(newXp);
  const claimedLevels = user.claimedLevelRewards ?? [];
  if (!Array.isArray(claimedLevels) ||
      claimedLevels.some((n) =>
        !Number.isSafeInteger(n) || n < 2 || n > LEVELS.length) ||
      new Set(claimedLevels).size !== claimedLevels.length) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Recompensas previas inválidas."
    );
  }

  const claimed = new Set(claimedLevels);
  let coinsAwarded = 0;
  for (let n = beforeLevel + 1; n <= level; n++) {
    if (!claimed.has(n)) {
      claimed.add(n);
      coinsAwarded += LEVELS[n - 1][1];
    }
  }
  const coins = beforeCoins + coinsAwarded;
  if (coins > 1000000000) {
    throw new RegistrationPolicyError(
      "failed-precondition", "Límite de monedas excedido."
    );
  }

  return Object.freeze({
    habitId: request.habitId,
    attemptId: request.attemptId,
    operationId: request.operationId,
    xpAwarded,
    xp: newXp,
    attemptXp: earnedXp + xpAwarded,
    level,
    coinsAwarded,
    coins,
    claimedLevelRewards: [...claimed].sort((a, b) => a - b),
    progress: period.progressAfter,
    completed: period.completed,
    periodCount: period.periodCountAfter,
  });
}

module.exports = {
  parseOfficialRegistration,
  planOfficialReward,
};
