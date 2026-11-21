"use strict";

const {before, after, test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {initializeTestEnvironment, assertSucceeds, assertFails} =
  require("@firebase/rules-unit-testing");
const {doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp} =
  require("firebase/firestore");

let env, alice, bob, guest;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-healthy-habit-strict",
    firestore: {
      host: "127.0.0.1", port: 8080,
      rules: fs.readFileSync(path.resolve(__dirname,
        "../../firestore.strict-habits.rules"), "utf8"),
    },
  });
  alice = env.authenticatedContext("strict-alice").firestore();
  bob = env.authenticatedContext("strict-bob").firestore();
  guest = env.unauthenticatedContext().firestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "users/strict-alice"), {
      uid: "strict-alice", name: "Alice", username: "alice",
      email: "alice@example.test", xp: 100, currentXp: 100,
      habitCoins: 250, level: 2, currentStreak: 3,
      habitSlots: 3, habitMutationVersion: 1,
      calendarTimeZone: "America/Monterrey",
      shopInventory: ["crown"], shopEquipped: {},
    });
    await setDoc(doc(db,
      "users/strict-alice/user_habits/alim_004"), {
      latestStatus: "inProgress", lastStatus: "inProgress",
      latestAttemptId: "attempt_0000000001",
    });
    await setDoc(doc(db,
      "users/strict-alice/user_habits/alim_004/attempts/attempt_0000000001"), {
      status: "inProgress", progress: 1, xpEarned: 10,
      calendarTimeZone: "America/Monterrey",
    });
    await setDoc(doc(db,
      "users/strict-alice/user_habits/alim_004/attempts/attempt_0000000001/logs/reg_001"), {
      xpEarned: 10,
    });
    await setDoc(doc(db, "public_profiles/strict-alice"), {
      name: "Alice", username: "alice", xp: 100, currentXp: 100,
      level: 2, currentStreak: 3, streakDays: 3,
      completedHabits: 2,
      settings: {mostrarRachaAmigos: true, visibilidadLogros: "Todos"},
    });
    await setDoc(doc(db, "users/strict-bob"), {
      name: "Bob", xp: 40, habitCoins: 30,
    });
  });
});

after(async () => { await env?.cleanup(); });

test("el propietario lee hábitos e intentos y terceros no", async () => {
  const ref = "users/strict-alice/user_habits/alim_004/attempts/attempt_0000000001";
  await assertSucceeds(getDoc(doc(alice, ref)));
  await assertFails(getDoc(doc(bob, ref)));
  await assertFails(getDoc(doc(guest, ref)));
});

test("el cliente no crea ni modifica hábitos, intentos o registros", async () => {
  const root = "users/strict-alice/user_habits/";
  await assertFails(setDoc(doc(alice, root + "hidr_001"), {
    title: "Falsificación",
  }));
  await assertFails(updateDoc(doc(alice, root + "alim_004"), {
    latestStatus: "completed",
  }));
  const attempt = root + "alim_004/attempts/attempt_0000000001";
  await assertFails(updateDoc(doc(alice, attempt), {
    progress: 42, xpEarned: 9999,
  }));
  await assertFails(setDoc(doc(alice, attempt + "/logs/forged"), {
    xpEarned: 999,
  }));
  await assertFails(deleteDoc(doc(alice, attempt)));
});

test("el cliente no puede modificar XP, monedas, racha ni calendario privado", async () => {
  for (const fields of [
    {xp: 100000}, {habitCoins: 999999}, {currentXp: 999},
    {level: 19}, {currentStreak: 300}, {streakDays: 100},
    {calendarTimeZone: "UTC"}, {habitSlots: 100},
    {habitMutationVersion: 100}, {shopInventory: ["crown", "cape"]},
  ]) await assertFails(updateDoc(doc(alice, "users/strict-alice"), fields));
  await assertFails(deleteDoc(doc(alice, "users/strict-alice")));
});

test("los cambios de nombre siguen permitidos sin modificar economía", async () => {
  await assertSucceeds(updateDoc(doc(alice, "users/strict-alice"), {
    name: "Nuevo nombre",
  }));
  await assertSucceeds(getDoc(doc(alice, "users/strict-alice")));
  await assertFails(updateDoc(doc(bob, "users/strict-alice"), {
    name: "Atacante",
  }));
});

test("equipar un artículo adquirido no altera el saldo", async () => {
  await assertSucceeds(updateDoc(doc(alice, "users/strict-alice"), {
    shopEquipped: {cabeza: "crown"},
  }));
  await assertFails(updateDoc(doc(alice, "users/strict-alice"), {
    shopEquipped: {cabeza: "cap"},
  }));
});

test("los perfiles públicos no aceptan XP ni rachas falsificadas", async () => {
  const ref = doc(alice, "public_profiles/strict-alice");
  await assertSucceeds(getDoc(doc(bob, "public_profiles/strict-alice")));
  for (const fields of [
    {xp: 100000}, {currentXp: 999}, {level: 20},
    {currentStreak: 100}, {streakDays: 100},
    {completedHabits: 100},
  ]) await assertFails(updateDoc(ref, fields));
  await assertSucceeds(updateDoc(ref, {bio: "Mi perfil actualizado"}));
  await assertFails(deleteDoc(ref));
});

test("un perfil público nuevo no puede autoconcederse progreso", async () => {
  const client = env.authenticatedContext("strict-new").firestore();
  const ref = doc(client, "public_profiles/strict-new");
  const profile = {
    name: "New", username: "new", xp: 0,
    settings: {mostrarRachaAmigos: true, visibilidadLogros: "Todos"},
  };
  await assertFails(setDoc(ref, {...profile, xp: 9999}));
  await assertFails(setDoc(ref, {...profile, nextLevelXp: 999999}));
  await assertFails(setDoc(ref, {...profile, nextAchievementProgress: 999}));
  await assertSucceeds(setDoc(ref, profile));
});

test("el cliente no puede crear operaciones de Admin SDK", async () => {
  await assertFails(setDoc(doc(alice,
    "users/strict-alice/habit_activation_operations/operation_00001"), {
    habitId: "alim_004",
  }));
  await assertFails(setDoc(doc(alice,
    "users/strict-alice/habit_cancellation_operations/operation_00001"), {
    habitId: "alim_004",
  }));
  await assertFails(setDoc(doc(alice,
    "users/strict-alice/registration_operations/operation_00001"), {
    habitId: "alim_004",
  }));
});

test("el perfil inicial legítimo conserva XP cero y monedas iniciales", async () => {
  const client = env.authenticatedContext("strict-signup").firestore();
  const ref = doc(client, "users/strict-signup");
  const profile = {
    uid: "strict-signup", name: "Nuevo", username: "newbie",
    email: "signup@example.test", level: 1, xp: 0,
    habitCoins: 100, currentStreak: 0, createdAt: serverTimestamp(),
  };
  await assertSucceeds(setDoc(ref, profile));
  await assertFails(updateDoc(ref, {xp: 999}));
});
