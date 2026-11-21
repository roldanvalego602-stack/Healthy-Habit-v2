import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, writeBatch, serverTimestamp, updateDoc, deleteDoc, collection, query, where, getDocs } from 'firebase/firestore';

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

async function seedFriendship(a = 'alice', b = 'bob') {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const batch = writeBatch(ctx.firestore());
    batch.set(doc(ctx.firestore(), `users/${a}/friends/${b}`),
      { createdAt: new Date() });
    batch.set(doc(ctx.firestore(), `users/${b}/friends/${a}`),
      { createdAt: new Date() });
    await batch.commit();
  });
}

async function sendRequest(sender = 'alice', recipient = 'bob') {
  const db = as(sender);
  const batch = writeBatch(db);
  batch.set(doc(db, `users/${recipient}/solicitudes/${sender}`),
    { createdAt: serverTimestamp() });
  batch.set(doc(db, `users/${sender}/solicitudes_enviadas/${recipient}`),
    { createdAt: serverTimestamp() });
  await assertSucceeds(batch.commit());
}

test('una persona no puede forjar amistades creando dos copias sin solicitud', async () => {
  const db = as('alice');
  const batch = writeBatch(db);
  batch.set(doc(db, 'users/alice/friends/bob'),
    { createdAt: serverTimestamp() });
  batch.set(doc(db, 'users/bob/friends/alice'),
    { createdAt: serverTimestamp() });
  await assertFails(batch.commit());
});

test('aceptar solicitud crea dos amistades y consume los dos espejos', async () => {
  await sendRequest();
  const db = as('bob');
  const batch = writeBatch(db);
  batch.set(doc(db, 'users/alice/friends/bob'),
    { createdAt: serverTimestamp() });
  batch.set(doc(db, 'users/bob/friends/alice'),
    { createdAt: serverTimestamp() });
  batch.delete(doc(db, 'users/bob/solicitudes/alice'));
  batch.delete(doc(db, 'users/alice/solicitudes_enviadas/bob'));
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(doc(as('alice'), 'users/alice/friends/bob')));
  const snapshot = await getDoc(doc(as('bob'), 'users/bob/friends/alice'));
  if (!snapshot.exists()) throw new Error('No se creó la amistad recíproca');
});

test('rechaza aceptación que no borre la solicitud', async () => {
  await sendRequest();
  const db = as('bob');
  const batch = writeBatch(db);
  batch.set(doc(db, 'users/alice/friends/bob'),
    { createdAt: serverTimestamp() });
  batch.set(doc(db, 'users/bob/friends/alice'),
    { createdAt: serverTimestamp() });
  await assertFails(batch.commit());
});

test('cualquiera de los amigos puede eliminar ambas copias a la vez', async () => {
  await seedFriendship();
  const db = as('alice');
  const batch = writeBatch(db);
  batch.delete(doc(db, 'users/alice/friends/bob'));
  batch.delete(doc(db, 'users/bob/friends/alice'));
  await assertSucceeds(batch.commit());
});

test('una persona extraña no puede eliminar la amistad ajena', async () => {
  await seedFriendship();
  await assertFails(deleteDoc(doc(as('mallory'), 'users/alice/friends/bob')));
});

test('no se pueden crear reacciones para personas sin amistad', async () => {
  await assertFails(setDoc(doc(as('alice'), 'interactions', 'forged'), {
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

test('una invitación a quien no es amigo debe rechazarse', async () => {
  await assertFails(setDoc(doc(as('alice'),
    'shared_habit_invites', 'untrusted'), {
    senderUid: 'alice',
    recipientUid: 'mallory',
    habitId: 'beber-agua',
    habitTitle: 'Beber agua',
    status: 'pendiente',
    createdAt: serverTimestamp(),
    resolvedAt: null,
  }));
});

test('sólo el destinatario acepta una invitación; un tercero no puede', async () => {
  await seedFriendship();
  const id = 'pair-1';
  await assertSucceeds(setDoc(doc(as('alice'), 'shared_habit_invites', id), {
    senderUid: 'alice', recipientUid: 'bob', habitId: 'beber-agua',
    habitTitle: 'Beber agua', status: 'pendiente',
    createdAt: serverTimestamp(), resolvedAt: null,
  }));
  await assertFails(updateDoc(doc(as('mallory'), 'shared_habit_invites', id),
    { status: 'aceptada', resolvedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(as('bob'), 'shared_habit_invites', id),
    { status: 'aceptada', resolvedAt: serverTimestamp() }));
});

test('una persona ajena no puede consultar invitaciones de la pareja', async () => {
  await seedFriendship();
  await assertSucceeds(setDoc(doc(as('alice'), 'shared_habit_invites', 'pair-2'), {
    senderUid: 'alice', recipientUid: 'bob', habitId: 'beber-agua',
    habitTitle: 'Beber agua', status: 'pendiente',
    createdAt: serverTimestamp(), resolvedAt: null,
  }));
  await assertFails(getDoc(doc(as('mallory'), 'shared_habit_invites', 'pair-2')));
});

test('las consultas de invitaciones sólo exponen al participante', async () => {
  await seedFriendship();
  await assertSucceeds(setDoc(doc(as('alice'), 'shared_habit_invites', 'pair-3'), {
    senderUid: 'alice', recipientUid: 'bob', habitId: 'beber-agua',
    habitTitle: 'Beber agua', status: 'pendiente',
    createdAt: serverTimestamp(), resolvedAt: null,
  }));
  await assertSucceeds(getDocs(query(
    collection(as('bob'), 'shared_habit_invites'),
    where('recipientUid', '==', 'bob'),
  )));
  await assertFails(getDocs(collection(as('mallory'), 'shared_habit_invites')));
});

test('el registro inicial válido conserva el acceso propio', async () => {
  await assertSucceeds(setDoc(doc(as('alice'), 'users/alice'), {
    uid: 'alice', name: 'Alice', username: 'alice',
    email: 'alice@example.test', level: 1, xp: 0,
    habitCoins: 100, currentStreak: 0, createdAt: serverTimestamp(),
  }));
});

test('el alta inicial no permite crear saldo y XP arbitrarios', async () => {
  await assertFails(setDoc(doc(as('alice'), 'users/alice'), {
    uid: 'alice', name: 'Alice', username: 'alice',
    email: 'alice@example.test', level: 40, xp: 99999,
    habitCoins: 999999, currentStreak: 0,
    createdAt: serverTimestamp(),
  }));
});

test('el usuario cambia preferencias sin acceder a datos de terceros', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), { name: 'Alice', xp: 0,
      habitCoins: 100 });
  });
  await assertSucceeds(updateDoc(doc(as('alice'), 'users/alice'),
    { settings: { tema: 'oscuro' } }));
  await assertFails(updateDoc(doc(as('mallory'), 'users/alice'),
    { settings: { tema: 'claro' } }));
});

test('una compra del catálogo debita el precio correcto del inventario', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'),
      { name: 'Alice', xp: 0, habitCoins: 150, shopInventory: [] });
  });
  await assertSucceeds(updateDoc(doc(as('alice'), 'users/alice'),
    { habitCoins: 30, shopInventory: ['avatar_frame'] }));
});

test('no se permite comprar sin descontar monedas', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'),
      { name: 'Alice', xp: 0, habitCoins: 150, shopInventory: [] });
  });
  await assertFails(updateDoc(doc(as('alice'), 'users/alice'),
    { habitCoins: 150, shopInventory: ['avatar_frame'] }));
});

test('sólo el titular puede crear registros privados de hábito', async () => {
  await assertSucceeds(setDoc(
    doc(as('alice'), 'users/alice/user_habits/hidr_001/attempts/one/logs/x'),
    { userId: 'alice', xpEarned: 10, createdAt: serverTimestamp() }));
  await assertFails(setDoc(
    doc(as('mallory'), 'users/alice/user_habits/hidr_001/attempts/one/logs/y'),
    { userId: 'alice', xpEarned: 10, createdAt: serverTimestamp() }));
});

test('cada persona ve los perfiles públicos sin editar el de otra', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'public_profiles/alice'),
      {name: 'Alice', username: 'alice', xp: 0, settings: {}});
  });
  await assertSucceeds(getDoc(doc(as('bob'), 'public_profiles/alice')));
  await assertFails(updateDoc(doc(as('mallory'), 'public_profiles/alice'),
    { name: 'Mallory' }));
});

test('nadie modifica configuración global desde un cliente móvil', async () => {
  await assertFails(setDoc(doc(as('alice'), 'system', 'settings'),
    { allowRewards: true }));
});

test('la app no puede crear nuevos seguidores heredados', async () => {
  await assertFails(setDoc(
    doc(as('alice'), 'users/alice/following/bob'),
    { createdAt: serverTimestamp() }));
  await assertFails(setDoc(
    doc(as('alice'), 'users/alice/followers/bob'),
    { createdAt: serverTimestamp() }));
});

test('el destinatario puede rechazar reacciones desde su perfil público', async () => {
  await seedFriendship();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'public_profiles/bob'),
      { name: 'Bob', username: 'bob', xp: 0,
        settings: { permitirReacciones: false } });
  });
  await assertFails(setDoc(doc(as('alice'), 'interactions/blocked'), {
    challengeId: '', createdAt: new Date(), emoji: '👏', estado: 'enviado',
    fromUid: 'alice', leido: false, respondedAt: null,
    tipo: 'reaccion', toUid: 'bob',
  }));
});

test('perfil público respeta el XP almacenado y no publica uno distinto', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'),
      { name: 'Alice', xp: 20, habitCoins: 100 });
  });
  const publicData = {
    name: 'Alice', username: 'alice', xp: 20, settings: {},
  };
  await assertSucceeds(setDoc(doc(as('alice'), 'public_profiles/alice'),
    publicData));
  await assertFails(updateDoc(doc(as('alice'), 'public_profiles/alice'),
    { xp: 999999 }));
});

test('evidencia temporal se guarda sólo por su dueño con caducidad', async () => {
  const expiry = new Date(Date.now() + 24 * 60 * 60 * 1000);
  await assertSucceeds(setDoc(doc(as('alice'),
    'users/alice/temporary_habit_evidence/log-1'), {
    userId: 'alice', habitId: 'hidr_001', attemptId: 'one',
    logId: 'log-1', imageBase64: 'dGVzdA==',
    contentType: 'image/jpeg', createdAt: serverTimestamp(),
    expiresAt: expiry,
  }));
  await assertFails(getDoc(doc(as('mallory'),
    'users/alice/temporary_habit_evidence/log-1')));
});

test('no se puede crear evidencia de un usuario diferente', async () => {
  await assertFails(setDoc(doc(as('alice'),
    'users/alice/temporary_habit_evidence/forged'), {
    userId: 'bob', habitId: 'hidr_001', attemptId: 'one',
    logId: 'forged', imageBase64: 'dGVzdA==',
    contentType: 'image/jpeg', createdAt: serverTimestamp(),
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
  }));
});
