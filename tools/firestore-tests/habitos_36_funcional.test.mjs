// Prueba funcional exhaustiva, SOLO Firebase Emulator y proyecto demo.
// Una carga inicial administrativa se limita a 127.0.0.1:8080; el resto
// opera por SDK cliente autenticado y callables oficiales de demostración.
import {before, after, test} from 'node:test';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {initializeApp, deleteApp} from 'firebase/app';
import {getAuth, connectAuthEmulator, signInAnonymously, signOut} from 'firebase/auth';
import {getFirestore, connectFirestoreEmulator, getDoc, doc, collection,
  updateDoc} from 'firebase/firestore';
import {getFunctions, connectFunctionsEmulator, httpsCallable} from 'firebase/functions';

const require = createRequire(import.meta.url);
const {SERVER_CATALOG} = require('../../functions/official_habit_catalog.js');
const PROJECT = 'demo-healthy-habit';
const HOST = '127.0.0.1';
const DB = 'default'; // no es (default)
let app, auth, db, functions;

const nextId = () => doc(collection(db, '_local_test_ids')).id;

function requireEmulators() {
  assert.equal(process.env.GCLOUD_PROJECT, PROJECT,
    'Nunca ejecutar contra un proyecto distinto de demo-healthy-habit.');
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, HOST + ':8080',
    'Se requiere Firestore Emulator LOCAL en 127.0.0.1:8080.');
  assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, HOST + ':9099',
    'Se requiere Auth Emulator LOCAL en 127.0.0.1:9099.');
  assert.equal(process.env.FIREBASE_FUNCTIONS_EMULATOR_HOST, HOST + ':5001',
    'Se requiere Functions Emulator LOCAL en 127.0.0.1:5001.');
}

before(() => {
  requireEmulators();
  app = initializeApp({
    apiKey: 'demo-api-key',
    authDomain: PROJECT + '.firebaseapp.com',
    projectId: PROJECT,
    appId: '1:1234567890:web:abcdef1234567890',
  }, 'todos-los-habitos-demo');
  auth = getAuth(app);
  connectAuthEmulator(auth, 'http://' + HOST + ':9099',
    {disableWarnings: true});
  db = getFirestore(app, DB);
  connectFirestoreEmulator(db, HOST, 8080);
  functions = getFunctions(app, 'us-central1');
  connectFunctionsEmulator(functions, HOST, 5001);
});

after(async () => {
  if (auth?.currentUser) await signOut(auth);
  if (app) await deleteApp(app);
});

// La ruta REST sólo sirve para sembrar XP suficiente en un usuario efímero
// de los emuladores: las reglas correctamente impiden que Flutter se lo asigne.
// El token especial "owner" nunca debe apuntar a un servidor externo.
async function seedEmulatorProfile(uid) {
  requireEmulators();
  const url = 'http://' + HOST + ':8080/v1/projects/' + PROJECT +
    '/databases/' + DB + '/documents/users/' + encodeURIComponent(uid);
  const body = {fields: {
    uid: {stringValue: uid},
    name: {stringValue: 'Prueba exhaustiva demo'},
    username: {stringValue: 'test_' + uid},
    email: {stringValue: ''},
    xp: {integerValue: '10000'},
    currentXp: {integerValue: '10000'},
    level: {integerValue: '20'},
    habitCoins: {integerValue: '1000'},
    habitSlots: {integerValue: '1'},
    habitMutationVersion: {integerValue: '0'},
    currentStreak: {integerValue: '0'},
  }};
  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: 'Bearer owner',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  assert.equal(response.status, 200,
    'No se pudo crear la cuenta local del emulador: ' +
      (await response.text()).slice(0, 400));
}

test('36 hábitos: activación, cancelación y reintentos reales con reglas restrictivas', async () => {
  assert.equal(Object.keys(SERVER_CATALOG).length, 36);
  const {user} = await signInAnonymously(auth);
  const uid = user.uid;
  await seedEmulatorProfile(uid);
  const userRef = doc(db, 'users', uid);
  assert.equal((await getDoc(userRef)).data().xp, 10000);
  await assert.rejects(updateDoc(userRef, {xp: 999999}),
    (error) => error.code === 'permission-denied');

  const activate = httpsCallable(functions, 'activateOfficialHabitDemo');
  const cancel = httpsCallable(functions, 'cancelOfficialHabitDemo');
  let totalPenalty = 0;
  let done = 0;
  for (const [habitId, catalog] of Object.entries(SERVER_CATALOG)) {
    const attemptId = nextId();
    const activation = {habitId, attemptId, operationId: nextId()};
    const first = (await activate(activation)).data;
    assert.equal(first.alreadyProcessed, false, habitId);
    assert.equal(first.habitId, habitId, habitId);
    assert.equal(first.chargedCoins, catalog.coinCost, habitId);
    assert.equal((await activate(activation)).data.alreadyProcessed, true, habitId);

    const attemptRef = doc(db, 'users', uid,
      'user_habits', habitId, 'attempts', attemptId);
    const attempt = (await getDoc(attemptRef)).data();
    assert.equal(attempt.status, 'inProgress', habitId);
    assert.equal(attempt.target, catalog.target, habitId);
    assert.equal(attempt.frequencyType, catalog.frequencyType, habitId);
    assert.equal(attempt.registrationsPerPeriod, catalog.registrationsPerPeriod, habitId);

    // Con un único cupo, no se puede activar un segundo hábito antes de cancelar.
    if (done === 0) {
      const otherId = Object.keys(SERVER_CATALOG)[1];
      await assert.rejects(activate({
        habitId: otherId, attemptId: nextId(), operationId: nextId(),
      }), (error) => error.code === 'functions/resource-exhausted');
    }

    const difficult = catalog.difficulty === 'Difícil';
    if (difficult) {
      await assert.rejects(cancel({
        habitId, attemptId, operationId: nextId(), maxPenalty: 0,
      }), (error) => error.code === 'functions/failed-precondition');
    }
    const cancellation = {
      habitId, attemptId, operationId: nextId(), maxPenalty: difficult ? 25 : 0,
    };
    const cancelled = (await cancel(cancellation)).data;
    const expectedPenalty = difficult ? 25 : 0;
    assert.equal(cancelled.alreadyProcessed, false, habitId);
    assert.equal(cancelled.chargedCoins, expectedPenalty, habitId);
    assert.equal((await cancel(cancellation)).data.alreadyProcessed, true, habitId);
    assert.equal((await getDoc(attemptRef)).data().status, 'cancelled', habitId);
    totalPenalty += expectedPenalty;
    done++;
  }
  const finalUser = (await getDoc(userRef)).data();
  assert.equal(done, 36);
  assert.equal(finalUser.xp, 10000, 'Activar y cancelar nunca acredita XP');
  assert.equal(finalUser.habitCoins, 1000 - totalPenalty,
    'Los cobros solo aplican una vez');
  assert.equal(finalUser.habitMutationVersion, 72,
    'Cada activación y cancelación incrementa una única vez la versión');
});
