'use strict';

const { before, after, test } = require('node:test');
const assert = require('node:assert/strict');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, getDocs, collection } = require('firebase/firestore');
const fs = require('node:fs');
const path = require('node:path');

let env;
let alice;
let bob;
let anonymous;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-healthy-habit',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(
        path.resolve(__dirname, '../../firestore.candidate.rules'),
        'utf8',
      ),
    },
  });
  alice = env.authenticatedContext('alice').firestore();
  bob = env.authenticatedContext('bob').firestore();
  anonymous = env.unauthenticatedContext().firestore();

  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/alice'), {
      name: 'Alice', xp: 50, habitCoins: 10,
    });
    await setDoc(doc(db, 'users/bob'), {
      name: 'Bob', xp: 100, habitCoins: 25,
    });
    await setDoc(doc(db, 'users/bob/temporary_habit_evidence/photo-1'), {
      imageBase64: 'secret-example',
    });
    await setDoc(doc(db, 'users/bob/user_habits/water/attempts/try-1/logs/l1'), {
      note: 'private',
    });
    await setDoc(doc(db, 'system/catalog'), { version: 1 });
  });
});

after(async () => {
  await env?.cleanup();
});

test('propietario puede leer su perfil privado y sus registros', async () => {
  await assertSucceeds(getDoc(doc(alice, 'users/alice')));
  await assertSucceeds(setDoc(doc(alice, 'users/alice/user_habits/water'), {
    title: 'Beber agua',
  }));
});

test('usuario A no puede leer perfil, evidencia ni logs de B', async () => {
  await assertFails(getDoc(doc(alice, 'users/bob')));
  await assertFails(getDoc(doc(alice, 'users/bob/temporary_habit_evidence/photo-1')));
  await assertFails(getDoc(doc(alice, 'users/bob/user_habits/water/attempts/try-1/logs/l1')));
});

test('usuario A no puede alterar monedas ni datos de B', async () => {
  await assertFails(updateDoc(doc(alice, 'users/bob'), { habitCoins: 9999 }));
  await assertFails(setDoc(doc(alice, 'users/bob/user_habits/forged'), { title: 'false' }));
});

test('nadie puede consultar todos los documentos privados de users', async () => {
  await assertFails(getDocs(collection(alice, 'users')));
});

test('system es legible para autenticados pero no editable desde cliente', async () => {
  await assertSucceeds(getDoc(doc(alice, 'system/catalog')));
  await assertFails(updateDoc(doc(bob, 'system/catalog'), { version: 99 }));
  await assertFails(getDoc(doc(anonymous, 'system/catalog')));
});

test('sin autenticación no se permite acceder a perfiles', async () => {
  await assertFails(getDoc(doc(anonymous, 'users/alice')));
  assert.ok(env);
});
