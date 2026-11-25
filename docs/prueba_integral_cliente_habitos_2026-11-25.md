# Migración de hábitos — prueba integral de cliente autenticado

Fecha: 25 de noviembre de 2026

## Objetivo

Validar por primera vez el recorrido **SDK Firebase cliente (Auth real del
emulador) → Callable Functions Emulator → Admin SDK → Firestore Emulator**
con **reglas restrictivas**. Esta prueba complementa, pero NO sustituye,
las 128 pruebas unitarias, las 42 transaccionales ni las 19 de reglas.

El escenario de `tools/firestore-tests/habitos_cliente_integral.test.mjs`:

1. Comprueba la identidad de proyecto `demo-healthy-habit` y la presencia
   de los tres emuladores; crea un usuario anónimo en Auth Emulator.
2. Carga exclusivamente en Firestore Emulator las reglas proyectadas por
   `release_preview_rules.mjs` (nunca las despliega).
3. Crea un perfil válido mediante el SDK cliente con saldo inicial oficial.
4. Comprueba que el cliente no puede concederse XP.
5. Activa `alim_001` a través de `activateOfficialHabitDemo`; comprueba
   que repetir el mismo `operationId` no crea otra activación.
6. Comprueba que un cliente no puede modificar el progreso del intento.
7. Registra una actividad manual mediante `registerOfficialHabitDemo`,
   confirma el XP del catálogo y que el reintento no acredita otro registro.
8. Reclama una única vez el premio del día mediante `claimDailyStreakReward`.
9. Cancela el intento con `cancelOfficialHabitDemo`, conserva los saldos y
   rechaza un registro posterior a la cancelación.

## Ejecución

Desde la raíz del repositorio, sin emuladores previamente abiertos:

```bash
git fetch origin main
git merge --ff-only origin/main
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
```

**Todavía no se ha ejecutado esta prueba nueva en el equipo del usuario**.
Si falla, compartir la sección `failing tests` y el error de Functions Emulator.

## Restricciones y próximos pasos

- Esta prueba usa el catálogo real pero solo el hábito sencillo `alim_001`.
  No valida fotografías, notas ni herramientas interactivas.
- Las reglas estrictas se cargan exclusivamente en la base de datos del
  emulador y no quedan activas en Firebase de producción.
- El piloto Flutter ya invoca estas Functions con las tres banderas
  `HH_SHOP_DEMO_FIREBASE`, `HH_DEMO_SHOP_PURCHASE` y
  `HH_DEMO_OFFICIAL_HABITS`; la versión normal sigue usando operaciones
  antiguas.
- Todavía falta probar los recorridos de todas las pantallas, la recuperación
  tras cortes de red y la persistencia de los identificadores de operación.
- Ninguna de estas verificaciones autoriza `firebase deploy`.

## Corrección tras la primera ejecución del 25/11/2026

La primera ejecución con Auth, Firestore y Functions Emulator devolvió
`functions/not-found: Perfil inexistente` en la activación. El cliente
estaba usando `getFirestore(app)`, que selecciona la base `(default)`,
mientras que Flutter y Admin SDK usan explícitamente la base nombrada
`default` (`databaseId: 'default'` y `getFirestore('default')`).
Se corrigió la prueba integral para usar `getFirestore(app, 'default')`.

El error de Git `cannot lock ref refs/remotes/origin/main` ocurrió junto
con un merge `Fast-forward` satisfactorio; es una discrepancia local de
referencias durante `git fetch`, no un fallo de la transacción. Confirmar
`git status` y `git rev-parse HEAD` antes de repetir actualizaciones.

**Pendiente:** repetir la prueba integral y comprobar específicamente
que las reglas restrictivas bloquean escrituras del cliente en la base
nombrada `default`, no solo en `(default)`. Si no se rechazan, detener
la migración y corregir el alcance de las reglas del emulador. No
desplegar ni usar credenciales de producción.

## Segunda ejecución: ausencia de reglas en la base nombrada

El 25/11 la prueba avanzó al perfil de la base `default`, pero
`assert.rejects(updateDoc(userRef, {xp: 5000}))` falló porque la
escritura **fue aceptada**. La causa fue que `initializeTestEnvironment`
cargaba las reglas en `(default)`; el cliente y Functions operan en
la base nombrada `default`. Según la documentación oficial de Firebase,
las bases nombradas creadas implícitamente por el emulador tienen
**reglas abiertas** si no se declaran expresamente.

Para impedir que vuelva a pasar, se incorporó:

- `firebase.lockdown.emulator.json`: configuración alternativa de
  emuladores donde `default` tiene su propio archivo de reglas restrictivas.
- `generar_reglas_integrales.mjs`: genera ese archivo temporal usando
  exactamente la proyección del laboratorio; está excluido de Git.
- `test:cliente-integral:emulador`: genera primero el archivo, después
  inicia todos los emuladores con la configuración alternativa y por
  último ejecuta el test. **No usar `firebase.emulator.json` para esta
  prueba integral**: deja la base nombrada sin reglas de laboratorio.

La prueba debe rechazar la manipulación de XP antes de invocar la
primera Function. No quitar esa aserción aunque fallen otras partes.
La nueva configuración y su recorrido completo aún deben validarse
localmente; hasta entonces, no informar que la prueba integral pasó.

## Tercera ejecución: advertencia de configuración multibase

La CLI del equipo rechazó la configuración Firestore en forma de arreglo
y mostró explícitamente **"The emulator will default to allowing all reads
and writes"**. La prueba falló correctamente al intentar adulterar XP,
antes de llamar a cualquier Function.

Se sustituyó el arreglo `firestore` por un único objeto con
`database: "default"` y `rules: ".firebase-lockdown-preview.rules"`.
Esta variante todavía requiere verificación local con la versión de
Firebase CLI instalada. **Si vuelve a aparecer la advertencia de reglas
abiertas, detener las pruebas y no considerar segura la configuración.**
La aserción negativa de XP debe seguir siendo obligatoria.

La configuración experimental no reemplaza `firebase.emulator.json`
ni modifica `firebase.json` o las reglas de producción.
