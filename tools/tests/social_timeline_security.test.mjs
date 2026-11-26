import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const read = (file) => readFileSync(file, 'utf8');
const backend = read('functions/habit_registration_transaction.js');
const rules = read('firestore.candidate.rules');
const feed = read('lib/páginas/perfil/feed_amigos_screen.dart');
const picker = read('lib/páginas/perfil/reaction_picker_dialog.dart');

test('el servidor origina los niveles y logros verificables, no Flutter', () => {
  assert.match(backend, /mode === "official"/);
  assert.match(backend, /kind: "level_up"/);
  assert.match(backend, /kind: "achievement_unlocked"/);
  assert.match(backend, /verifiedCompletedHabits/);
  assert.doesNotMatch(backend, /kind: "habit_completed"/);
  assert.match(backend, /"level_" \+ logRef\.id/);
});

test('la cronología es de solo lectura para clientes y amistades recíprocas', () => {
  assert.match(rules, /match \/activity_events\/\{eventId\}/);
  assert.match(rules, /allow create, update, delete: if false;/);
  assert.match(rules, /exists\(friendsRef\(request\.auth\.uid, uid\)\)/);
  assert.match(rules, /exists\(friendsRef\(uid, request\.auth\.uid\)\)/);
  assert.match(rules, /activity_events\/\$\(request\.resource\.data\.challengeId\)/);
});

test('el feed no inventa la hora de logros y permite reaccionar a su ID', () => {
  assert.match(feed, /orderBy\('createdAt', descending: true\)/);
  assert.match(feed, /data\['createdAt'\] is! Timestamp/);
  assert.match(feed, /achievement_unlocked/);
  assert.match(feed, /eventId: event\.eventId/);
  assert.match(picker, /widget\.eventId!/);
});
