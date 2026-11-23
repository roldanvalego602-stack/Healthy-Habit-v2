"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  validateClaimDay, claimDailyStreakRewardTransaction,
  DailyStreakClaimError,
} = require("../streak_claim_transaction");

test("validación acepta únicamente días reales YYYY-MM-DD", () => {
  assert.equal(validateClaimDay("2026-11-22"), "2026-11-22");
  for (const invalid of ["2026-02-30", "2026-13-01",
    "22-11-2026", "2026/11/22", "../2026", "", null, 123]) {
    assert.throws(() => validateClaimDay(invalid), DailyStreakClaimError);
  }
});

test("reclamar sin sesión o con fecha adulterada falla antes de leer DB",
  async () => {
    const db = {};
    await assert.rejects(
      claimDailyStreakRewardTransaction({db, uid: "", day: "2026-11-22"}),
      (error) => error.code === "unauthenticated"
    );
    await assert.rejects(
      claimDailyStreakRewardTransaction({
        db, uid: "valid_user", day: "2026-11-31",
      }),
      (error) => error.code === "invalid-argument"
    );
  }
);
