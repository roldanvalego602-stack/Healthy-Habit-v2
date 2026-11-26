import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';

const read = (path) => readFileSync(resolve(process.cwd(), path), 'utf8');
const action = read('lib/páginas/habitos/habit_action_service.dart');
const registration = read('lib/páginas/habitos/registrar_habito_screen.dart');
const gateway = read('lib/servicios/beta_habit_gateway.dart');

test('activación y cancelación beta se despachan antes de la ruta directa', () => {
  const start = action.indexOf('Future<HabitActionResult> execute(');
  const beta = action.indexOf('if (BetaHabitGateway.enabled)', start);
  const pending = action.indexOf('PendingBetaHabitOperations().execute(', beta);
  const endBeta = action.indexOf('return HabitActionResult(', pending);
  const direct = action.indexOf('_db.runTransaction', beta);
  assert.ok(start >= 0 && beta > start && pending > beta);
  assert.ok(endBeta > pending && direct > endBeta);
  assert.match(action.slice(beta, direct), /action: preview\.remove \? 'cancelar' : 'activar'/);
  assert.match(action.slice(beta, direct), /attemptId: preview\.attemptId/);
  assert.match(action.slice(beta, direct), /maxPenalty: preview\.remove \? preview\.estimatedCost : null/);
});

test('registro beta usa operación persistida antes de las escrituras heredadas', () => {
  const start = registration.indexOf('Future<void> _guardarRegistro()');
  const branch = registration.indexOf('if (OfficialHabitEmulatorService.enabled || BetaHabitGateway.enabled)', start);
  const pending = registration.indexOf('PendingBetaHabitOperations().execute(', branch);
  const direct = registration.indexOf('_db.runTransaction', start);
  assert.ok(start >= 0 && branch > start && pending > branch && direct > pending);
  assert.match(registration.slice(branch, direct), /action: 'registrar'/);
  assert.match(registration.slice(branch, direct), /habitId: habitoRef\.id/);
  assert.match(registration.slice(branch, direct), /attemptId: attemptRef\.id/);
  assert.match(registration.slice(branch, direct), /BetaHabitGateway\.enabled && photoBytes != null/);
});

test('gateway beta valida proyecto, sesión y no permite volver al cliente directo', () => {
  assert.match(gateway, /static const enabled = bool\.fromEnvironment\(/);
  assert.match(gateway, /defaultValue: false/);
  assert.match(gateway, /Firebase\.app\(\)\.options\.projectId != projectId/);
  assert.match(gateway, /FirebaseAuth\.instance\.currentUser\?\.uid != originalUser/);
  assert.match(gateway, /'activar': 'activateOfficialHabitBeta'/);
  assert.match(gateway, /'cancelar': 'cancelOfficialHabitBeta'/);
  assert.match(gateway, /'registrar': 'registerOfficialHabitBeta'/);
});
