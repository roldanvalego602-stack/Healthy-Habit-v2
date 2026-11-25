// Prueba integral contra Auth, Firestore y Functions Emulator.
// Ejecutar con `firebase emulators:exec` y proyecto demo-healthy-habit.
// No utiliza Admin SDK: todas las solicitudes provienen del cliente.
import {after, before, test} from 'node:test';
import assert from 'node:assert/strict';
import {initializeApp, deleteApp} from 'firebase/app';
import {getAuth, connectAuthEmulator, signInAnonymously, signOut} from 'firebase/auth';
import {getFirestore, connectFirestoreEmulator, doc, collection,
  setDoc, getDoc, updateDoc, serverTimestamp} from 'firebase/firestore';
import {getFunctions, connectFunctionsEmulator, httpsCallable} from 'firebase/functions';
import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {releasePreviewRules} from './release_preview_rules.mjs';

const PROJECT = 'demo-healthy-habit';
const EMULATOR_HOST = '127.0.0.1';
let app;
let env;
let auth;
let db;
let functions;

function nextId() {
  return doc(collection(db, '_operation_ids')).id;
}

function assertDemoOnly() {
  assert.equal(process.env.GCLOUD_PROJECT, PROJECT,
    'La prueba integral requiere el proyecto demo-healthy-habit');
  // Firebase CLI no garantiza exportar una variable de entorno
  // uniforme para Functions Emulator; el callable la comprobará por
  // conexión a 127.0.0.1:5001.
  for (const name of ['FIRESTORE_EMULATOR_HOST',
    'FIREBASE_AUTH_EMULATOR_HOST']) {
    assert.ok(process.env[name], `Falta el emulador: ${name}`);
  }
}

before(async () => {
  assertDemoOnly();
  // Cargar reglas restrictivas exclusivamente en el emulador.
  // El SDK del usuario nunca obtiene permisos administrativos.
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: {
      host: EMULATOR_HOST,
      port: 8080,
      rules: releasePreviewRules(),
    },
  });
  app = initializeApp({
    apiKey: 'demo-api-key',
    authDomain: PROJECT + '.firebaseapp.com',
    projectId: PROJECT,
    appId: '1:1234567890:web:abcdef1234567890',
  }, 'prueba-integral-habitos');
  auth = getAuth(app);
  connectAuthEmulator(auth, 'http://' + EMULATOR_HOST + ':9099',
    {disableWarnings: true});
  db = getFirestore(app);
  connectFirestoreEmulator(db, EMULATOR_HOST, 8080);
  functions = getFunctions(app, 'us-central1');
  connectFunctionsEmulator(functions, EMULATOR_HOST, 5001);
});

after(async () => {
  if (auth?.currentUser) await signOut(auth);
  if (app) await deleteApp(app);
  if (env) await env.cleanup();
});

test('cliente autenticado: flujo completo sin escrituras económicas directas', async () => {
  const credential = await signInAnonymously(auth);
  const uid = credential.user.uid;
  const userRef = doc(db, 'users', uid);
  await setDoc(userRef, {
    uid,
    name: 'Prueba de hábitos',
    username: 'prueba_' + uid,
    email: '',
    level: 1,
    xp: 0,
    habitCoins: 100,
    currentStreak: 0,
    createdAt: serverTimestamp(),
  });
  assert.equal((await getDoc(userRef)).data().habitCoins, 100);

  // Las reglas restrictivas deben impedir la falsificación desde el SDK.
  await assert.rejects(updateDoc(userRef, {xp: 5000}),
    (error) => error.code === 'permission-denied');
  assert.equal((await getDoc(userRef)).data().xp, 0);

  const habitId = 'alim_001'; // "Incluir una fruta", nivel 1.
  const attemptId = nextId();
  const activationId = nextId();
  const activate = httpsCallable(functions, 'activateOfficialHabitDemo');
  const registration = httpsCallable(functions, 'registerOfficialHabitDemo');
  const claim = httpsCallable(functions, 'claimDailyStreakReward');
  const cancel = httpsCallable(functions, 'cancelOfficialHabitDemo');

  const input = {habitId, attemptId, operationId: activationId};
  const firstActivation = (await activate(input)).data;
  assert.equal(firstActivation.alreadyProcessed, false);
  const repeatedActivation = (await activate(input)).data;
  assert.equal(repeatedActivation.alreadyProcessed, true);
  assert.equal((await getDoc(userRef)).data().habitMutationVersion, 1);

  const attemptRef = doc(db, 'users', uid,
    'user_habits', habitId, 'attempts', attemptId);
  assert.equal((await getDoc(attemptRef)).data().status, 'inProgress');
  await assert.rejects(updateDoc(attemptRef, {progress: 999}),
    (error) => error.code === 'permission-denied');

  const registrationInput = {habitId, attemptId, operationId: nextId()};
  const firstRegistration = (await registration(registrationInput)).data;
  assert.equal(firstRegistration.alreadyProcessed, false);
  assert.equal(firstRegistration.xpAwarded, 10);
  assert.equal(firstRegistration.progress, 1);
  const repeatedRegistration = (await registration(registrationInput)).data;
  assert.equal(repeatedRegistration.alreadyProcessed, true);
  assert.equal((await getDoc(userRef)).data().xp, 10);

  const streakDay = firstRegistration.dailyStreakDay;
  assert.match(streakDay, /^\\d{4}-\\d{2}-\\d{2}$/);
  const firstClaim = (await claim({day: streakDay})).data;
  const repeatedClaim = (await claim({day: streakDay})).data;
  assert.equal(firstClaim.coinsAwarded, 10);
  assert.equal(repeatedClaim.coinsAwarded, 0);
  assert.equal(repeatedClaim.alreadyClaimed, true);
  assert.equal((await getDoc(userRef)).data().habitCoins, 110);

  const cancellationInput = {
    habitId, attemptId, operationId: nextId(), maxPenalty: 0,
  };
  const firstCancellation = (await cancel(cancellationInput)).data;
  assert.equal(firstCancellation.chargedCoins, 0);
  const repeatedCancellation = (await cancel(cancellationInput)).data;
  assert.equal(repeatedCancellation.alreadyProcessed, true);
  assert.equal((await getDoc(attemptRef)).data().status, 'cancelled');
  assert.equal((await getDoc(userRef)).data().habitCoins, 110);

  await assert.rejects(registration({
    habitId, attemptId, operationId: nextId(),
  }), (error) => error.code === 'functions/failed-precondition');
});
