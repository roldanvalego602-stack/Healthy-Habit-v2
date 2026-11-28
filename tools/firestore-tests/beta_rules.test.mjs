// Seguridad real de beta: pruebas positivas y adversariales del mismo
// archivo listo para revisión de despliegue, sin tocar Firebase real.
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {before, beforeEach, after, test} from 'node:test';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp} from 'firebase/firestore';

const PROJECT = 'demo-healthy-habit';
const rules = readFileSync(resolve(
  new URL('../../firestore.beta.rules', import.meta.url).pathname), 'utf8');
let env;
const as = (uid) => env.authenticatedContext(uid).firestore();
const ref = (db, path) => doc(db, path);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: {host: '127.0.0.1', port: 8080, rules},
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => {if (env) await env.cleanup();});

async function seed(uid = 'alice') {
  await env.withSecurityRulesDisabled(async (admin) => {
    await setDoc(ref(admin.firestore(), 'users/' + uid), {
      uid, name: 'Alice', username: 'alice', email: '',
      xp: 0, currentXp: 0, level: 1,
      habitCoins: 120, currentStreak: 0, streakDays: 0,
      shopInventory: [], shopEquipped: {},
    });
  });
}

test('beta: nadie lee los datos privados de otro UID', async () => {
  await seed();
  await assertSucceeds(getDoc(ref(as('alice'), 'users/alice')));
  await assertFails(getDoc(ref(as('bob'), 'users/alice')));
  await assertFails(updateDoc(ref(as('bob'), 'users/alice'), {name: 'Otra'}));
  await assertFails(deleteDoc(ref(as('alice'), 'users/alice')));
  await assertFails(getDoc(ref(env.unauthenticatedContext().firestore(),
    'users/alice')));
});

test('beta: una cuenta nueva solo recibe estado inicial predefinido', async () => {
  const db = as('fresh');
  await assertSucceeds(setDoc(ref(db, 'users/fresh'), {
    uid: 'fresh', name: 'Nuevo', username: 'nuevo', email: '',
    xp: 0, level: 1, habitCoins: 100, currentStreak: 0,
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(ref(db, 'users/hacker'), {
    uid: 'hacker', name: 'Intruso', username: 'intruso', email: '',
    xp: 0, level: 1, habitCoins: 100, currentStreak: 0,
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(ref(as('rich'), 'users/rich'), {
    uid: 'rich', name: 'Adulterado', username: 'rich', email: '',
    xp: 999, level: 99, habitCoins: 100000,
    currentStreak: 9, createdAt: serverTimestamp(),
  }));
});

test('beta: editar datos inocuos no permite alterar XP, monedas o inventario', async () => {
  await seed();
  const db = as('alice');
  await assertSucceeds(updateDoc(ref(db, 'users/alice'), {
    name: 'Nombre actualizado', bio: 'Mi bio',
    settings: {mostrarRachaAmigos: false},
  }));
  for (const forged of [
    {xp: 1}, {level: 5}, {habitCoins: 121}, {currentStreak: 10},
    {shopInventory: ['ufo_gold']}, {shopEquipped: {ufo_skin: 'ufo_gold'}},
    {profileTitle: 'Campeón de temporada'},
    {habitMutationVersion: 900}, {completedHabits: 100},
    {serverStreakDays: 100}, {dailyRewardClaimed: true},
  ]) {
    await assertFails(updateDoc(ref(db, 'users/alice'), forged));
  }
});

test('beta: estadísticas públicas no se falsifican, aunque el UID sea propio', async () => {
  await seed();
  const db = as('alice');
  const published = {
    name: 'Alice', username: 'alice', xp: 0, currentXp: 0,
    level: 1, completedHabits: 0, nextLevelXp: 1000,
    currentStreak: 0, streakDays: 0, nextAchievementProgress: 0,
    nextAchievementTitle: '', settings: {},
    healthyEquipped: {}, profileBanner: 'Amanecer',
  };
  await assertSucceeds(setDoc(ref(db, 'public_profiles/alice'), published));
  await assertFails(updateDoc(ref(db, 'public_profiles/alice'), {
    level: 99, currentXp: 9999,
  }));
  await assertFails(updateDoc(ref(db, 'public_profiles/alice'), {
    completedHabits: 999,
  }));
  await assertFails(updateDoc(ref(as('bob'), 'public_profiles/alice'),
    {name: 'suplantación'}));
});

test('beta: registros, logros y constancias requieren Admin SDK', async () => {
  await seed();
  const db = as('alice');
  for (const path of [
    'users/alice/user_habits/hidr_001',
    'users/alice/user_habits/hidr_001/attempts/falso',
    'users/alice/achievements/leyenda',
    'users/alice/daily_streak_days/2026-11-27',
    'users/alice/shop_purchase_operations/operation123456789',
    'users/alice/registration_operations/operation123456789',
    'system/challenge_attestations/users/alice/challenges/bonus',
  ]) {
    await assertFails(setDoc(ref(db, path), {
      status: 'completed', xpEarned: 9000, verified: true,
    }));
  }
  await assertFails(getDoc(ref(db,
    'system/challenge_attestations/users/alice/challenges/bonus')));
});

test('beta: colección system es privada salvo el catálogo público explícito', async () => {
  await env.withSecurityRulesDisabled(async (admin) => {
    await setDoc(ref(admin.firestore(), 'system/catalog'), {version: 1});
    await setDoc(ref(admin.firestore(), 'system/internal_secrets'),
      {token: 'NUNCA'});
  });
  await assertSucceeds(getDoc(ref(as('alice'), 'system/catalog')));
  await assertFails(getDoc(ref(as('alice'), 'system/internal_secrets')));
  await assertFails(updateDoc(ref(as('alice'), 'system/catalog'),
    {version: 999}));
  await assertFails(getDoc(ref(env.unauthenticatedContext().firestore(),
    'system/catalog')));
});

test('beta: conversaciones propias privadas y editables sin abrir otros datos', async () => {
  await seed();
  const session = 'users/alice/healthy_chats/session1';
  const message = session + '/messages/message1';
  await assertSucceeds(setDoc(ref(as('alice'), session), {
    title: 'Mi chat', updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(setDoc(ref(as('alice'), message), {
    text: 'Hola', isUser: true, createdAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(ref(as('alice'), message)));
  await assertFails(getDoc(ref(as('bob'), message)));
  await assertFails(deleteDoc(ref(as('bob'), session)));
});

test('beta: nadie crea evidencias verificadas ni imágenes temporales arbitrarias', async () => {
  await seed();
  const db = as('alice');
  await assertFails(setDoc(ref(db,
    'users/alice/temporary_habit_evidence/image1'), {
    userId: 'alice', imageBase64: 'AAA', expiresAt: new Date(),
  }));
  await assertFails(setDoc(ref(db,
    'public_profiles/alice/activity_events/level_99'), {
    xp: 9000, createdAt: serverTimestamp(), kind: 'level_up',
  }));
});
