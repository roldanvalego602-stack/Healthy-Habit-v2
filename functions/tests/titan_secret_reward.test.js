"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {normalizedAnswer, resolveAttempt, claimTitanSecret, secretDayKey, SKIN_ID} =
  require("../titan_secret_reward");

test("el acertijo acepta solo la respuesta completa y normalizada", () => {
  assert.equal(normalizedAnswer(" CONStANCIA "), "constancia");
  assert.equal(normalizedAnswer("constáncia"), "constancia");
  assert.equal(resolveAttempt({solved:false,attempts:0,answer:"constancia"}).award,true);
  assert.equal(resolveAttempt({solved:false,attempts:0,answer:"fuerza"}).award,false);
  assert.equal(resolveAttempt({solved:false,attempts:0,answer:"con stan cia"}).award,false);
});

test("la fecha del santuario respeta la medianoche de México", () => {
  assert.equal(secretDayKey(new Date("2026-11-28T04:00:00Z")),
    "2026-11-27");
  assert.equal(secretDayKey(new Date("2026-11-28T06:00:00Z")),
    "2026-11-28");
});

test("el límite de cinco intentos no concede premios adicionales", () => {
  assert.equal(resolveAttempt({solved:false,attempts:4,answer:"fallo"}).status,"locked");
  assert.equal(resolveAttempt({solved:false,attempts:5,answer:"constancia"}).award,false);
  assert.throws(()=>resolveAttempt({solved:false,attempts:-1,answer:"x"}));
});

function fakeDb(initial = {}) {
  const documents = new Map(Object.entries(initial));
  const writes = [];
  const db = {
    collection: (collection) => ({
      doc: (id) => ({path: collection + "/" + id}),
    }),
    runTransaction: async (fn) => fn({
      get: async (ref) => {
        const raw = documents.get(ref.path);
        return {exists: raw !== undefined, data: () => raw};
      },
      set: (ref, data) => {documents.set(ref.path,data);writes.push(["set",ref.path]);},
      create: (ref, data) => {
        assert.equal(documents.has(ref.path),false);
        documents.set(ref.path,data);writes.push(["create",ref.path]);
      },
      update: (ref, data) => {writes.push(["update",ref.path,data]);},
    }),
  };
  return {db, documents, writes};
}

test("una respuesta correcta concede solo skin, sin cambiar Habit Coins", async () => {
  const uid = "usuario_demo";
  const env = fakeDb({"users/usuario_demo": {habitCoins: 314, shopInventory: []}});
  const first = await claimTitanSecret({db:env.db,uid,answer:"constancia",
    now:new Date("2026-11-27T18:00:00Z")});
  assert.equal(first.awarded,true);
  assert.equal(first.skinId,SKIN_ID);
  assert.equal(env.writes.filter(([op])=>op==="create").length,1);
  const update = env.writes.find(([op])=>op==="update");
  assert.equal(update[1],"users/usuario_demo");
  assert.equal(Object.hasOwn(update[2],"habitCoins"),false);
  assert.equal(Object.hasOwn(update[2],"shopInventory"),true);
  const second = await claimTitanSecret({db:env.db,uid,answer:"constancia",
    now:new Date("2026-11-27T18:00:00Z")});
  assert.equal(second.awarded,false);
  assert.equal(env.writes.filter(([op])=>op==="create").length,1);
});

test("respuesta errónea consume intento, no inventario ni recompensa", async () => {
  const env = fakeDb({"users/usuario_demo": {habitCoins: 99, shopInventory: []}});
  const result = await claimTitanSecret({
    db:env.db,uid:"usuario_demo",answer:"misterio",
    now:new Date("2026-11-27T18:00:00Z"),
  });
  assert.equal(result.status,"incorrect");
  assert.equal(result.remaining,4);
  assert.equal(env.writes.some(([op])=>op==="update"),false);
  assert.equal(env.writes.some(([op])=>op==="create"),false);
});

test("un usuario sin perfil y entradas inválidas no reciben skin", async () => {
  const env = fakeDb();
  await assert.rejects(()=>claimTitanSecret({
    db:env.db,uid:"usuario_demo",answer:"constancia"}),/perfil/);
  await assert.rejects(()=>claimTitanSecret({
    db:env.db,uid:"uid/ajeno",answer:"constancia"}),/Sesión/);
  await assert.rejects(()=>claimTitanSecret({
    db:env.db,uid:"usuario_demo",answer:"x".repeat(71)}),/Respuesta/);
});
