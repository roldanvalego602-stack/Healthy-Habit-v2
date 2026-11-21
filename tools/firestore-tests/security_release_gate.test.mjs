// RELEASE GATE: these tests MUST pass before production deployment.
// They document missing server-authoritative economy and achievements.
// A failure is evidence that these rules are NOT ready to publish.
import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  initializeTestEnvironment, assertFails,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';

let env;
const alice = () => env.authenticatedContext('alice').firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-healthy-habit',
    firestore: {
      host: '127.0.0.1', port: 8080,
      rules: readFileSync(resolve(process.cwd(),
        'firestore.candidate.rules'), 'utf8'),
    },
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => { if (env) await env.cleanup(); });

test('BLOQUEANTE: nadie puede concederse XP o monedas arbitrarias', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), {
      uid: 'alice', name: 'Alice', xp: 0, currentXp: 0,
      level: 1, habitCoins: 100, shopInventory: [],
    });
  });
  await assertFails(updateDoc(doc(alice(), 'users/alice'), {
    xp: 100000, currentXp: 100000, level: 20, habitCoins: 999999,
  }));
});

test('BLOQUEANTE: no se pueden fabricar registros oficiales a voluntad', async () => {
  await assertFails(setDoc(doc(alice(),
    'users/alice/user_habits/hidr_001/attempts/forged'), {
    status: 'completed', progress: 99999, target: 1,
    xpEarned: 999999, habitId: 'hidr_001',
  }));
});

test('BLOQUEANTE: no se pueden autootorgar medallas restringidas', async () => {
  await assertFails(setDoc(doc(alice(),
    'users/alice/achievements/elite_unearned'), {
    earnedAt: new Date(), verified: true, awardedXp: 999999,
  }));
});
