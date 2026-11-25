# Laboratorio de endurecimiento de reglas — 25/11/2026

**NO DESPLEGAR.** La versión actual de Flutter todavía escribe directamente
progreso, registros, XP, monedas y logros. Endurecer reglas en producción
antes de migrar esas operaciones interrumpiría funciones de Healthy Habit.

## Resultado base comprobado por el usuario

- `test:release` con suites serializadas: 75/91 aprobadas; 16 fallidas.
- Los flujos sociales positivos pasan. Las 16 fallas son validaciones de
  integridad que esperan un rechazo y reciben una escritura exitosa.
- La regla `firestore.candidate.rules` permanece sin endurecer, para no
  ocultar ni alterar el problema de la release gate.

## Laboratorio añadido

- `release_preview_rules.mjs` lee `firestore.candidate.rules` y genera
  **en memoria** una variante restrictiva. No se crea un archivo de reglas
  desplegable.
- La variante permite modificar campos limitados de perfil y preferencias,
  conserva las compras que satisfacen `validInventoryChange`, y permite
  equipar artículos mediante `validEquipped`.
- Rechaza otras escrituras sobre el documento de usuario, incluidos XP,
  monedas incrementadas, nivel, rachas y estadísticas.
- Rechaza escrituras desde clientes en `user_habits/{path=**}` y
  `achievements/{path=**}`, conservando lectura propietaria.
- `security_release_gate.test.mjs` ejecuta **exactamente las mismas
  expectativas de rechazo**, con regla candidata por defecto, o con
  reglas de laboratorio solamente si `HH_RELEASE_PREVIEW=1`.
- `release_preview_positive.test.mjs` prueba que nombres, preferencias,
  compras válidas y lectura de intentos persisten, y que las escrituras
  directas de progreso no pasan.

Comando para el laboratorio (Linux):

```bash
git fetch origin main
git merge --ff-only origin/main
firebase emulators:exec --config firebase.emulator.json \
  --only auth,firestore --project demo-healthy-habit \
  "npm --prefix tools/firestore-tests run test:lockdown"
```

**No se han ejecutado esas nuevas pruebas desde GitHub.**
El resultado no debe reportarse como aprobado sin la salida del emulador.

## Trabajo para convertir la simulación en seguridad real

1. Mantener el catálogo de 36 hábitos sincronizado con
   `functions/official_habit_catalog.js`.
2. Revisar las transacciones de activación, cancelación y registro oficiales
   existentes; cubrir reintentos, operaciones idempotentes, concurrencia,
   evidencia, horarios y estados heredados.
3. Conectar las pantallas de Flutter y los módulos que aún escriben
   `users/{uid}`, intentos, logs, logros, estadísticas y monedas
   directamente a Functions autenticadas.
4. Migrar también compras y canjes a backend si deben considerarse
   parte de la economía segura; una compra validada con saldo fraudulento
   previo no aporta integridad total.
5. Volver a ejecutar todas las pruebas positivas de flujos reales contra
   reglas restrictivas, además de pruebas adversariales.
6. Solo entonces crear una **regla de producción** auditada, preparar
   plan de reversión y desplegar cliente y reglas coordinadamente.

Esta herramienta es un experimento de compatibilidad, **no un
criterio suficiente para liberar la beta**. La release gate de reglas
candidatas debe permanecer roja hasta la migración.
