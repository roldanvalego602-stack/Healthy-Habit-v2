# Healthy Habit — migración de integridad para beta

Fecha: 24 de noviembre de 2026
Estado: **NO PUBLICAR / SIN DESPLIEGUE**

## Resultado de la primera inspección

1. `firestore.candidate.rules` tenía una expresión de `challengeId.matches`
   interrumpida. Se reconstruyó el permiso de reacciones comunes y
   stickers, validando posesión y correspondencia de emoji.
2. `validOwnerUpdate(uid)` permite incrementos arbitrarios de
   `xp`, `currentXp`, `level`, `habitCoins`, racha y datos de
   progreso, siempre que no se active una ruta especial de compra.
3. `/users/{uid}/user_habits/{path=**}` y
   `/users/{uid}/achievements/{path=**}` dejan que el propietario
   escriba registros que aparentan ser progreso verificable.
4. El flujo real de Flutter en `registrar_habito_screen.dart` escribe
   directamente XP, racha y progreso dentro de una transacción. También
   `habit_action_service.dart` modifica estados de intentos, lo cual
   impide simplemente bloquear esas escrituras sin romper la aplicación.
5. Cloud Functions ya ofrece un piloto aislado con transacciones
   autoritativas, pero `functions/index.js` solo permite operaciones
   oficiales en Functions Emulator con proyecto `demo-healthy-habit`.
   No se ha migrado el catálogo real de 36 hábitos.
6. Los documentos `daily_streak_days` ya bloquean escrituras cliente;
   mantener esa protección.

## Cambios de esta etapa

- Corrección de sintaxis/permiso de stickers en las reglas **candidatas**.
- Ampliación de la suite de regresión de reacciones para comprobar
  artículos propios y emoji oficial.
- Ampliación de la *release gate* adversarial:
  incremento aislado de XP, monedas y nivel, rachas fabricadas,
  logs inyectados, premios diarios fabricados y logros premium.
- Sin despliegue, sin modificación de los datos de usuarios.

**Importante:** las pruebas de release están diseñadas para fallar
mientras existan vulnerabilidades. NO cambiarlas a `assertSucceeds`
para obtener un resultado verde. Es necesario ejecutar ambas suites
en el emulador y conservar evidencia del resultado.

## Secuencia de remediación (no saltar etapas)

1. Establecer un catálogo de hábitos único en el backend y contrastarlo
   con los 36 elementos visibles en Flutter; identificar reglas
   para activar, cancelar, registrar, evidenciar, reintentar y completar.
2. Migrar la escritura de actividades e intentos a Cloud Functions
   autenticadas con operaciones idempotentes; validar usuario, hábito
   permitido, intento y estados anteriores en transacciones.
3. Hacer que XP, nivel, monedas, racha, logros y contadores solo se
   acrediten mediante transacciones de servidor. No confiar en campos
   enviados por Flutter como `rewardCoins` o `xpAwarded`.
4. Actualizar `RegistrarHabitoScreen`, `HabitActionService`,
   desafios, compra y perfil para que las solicitudes invoquen el
   backend autoritativo sin escrituras económicas directas.
5. En una copia aislada de las reglas (emulador), denegar al cliente
   modificaciones de campos económicos y escrituras de intentos,
   logs y medallas verificadas. Conservar permisos mínimos para editar
   nombre, preferencias, apariencia y otras acciones no económicas.
6. Pasar pruebas positivas de todos los recorridos y negativas de
   falsificación. Revisar el límite de accesos de reglas y el control
   de concurrencia, las zonas horarias y la idempotencia.
7. Revisar privacidad y Storage; respaldar reglas actuales, preparar
   reversión y desplegar en una etapa coordinada.

## Ejecución local

```bash
git fetch origin main
git merge --ff-only origin/main
firebase emulators:exec --config firebase.emulator.json \
  --only auth,firestore --project demo-healthy-habit \
  "npm --prefix tools/firestore-tests run test:release"
```

Las pruebas negativas aún no deben considerarse aprobadas.
**No ejecutar `firebase deploy` con esta configuración.**

La suite Flutter aprobada por el usuario (364/364) verifica
funcionalidad Dart, no demuestra autorización segura en Firestore.
