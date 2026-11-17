"use strict";

const {evaluateVisualEvidence} = require("./evidence_policy");

/**
 * Adaptador de Vision API. Mantener privado: NUNCA expone imágenes,
 * credenciales ni llamadas de pago directamente desde Flutter.
 *
 * El cliente oficial se carga solo si se ejecuta una petición real.
 * Para activar llamadas reales: npm install @google-cloud/vision
 * y habilitar Cloud Vision API en un proyecto de pruebas con facturación.
 */
async function detectLabels(imageBytes, {visionClient} = {}) {
  if (!Buffer.isBuffer(imageBytes) ||
      imageBytes.length === 0 ||
      imageBytes.length > 250 * 1024) {
    throw new TypeError("La imagen debe tener entre 1 y 256000 bytes.");
  }

  const client = visionClient ||
    new (require("@google-cloud/vision").ImageAnnotatorClient)();

  const image = {content: imageBytes};
  const [[labelResponse], [objectResponse]] = await Promise.all([
    client.labelDetection({image}),
    client.objectLocalization({image}),
  ]);
  const byName = new Map();
  const add = (name, score) => {
    if (typeof name !== "string" || typeof score !== "number" ||
        !Number.isFinite(score) || score < 0 || score > 1) return;
    const key = name.toLowerCase().trim();
    byName.set(key, Math.max(score, byName.get(key) ?? 0));
  };
  for (const label of labelResponse?.labelAnnotations || []) {
    add(label.description, label.score);
  }
  for (const item of objectResponse?.localizedObjectAnnotations || []) {
    add(item.name, item.score);
  }
  return [...byName].map(([name, score]) => ({name, score}));
}

async function assessEvidenceImage({imageBytes, profileId, challengeObjectId, visionClient}) {
  const detections = await detectLabels(imageBytes, {visionClient});
  return evaluateVisualEvidence({profileId, challengeObjectId, detections});
}

module.exports = {detectLabels, assessEvidenceImage};
