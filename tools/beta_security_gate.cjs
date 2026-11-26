"use strict";

// Bloqueo preventivo de publicación de la beta. NO despliega reglas ni Functions.
// Comprueba las rutas activas de Flutter y el archivo exportado manualmente
// desde Firebase Console para la base nombrada "default".
// Uso: node tools/beta_security_gate.cjs ruta/a/reglas-exportadas.rules
const fs = require("node:fs");
const path = require("node:path");

function inspectRules(rules) {
  const findings = [];
  const compact = rules.replace(/\/\/[^\n]*/g, "").replace(/\s+/g, " ");
  if (/match\s*\/\{document=\*\*\}/.test(compact) &&
      /allow\s+(?:read\s*,\s*write|write\s*,\s*read)\s*:\s*if\s*request\.auth\s*!=\s*null\s*;/.test(compact)) {
    findings.push("Regla global: cualquier usuario autenticado puede leer y escribir documentos ajenos.");
  }
  if (/match\s*\/system\/\{document=\*\*\}/.test(compact) &&
      /allow\s+(?:read\s*,\s*write|write\s*,\s*read)\s*:\s*if\s*request\.auth\s*!=\s*null\s*;/.test(compact)) {
    findings.push("Configuración de sistema accesible para escritura a cualquier usuario autenticado.");
  }
  if (!/rules_version\s*=\s*['"]2['"]\s*;/.test(compact) ||
      !/service\s+cloud\.firestore/.test(compact)) {
    findings.push("Archivo sin encabezado reconocible de reglas Firestore v2.");
  }
  return findings;
}

function inspectRepository(root) {
  const findings = [];
  const load = (file) => fs.readFileSync(path.join(root, file), "utf8");
  const register = load("lib/páginas/habitos/registrar_habito_screen.dart");
  const actions = load("lib/páginas/habitos/habit_action_service.dart");
  const shop = load("lib/páginas/tienda/shop_service.dart");
  const bridge = load("lib/servicios/official_habit_emulator_service.dart");
  const boot = load("lib/servicios/shop_demo_bootstrap.dart");
  const firebase = JSON.parse(load("firebase.json"));
  const expectedProject = "cloud-firestore-d8c61";
  if (firebase.flutter?.platforms?.android?.default?.projectId !== expectedProject) {
    findings.push("El proyecto de Firebase cambió: revisar manualmente la base nombrada default.");
  }
  if (register.includes("_db.runTransaction(")) {
    findings.push("Registrar hábito todavía escribe economía/progreso desde Flutter.");
  }
  if (actions.includes("_db.runTransaction")) {
    findings.push("Activación o cancelación todavía escribe directamente desde Flutter.");
  }
  if (shop.includes("_db.runTransaction")) {
    findings.push("Tienda todavía conserva transacciones de cliente.");
  }
  if (bridge.includes("OfficialHabitEmulatorService") &&
      boot.includes("HH_DEMO_OFFICIAL_HABITS")) {
    findings.push("El recorrido autoritativo de hábitos continúa limitado al entorno demo.");
  }
  // Evitar que un fichero experimental se convierta silenciosamente en
  // reglas desplegables mediante un cambio de configuración.
  const configs = firebase.firestore == null ? [] :
    (Array.isArray(firebase.firestore) ? firebase.firestore : [firebase.firestore]);
  for (const config of configs) {
    if (/candidate|preview|lockdown|demo/i.test(config.rules || "")) {
      findings.push("firebase.json intenta publicar reglas experimentales: " + config.rules);
    }
  }
  return findings;
}

function main() {
  const rulesPath = process.argv[2];
  if (!rulesPath) {
    console.error("Uso: node tools/beta_security_gate.cjs <archivo-exportado-de-reglas-default>");
    process.exitCode = 2;
    return;
  }
  try {
    const rules = fs.readFileSync(path.resolve(rulesPath), "utf8");
    const findings = [
      ...inspectRules(rules),
      ...inspectRepository(path.resolve(__dirname, "..")),
    ];
    if (findings.length) {
      console.error("BETA BLOQUEADA: " + findings.length + " condiciones pendientes.");
      findings.forEach((reason, n) => console.error(`${n + 1}. ${reason}`));
      process.exitCode = 1;
    } else {
      console.log("Sin bloqueos estáticos conocidos. No es certificación de seguridad.");
      console.log("Faltan pruebas de Firestore Emulator, UI, usuarios y despliegue.");
    }
  } catch (error) {
    console.error("No se pudo comprobar la seguridad:", error.message);
    process.exitCode = 2;
  }
}

if (require.main === module) main();
module.exports = {inspectRules, inspectRepository};
