// RELEASE GATE: these tests MUST pass before production deployment.
// They document missing server-authoritative economy and achievements.
// A failure is evidence that these rules are NOT ready to publish.
import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { releasePreviewRules } from './release_preview_rules.mjs';
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
      rules: process.env.HH_RELEASE_PREVIEW === '1'
        ? releasePreviewRules()
        : readFileSync(resolve(new URL('../../firestore.candidate.rules', import.meta.url).pathname), 'utf8'),
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

test('BLOQUEANTE: incrementar solo XP, aun en un valor pequeño, es indebido', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), {
      uid: 'alice', name: 'Alice', xp: 0, currentXp: 0,
      level: 1, habitCoins: 100, shopInventory: [],
    });
  });
  await assertFails(updateDoc(doc(alice(), 'users/alice'), {xp: 1}));
});

test('BLOQUEANTE: incrementar solo monedas no requiere combinar otros campos', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), {
      uid: 'alice', name: 'Alice', xp: 0, currentXp: 0,
      level: 1, habitCoins: 100, shopInventory: [],
    });
  });
  await assertFails(updateDoc(doc(alice(), 'users/alice'), {habitCoins: 101}));
});

test('BLOQUEANTE: el cliente no puede inventar una racha histórica', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), {
      uid: 'alice', name: 'Alice', xp: 0, currentStreak: 0,
      streakDays: 0, longestStreak: 0,
      lastStreakDate: '2026-11-23', habitCoins: 100,
    });
  });
  await assertFails(updateDoc(doc(alice(), 'users/alice'), {
    currentStreak: 1000,
    streakDays: 1000,
    longestStreak: 1000,
    lastStreakDate: '2026-11-24',
  }));
});

test('BLOQUEANTE: no se pueden fabricar logs aunque el intento ya exista', async () => {
  const parent = 'users/alice/user_habits/hidr_001/attempts/one';
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), parent), {
      status: 'inProgress', progress: 0, target: 1,
    });
  });
  await assertFails(setDoc(doc(alice(), parent + '/logs/forged'), {
    userId: 'alice', xpEarned: 10000,
    completed: true, progressAfter: 1,
  }));
});

test('BLOQUEANTE: no se puede falsificar nivel sin cambiar XP', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), {
      uid: 'alice', name: 'Alice', xp: 0,
      level: 1, habitCoins: 100,
    });
  });
  await assertFails(updateDoc(doc(alice(), 'users/alice'), {level: 20}));
});

test('BLOQUEANTE: ningún cliente puede insertar recompensa diaria', async () => {
  await assertFails(setDoc(doc(alice(),
    'users/alice/daily_streak_days/2026-11-24'), {
    day: '2026-11-24', streak: 1,
    rewardCoins: 200, claimed: false,
  }));
});
