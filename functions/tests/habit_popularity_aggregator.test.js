"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  aggregateActiveHabits,
  parseHabitPath,
} = require("../habit_popularity_aggregator");

test("acepta únicamente la ruta canónica de usuarios y el catálogo", () => {
  assert.deepEqual(parseHabitPath("users/u1/user_habits/alim_001"),
    {uid: "u1", habitId: "alim_001"});
  assert.equal(parseHabitPath("other/u1/user_habits/alim_001"), null);
  assert.equal(parseHabitPath("users/u1/private/user_habits/alim_001"), null);
  assert.equal(parseHabitPath("users/u1/user_habits/custom_1"), null);
});

test("publica exclusivamente hábitos con cinco usuarios activos", () => {
  const docs = Array.from({length: 5}, (_, i) => ({
    path: `users/user${i}/user_habits/hidr_001`,
    data: {latestStatus: "inProgress"},
  }));
  docs.push({
    path: "users/u6/user_habits/hidr_002",
    data: {latestStatus: "completed"},
  });
  docs.push({
    path: "users/u7/user_habits/hidr_002",
    data: {latestStatus: "inProgress"},
  });
  assert.deepEqual(aggregateActiveHabits(docs), [
    {habitId: "hidr_001", activeUsers: 5},
  ]);
});

test("deduplica usuarios y descarta intents no activos", () => {
  const docs = [
    {path: "users/a/user_habits/bien_001", data: {latestStatus: "inProgress"}},
    {path: "users/a/user_habits/bien_001", data: {latestStatus: "inProgress"}},
    {path: "users/b/user_habits/bien_001", data: {latestStatus: "cancelled"}},
  ];
  assert.deepEqual(aggregateActiveHabits(docs, 2), []);
});

test("rechaza umbrales no seguros", () => {
  assert.throws(() => aggregateActiveHabits([], 1), TypeError);
});
