"use strict";
const assert = require("node:assert/strict");
const test = require("node:test");
const {
  prepareQuery, cleanSnippet, searchEncyclopedia,
} = require("../mr_healthy_web_search");

test("rechaza consultas vacías, demasiado largas y operaciones", () => {
  assert.throws(() => prepareQuery("hi"), TypeError);
  assert.throws(() => prepareQuery("x".repeat(121)), TypeError);
  assert.throws(() => prepareQuery("borra mi cuenta"), RangeError);
  assert.throws(() => prepareQuery("dosis de medicamento"), RangeError);
  assert.equal(prepareQuery("  planeta    Marte  "), "planeta Marte");
});

test("elimina etiquetas sin ejecutar contenido del proveedor", () => {
  assert.equal(cleanSnippet("<span>Marte</span> &amp; <b>espacio</b>"),
    "Marte & espacio");
});

test("devuelve solo URLs de Wikipedia y como máximo tres resultados", async () => {
  const fakeFetch = async (url) => {
    const parsed = new URL(url);
    assert.equal(parsed.host, "es.wikipedia.org");
    assert.equal(parsed.searchParams.get("srsearch"), "planeta Marte");
    return {
      ok: true,
      json: async () => ({
        query: {search: [1, 2, 3, 4].map((x) => ({
          title: "Marte " + x,
          snippet: "<span>Planeta</span> rojo",
        }))},
      }),
    };
  };
  const result = await searchEncyclopedia("planeta Marte",
    {fetchImpl: fakeFetch});
  assert.equal(result.results.length, 3);
  assert.equal(result.results[0].excerpt, "Planeta rojo");
  assert.match(result.results[0].url, /^https:\/\/es\.wikipedia\.org\/wiki\//);
});

test("no inventa resultados cuando el proveedor falla", async () => {
  await assert.rejects(
    () => searchEncyclopedia("planeta Marte", {
      fetchImpl: async () => ({ok: false}),
    }), /no disponible/);
});
