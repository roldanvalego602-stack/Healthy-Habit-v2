import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';

const source = readFileSync(resolve(process.cwd(),
  'lib/páginas/desafios/desafios_screen.dart'), 'utf8');

test('desafíos nunca acreditan XP o monedas desde Flutter', () => {
  assert.doesNotMatch(source, /_db\.runTransaction\s*\(/);
  assert.doesNotMatch(source, /transaction\.(set|update)\s*\(userRef/);
  assert.match(source, /claimVerifiedChallengeBeta/);
});

test('beta desactivada impide el cobro y deshabilita la acción en la pantalla', () => {
  assert.match(source, /if \(!BetaHabitGateway\.enabled\)\s*\{\s*throw StateError/);
  assert.match(source, /onPressed:\s*!BetaHabitGateway\.enabled \|\| processing/);
  assert.match(source, /Recompensa pendiente de verificación/);
});
