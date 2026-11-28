"use strict";

const {FieldValue} = require("firebase-admin/firestore");
const {RegistrationPolicyError} = require("./habit_registration_policy");

// La insignia debe provenir de una constancia independiente de servidor.
// Los eventos y medallas del período con reglas abiertas NO son confiables.
const TITLES = Object.freeze({
  novato: {name: "Semilla saludable", minLevel: 1},
  cultivador: {name: "Cultivador de constancia", minLevel: 3},
  explorador: {name: "Explorador del bienestar", minLevel: 5},
  veterano: {name: "Leyenda saludable", minLevel: 10},
  primera_meta: {name: "Primer paso cumplido", badgeId: "primera_meta"},
  racha_siete: {name: "Guardián de la constancia", badgeId: "racha_7"},
  festival: {name: "Espíritu del festival", badgeId: "festival_participant_2026"},
  temporada: {name: "Campeón de temporada", badgeId: "season_champion_01"},
});

function validateTitleSelection(data) {
  if (!data || typeof data !== "object" || Array.isArray(data) ||
      Object.keys(data).length !== 1 || typeof data.titleId !== "string" ||
      !Object.hasOwn(TITLES, data.titleId)) {
    throw new RegistrationPolicyError("invalid-argument",
      "Elige un título del catálogo oficial.");
  }
  return data.titleId;
}

async function selectProfileTitle({db, uid, data}) {
  if (typeof uid !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Inicia sesión.");
  }
  if (!db || typeof db.runTransaction !== "function") {
    throw new TypeError("Se requiere Firestore Admin SDK.");
  }
  const id = validateTitleSelection(data);
  const title = TITLES[id];
  const profileRef = db.collection("users").doc(uid);
  const proofRef = title.badgeId ? db.collection("system")
    .doc("title_attestations").collection("users").doc(uid)
    .collection("titles").doc(id) : null;
  return db.runTransaction(async (tx) => {
    const user = await tx.get(profileRef);
    if (!user.exists) {
      throw new RegistrationPolicyError("not-found", "Perfil inexistente.");
    }
    const profile = user.data();
    if (!Number.isSafeInteger(profile.level) || profile.level < 1) {
      throw new RegistrationPolicyError("failed-precondition",
        "El nivel del perfil no ha sido certificado.");
    }
    if ((title.minLevel ?? 1) > profile.level) {
      throw new RegistrationPolicyError("failed-precondition",
        "Debes alcanzar el nivel requerido.");
    }
    if (proofRef) {
      const proof = await tx.get(proofRef);
      if (!proof.exists || proof.data().uid !== uid ||
          proof.data().titleId !== id ||
          proof.data().badgeId !== title.badgeId ||
          proof.data().verified !== true) {
        throw new RegistrationPolicyError("permission-denied",
          "No existe una constancia oficial para este título.");
      }
    }
    if (profile.profileTitle === title.name) {
      return {titleId: id, name: title.name, unchanged: true};
    }
    tx.update(profileRef, {
      profileTitle: title.name,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return {titleId: id, name: title.name, unchanged: false};
  });
}

module.exports = {TITLES, validateTitleSelection, selectProfileTitle};
