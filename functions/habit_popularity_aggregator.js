"use strict";

// Función pura para preparar métricas de uso del catálogo oficial.
// La agregación solo admite documentos usuarios/{uid}/user_habits/{habitId}.
const HABIT_ID_PATTERN = /^(?:alim|hidr|ener|bien)_[0-9]{3}$/;
const MIN_PUBLIC_USERS = 5;

function parseHabitPath(path) {
  if (typeof path !== "string") return null;
  const parts = path.split("/");
  if (parts.length !== 4 || parts[0] !== "users" ||
      parts[2] !== "user_habits" || !parts[1] ||
      !HABIT_ID_PATTERN.test(parts[3])) return null;
  return {uid: parts[1], habitId: parts[3]};
}

function aggregateActiveHabits(documents, minUsers = MIN_PUBLIC_USERS) {
  if (!Number.isSafeInteger(minUsers) || minUsers < 2) {
    throw new TypeError("Umbral público inválido.");
  }
  const perHabit = new Map();
  for (const doc of documents) {
    const path = parseHabitPath(doc.path);
    if (!path) continue;
    if (doc.data?.latestStatus !== "inProgress") continue;
    let users = perHabit.get(path.habitId);
    if (!users) {
      users = new Set();
      perHabit.set(path.habitId, users);
    }
    users.add(path.uid);
  }
  return [...perHabit.entries()]
    .map(([habitId, users]) => ({habitId, activeUsers: users.size}))
    .filter((entry) => entry.activeUsers >= minUsers)
    .sort((a, b) =>
      b.activeUsers - a.activeUsers || a.habitId.localeCompare(b.habitId));
}

module.exports = {
  parseHabitPath,
  aggregateActiveHabits,
  MIN_PUBLIC_USERS,
};
