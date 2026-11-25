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

const PROJECT = 'demo-healthy-habit';
const EMULATOR_HOST = '127.0.0.1';
let app;
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
  // Las reglas se cargan en la base nombrada "default" al iniciar
  // Firestore Emulator con firebase.lockdown.emulator.json.
  // No usar initializeTestEnvironment: carga reglas en "(default)"
  // y dejaría la base de Flutter abierta por creación implícita.
  app = initializeApp({
    apiKey: 'demo-api-key',
    authDomain: PROJECT + '.firebaseapp.com',
    projectId: PROJECT,
    appId: '1:1234567890:web:abcdef1234567890',
  }, 'prueba-integral-habitos');
  auth = getAuth(app);
  connectAuthEmulator(auth, 'http://' + EMULATOR_HOST + ':9099',
    {disableWarnings: true});
  // Firestore distingue la base `(default)` de la base nombrada `default`.
  // Flutter y Functions usan explícitamente `default`; el SDK de prueba
  // debe usar la misma para que el perfil sea visible al backend.
  db = getFirestore(app, 'default');
  connectFirestoreEmulator(db, EMULATOR_HOST, 8080);
  functions = getFunctions(app, 'us-central1');
  connectFunctionsEmulator(functions, EMULATOR_HOST, 5001);
});

after(async () => {
  if (auth?.currentUser) await signOut(auth);
  if (app) await deleteApp(app);
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
  assert.equal(db._databaseId?.database ?? 'default', 'default');

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
  assert.match(streakDay, /^\d{4}-\d{2}-\d{2}$/);
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


test('respuesta perdida: recuperar activación, registro y cancelación sin duplicados', async () => {
  // Usuario aislado del primer escenario. El SDK cliente se autentica
  // contra Auth Emulator y solo puede leer lo que permiten las reglas.
  await signOut(auth);
  const credential = await signInAnonymously(auth);
  const uid = credential.user.uid;
  const userRef = doc(db, 'users', uid);
  await setDoc(userRef, {
    uid,
    name: 'Prueba de respuesta perdida',
    username: 'recuperacion_' + uid,
    email: '',
    level: 1,
    xp: 0,
    habitCoins: 100,
    currentStreak: 0,
    createdAt: serverTimestamp(),
  });

  const habitId = 'alim_001';
  const attemptId = nextId();
  const activate = httpsCallable(functions, 'activateOfficialHabitDemo');
  const register = httpsCallable(functions, 'registerOfficialHabitDemo');
  const cancel = httpsCallable(functions, 'cancelOfficialHabitDemo');
  const attemptRef = doc(db, 'users', uid, 'user_habits', habitId,
    'attempts', attemptId);

  // Simula que el servidor confirmó y Firestore persistió, pero Flutter
  // perdió la respuesta: se descarta intencionalmente el primer resultado.
  // La simulación NO corta TCP y no valida SharedPreferences.
  const activationPayload = {habitId, attemptId, operationId: nextId()};
  await activate(activationPayload); // Respuesta descartada.
  const beforeActivationRetry = (await getDoc(userRef)).data();
  const attemptBeforeActivationRetry = (await getDoc(attemptRef)).data();
  assert.equal(beforeActivationRetry.habitMutationVersion, 1);
  assert.equal(attemptBeforeActivationRetry.status, 'inProgress');
  const activationRecovered = (await activate(activationPayload)).data;
  assert.equal(activationRecovered.alreadyProcessed, true);
  assert.equal((await getDoc(userRef)).data().habitMutationVersion,
    beforeActivationRetry.habitMutationVersion);
  assert.equal((await getDoc(attemptRef)).data().status, 'inProgress');

  const registrationPayload = {habitId, attemptId, operationId: nextId()};
  await register(registrationPayload); // Respuesta descartada.
  const beforeRegistrationRetry = (await getDoc(userRef)).data();
  const attemptBeforeRegistrationRetry = (await getDoc(attemptRef)).data();
  assert.equal(beforeRegistrationRetry.xp, 10);
  assert.equal(attemptBeforeRegistrationRetry.progress, 1);
  const registrationRecovered = (await register(registrationPayload)).data;
  assert.equal(registrationRecovered.alreadyProcessed, true);
  assert.equal(registrationRecovered.xpAwarded, 10);
  assert.equal(registrationRecovered.progress, 1);
  const afterRegistrationRetry = (await getDoc(userRef)).data();
  const attemptAfterRegistrationRetry = (await getDoc(attemptRef)).data();
  assert.equal(afterRegistrationRetry.xp, beforeRegistrationRetry.xp);
  assert.equal(afterRegistrationRetry.habitCoins,
    beforeRegistrationRetry.habitCoins);
  assert.equal(attemptAfterRegistrationRetry.progress,
    attemptBeforeRegistrationRetry.progress);
  assert.equal(attemptAfterRegistrationRetry.xpEarned,
    attemptBeforeRegistrationRetry.xpEarned);

  const cancellationPayload = {
    habitId, attemptId, operationId: nextId(), maxPenalty: 0,
  };
  await cancel(cancellationPayload); // Respuesta descartada.
  const beforeCancellationRetry = (await getDoc(userRef)).data();
  assert.equal((await getDoc(attemptRef)).data().status, 'cancelled');
  const cancellationRecovered = (await cancel(cancellationPayload)).data;
  assert.equal(cancellationRecovered.alreadyProcessed, true);
  assert.equal(cancellationRecovered.chargedCoins, 0);
  const afterCancellationRetry = (await getDoc(userRef)).data();
  assert.equal(afterCancellationRetry.habitCoins,
    beforeCancellationRetry.habitCoins);
  assert.equal(afterCancellationRetry.xp, beforeCancellationRetry.xp);
  assert.equal(afterCancellationRetry.habitMutationVersion,
    beforeCancellationRetry.habitMutationVersion);
  assert.equal((await getDoc(attemptRef)).data().status, 'cancelled');
});


test('notas oficiales: almacenar texto sin cambiar recompensas ni aceptar alteraciones', async () => {
  await signOut(auth);
  const credential = await signInAnonymously(auth);
  const uid = credential.user.uid;
  const userRef = doc(db, 'users', uid);
  await setDoc(userRef, {
    uid,
    name: 'Prueba de notas',
    username: 'notas_' + uid,
    email: '',
    level: 1,
    xp: 0,
    habitCoins: 100,
    currentStreak: 0,
    createdAt: serverTimestamp(),
  });
  const habitId = 'alim_001';
  const attemptId = nextId();
  await httpsCallable(functions, 'activateOfficialHabitDemo')({
    habitId, attemptId, operationId: nextId(),
  });
  const register = httpsCallable(functions, 'registerOfficialHabitDemo');
  const operationId = nextId();
  const input = {
    habitId, attemptId, operationId,
    note: 'Comí una manzana en el desayuno.',
  };
  const first = (await register(input)).data;
  assert.equal(first.alreadyProcessed, false);
  assert.equal(first.xpAwarded, 10);
  const logRef = doc(db, 'users', uid, 'user_habits', habitId,
    'attempts', attemptId, 'logs', operationId);
  assert.equal((await getDoc(logRef)).data().note, input.note);
  const xpBeforeRetry = (await getDoc(userRef)).data().xp;
  const repeated = (await register(input)).data;
  assert.equal(repeated.alreadyProcessed, true);
  assert.equal((await getDoc(userRef)).data().xp, xpBeforeRetry);

  await assert.rejects(register({...input, note: 'Una nota distinta'}),
    (error) => error.code === 'functions/already-exists');
  assert.equal((await getDoc(logRef)).data().note, input.note);
  assert.equal((await getDoc(userRef)).data().xp, xpBeforeRetry);

  await assert.rejects(register({
    habitId, attemptId, operationId: nextId(),
    note: 'a'.repeat(501),
  }), (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({
    habitId, attemptId, operationId: nextId(), note: 'Correcto', xp: 100000,
  }), (error) => error.code === 'functions/invalid-argument');
  assert.equal((await getDoc(userRef)).data().xp, xpBeforeRetry);
});


test('contadores autodeclarados: formato seguro, misma recompensa y reintentos', async () => {
  await signOut(auth);
  const {user} = await signInAnonymously(auth);
  const uid = user.uid;
  const userRef = doc(db, 'users', uid);
  await setDoc(userRef, {
    uid, name: 'Prueba de contadores',
    username: 'contador_' + uid, email: '',
    level: 1, xp: 0, habitCoins: 100, currentStreak: 0,
    createdAt: serverTimestamp(),
  });
  const habitId = 'hidr_001';
  const attemptId = nextId();
  const activate = httpsCallable(functions, 'activateOfficialHabitDemo');
  const register = httpsCallable(functions, 'registerOfficialHabitDemo');
  await activate({habitId, attemptId, operationId: nextId()});
  const operationId = nextId();
  const interaction = {
    type: 'hydration', value: 250, target: 250, unit: 'ml',
  };
  const payload = {
    habitId, attemptId, operationId,
    note: 'Un vaso de agua.',
    interaction,
  };
  const first = (await register(payload)).data;
  assert.equal(first.alreadyProcessed, false);
  assert.equal(first.xpAwarded, 10);
  const logRef = doc(db, 'users', uid, 'user_habits', habitId,
    'attempts', attemptId, 'logs', operationId);
  const log = (await getDoc(logRef)).data();
  assert.deepEqual(log.interaction, {...interaction, verified: false});
  assert.equal((await getDoc(userRef)).data().xp, 10);

  const repeated = (await register(payload)).data;
  assert.equal(repeated.alreadyProcessed, true);
  assert.equal((await getDoc(userRef)).data().xp, 10);
  await assert.rejects(register({...payload,
    interaction: {...interaction, value: 500}}),
  (error) => error.code === 'functions/already-exists');
  await assert.rejects(register({...payload,
    interaction: {...interaction, verified: true}}),
  (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({...payload,
    operationId: nextId(),
    interaction: {...interaction, target: 12000}}),
  (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({...payload,
    operationId: nextId(),
    interaction: {...interaction, unit: 'litros'}}),
  (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({...payload,
    operationId: nextId(),
    interaction: {...interaction, value: 100}}),
  (error) => error.code === 'functions/invalid-argument');
  assert.equal((await getDoc(userRef)).data().xp, 10);
  assert.deepEqual((await getDoc(logRef)).data().interaction,
    {...interaction, verified: false});
});


test('tiempos autodeclarados: aceptar segundos, rechazar falsificaciones y no duplicar XP', async () => {
  await signOut(auth);
  const {user} = await signInAnonymously(auth);
  const uid = user.uid;
  const userRef = doc(db, 'users', uid);
  await setDoc(userRef, {
    uid, name: 'Prueba de temporizadores',
    username: 'tiempo_' + uid, email: '',
    level: 1, xp: 0, habitCoins: 100, currentStreak: 0,
    createdAt: serverTimestamp(),
  });
  const habitId = 'alim_001';
  const attemptId = nextId();
  await httpsCallable(functions, 'activateOfficialHabitDemo')({
    habitId, attemptId, operationId: nextId(),
  });
  const register = httpsCallable(functions, 'registerOfficialHabitDemo');
  const operationId = nextId();
  const interaction = {
    type: 'stopwatch', value: 90, target: 90, unit: 'segundos',
  };
  const data = {habitId, attemptId, operationId, interaction};
  const result = (await register(data)).data;
  assert.equal(result.alreadyProcessed, false);
  assert.equal(result.xpAwarded, 10);
  const logRef = doc(db, 'users', uid, 'user_habits', habitId,
    'attempts', attemptId, 'logs', operationId);
  assert.deepEqual((await getDoc(logRef)).data().interaction,
    {...interaction, verified: false});
  const xp = (await getDoc(userRef)).data().xp;
  const replay = (await register(data)).data;
  assert.equal(replay.alreadyProcessed, true);
  assert.equal((await getDoc(userRef)).data().xp, xp);

  await assert.rejects(register({
    ...data, interaction: {...interaction, type: 'timer'},
  }), (error) => error.code === 'functions/already-exists');
  await assert.rejects(register({
    ...data, operationId: nextId(),
    interaction: {...interaction, unit: 'horas'},
  }), (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({
    ...data, operationId: nextId(),
    interaction: {...interaction, target: 86401, value: 86401},
  }), (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({
    ...data, operationId: nextId(),
    interaction: {...interaction, value: 10},
  }), (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({
    ...data, operationId: nextId(),
    interaction: {...interaction, verified: true},
  }), (error) => error.code === 'functions/invalid-argument');
  assert.equal((await getDoc(userRef)).data().xp, xp);
});


test('sesiones guiadas: respiración y Pomodoro sin recompensas adicionales', async () => {
  const activate = httpsCallable(functions, 'activateOfficialHabitDemo');
  const register = httpsCallable(functions, 'registerOfficialHabitDemo');
  for (const type of ['breathing', 'pomodoro']) {
    if (auth.currentUser) await signOut(auth);
    const {user} = await signInAnonymously(auth);
    const uid = user.uid;
    const userRef = doc(db, 'users', uid);
    await setDoc(userRef, {
      uid, name: 'Prueba de sesiones guiadas',
      username: 'sesion_' + uid, email: '',
      level: 1, xp: 0, habitCoins: 100, currentStreak: 0,
      createdAt: serverTimestamp(),
    });

    const habitId = 'alim_001';
    const attemptId = nextId();
    await activate({habitId, attemptId, operationId: nextId()});

    const operationId = nextId();
    const interaction = {
      type, value: type === 'breathing' ? 60 : 1500,
      target: type === 'breathing' ? 60 : 1500,
      unit: 'segundos',
    };
    const input = {habitId, attemptId, operationId, interaction};
    const first = (await register(input)).data;
    assert.equal(first.alreadyProcessed, false);
    assert.equal(first.xpAwarded, 10);

    const logRef = doc(db, 'users', uid, 'user_habits', habitId,
      'attempts', attemptId, 'logs', operationId);
    assert.deepEqual((await getDoc(logRef)).data().interaction,
      {...interaction, verified: false});
    const userBeforeRetry = (await getDoc(userRef)).data();
    assert.equal(userBeforeRetry.xp, 10);

    const replay = (await register(input)).data;
    assert.equal(replay.alreadyProcessed, true);
    assert.equal((await getDoc(userRef)).data().xp, userBeforeRetry.xp);
    assert.equal((await getDoc(userRef)).data().habitCoins,
      userBeforeRetry.habitCoins);

    await assert.rejects(register({
      ...input, interaction: {...interaction, target: interaction.target + 1,
        value: interaction.value + 1},
    }), (error) => error.code === 'functions/already-exists');

    await assert.rejects(register({
      ...input, operationId: nextId(),
      interaction: {...interaction, verified: true},
    }), (error) => error.code === 'functions/invalid-argument');

    await assert.rejects(register({
      ...input, operationId: nextId(),
      interaction: {...interaction, unit: 'minutos'},
    }), (error) => error.code === 'functions/invalid-argument');

    await assert.rejects(register({
      ...input, operationId: nextId(),
      interaction: {...interaction, value: 1},
    }), (error) => error.code === 'functions/invalid-argument');

    await assert.rejects(register({
      ...input, operationId: nextId(), xp: 5000,
    }), (error) => error.code === 'functions/invalid-argument');

    assert.equal((await getDoc(userRef)).data().xp, userBeforeRetry.xp);
  }
});


test('podómetro: pasos no verificados, permisos económicos e idempotencia', async () => {
  if (auth.currentUser) await signOut(auth);
  const {user} = await signInAnonymously(auth);
  const uid = user.uid;
  const userRef = doc(db, 'users', uid);
  await setDoc(userRef, {
    uid, name: 'Prueba de pasos',
    username: 'pasos_' + uid, email: '',
    level: 1, xp: 0, habitCoins: 100, currentStreak: 0,
    createdAt: serverTimestamp(),
  });
  const habitId = 'alim_001';
  const attemptId = nextId();
  await httpsCallable(functions, 'activateOfficialHabitDemo')({
    habitId, attemptId, operationId: nextId(),
  });
  const register = httpsCallable(functions, 'registerOfficialHabitDemo');
  const operationId = nextId();
  const interaction = {type: 'steps', value: 250, target: 250, unit: 'pasos'};
  const payload = {habitId, attemptId, operationId, interaction};
  const first = (await register(payload)).data;
  assert.equal(first.alreadyProcessed, false);
  assert.equal(first.xpAwarded, 10);
  const logRef = doc(db, 'users', uid, 'user_habits', habitId,
    'attempts', attemptId, 'logs', operationId);
  assert.deepEqual((await getDoc(logRef)).data().interaction,
    {...interaction, verified: false});
  const beforeRetry = (await getDoc(userRef)).data();
  const repeated = (await register(payload)).data;
  assert.equal(repeated.alreadyProcessed, true);
  assert.equal((await getDoc(userRef)).data().xp, beforeRetry.xp);
  assert.equal((await getDoc(userRef)).data().habitCoins,
    beforeRetry.habitCoins);
  await assert.rejects(register({...payload,
    interaction: {...interaction, value: 300}}),
  (error) => error.code === 'functions/already-exists');
  await assert.rejects(register({...payload,
    operationId: nextId(), interaction: {...interaction, verified: true}}),
  (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({...payload,
    operationId: nextId(), interaction: {...interaction, unit: 'segundos'}}),
  (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({...payload,
    operationId: nextId(), interaction: {...interaction, target: 10001,
      value: 10001}}),
  (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(register({...payload,
    operationId: nextId(), xp: 9999}),
  (error) => error.code === 'functions/invalid-argument');
  assert.equal((await getDoc(userRef)).data().xp, beforeRetry.xp);
});


test('reserva de evidencia: vinculada al intento, idempotente y sin alterar XP', async () => {
  if (auth.currentUser) await signOut(auth);
  const {user} = await signInAnonymously(auth);
  const uid = user.uid;
  const userRef = doc(db, 'users', uid);
  await setDoc(userRef, {
    uid, name: 'Prueba de reserva privada',
    username: 'reserva_' + uid, email: '',
    level: 1, xp: 0, habitCoins: 100, currentStreak: 0,
    createdAt: serverTimestamp(),
  });
  const habitId = 'alim_001';
  const attemptId = nextId();
  const operationId = nextId();
  const reserve = httpsCallable(functions, 'reserveHabitEvidenceDemo');
  const activation = httpsCallable(functions, 'activateOfficialHabitDemo');
  const cancellation = httpsCallable(functions, 'cancelOfficialHabitDemo');
  const payload = {habitId, attemptId, operationId};

  await assert.rejects(reserve(payload),
    (error) => error.code === 'functions/not-found');
  await activation({habitId, attemptId, operationId: nextId()});

  const before = (await getDoc(userRef)).data();
  const first = (await reserve(payload)).data;
  assert.equal(first.alreadyReserved, false);
  assert.equal(first.storagePath,
    'habit-evidence/' + uid + '/' + attemptId + '/' + operationId);
  assert.ok(Date.parse(first.expiresAt) > Date.now());

  const repeat = (await reserve(payload)).data;
  assert.equal(repeat.alreadyReserved, true);
  assert.equal(repeat.storagePath, first.storagePath);
  assert.equal(repeat.expiresAt, first.expiresAt);

  const reservationRef = doc(db, 'users', uid,
    'habit_evidence_reservations', operationId);
  // El cliente no puede leer ni escribir el documento interno de reserva.
  // Su único comprobante es la respuesta autenticada del Callable.
  await assert.rejects(getDoc(reservationRef),
    (error) => error.code === 'permission-denied');
  await assert.rejects(setDoc(reservationRef, {status: 'verified'}),
    (error) => error.code === 'permission-denied');

  await assert.rejects(reserve({...payload, habitId: 'hidr_001'}),
    (error) => error.code === 'functions/already-exists');
  await assert.rejects(reserve({...payload, xp: 9999}),
    (error) => error.code === 'functions/invalid-argument');
  await assert.rejects(reserve({...payload, operationId: 'wrong'}),
    (error) => error.code === 'functions/invalid-argument');

  const after = (await getDoc(userRef)).data();
  assert.equal(after.xp, before.xp);
  assert.equal(after.habitCoins, before.habitCoins);
  assert.equal(after.habitMutationVersion, before.habitMutationVersion);

  await cancellation({
    habitId, attemptId, operationId: nextId(), maxPenalty: 0,
  });
  await assert.rejects(reserve({...payload, operationId: nextId()}),
    (error) => error.code === 'functions/failed-precondition');
});
