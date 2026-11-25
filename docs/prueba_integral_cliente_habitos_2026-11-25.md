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
firebase emulators:exec \
  --config firebase.emulator.json \
  --only auth,firestore,functions \
  --project demo-healthy-habit \
  "npm --prefix tools/firestore-tests run test:cliente-integral"
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
