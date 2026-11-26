// SOLO PRUEBAS: genera una vista en memoria de reglas endurecidas.
// NO usar como firebase.rules ni desplegar antes de migrar Flutter a Functions.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const candidatePath = resolve(
  new URL('../../firestore.candidate.rules', import.meta.url).pathname,
);

function replaceExactlyOnce(source, from, to, label) {
  const parts = source.split(from);
  if (parts.length !== 2) {
    throw new Error(`No se encontró exactamente una vez: ${label}`);
  }
  return parts[0] + to + parts[1];
}

export function releasePreviewRules() {
  let rules = readFileSync(candidatePath, 'utf8');
  // Se respetan las compras validadas existentes y los ajustes inocuos
  // de perfil. Los cambios monetarios arbitrarios, nivel y rachas no pasan.
  const start = rules.indexOf('    function validOwnerUpdate(uid) {');
  const end = rules.indexOf('    // Desafíos sembrados por Flutter:', start);
  if (start < 0 || end <= start) {
    throw new Error('No se pudo aislar validOwnerUpdate');
  }
  const replacement = `    function validOwnerUpdate(uid) {
      let changed = request.resource.data.diff(resource.data).affectedKeys();
      let profileFields = [
        'name', 'username', 'bio', 'settings', 'photoUrl',
        'profileAvatarStyle', 'profileBanner', 'profileFrame',
        'profileStatus', 'profileVisibility', 'tema',
        'estiloVisual', 'modoVisual'
      ];
      return owner(uid) && (
        changed.hasOnly(profileFields)
        || (changed.hasOnly(['habitCoins', 'shopInventory'])
          && validInventoryChange())
        || (changed.hasOnly(['shopEquipped']) && validEquipped())
      );
    }

`;
  rules = rules.slice(0, start) + replacement + rules.slice(end);
  rules = replaceExactlyOnce(
    rules,
    'allow read, write: if owner(uid);\n      }\n      // Recompensas de racha:',
    'allow read: if owner(uid);\n        allow write: if false;\n      }\n      // Recompensas de racha:',
    'rutas de progreso de hábitos',
  );
  rules = replaceExactlyOnce(
    rules,
    'match /achievements/{path=**} {\n        allow read, write: if owner(uid);\n      }',
    'match /achievements/{path=**} {\n        allow read: if owner(uid);\n        allow write: if false;\n      }',
    'logros de servidor',
  );
  // Cuando la recompensa sale del servidor, Flutter jamás puede marcar
  // un desafío como cobrado: esa transición también pertenece al backend.
  rules = replaceExactlyOnce(
    rules,
    "&& (demoChallengeAccept() || trustedChallengeClaim());",
    "&& demoChallengeAccept();",
    "reclamación de desafíos solo por Admin SDK",
  );
  // La alta inicial conserva el saldo inicial validado en reglas candidatas.
  return rules;
}
