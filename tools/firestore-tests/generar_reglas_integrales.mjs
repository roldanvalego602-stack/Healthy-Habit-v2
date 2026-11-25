// Genera reglas de laboratorio antes de iniciar Firestore Emulator.
// Nunca se debe desplegar este archivo o utilizar en Firebase real.
import {writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {releasePreviewRules} from './release_preview_rules.mjs';

if (process.env.GCLOUD_PROJECT &&
    process.env.GCLOUD_PROJECT !== 'demo-healthy-habit') {
  throw new Error('Solo se permite generar reglas para demo-healthy-habit.');
}
const target = resolve(
  new URL('../../.firebase-lockdown-preview.rules', import.meta.url).pathname,
);
writeFileSync(target, releasePreviewRules(), {encoding: 'utf8', mode: 0o600});
console.log('Reglas restrictivas temporales generadas para la base nombrada default.');
