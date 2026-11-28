"use strict";

// Auditoría SOLO LECTURA del estado histórico de Firestore. No se muestra
// correo, nombre, UID ni contenido de hábitos. NO confiere legitimidad.
// Ejecutar después de respaldar datos y registrar hora REAL del cierre.
const {initializeApp, applicationDefault, deleteApp} =
  require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {SHOP_PRICES} = require("../official_shop_catalog");
const {TITLES} = require("../profile_title_transaction");

function classifyProfile(data, createdAt, cutover) {
  const inventory = data.shopInventory;
  const items = Array.isArray(inventory) ? inventory : [];
  const unique = new Set(items);
  const created = createdAt && typeof createdAt.toDate === "function" ?
    createdAt.toDate() : createdAt instanceof Date ? createdAt : null;
  const title = Object.values(TITLES).find((entry) =>
    entry.name === data.profileTitle);
  return Object.freeze({
    historicalOrUnknown: !created || !Number.isFinite(created.getTime()) ||
      created.getTime() < cutover.getTime(),
    duplicateInventory: Array.isArray(inventory) &&
      items.length !== unique.size,
    unknownShopItem: !Array.isArray(inventory) ? inventory !== undefined :
      items.some((id) => typeof id !== "string" ||
        !Object.hasOwn(SHOP_PRICES, id)),
    invalidBalance: !Number.isSafeInteger(data.habitCoins) ||
      data.habitCoins < 0 || data.habitCoins > 1000000000,
    legacyProgress: Number(data.xp) > 0 || Number(data.currentStreak) > 0 ||
      Number(data.level) > 1,
    suspiciousTitle: Boolean(title && title.minLevel &&
      Number(data.level ?? 0) < title.minLevel),
  });
}

function parseOptions(argv) {
  const flags = Object.fromEntries(argv.filter((x) => x.startsWith("--"))
    .map((x) => {
      const i = x.indexOf("=");
      return i < 0 ? [x.slice(2), true] :
        [x.slice(2, i), x.slice(i + 1)];
    }));
  if (flags.project !== "cloud-firestore-d8c61" ||
      flags.database !== "default" || flags["read-only-confirm"] !== true ||
      typeof flags["cutover-utc"] !== "string" ||
      !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(flags["cutover-utc"])) {
    throw new Error("Se requiere proyecto, base nombrada default, corte UTC y confirmación de solo lectura.");
  }
  const cutover = new Date(flags["cutover-utc"]);
  const limit = flags.limit === undefined ? 300 : Number(flags.limit);
  if (!Number.isFinite(cutover.getTime()) ||
      !Number.isSafeInteger(limit) || limit < 1 || limit > 1000) {
    throw new Error("Corte UTC o límite inválido (1–1000 documentos).");
  }
  return {projectId: flags.project, databaseId: flags.database, cutover, limit};
}

async function main(argv) {
  const {projectId, databaseId, cutover, limit} = parseOptions(argv);
  // Evitar leer sin querer un proyecto distinto del declarado por credenciales.
  const configuredProject = process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT;
  if (configuredProject && configuredProject !== projectId) {
    throw new Error("El proyecto de las credenciales no coincide con el solicitado.");
  }
  const app = initializeApp({
    credential: applicationDefault(), projectId,
  }, "hh-beta-auditoria-lectura");
  try {
    const db = getFirestore(app, databaseId);
    const records = await db.collection("users").limit(limit).get();
    const totals = {
      profilesInspected: records.size,
      historicalOrUnknown: 0, possiblyAfterCutover: 0,
      duplicateInventory: 0, unknownShopItem: 0,
      invalidBalance: 0, legacyProgress: 0, suspiciousTitle: 0,
      truncated: records.size === limit,
    };
    for (const record of records.docs) {
      const data = record.data() || {};
      const flags = classifyProfile(data, data.createdAt, cutover);
      if (!flags.historicalOrUnknown) totals.possiblyAfterCutover++;
      for (const [key, value] of Object.entries(flags)) {
        if (value === true && key in totals) totals[key]++;
      }
    }
    console.log(JSON.stringify({
      disclaimer: "Indicadores agregados, NO prueban autoría ni legitimidad. No reutilizar saldos históricos.",
      project: projectId, database: databaseId,
      cutoverUtc: cutover.toISOString(), ...totals,
    }, null, 2));
    return totals;
  } finally {
    await deleteApp(app);
  }
}

if (require.main === module) {
  main(process.argv.slice(2)).catch((error) => {
    console.error("Auditoría cancelada: " + (error?.code || error?.message || "error"));
    process.exitCode = 1;
  });
}

module.exports = {classifyProfile, parseOptions, main};
