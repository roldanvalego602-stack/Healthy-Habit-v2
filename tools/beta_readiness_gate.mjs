#!/usr/bin/env node
// Puerta preventiva de beta: comprobaciones estáticas, NO una auditoría de seguridad.
// Mantener en rojo mientras la aplicación normal permita modificar economía
// y progreso directamente desde Flutter. Ejecutar desde la raíz del repositorio.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const paths = {
  registro: 'lib/páginas/habitos/registrar_habito_screen.dart',
  acciones: 'lib/páginas/habitos/habit_action_service.dart',
  tienda: 'lib/páginas/tienda/shop_service.dart',
  desafios: 'lib/páginas/desafios/desafios_screen.dart',
  puente: 'lib/servicios/official_habit_emulator_service.dart',
  configuracion: 'lib/servicios/shop_demo_bootstrap.dart',
};
let failures = 0;
function file(path) {
  try {
    return readFileSync(resolve(process.cwd(), path), 'utf8');
  } catch (error) {
    console.error(`BLOQUEO: no se pudo leer ${path}: ${error.message}`);
    failures++;
    return '';
  }
}
const source = Object.fromEntries(Object.entries(paths).map(([key, path]) => [key, file(path)]));
function block(condition, title) {
  if (condition) {
    failures++;
    console.error(`BLOQUEO: ${title}`);
  } else {
    console.log(`REVISAR MANUALMENTE: ${title} — patrón no detectado; no implica seguridad`);
  }
}
block(source.registro.includes('_db.runTransaction('),
  'El registro normal conserva una transacción directa en Firestore');
block(source.acciones.includes('_db.runTransaction'),
  'Las acciones de hábitos conservan transacciones directas en Firestore');
block(source.tienda.includes('_db.runTransaction'),
  'La tienda conserva transacciones directas en Firestore');
block(source.desafios.includes('_db.runTransaction'),
  'Los desafíos conservan cobros directos de XP y monedas en Firestore');
block(!source.registro.includes("if (OfficialHabitEmulatorService.enabled || BetaHabitGateway.enabled)") ||
  !source.registro.includes("PendingBetaHabitOperations().execute("),
  'El registro carece de ruta de beta separada de las escrituras directas');
block(!source.acciones.includes("if (BetaHabitGateway.enabled)") ||
  !source.acciones.includes("PendingBetaHabitOperations().execute("),
  'Las acciones carecen de ruta de beta separada de las escrituras directas');
block(!source.tienda.includes("if (BetaHabitGateway.enabled)") ||
  !source.tienda.includes("BetaShopPurchaseGateway().comprar") ||
  !source.tienda.includes("changeShopAppearanceBeta"),
  'La tienda carece de ruta de beta con compra y equipamiento autoritativos');
// La ruta segura es fail-closed: el cliente normal rechaza el cobro,
// la beta solicita la autorización al servidor. No exigir un if positivo,
// porque "if (!BetaHabitGateway.enabled) throw" es equivalente y más seguro.
block(!/if\s*\(!BetaHabitGateway\.enabled\)\s*\{\s*throw StateError/.test(source.desafios) ||
  !source.desafios.includes("claimVerifiedChallengeBeta") ||
  !source.desafios.includes("onPressed: !BetaHabitGateway.enabled || processing"),
  'Los desafíos carecen del bloqueo normal o la ruta de cobro por Functions');
block(source.puente.includes('demo-healthy-habit') && source.puente.includes('OfficialHabitEmulatorService'),
  'El servicio oficial de hábitos sigue restringido al emulador demo');
block(source.configuracion.includes("defaultValue: false") &&
  source.configuracion.includes('HH_DEMO_OFFICIAL_HABITS'),
  'El recorrido seguro de hábitos requiere banderas experimentales');
// Estas comprobaciones demuestran solo la presencia de rutas. No prueban
// que la rama se ejecute, ni permisos, despliegue, privacidad o Android.
console.log(`Resultado: ${failures} bloqueo(s) estático(s).`);
if (failures) {
  console.error('NO DISTRIBUIR beta conectada a Firebase real. Ejecutar además las pruebas de reglas y flujos integrales.');
  process.exitCode = 1;
}
