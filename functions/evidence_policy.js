"use strict";

/**
 * Reglas conservadoras para evidencia. No concede XP ni prueba que una
 * actividad ocurrió: solo compara etiquetas visuales con un contexto.
 * Se deben emitir desafíos por sesión en el servidor, no en el cliente.
 */
const PROFILES = Object.freeze({
  hydration: {
    title: "Hidratación",
    match: ["water", "drinking water", "bottled water", "water bottle",
      "drinking glass", "glass", "bottle", "cup", "beverage", "drink"],
  },
  fruit_vegetable: {
    title: "Frutas y verduras",
    match: ["fruit", "vegetable", "produce", "apple", "banana", "orange",
      "carrot", "salad", "broccoli", "tomato", "food"],
  },
  meal: {
    title: "Comida",
    match: ["food", "meal", "dish", "plate", "lunch", "dinner",
      "breakfast", "cuisine"],
  },
});

const CHALLENGE_OBJECTS = Object.freeze([
  {id: "spoon", title: "Una cuchara", labels: ["spoon", "cutlery", "silverware"]},
  {id: "pen", title: "Un bolígrafo", labels: ["pen", "ballpoint pen", "writing implement"]},
  {id: "paper", title: "Una hoja de papel", labels: ["paper", "sheet of paper", "writing paper"]},
  {id: "cup", title: "Una taza", labels: ["cup", "mug", "coffee cup"]},
  {id: "napkin", title: "Una servilleta", labels: ["napkin", "tissue", "paper towel"]},
]);

function normalize(value) {
  return typeof value === "string"
    ? value.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
        .toLowerCase().trim().replace(/\s+/g, " ")
    : "";
}

function getAvailableChallengeOptions() {
  return CHALLENGE_OBJECTS.map(({id, title}) => ({id, title}));
}

function validateChoice(choiceId) {
  return CHALLENGE_OBJECTS.some((item) => item.id === choiceId);
}

function matches(label, candidate) {
  const a = normalize(label);
  const b = normalize(candidate);
  return a === b || a.includes(b) || b.includes(a);
}

function evaluateVisualEvidence({
  profileId,
  challengeObjectId,
  detections,
  minConfidence = 0.65,
}) {
  const profile = PROFILES[profileId];
  if (!profile) {
    return {
      status: "review",
      reason: "unsupported_habit",
      contentDetected: false,
      challengeDetected: false,
    };
  }

  // Sin desafío de sesión emitido y persistido por el servidor:
  // no se considera verificación completa.
  const challenge = CHALLENGE_OBJECTS.find((c) => c.id === challengeObjectId);
  const labels = Array.isArray(detections) ? detections.filter((item) =>
    item && typeof item.name === "string" &&
    typeof item.score === "number" &&
    Number.isFinite(item.score) && item.score >= minConfidence &&
    item.score <= 1
  ) : [];
  const present = (synonyms) =>
    labels.some((entry) => synonyms.some((word) => matches(entry.name, word)));
  const contentDetected = present(profile.match);
  const challengeDetected = Boolean(challenge && present(challenge.labels));

  if (!contentDetected) {
    return {
      status: "review",
      reason: "habit_content_not_detected",
      contentDetected,
      challengeDetected,
    };
  }
  if (!challenge) {
    return {
      status: "review",
      reason: "session_challenge_required",
      contentDetected,
      challengeDetected,
    };
  }
  if (!challengeDetected) {
    return {
      status: "review",
      reason: "challenge_object_not_detected",
      contentDetected,
      challengeDetected,
    };
  }

  // supported = coincidencia visual; nunca prueba actualidad/autoría.
  return {
    status: "supported",
    reason: "visual_match_only",
    contentDetected,
    challengeDetected,
  };
}

module.exports = {
  PROFILES,
  getAvailableChallengeOptions,
  validateChoice,
  evaluateVisualEvidence,
};
