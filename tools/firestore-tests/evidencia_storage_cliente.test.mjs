// Prueba aislada de Cloud Storage Security Rules con Firebase Auth real.
// Ejecución exclusiva en demo-healthy-habit y Storage Emulator local.
import {before, after, test} from 'node:test';
import assert from 'node:assert/strict';
import {initializeApp, deleteApp} from 'firebase/app';
import {getAuth, connectAuthEmulator, signInAnonymously, signOut}
  from 'firebase/auth';
import {getStorage, connectStorageEmulator, ref,
  uploadBytes, getMetadata, deleteObject} from 'firebase/storage';

const PROJECT = 'demo-healthy-habit';
const HOST = '127.0.0.1';
let apps = [];

function id() {
  return 'evidence_demo_1234567890_' +
    Math.random().toString(36).slice(2, 12).padEnd(12, 'x');
}

async function login(label) {
  const app = initializeApp({
    apiKey: 'demo-api-key',
    authDomain: PROJECT + '.firebaseapp.com',
    projectId: PROJECT,
    appId: '1:1234567890:web:abcdef1234567890',
    storageBucket: PROJECT + '.firebasestorage.app',
  }, label);
  apps.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, 'http://' + HOST + ':9099',
    {disableWarnings: true});
  const storage = getStorage(app);
  connectStorageEmulator(storage, HOST, 9199);
  const {user} = await signInAnonymously(auth);
  return {auth, storage, uid: user.uid};
}

before(() => {
  assert.equal(process.env.GCLOUD_PROJECT, PROJECT,
    'La prueba exige el proyecto demo-healthy-habit.');
  assert.ok(process.env.FIREBASE_AUTH_EMULATOR_HOST,
    'No está activo Auth Emulator.');
  assert.ok(process.env.FIREBASE_STORAGE_EMULATOR_HOST,
    'No está activo Storage Emulator.');
});

after(async () => {
  for (const app of apps) {
    const auth = getAuth(app);
    if (auth.currentUser) await signOut(auth);
    await deleteApp(app);
  }
});

test('Storage: dueño puede crear y borrar; terceros, sobreescritura y archivo inválido se bloquean', async () => {
  const owner = await login('evidence-owner');
  const outsider = await login('evidence-outsider');
  const attemptId = id();
  const evidenceId = id();
  const path = 'habit-evidence/' + owner.uid + '/' +
    attemptId + '/' + evidenceId;
  const file = ref(owner.storage, path);
  // Firma de ejemplo para el laboratorio: las reglas solo verifican
  // metadatos. Una validación real del formato requiere inspección servidor.
  const smallImage = new Uint8Array([255, 216, 255, 217]);

  await uploadBytes(file, smallImage, {contentType: 'image/jpeg'});
  const metadata = await getMetadata(file);
  assert.equal(metadata.contentType, 'image/jpeg');
  assert.equal(metadata.size, smallImage.length);

  await assert.rejects(uploadBytes(file, smallImage,
    {contentType: 'image/jpeg'}));
  await assert.rejects(getMetadata(ref(outsider.storage, path)));
  await assert.rejects(deleteObject(ref(outsider.storage, path)));

  const foreignPath = 'habit-evidence/' + outsider.uid +
    '/' + attemptId + '/' + id();
  await assert.rejects(uploadBytes(ref(owner.storage, foreignPath),
    smallImage, {contentType: 'image/jpeg'}));

  await assert.rejects(uploadBytes(ref(owner.storage,
    'habit-evidence/' + owner.uid + '/' + attemptId + '/' + id()),
  smallImage, {contentType: 'text/plain'}));

  await assert.rejects(uploadBytes(ref(owner.storage,
    'habit-evidence/' + owner.uid + '/' + attemptId + '/' + id()),
  new Uint8Array(256001), {contentType: 'image/png'}));

  await assert.rejects(uploadBytes(ref(owner.storage,
    'other-path/' + owner.uid + '/' + id()),
  smallImage, {contentType: 'image/jpeg'}));

  await deleteObject(file);
  await assert.rejects(getMetadata(file));
});
