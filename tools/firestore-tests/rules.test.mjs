import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, writeBatch, serverTimestamp, updateDoc, deleteDoc, collection, query, where, getDocs } from 'firebase/firestore';

const rulesPath = resolve(new URL('../../firestore.candidate.rules', import.meta.url).pathname);
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

/* -------------------------------------------------------
 * Cobertura adicional: alta, economía, tienda, desafíos,
 * datos privados, perfil público, interacciones y sistema.
 * Los casos negativos son requisitos de seguridad: si fallan,
 * NO publicar las reglas.
 * ----------------------------------------------------- */

async function seedUser(uid = 'alice', values = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users', uid), {
      uid, name: uid, username: uid, email: uid + '@example.test',
      level: 1, xp: 0, habitCoins: 100, currentStreak: 0,
      createdAt: new Date(), ...values,
    });
  });
}

function initialAccount(uid = 'alice') {
  return {
    uid, name: 'Alice', username: uid, email: uid + '@example.test',
    level: 1, xp: 0, habitCoins: 100, currentStreak: 0,
    createdAt: serverTimestamp(),
  };
}

test('registro: propietario crea cuenta con saldos iniciales oficiales', async () => {
  await assertSucceeds(setDoc(doc(as('alice'), 'users', 'alice'),
    initialAccount()));
});

test('registro: se rechazan monedas iniciales fabricadas', async () => {
  await assertFails(setDoc(doc(as('alice'), 'users', 'alice'),
    { ...initialAccount(), habitCoins: 999999 }));
});

test('registro: se rechazan XP iniciales fabricados', async () => {
  await assertFails(setDoc(doc(as('alice'), 'users', 'alice'),
    { ...initialAccount(), xp: 999999 }));
});

test('registro: no puedo crear la cuenta privada de otra persona', async () => {
  await assertFails(setDoc(doc(as('mallory'), 'users', 'alice'),
    initialAccount('alice')));
});

test('perfil: el titular puede modificar su nombre y biografía', async () => {
  await seedUser();
  await assertSucceeds(updateDoc(doc(as('alice'), 'users', 'alice'), {
    name: 'Alicia', bio: 'Probando Healthy Habit',
  }));
});

test('perfil: nadie puede editar los datos privados de otra persona', async () => {
  await seedUser();
  await assertFails(updateDoc(doc(as('mallory'), 'users', 'alice'), {
    name: 'Suplantación',
  }));
});

test('gamificación: no se puede regalar XP sin registro válido', async () => {
  await seedUser();
  await assertFails(updateDoc(doc(as('alice'), 'users', 'alice'), {
    xp: 999999, currentXp: 999999, level: 100,
  }));
});

test('economía: no se pueden crear monedas desde el cliente', async () => {
  await seedUser();
  await assertFails(updateDoc(doc(as('alice'), 'users', 'alice'), {
    habitCoins: 999999,
  }));
});

test('economía: no se pueden falsificar recompensas de niveles', async () => {
  await seedUser();
  await assertFails(updateDoc(doc(as('alice'), 'users', 'alice'), {
    claimedLevelRewards: [2,3,4,5,6,7,8,9,10,11,12],
    habitCoins: 999999,
  }));
});

test('tienda: compra válida descuenta exactamente el precio', async () => {
  await seedUser('alice', { habitCoins: 250, shopInventory: [] });
  await assertSucceeds(updateDoc(doc(as('alice'), 'users', 'alice'), {
    habitCoins: 130,
    shopInventory: ['avatar_frame'],
  }));
});

test('tienda: una compra sin descontar monedas se rechaza', async () => {
  await seedUser('alice', { habitCoins: 250, shopInventory: [] });
  await assertFails(updateDoc(doc(as('alice'), 'users', 'alice'), {
    habitCoins: 250,
    shopInventory: ['avatar_frame'],
  }));
});

test('tienda: equipar un artículo que no se compró se rechaza', async () => {
  await seedUser('alice', { shopInventory: [] });
  await assertFails(updateDoc(doc(as('alice'), 'users', 'alice'), {
    shopEquipped: { perfil_marco: 'avatar_frame' },
  }));
});

test('tienda: equipar un artículo adquirido está permitido', async () => {
  await seedUser('alice', { shopInventory: ['avatar_frame'] });
  await assertSucceeds(updateDoc(doc(as('alice'), 'users', 'alice'), {
    shopEquipped: { perfil_marco: 'avatar_frame' },
  }));
});

test('datos privados: propietario accede a intentos y registros del hábito', async () => {
  const ref = doc(as('alice'),
    'users/alice/user_habits/agua/attempts/uno/logs/registro');
  await assertSucceeds(setDoc(ref, {
    note: 'Bebí agua', createdAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(ref));
});

test('datos privados: otra cuenta no accede a registros de hábitos', async () => {
  await assertFails(getDoc(doc(as('mallory'),
    'users/alice/user_habits/agua/attempts/uno/logs/registro')));
});

test('datos privados: otra cuenta no puede escribir evidencias', async () => {
  await assertFails(setDoc(doc(as('mallory'),
    'users/alice/temporary_habit_evidence/uno'), {imageBase64:'x'}));
});

test('datos privados: propietario puede escribir evidencias temporales', async () => {
  await assertSucceeds(setDoc(doc(as('alice'),
    'users/alice/temporary_habit_evidence/uno'), {
    userId: 'alice', habitId: 'agua', attemptId: 'intento',
    logId: 'uno', imageBase64: 'AQID',
    contentType: 'image/jpeg',
    createdAt: serverTimestamp(),
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
  }));
});

test('datos privados: otra cuenta no lee logros privados', async () => {
  await assertFails(getDoc(doc(as('mallory'),
    'users/alice/achievements/nivel_dos')));
});

test('datos privados: no puedo escribir logros de otra cuenta', async () => {
  await assertFails(setDoc(doc(as('mallory'),
    'users/alice/achievements/nivel_dos'), {unlocked:true}));
});

test('datos privados: propietario puede escribir sus logros', async () => {
  await assertSucceeds(setDoc(doc(as('alice'),
    'users/alice/achievements/nivel_dos'), {unlocked:true}));
});

function demoChallenge() {
  return {
    title: 'Desafío diario', status: 'available',
    currentProgress: 0, totalProgress: 5,
    xpReward: 10, hcReward: 5,
    demoSeed: true, progressVerified: false,
    progressSource: 'demo',
    createdAt: serverTimestamp(),
  };
}

test('desafíos: el propietario puede crear un desafío de demostración', async () => {
  await assertSucceeds(setDoc(doc(as('alice'),
    'users/alice/challenges/daily'), demoChallenge()));
});

test('desafíos: no puede sembrarse un reto marcado como verificado', async () => {
  await assertFails(setDoc(doc(as('alice'),
    'users/alice/challenges/daily'),
    { ...demoChallenge(), progressVerified: true }));
});

test('desafíos: un desafío de demostración puede aceptarse', async () => {
  await assertSucceeds(setDoc(doc(as('alice'),
    'users/alice/challenges/daily'), demoChallenge()));
  await assertSucceeds(updateDoc(doc(as('alice'),
    'users/alice/challenges/daily'), {
    status:'inProgress', acceptedAt:serverTimestamp(),
  }));
});

test('desafíos: no se puede reclamar reto demostrativo sin progreso verificado', async () => {
  await assertSucceeds(setDoc(doc(as('alice'),
    'users/alice/challenges/daily'), demoChallenge()));
  await assertFails(updateDoc(doc(as('alice'),
    'users/alice/challenges/daily'), {
    status:'claimed', claimedAt:serverTimestamp(),
  }));
});

test('desafíos: un tercero no puede crear retos en otra cuenta', async () => {
  await assertFails(setDoc(doc(as('mallory'),
    'users/alice/challenges/daily'), demoChallenge()));
});

function publicProfile() {
  return {
    name:'Alice', username:'alice', xp:0,
    settings:{ mostrarRachaAmigos:true, visibilidadLogros:'Solo amigos',
      permitirReacciones:true },
  };
}

test('perfil público: puede crearse con campos válidos', async () => {
  await seedUser();
  await assertSucceeds(setDoc(doc(as('alice'),
    'public_profiles/alice'), publicProfile()));
});

test('perfil público: una cuenta autenticada puede consultar otro perfil', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'public_profiles/alice'),
      publicProfile());
  });
  await assertSucceeds(getDoc(doc(as('bob'), 'public_profiles/alice')));
});

test('perfil público: no puede editarse el perfil de otro usuario', async () => {
  await assertFails(setDoc(doc(as('mallory'),
    'public_profiles/alice'), publicProfile()));
});

test('perfil público: no pueden publicarse claves desconocidas', async () => {
  await seedUser();
  await assertFails(setDoc(doc(as('alice'), 'public_profiles/alice'),
    { ...publicProfile(), isAdministrator:true }));
});

test('perfil público: el titular no debe poder falsificar su XP público', async () => {
  await seedUser();
  await assertFails(setDoc(doc(as('alice'), 'public_profiles/alice'),
    { ...publicProfile(), xp:999999 }));
});

test('perfiles públicos: una cuenta no autenticada no puede consultar', async () => {
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),
    'public_profiles/alice')));
});

test('sistema: los usuarios pueden leer la configuración existente', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'system', 'global'), {version:1});
  });
  await assertSucceeds(getDoc(doc(as('alice'), 'system', 'global')));
});

test('sistema: ningún usuario normal puede cambiar la configuración', async () => {
  await assertFails(setDoc(doc(as('alice'), 'system', 'global'),
    { isAdmin:true }));
});

test('agregados: el cliente no puede fabricar popularidad pública', async () => {
  await assertFails(setDoc(doc(as('alice'),
    'public_habit_popularity', 'agua'), { users:999999 }));
});

test('agregados: la consulta de popularidad pública está permitida', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'public_habit_popularity', 'agua'),
      { users:10 });
  });
  await assertSucceeds(getDoc(doc(as('alice'),
    'public_habit_popularity', 'agua')));
});

test('integridad: usuario anónimo no puede crear solicitudes', async () => {
  const db=env.unauthenticatedContext().firestore();
  await assertFails(setDoc(doc(db, 'users/bob/solicitudes/alice'),
    { createdAt:serverTimestamp() }));
});

test('interacciones: el receptor puede marcar una reacción como leída', async () => {
  await seedFriendship();
  await assertSucceeds(setDoc(doc(as('alice'), 'interactions', 'reaction-r'), {
    challengeId:'', createdAt:new Date(), emoji:'👏', estado:'enviado',
    fromUid:'alice', leido:false, respondedAt:null, tipo:'reaccion',
    toUid:'bob',
  }));
  await assertSucceeds(updateDoc(doc(as('bob'), 'interactions', 'reaction-r'),
    {leido:true}));
});

test('interacciones: el remitente no puede marcar como leída su reacción', async () => {
  await seedFriendship();
  await assertSucceeds(setDoc(doc(as('alice'), 'interactions', 'reaction-r'), {
    challengeId:'', createdAt:new Date(), emoji:'👏', estado:'enviado',
    fromUid:'alice', leido:false, respondedAt:null, tipo:'reaccion',
    toUid:'bob',
  }));
  await assertFails(updateDoc(doc(as('alice'), 'interactions', 'reaction-r'),
    {leido:true}));
});

test('interacciones: consulta del destinatario filtrada por su UID', async () => {
  await seedFriendship();
  await assertSucceeds(setDoc(doc(as('alice'), 'interactions', 'reaction-r'), {
    challengeId:'', createdAt:new Date(), emoji:'👏', estado:'enviado',
    fromUid:'alice', leido:false, respondedAt:null, tipo:'reaccion',
    toUid:'bob',
  }));
  await assertSucceeds(getDocs(query(
    collection(as('bob'), 'interactions'),where('toUid','==','bob'))));
  await assertFails(getDocs(collection(as('mallory'), 'interactions')));
});

test('sistema anterior: no deben poder crearse nuevas relaciones following', async () => {
  await assertFails(setDoc(doc(as('alice'),
    'users/alice/following/bob'), {createdAt:serverTimestamp()}));
});

test('sistema anterior: no deben poder crearse nuevas relaciones followers', async () => {
  await assertFails(setDoc(doc(as('bob'),
    'users/bob/followers/alice'), {createdAt:serverTimestamp()}));
});

/* Requisitos de integridad de gamificación. Las reglas actuales
 * permitirán varias de estas acciones: los fallos son hallazgos de
 * seguridad, no problemas del test. Evitar producción hasta resolverlos.
 */

test('integridad: no puedo falsificar la finalización de mi hábito', async () => {
  await seedUser();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice/user_habits/agua'),
      { latestStatus: 'inProgress', latestProgress: 0, latestTarget: 5 });
  });
  await assertFails(updateDoc(doc(as('alice'),
    'users/alice/user_habits/agua'), {
    latestStatus: 'completed', latestProgress: 5,
  }));
});

test('integridad: no puedo acreditar a mano un intento completado', async () => {
  await seedUser();
  const ref = 'users/alice/user_habits/agua/attempts/primero';
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), ref), {
      status: 'inProgress', progress: 0, target: 5, xpEarned: 0,
    });
  });
  await assertFails(updateDoc(doc(as('alice'), ref), {
    status: 'completed', progress: 5, xpEarned: 5000,
  }));
});

test('integridad: un registro fabricado no debe acreditar XP', async () => {
  await seedUser();
  const db = as('alice');
  await assertFails(setDoc(doc(db,
    'users/alice/user_habits/agua/attempts/primero/logs/falso'), {
    xpEarned: 5000, progressAfter: 5, completed: true,
    userId: 'alice', createdAt:serverTimestamp(),
  }));
});

test('integridad: no se pueden registrar logros falsos de otra cuenta', async () => {
  await assertFails(setDoc(doc(as('mallory'),
    'users/alice/achievements/estrella'), { unlocked:true, xpReward:500 }));
});

test('integridad: una cuenta no debe autoadjudicarse un logro premium', async () => {
  await seedUser();
  await assertFails(setDoc(doc(as('alice'),
    'users/alice/achievements/premium'), {
    unlocked: true, verified: true, xpReward: 9999,
  }));
});

test('integridad: no se pueden publicar estadísticas manipuladas', async () => {
  await seedUser();
  await assertFails(updateDoc(doc(as('alice'), 'users', 'alice'), {
    completedHabits: 99999,
    currentStreak: 99999,
  }));
});

test('stickers: un artículo no comprado no puede enviarse como reacción', async () => {
  await seedFriendship();
  await assertFails(setDoc(doc(as('alice'), 'interactions', 'sticker-unowned'), {
    challengeId: 'sticker:reaction_like', createdAt: new Date(),
    emoji: '🔥', estado: 'enviado', fromUid: 'alice',
    leido: false, respondedAt: null, tipo: 'reaccion', toUid: 'bob',
  }));
});

test('stickers: un artículo comprado admite el emoji oficial', async () => {
  await seedFriendship();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), {
      shopInventory: ['reaction_like'],
    });
  });
  await assertSucceeds(setDoc(doc(as('alice'), 'interactions', 'sticker-owned'), {
    challengeId: 'sticker:reaction_like', createdAt: new Date(),
    emoji: '🔥', estado: 'enviado', fromUid: 'alice',
    leido: false, respondedAt: null, tipo: 'reaccion', toUid: 'bob',
  }));
});

test('stickers: no se puede usar emoji distinto al artículo comprado', async () => {
  await seedFriendship();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), {
      shopInventory: ['reaction_like'],
    });
  });
  await assertFails(setDoc(doc(as('alice'), 'interactions', 'sticker-mismatch'), {
    challengeId: 'sticker:reaction_like', createdAt: new Date(),
    emoji: '🎉', estado: 'enviado', fromUid: 'alice',
    leido: false, respondedAt: null, tipo: 'reaccion', toUid: 'bob',
  }));
});
