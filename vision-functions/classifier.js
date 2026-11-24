"use strict";

// Heurística conservadora para previsualización. No valida hábitos ni otorga XP.
const concepts = Object.freeze({
  hydration: new Set(["water", "drinking water", "bottled water", "mineral water",
    "water bottle", "beverage", "drink", "drinking"]),
  fruit_vegetable: new Set(["fruit", "vegetable", "apple", "banana", "orange",
    "carrot", "broccoli", "tomato", "grape", "strawberry", "salad", "leaf vegetable",
    "cucumber", "avocado", "pear"]),
  meal: new Set(["food", "meal", "dish", "breakfast", "lunch", "dinner",
    "cuisine", "prepared food", "staple food", "cereal", "sandwich",
    "rice", "pasta", "soup", "salad", "bread", "fruit", "vegetable"]),
});

const threshold = 0.70;
function normalize(value) {
  return String(value).trim().toLowerCase().replace(/\s+/g, " ");
}

function present(profileId, responses) {
  if (!Object.hasOwn(concepts, profileId)) {
    throw new TypeError("Categoría de análisis desconocida.");
  }
  const items = new Map();
  for (const item of [
    ...(responses[0]?.labelAnnotations || []),
    ...(responses[1]?.localizedObjectAnnotations || []),
  ]) {
    const name = typeof item.description === "string" ?
      item.description : item.name;
    const score = Number(item.score);
    if (typeof name !== "string" || !Number.isFinite(score) ||
        score < 0 || score > 1) continue;
    const key = normalize(name);
    if (key.length > 80 || !key) continue;
    items.set(key, Math.max(items.get(key) || 0, score));
  }
  const labels = [...items.entries()]
      .sort((a, b) => b[1] - a[1]).slice(0, 12)
      .map(([name, score]) => ({name, score}));
  const matches = labels.filter(({name, score}) =>
    score >= threshold && concepts[profileId].has(name));
  const compatible = matches.length > 0;
  return {
    status: compatible ? "visual_match_only" : "inconclusive",
    profileId, labels,
    imageVerified: false, xpAwarded: 0, coinsAwarded: 0,
    message: compatible ?
      "Se observaron elementos relacionados con la categoría elegida. Esto NO demuestra que hayas realizado el hábito." :
      "No encontramos elementos suficientemente claros de esta categoría. Puedes registrar el hábito normalmente.",
  };
}

module.exports = {present};
