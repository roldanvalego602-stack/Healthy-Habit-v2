"use strict";

const {detectLabels} = require("./evidence_vision");
const {PROFILES} = require("./evidence_policy");

const MAX_BYTES = 250 * 1024;
const ALLOWED_PROFILES = Object.freeze(["hydration", "fruit_vegetable", "meal"]);

class EvidencePreviewError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "EvidencePreviewError";
    this.code = code;
  }
}

function decodePreviewImage(imageBase64) {
  if (typeof imageBase64 !== "string" || imageBase64.length < 8 ||
      imageBase64.length > Math.ceil(MAX_BYTES / 3) * 4 + 4 ||
      !/^[A-Za-z0-9+/]+={0,2}$/.test(imageBase64) ||
      imageBase64.length % 4 !== 0) {
    throw new EvidencePreviewError("invalid-argument", "Imagen Base64 inválida o demasiado grande.");
  }
  const buffer = Buffer.from(imageBase64, "base64");
  if (!buffer.length || buffer.length > MAX_BYTES ||
      buffer.toString("base64") !== imageBase64) {
    throw new EvidencePreviewError("invalid-argument", "La imagen supera 250 KB o está dañada.");
  }
  const jpeg = buffer.length >= 4 && buffer[0] === 0xff &&
      buffer[1] === 0xd8 && buffer[2] === 0xff;
  const png = buffer.length >= 8 &&
      buffer.subarray(0, 8).equals(Buffer.from("89504e470d0a1a0a", "hex"));
  const webp = buffer.length >= 12 &&
      buffer.toString("ascii", 0, 4) === "RIFF" &&
      buffer.toString("ascii", 8, 12) === "WEBP";
  if (!jpeg && !png && !webp) {
    throw new EvidencePreviewError("invalid-argument", "Usa una imagen JPEG, PNG o WebP.");
  }
  return buffer;
}

function normalized(str) {
  return str.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
      .toLowerCase().trim();
}

function previewFromLabels(profileId, labels) {
  if (!ALLOWED_PROFILES.includes(profileId)) {
    throw new EvidencePreviewError("invalid-argument", "Categoría de prueba desconocida.");
  }
  const candidates = (Array.isArray(labels) ? labels : [])
      .filter((l) => l && typeof l.name === "string" &&
        typeof l.score === "number" && Number.isFinite(l.score) &&
        l.score >= 0 && l.score <= 1)
      .sort((a, b) => b.score - a.score)
      .slice(0, 12)
      .map((l) => ({name: l.name.slice(0, 80), score: l.score}));
  const keywords = PROFILES[profileId].match;
  const compatible = candidates.some(({name, score}) =>
    score >= 0.65 && keywords.some((word) => {
      const n = normalized(name);
      const w = normalized(word);
      return n === w || n.includes(w) || w.includes(n);
    }));
  return {
    status: compatible ? "visual_match_only" : "inconclusive",
    profileId,
    labels: candidates,
    imageVerified: false,
    xpAwarded: 0,
    coinsAwarded: 0,
    message: compatible
      ? "Contenido compatible detectado. No acredita que se realizó el hábito."
      : "No hay coincidencia concluyente. Puedes registrar el hábito normalmente.",
  };
}

async function analyzeEvidencePreview({imageBase64, profileId}, {detector = detectLabels} = {}) {
  if (!ALLOWED_PROFILES.includes(profileId)) {
    throw new EvidencePreviewError("invalid-argument", "Categoría de prueba desconocida.");
  }
  const imageBytes = decodePreviewImage(imageBase64);
  const labels = await detector(imageBytes);
  return previewFromLabels(profileId, labels);
}

module.exports = {
  MAX_BYTES,
  ALLOWED_PROFILES,
  EvidencePreviewError,
  decodePreviewImage,
  previewFromLabels,
  analyzeEvidencePreview,
};
