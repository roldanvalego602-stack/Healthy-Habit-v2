"use strict";

/**
 * Exporta las 11,500 correspondencias pregunta/respuesta del banco editorial.
 * No entrena un modelo de IA: expande para auditoría las variaciones que la
 * aplicación genera dinámicamente. Los 115 textos base son reutilizados.
 *
 * Uso:
 *   node tools/generate_mr_healthy_qa.js
 *   node tools/generate_mr_healthy_qa.js /ruta/salida.jsonl
 */
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const inputPath = path.join(root,
  "assets/knowledge/mr_healthy_topics_v2.json");
const dartPath = path.join(root,
  "lib/páginas/chatbot/mr_healthy_topic_service.dart");

const document = JSON.parse(fs.readFileSync(inputPath, "utf8"));
if (document.schemaVersion !== 2 || document.language !== "es" ||
    !Array.isArray(document.entries)) {
  throw new Error("Formato de temas incompatible");
}

const dart = fs.readFileSync(dartPath, "utf8");
const match = dart.match(
  /static const templates = <String>\[([\s\S]*?)\];/);
if (!match) throw new Error("No se encontraron plantillas Dart");
const templates = [...match[1].matchAll(/'([^']+)'/g)]
  .map((x) => x[1]);
if (templates.length !== 25) {
  throw new Error("La cantidad de plantillas cambió; revisar el exportador");
}

function normalize(s) {
  return s.toLowerCase()
    .replace(/[áéíóúüñ]/g, (c) =>
      ({á:"a",é:"e",í:"i",ó:"o",ú:"u",ü:"u",ñ:"n"})[c])
    .replace(/[^a-z0-9 ]/g, " ")
    .replace(/\s+/g, " ").trim();
}

const phrases = new Map();
const ambiguous = new Set();
for (const topic of document.entries) {
  if (!topic.id || !topic.answer || !topic.followUp || !topic.detail ||
      !Array.isArray(topic.terms) || topic.terms.length < 4) {
    throw new Error("Tema incompleto: " + topic.id);
  }
  for (const term of topic.terms) {
    for (const template of templates) {
      const question = template.replace("{tema}", term);
      const key = normalize(question);
      if (!key || ambiguous.has(key)) continue;
      const previous = phrases.get(key);
      if (previous && previous.topicId !== topic.id) {
        phrases.delete(key);
        ambiguous.add(key);
      } else {
        phrases.set(key, {
          question, topicId: topic.id,
          category: topic.category,
          answer: topic.answer + "\n\n" + topic.followUp,
          continuation: topic.detail,
        });
      }
    }
  }
}
if (phrases.size < 10000) {
  throw new Error("Cobertura menor a 10,000 preguntas: " + phrases.size);
}

const output = path.resolve(process.argv[2] ||
  path.join(root, "mr_healthy_qa_11500.jsonl"));
fs.writeFileSync(output,
  [...phrases.values()].map((row) => JSON.stringify(row)).join("\n") + "\n");
console.log(JSON.stringify({
  output,
  topics: document.entries.length,
  questionAnswerPairs: phrases.size,
  ambiguous: ambiguous.size,
  humanEditedAnswerBases: document.entries.length,
  trainedModel: false,
}, null, 2));
