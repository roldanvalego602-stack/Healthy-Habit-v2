"use strict";

const {RegistrationPolicyError} = require("./habit_registration_policy");
const {SHOP_PRICES} = require("./official_shop_catalog");

const SHOP_SLOTS = Object.freeze({
  "avatar_frame": "perfil_marco",
  "banner": "perfil_banner",
  "achievement_display": "perfil_expositor",
  "elite_avatar": "perfil_avatar",
  "mint_scarf": "cuello",
  "sunglasses": "ojos",
  "bandana": "cuello",
  "cap": "cabeza",
  "crown": "cabeza",
  "mint_aura": "aura",
  "leaf_aura": "aura",
  "stellar_aura": "aura",
  "golden_aura": "aura",
  "cape": "espalda",
  "pixel_glasses": "ojos",
  "cat_ears": "cabeza",
  "sports_headband": "cabeza",
  "leaf_headphones": "cabeza",
  "leaf_hoodie": "torso",
  "wellness_medal": "cuello",
  "water_bottle": "mano",
  "leaf_backpack": "espalda",
  "cat_headphones_pink": "cabeza",
  "chef_hat_green": "cabeza",
  "paper_sailor_hat": "cabeza",
  "green_gloves": "brazos",
  "superhero_cape_red": "espalda",
  "star_backpack_blue": "espalda",
  "rock_face_mask": "ojos",
  "space_helmet": "cabeza",
  "hero_mask_blue": "ojos",
  "frame_arcane": "perfil_marco",
  "frame_emerald": "perfil_marco",
  "frame_cyber": "perfil_marco",
  "frame_nature": "perfil_marco",
  "banner_space": "perfil_banner",
  "banner_sunset": "perfil_banner",
  "banner_floral": "perfil_banner",
  "banner_ice": "perfil_banner",
  "avatar_snowman": "perfil_avatar",
  "avatar_christmas": "perfil_avatar",
  "avatar_gingerbread": "perfil_avatar",
  "avatar_gift": "perfil_avatar",
  "aviator_goggles_gold": "cabeza",
  "leaf_glow_hat": "cabeza",
  "leaf_crown": "cabeza",
  "skin_christmas_cartoon": "skin",
  "banner_gradient_yellow_pink": "perfil_banner",
  "banner_gradient_blue_pink": "perfil_banner",
  "banner_gradient_teal_yellow": "perfil_banner",
  "banner_gradient_gold_black": "perfil_banner",
  "banner_gradient_purple_teal": "perfil_banner",
  "banner_gradient_pink_violet": "perfil_banner",
  "banner_gradient_turquoise_blue": "perfil_banner",
  "banner_gradient_black_blue": "perfil_banner"
});
const MAX_ITEMS = 200;
const MAX_SLOTS = 40;
const ID = /^[a-z][a-z0-9_]*$/;

function validateAppearanceRequest(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new RegistrationPolicyError("invalid-argument", "Solicitud inválida.");
  }
  const {action, itemId} = data;
  if (action === "reset" && Object.keys(data).length === 1) {
    return {action};
  }
  if (!["equip", "unequip"].includes(action) ||
      Object.keys(data).length !== 2 ||
      typeof itemId !== "string" || !ID.test(itemId) ||
      !Object.hasOwn(SHOP_SLOTS, itemId)) {
    throw new RegistrationPolicyError("invalid-argument",
      "Artículo o acción no admitidos.");
  }
  return {action, itemId};
}

function calculateAppearance(user, request) {
  if (!user || typeof user !== "object") {
    throw new RegistrationPolicyError("not-found", "Perfil inexistente.");
  }
  const inventory = user.shopInventory ?? [];
  const equipped = user.shopEquipped ?? {};
  if (!Array.isArray(inventory) || inventory.length > MAX_ITEMS ||
      inventory.some((id) => typeof id !== "string" ||
        !Object.hasOwn(SHOP_PRICES, id)) ||
      new Set(inventory).size !== inventory.length ||
      !equipped || typeof equipped !== "object" ||
      Array.isArray(equipped) || Object.keys(equipped).length > MAX_SLOTS ||
      Object.entries(equipped).some(([slot, id]) =>
        !ID.test(slot) || typeof id !== "string" ||
        SHOP_SLOTS[id] !== slot ||
        !(SHOP_PRICES[id] === 0 || inventory.includes(id)))) {
    throw new RegistrationPolicyError("failed-precondition",
      "Inventario o accesorios equipados inválidos.");
  }
  const next = {...equipped};
  if (request.action === "reset") {
    for (const slot of Object.keys(next)) {
      if (!slot.startsWith("perfil_")) delete next[slot];
    }
  } else {
    const {itemId, action} = request;
    if (SHOP_PRICES[itemId] !== 0 && !inventory.includes(itemId)) {
      throw new RegistrationPolicyError("failed-precondition",
        "Primero debes comprar el artículo.");
    }
    const slot = SHOP_SLOTS[itemId];
    if (action === "unequip") {
      if (next[slot] === itemId) delete next[slot];
    } else {
      next[slot] = itemId;
    }
  }
  return next;
}

async function changeShopAppearance({db, uid, data}) {
  if (typeof uid !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
    throw new RegistrationPolicyError("unauthenticated", "Sesión inválida.");
  }
  const request = validateAppearanceRequest(data);
  const userRef = db.collection("users").doc(uid);
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(userRef);
    if (!snapshot.exists) {
      throw new RegistrationPolicyError("not-found", "Perfil inexistente.");
    }
    const equipped = calculateAppearance(snapshot.data(), request);
    const before = snapshot.data().shopEquipped ?? {};
    const unchanged = JSON.stringify(Object.entries(before).sort()) ===
      JSON.stringify(Object.entries(equipped).sort());
    if (!unchanged) tx.update(userRef, {shopEquipped: equipped});
    return {equipped, unchanged};
  });
}

module.exports = {
  SHOP_SLOTS, validateAppearanceRequest, calculateAppearance,
  changeShopAppearance,
};
