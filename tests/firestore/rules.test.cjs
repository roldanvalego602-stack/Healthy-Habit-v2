'use strict';

const { before, after, test } = require('node:test');
const assert = require('node:assert/strict');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, getDocs, collection, writeBatch, serverTimestamp, deleteDoc, arrayUnion, query, where } = require('firebase/firestore');
const fs = require('node:fs');
const path = require('node:path');

let env;
let alice;
let bob;
let anonymous;
let buyer;
let economy;

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
  buyer = env.authenticatedContext('buyer').firestore();
  economy = env.authenticatedContext('economy').firestore();

  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/alice'), {
      name: 'Alice', xp: 50, habitCoins: 10,
    });
    await setDoc(doc(db, 'users/economy'), {
      name: 'Economy', xp: 0, currentXp: 0,
      level: 1, habitCoins: 50,
      currentStreak: 0, streakDays: 0,
    });
    await setDoc(doc(db, 'users/economy/user_habits/water'), {
      title: 'Tomar agua', latestStatus: 'inProgress',
    });
    await setDoc(doc(db, 'users/economy/user_habits/water/attempts/a1'), {
      status: 'inProgress', progress: 0, target: 6, xpEarned: 0,
    });
    await setDoc(doc(db, 'users/economy/challenges/c1'), {
      status: 'completed', xpReward: 40, hcReward: 10,
      currentProgress: 5, totalProgress: 5,
      demoSeed: false, progressVerified: true,
      progressSource: 'habit_records',
    });
    await setDoc(doc(db, 'users/buyer'), {
      name: 'Buyer', xp: 0, habitCoins: 500,
      shopInventory: [], shopEquipped: {},
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
    await setDoc(doc(db, 'public_profiles/alice'), {
      name: 'Alice', username: 'alice', xp: 50,
      settings: { mostrarRachaAmigos: true, visibilidadLogros: 'Todos' },
    });
    await setDoc(doc(db, 'public_profiles/bob'), {
      name: 'Bob', username: 'bob', xp: 100,
      settings: { mostrarRachaAmigos: false, visibilidadLogros: 'Solo amigos' },
    });
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

test('perfiles públicos son legibles para otros usuarios autenticados', async () => {
  await assertSucceeds(getDoc(doc(alice, 'public_profiles/bob')));
  await assertSucceeds(getDocs(collection(alice, 'public_profiles')));
  await assertFails(getDoc(doc(anonymous, 'public_profiles/bob')));
});

test('un usuario no puede modificar el perfil público ajeno', async () => {
  await assertFails(updateDoc(doc(alice, 'public_profiles/bob'), { xp: 9999 }));
  await assertSucceeds(updateDoc(doc(alice, 'public_profiles/alice'), { xp: 51 }));
});

test('campos privados no se pueden introducir en perfiles públicos', async () => {
  await assertFails(updateDoc(doc(alice, 'public_profiles/alice'), {
    email: 'private@example.test',
  }));
  await assertFails(updateDoc(doc(alice, 'public_profiles/alice'), {
    settings: { analizarHistorialIA: true },
  }));
});

test('solicitud se envía en batch y destinatario puede leerla', async () => {
  const batch = writeBatch(alice);
  batch.set(doc(alice, 'users/bob/solicitudes/alice'), {
    createdAt: serverTimestamp(),
  });
  batch.set(doc(alice, 'users/alice/solicitudes_enviadas/bob'), {
    createdAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(doc(bob, 'users/bob/solicitudes/alice')));
  await assertFails(getDoc(doc(alice, 'users/bob/solicitudes/alice')));
});

test('solicitudes unilaterales, falsificadas o entre terceros están prohibidas', async () => {
  await assertFails(setDoc(doc(alice, 'users/bob/solicitudes/alice'), {
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(alice, 'users/bob/solicitudes/charlie'), {
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(alice, 'users/alice/solicitudes_enviadas/bob'), {
    createdAt: serverTimestamp(),
  }));
});

test('no se puede seguir sin solicitud previa aceptada', async () => {
  await assertFails(setDoc(doc(alice, 'users/alice/following/bob'), {
    createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(bob, 'users/bob/followers/alice'), {
    createdAt: serverTimestamp(),
  }));
});

test('el destinatario acepta solicitud y se crean ambos reflejos de seguimiento', async () => {
  const batch = writeBatch(bob);
  batch.set(doc(bob, 'users/alice/following/bob'), {
    createdAt: serverTimestamp(),
  });
  batch.set(doc(bob, 'users/bob/followers/alice'), {
    createdAt: serverTimestamp(),
  });
  batch.delete(doc(bob, 'users/bob/solicitudes/alice'));
  batch.delete(doc(bob, 'users/alice/solicitudes_enviadas/bob'));
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(doc(alice, 'users/alice/following/bob')));
  await assertSucceeds(getDoc(doc(bob, 'users/bob/followers/alice')));
});

test('no es posible crear seguidores unilateralmente ni leer listas privadas ajenas', async () => {
  await assertFails(setDoc(doc(alice, 'users/bob/followers/alice'), {
    createdAt: serverTimestamp(),
  }));
  await assertFails(getDocs(collection(alice, 'users/bob/followers')));
});

test('el emisor puede cancelar una solicitud eliminando ambos reflejos', async () => {
  const send = writeBatch(bob);
  send.set(doc(bob, 'users/alice/solicitudes/bob'), {
    createdAt: serverTimestamp(),
  });
  send.set(doc(bob, 'users/bob/solicitudes_enviadas/alice'), {
    createdAt: serverTimestamp(),
  });
  await assertSucceeds(send.commit());

  await assertFails(deleteDoc(doc(bob, 'users/alice/solicitudes/bob')));

  const cancel = writeBatch(bob);
  cancel.delete(doc(bob, 'users/alice/solicitudes/bob'));
  cancel.delete(doc(bob, 'users/bob/solicitudes_enviadas/alice'));
  await assertSucceeds(cancel.commit());
  assert.equal((await getDoc(doc(alice, 'users/alice/solicitudes/bob'))).exists(), false);
  assert.equal((await getDoc(doc(bob, 'users/bob/solicitudes_enviadas/alice'))).exists(), false);
});

test('el destinatario puede rechazar una solicitud eliminando ambos reflejos', async () => {
  const send = writeBatch(alice);
  send.set(doc(alice, 'users/bob/solicitudes/alice'), {
    createdAt: serverTimestamp(),
  });
  send.set(doc(alice, 'users/alice/solicitudes_enviadas/bob'), {
    createdAt: serverTimestamp(),
  });
  await assertSucceeds(send.commit());

  const reject = writeBatch(bob);
  reject.delete(doc(bob, 'users/bob/solicitudes/alice'));
  reject.delete(doc(bob, 'users/alice/solicitudes_enviadas/bob'));
  await assertSucceeds(reject.commit());
  assert.equal((await getDoc(doc(bob, 'users/bob/solicitudes/alice'))).exists(), false);
  assert.equal((await getDoc(doc(alice, 'users/alice/solicitudes_enviadas/bob'))).exists(), false);
});

test('no se puede borrar sólo un reflejo del seguimiento', async () => {
  await assertFails(deleteDoc(doc(alice, 'users/alice/following/bob')));
  await assertFails(deleteDoc(doc(bob, 'users/bob/followers/alice')));
});

test('el seguidor puede dejar de seguir borrando los dos documentos', async () => {
  const batch = writeBatch(alice);
  batch.delete(doc(alice, 'users/alice/following/bob'));
  batch.delete(doc(alice, 'users/bob/followers/alice'));
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(doc(alice, 'users/alice/following/bob'))).exists(), false);
  assert.equal((await getDoc(doc(bob, 'users/bob/followers/alice'))).exists(), false);
});

test('compra legítima descuenta el precio real del catálogo', async () => {
  await assertSucceeds(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 320,
    shopInventory: arrayUnion('crown'),
  }));
  const result = await getDoc(doc(buyer, 'users/buyer'));
  assert.equal(result.data().habitCoins, 320);
  assert.deepEqual(result.data().shopInventory, ['crown']);
});

test('se rechazan inventario gratis, precio reducido y artículo inexistente', async () => {
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    shopInventory: arrayUnion('cape'),
  }));
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 310,
    shopInventory: arrayUnion('cape'),
  }));
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 300,
    shopInventory: arrayUnion('desconocido'),
  }));
});

test('se rechaza adquirir varios productos en la misma actualización', async () => {
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 100,
    shopInventory: arrayUnion('mint_scarf', 'cape'),
  }));
});

test('no se puede comprar dos veces un artículo ya adquirido', async () => {
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 140,
    shopInventory: arrayUnion('crown'),
  }));
});

test('el saldo del propio usuario sigue siendo falsificable: riesgo pendiente', async () => {
  // Este éxito NO es deseable en una solución final. Documenta explícitamente
  // que el cliente aún puede inflar Habit Coins sin tocar el inventario.
  await assertSucceeds(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 100000,
  }));
  await assertSucceeds(updateDoc(doc(buyer, 'users/buyer'), {
    xp: 999999,
  }));
});

test('no se pueden descontar monedas sin añadir una compra válida', async () => {
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 25,
  }));
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 25,
    shopInventory: ['crown'],
  }));
});

test('una compra no puede introducir otros cambios de perfil o XP', async () => {
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 300,
    shopInventory: arrayUnion('cape'),
    xp: 300000,
  }));
});

test('compras malformadas no permiten introducir inventario de otro tipo', async () => {
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    shopInventory: 'crown',
    habitCoins: 0,
  }));
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    shopInventory: { crown: true },
    habitCoins: 0,
  }));
});

test('saldo sin inventario y campos externos a la compra siguen sujetos a validación', async () => {
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 1,
    shopInventory: null,
  }));
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    habitCoins: 1,
    shopInventory: arrayUnion('cap'),
    level: 999,
  }));
});

test('regresión: un registro legítimo puede actualizar XP e intento en una transacción', async () => {
  const batch = writeBatch(economy);
  batch.update(doc(economy, 'users/economy'), {
    xp: 10, currentXp: 10, level: 1,
    habitCoins: 50, currentStreak: 1, streakDays: 1,
  });
  batch.update(doc(economy, 'users/economy/user_habits/water/attempts/a1'), {
    progress: 1, xpEarned: 10,
  });
  batch.set(doc(economy, 'users/economy/user_habits/water/attempts/a1/logs/log1'), {
    xpEarned: 10, progressAfter: 1, userId: 'economy',
  });
  await assertSucceeds(batch.commit());
});

test('regresión: reclamar desafío completado mantiene la actualización de XP y HC', async () => {
  const batch = writeBatch(economy);
  batch.update(doc(economy, 'users/economy'), {
    xp: 50, habitCoins: 60,
  });
  batch.update(doc(economy, 'users/economy/challenges/c1'), {
    status: 'claimed', claimedAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
});

test('un usuario no puede crear un desafío completado y con premios falsos', async () => {
  await assertFails(setDoc(doc(economy, 'users/economy/challenges/forged'), {
    status: 'completed', xpReward: 999999, hcReward: 999999,
    currentProgress: 1, totalProgress: 1, progressVerified: true,
    progressSource: 'habit_records', demoSeed: false,
    createdAt: serverTimestamp(),
  }));
});

test('se permite sembrar y aceptar un desafío demostrativo legítimo', async () => {
  const ref = doc(economy, 'users/economy/challenges/demo1');
  await assertSucceeds(setDoc(ref, {
    title: 'Hidratación constante',
    status: 'available', currentProgress: 0, totalProgress: 7,
    xpReward: 80, hcReward: 25,
    demoSeed: true, progressVerified: false, progressSource: 'demo',
    createdAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref, {
    status: 'inProgress', acceptedAt: serverTimestamp(),
  }));
});

test('no se permite modificar premios ni validar fraudulentamente un desafío demo', async () => {
  const ref = doc(economy, 'users/economy/challenges/demo1');
  await assertFails(updateDoc(ref, { xpReward: 999999 }));
  await assertFails(updateDoc(ref, {
    progressVerified: true,
    progressSource: 'habit_records',
    demoSeed: false,
  }));
  await assertFails(updateDoc(ref, { status: 'completed', currentProgress: 7 }));
});

test('un usuario no puede suprimir desafíos para recrearlos a voluntad', async () => {
  await assertFails(deleteDoc(doc(economy, 'users/economy/challenges/demo1')));
});

test('el cliente no puede generar desafíos inicialmente verificados', async () => {
  await assertFails(setDoc(doc(economy, 'users/economy/challenges/forgedVerified'), {
    title: 'Trampa',
    status: 'available', currentProgress: 0, totalProgress: 1,
    xpReward: 40, hcReward: 10,
    demoSeed: false, progressVerified: true,
    progressSource: 'habit_records', createdAt: serverTimestamp(),
  }));
});

test('un usuario puede enviar una reacción con campos legítimos', async () => {
  await assertSucceeds(setDoc(doc(alice, 'interactions/reaction-1'), {
    challengeId: '', createdAt: serverTimestamp(), emoji: '👏',
    estado: 'enviado', fromUid: 'alice', leido: false,
    respondedAt: null, tipo: 'reaccion', toUid: 'bob',
  }));
});

test('destinatario puede consultar sus reacciones, terceros no', async () => {
  await assertSucceeds(getDoc(doc(bob, 'interactions/reaction-1')));
  await assertSucceeds(getDocs(query(collection(bob, 'interactions'),
    where('toUid', '==', 'bob'))));
  await assertFails(getDoc(doc(alice, 'interactions/reaction-1')));
  await assertFails(getDocs(collection(bob, 'interactions')));
  await assertFails(getDocs(query(collection(alice, 'interactions'),
    where('toUid', '==', 'bob'))));
});

test('no se pueden suplantar remitentes ni enviar reacciones fraudulentas', async () => {
  await assertFails(setDoc(doc(alice, 'interactions/reaction-forged'), {
    challengeId: '', createdAt: serverTimestamp(), emoji: '👏',
    estado: 'enviado', fromUid: 'bob', leido: false,
    respondedAt: null, tipo: 'reaccion', toUid: 'alice',
  }));
  await assertFails(setDoc(doc(alice, 'interactions/reaction-reward'), {
    challengeId: '', createdAt: serverTimestamp(), emoji: '👏',
    estado: 'aceptado', fromUid: 'alice', leido: false,
    respondedAt: null, tipo: 'reaccion', toUid: 'bob',
  }));
});

test('destinatario puede marcar como leída y responder a una reacción', async () => {
  await assertSucceeds(updateDoc(doc(bob, 'interactions/reaction-1'), {
    leido: true,
  }));
  await assertSucceeds(updateDoc(doc(bob, 'interactions/reaction-1'), {
    estado: 'aceptado', respondedAt: serverTimestamp(),
  }));
});

test('nadie puede reasignar destinatario ni eliminar una reacción', async () => {
  await assertFails(updateDoc(doc(bob, 'interactions/reaction-1'), {
    toUid: 'alice',
  }));
  await assertFails(updateDoc(doc(alice, 'interactions/reaction-1'), {
    leido: false,
  }));
  await assertFails(deleteDoc(doc(bob, 'interactions/reaction-1')));
});

test('integración: equipar artículos propios modifica solo el perfil privado', async () => {
  await assertSucceeds(updateDoc(doc(buyer, 'users/buyer'), {
    shopEquipped: { cabeza: 'crown' },
  }));
  await assertFails(updateDoc(doc(alice, 'users/buyer'), {
    shopEquipped: { cabeza: 'crown' },
  }));
});

test('integración: actualizar nombre y preferencias del perfil no necesita modificar economía', async () => {
  await assertSucceeds(updateDoc(doc(economy, 'users/economy'), {
    name: 'Nuevo nombre',
    settings: { mostrarRachaAmigos: false },
  }));
  await assertFails(updateDoc(doc(bob, 'users/economy'), {
    name: 'Suplantación',
  }));
});

test('integración: evidencias temporales siguen privadas y son eliminables por su dueño', async () => {
  const ref = doc(economy, 'users/economy/temporary_habit_evidence/e-1');
  await assertSucceeds(setDoc(ref, {
    userId: 'economy', imageBase64: 'imagen-de-prueba',
  }));
  await assertFails(getDoc(doc(bob, 'users/economy/temporary_habit_evidence/e-1')));
  await assertSucceeds(deleteDoc(ref));
});

test('integración: progreso y logs anidados son legibles únicamente para su propietario', async () => {
  const attempt = doc(economy, 'users/economy/user_habits/water/attempts/a1');
  const logs = collection(economy,
    'users/economy/user_habits/water/attempts/a1/logs');
  await assertSucceeds(getDoc(attempt));
  await assertSucceeds(getDocs(logs));
  await assertFails(getDoc(doc(bob, 'users/economy/user_habits/water/attempts/a1')));
  await assertFails(getDocs(collection(bob,
    'users/economy/user_habits/water/attempts/a1/logs')));
});

test('alta legítima de perfil comienza con 0 XP y 100 Habit Coins', async () => {
  const ref = doc(env.authenticatedContext('newbie').firestore(), 'users/newbie');
  await assertSucceeds(setDoc(ref, {
    uid: 'newbie', name: 'Nuevo usuario', username: 'newbie',
    email: 'newbie@example.test', level: 1, xp: 0,
    habitCoins: 100, currentStreak: 0,
    createdAt: serverTimestamp(),
  }));
});

test('el alta no puede fabricar XP, monedas ni inventario', async () => {
  const ref = doc(env.authenticatedContext('cheater').firestore(), 'users/cheater');
  const base = {
    uid: 'cheater', name: 'Cheater', username: 'cheater',
    email: 'cheater@example.test', level: 1, xp: 0,
    habitCoins: 100, currentStreak: 0,
    createdAt: serverTimestamp(),
  };
  await assertFails(setDoc(ref, { ...base, xp: 100000 }));
  await assertFails(setDoc(ref, { ...base, habitCoins: 9999 }));
  await assertFails(setDoc(ref, { ...base, shopInventory: ['crown'] }));
  await assertFails(setDoc(ref, { ...base, uid: 'otro' }));
});

test('se puede equipar una prenda gratuita sin comprarla', async () => {
  await assertSucceeds(updateDoc(doc(economy, 'users/economy'), {
    shopEquipped: { ojos: 'sunglasses', cuello: 'bandana' },
  }));
});

test('el equipamiento rechaza artículos no adquiridos y ranuras incorrectas', async () => {
  await assertFails(updateDoc(doc(economy, 'users/economy'), {
    shopEquipped: { cabeza: 'crown' },
  }));
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    shopEquipped: { cuello: 'crown' },
  }));
  await assertFails(updateDoc(doc(buyer, 'users/buyer'), {
    shopEquipped: { cabeza: 'item_falso' },
  }));
});

test('equipar y restablecer el aspecto conserva la propiedad comprada', async () => {
  const ref = doc(buyer, 'users/buyer');
  await assertSucceeds(updateDoc(ref, {
    shopEquipped: { cabeza: 'crown', ojos: 'sunglasses' },
  }));
  await assertSucceeds(updateDoc(ref, { shopEquipped: {} }));
  const state = (await getDoc(ref)).data();
  assert.deepEqual(state.shopInventory, ['crown']);
});
