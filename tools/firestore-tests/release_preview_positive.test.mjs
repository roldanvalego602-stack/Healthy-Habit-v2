// Pruebas positivas separadas de la release gate adversarial.
// Reglas generadas en memoria; nunca desplegadas.
import { before, beforeEach, after, test } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { releasePreviewRules } from './release_preview_rules.mjs';

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-healthy-habit',
    firestore: {
      host: '127.0.0.1', port: 8080,
      rules: releasePreviewRules(),
    },
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => { if (env) await env.cleanup(); });

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), {
      uid: 'alice', name: 'Alice', xp: 0, currentXp: 0,
      level: 1, habitCoins: 250, shopInventory: [],
    });
  });
}

test('lockdown: editar nombre sigue permitido', async () => {
  await seed();
  await assertSucceeds(updateDoc(doc(as('alice'), 'users/alice'),
    {name: 'Alice Actualizada'}));
});
test('lockdown: el titular puede cambiar preferencias', async () => {
  await seed();
  await assertSucceeds(updateDoc(doc(as('alice'), 'users/alice'),
    {settings: {permitirRecordatorios: true}}));
});
test('lockdown: comprar con precio y descuento validado sigue permitido', async () => {
  await seed();
  await assertSucceeds(updateDoc(doc(as('alice'), 'users/alice'),
    {shopInventory: ['avatar_frame'], habitCoins: 130}));
});
test('lockdown: comprar sin descuento se rechaza', async () => {
  await seed();
  await assertFails(updateDoc(doc(as('alice'), 'users/alice'),
    {shopInventory: ['avatar_frame'], habitCoins: 250}));
});
test('lockdown: el propietario lee datos de intentos preexistentes', async () => {
  await seed();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(),
      'users/alice/user_habits/hidr_001/attempts/one'), {
      status: 'inProgress', progress: 0, target: 1,
    });
  });
  await assertSucceeds(getDoc(doc(as('alice'),
    'users/alice/user_habits/hidr_001/attempts/one')));
});
test('lockdown: el usuario no puede escribir progreso directamente', async () => {
  await seed();
  await assertFails(setDoc(doc(as('alice'),
    'users/alice/user_habits/hidr_001/attempts/forged'), {
    status: 'inProgress', progress: 0, target: 1,
  }));
});
test('lockdown: no puede cambiar datos de otro usuario', async () => {
  await seed();
  await assertFails(updateDoc(doc(as('mallory'), 'users/alice'),
    {name: 'Mallory'}));
});
