"use strict";

/** Consulta enciclopédica acotada: no es un modelo generativo ni un
 * buscador universal. Nunca recibe datos del perfil o del historial.
 */
const HOST = "es.wikipedia.org";
const BLOCKED = /\b(suicid\w*|autolesi\w*|matarme|asfixi\w*|intoxic\w*|veneno|emergencia|diagnostic\w*|recet\w*|tratamiento|dosis|medicamento|insulina|cuenta|contrasena|password|borrar|eliminar|comprar|monedas|saldo|habit coins)\b/i;

function prepareQuery(value) {
  if (typeof value !== "string") throw new TypeError("Consulta no válida.");
  const text = value.trim().replace(/\s+/g, " ");
  if (text.length < 3 || text.length > 120 ||
      /[\x00-\x1F]/.test(text)) {
    throw new TypeError("Utiliza una consulta de 3 a 120 caracteres.");
  }
  if (BLOCKED.test(text)) {
    throw new RangeError(
      "Esta consulta requiere orientación especializada; no se enviará a Wikipedia.");
  }
  return text;
}

function cleanSnippet(value) {
  if (typeof value !== "string") return "";
  return value.replace(/<[^>]*>/g, " ")
    .replace(/&quot;/g, '"').replace(/&#039;|&apos;/g, "'")
    .replace(/&amp;/g, "&").replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">").replace(/\s+/g, " ").trim().slice(0, 240);
}

async function searchEncyclopedia(rawQuery, {fetchImpl = fetch} = {}) {
  const query = prepareQuery(rawQuery);
  const url = new URL("https://" + HOST + "/w/api.php");
  url.search = new URLSearchParams({
    action: "query", list: "search", format: "json",
    utf8: "1", srsearch: query, srlimit: "3",
    srprop: "snippet", srnamespace: "0",
  }).toString();
  const response = await fetchImpl(url.toString(), {
    method: "GET",
    headers: {"User-Agent": "HealthyHabitApp/1.0 (educational-search; contact via repository)", "Accept": "application/json"},
    signal: AbortSignal.timeout(6500),
  });
  if (!response.ok) throw new Error("Wikipedia no disponible.");
  const body = await response.json();
  const results = body?.query?.search;
  if (!Array.isArray(results)) throw new Error("Respuesta enciclopédica inválida.");
  return {
    provider: "Wikipedia",
    query,
    results: results.slice(0, 3).map((item) => {
      const title = String(item.title || "").slice(0, 130);
      return {
        title,
        excerpt: cleanSnippet(item.snippet),
        url: "https://" + HOST + "/wiki/" +
          encodeURIComponent(title.replace(/ /g, "_")),
      };
    }).filter((item) => item.title.length > 0),
  };
}
module.exports = {prepareQuery, cleanSnippet, searchEncyclopedia};
