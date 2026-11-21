import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, writeBatch } from 'firebase/firestore';

const rulesPath = resolve(process.cwd(), 'firestore.candidate.rules');
let env;
const as = (uid) => env.authenticatedContext(uid).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-healthy-habit',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync(rulesPath, 'utf8'),
    },
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => { if (env) await env.cleanup(); });

test('cuenta A puede consultar su documento privado', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users', 'alice'),
      { name: 'Alice', xp: 0, habitCoins: 0 });
  });
  await assertSucceeds(getDoc(doc(as('alice'), 'users', 'alice')));
});

test('cuenta ajena no puede leer el documento de Alice', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users', 'alice'),
      { name: 'Alice', xp: 0, habitCoins: 0 });
  });
  await assertFails(getDoc(doc(as('mallory'), 'users', 'alice')));
});

test('nadie puede crear directamente una amistad sin solicitud', async () => {
  await assertFails(setDoc(doc(as('alice'), 'users/alice/friends/bob'),
    { createdAt: new Date() }));
});

test('una solicitud válida se envía con ambos documentos espejo', async () => {
  const db = as('alice');
  const batch = writeBatch(db);
  // Los serverTimestamp iguales se validan de forma atómica.
  const { serverTimestamp } = await import('firebase/firestore');
  batch.set(doc(db, 'users/bob/solicitudes/alice'),
    { createdAt: serverTimestamp() });
  batch.set(doc(db, 'users/alice/solicitudes_enviadas/bob'),
    { createdAt: serverTimestamp() });
  await assertSucceeds(batch.commit());
});

test('una cuenta no puede leer las solicitudes de otra', async () => {
  await assertFails(getDoc(doc(as('mallory'),
    'users/bob/solicitudes/alice')));
});

test('una reacción enviada por un amigo se permite con campos válidos', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice/friends/bob'),
      { createdAt: new Date() });
  });
  await assertSucceeds(setDoc(doc(as('alice'), 'interactions', 'reaction-one'), {
    challengeId: '',
    createdAt: new Date(),
    emoji: '👏',
    estado: 'enviado',
    fromUid: 'alice',
    leido: false,
    respondedAt: null,
    tipo: 'reaccion',
    toUid: 'bob',
  }));
});

test('una invitación de hábito entre amigos se puede crear', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice/friends/bob'),
      { createdAt: new Date() });
  });
  const { serverTimestamp } = await import('firebase/firestore');
  await assertSucceeds(setDoc(doc(as('alice'),
    'shared_habit_invites', 'inv-alice-bob-water'), {
    senderUid: 'alice',
    recipientUid: 'bob',
    habitId: 'beber-agua',
    habitTitle: 'Beber agua',
    status: 'pendiente',
    createdAt: serverTimestamp(),
    resolvedAt: null,
  }));
});
