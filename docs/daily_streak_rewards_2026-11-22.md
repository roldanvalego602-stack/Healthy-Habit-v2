# Racha diaria y premios — fase controlada (22 nov 2026)

## Regla de producto

La primera sesión de cualquier hábito registrada correctamente durante un día calendario activa la racha global. No hace falta completar el hábito entero. El primer registro debe estar validado por el motor oficial del servidor. La racha avanza como máximo una vez por fecha calendario en la zona horaria fijada por el intento (no enviada por el cliente). Si se pierde un día, la racha empieza de nuevo en 1 al registrar otra actividad. Los registros de hábitos semanales también pueden contar como una actividad del día, pero no se entregan premios adicionales por acumular registros el mismo día.

Premios diarios pequeños: día 1 = 2 Habit Coins; días 2–3 = 3; días 4–6 = 4; días 7 en adelante = 5. Las cifras son propuesta inicial, sujetas a balance económico del juego. No se concede XP adicional.

## Arquitectura

- Registro oficial del servidor: `registerOfficialHabitTransaction` crea `users/{uid}/daily_streak_days/{YYYY-MM-DD}` una vez por día, con `verifiedAt`, `streak`, `rewardCoins` y `claimed:false`. Guarda los campos `serverStreakDays`, `serverLastStreakDay` y `serverLongestStreak` en el documento privado del usuario.
- Reclamo: callable `claimDailyStreakReward` exige `request.auth.uid`, comprueba el día validado y cambia `claimed` y `habitCoins` en **una sola transacción**. Un doble intento responde `alreadyClaimed` sin otorgar otra recompensa.
- Interfaz: pestaña accesible tocando «Racha actual» en Inicio, premios por día, historial real y botón `Recoger` para días validados. El registro oficial aislado muestra una invitación a consultar el premio cuando verifica un día nuevo.
- Compatibilidad: se muestra racha histórica `currentStreak` pero **no es una prueba para otorgar monedas**. El contador visual se normaliza a 0 si la última actividad es anterior a ayer; el récord no se pierde.

## Bloqueadores antes de uso en producción

1. Los 36 hábitos oficiales siguen ejecutándose únicamente en `demo-healthy-habit` Emulator; la app de producción registra parte del progreso directamente desde Flutter. **En producción no habrá días verificables ni premios reclamables hasta completar la migración.**
2. No publicar las reglas candidatas completas: siguen existiendo ocho bloqueos de seguridad económica. Las nuevas reglas de `daily_streak_days` deniegan escrituras cliente, pero el resto debe revisarse antes de desplegar.
3. Verificar reglas realmente publicadas, impedir mutación cliente de campos `serverStreak*` y permitir sólo lectura propia de `daily_streak_days`.
4. Ejecutar `npm --prefix functions test`, pruebas del emulador y `flutter analyze --no-fatal-infos lib`, y probar dos reclamos simultáneos, reintentos, 2 cuentas y cambio de fecha/zona.
5. Preparar pruebas de transición de cuenta histórica y medición de coste. **No desplegar `functions/index.js` de esta rama todavía.**

## Casos de aceptación

- Día 1: registro oficial genera 1 día y premio pendiente de 2 monedas.
- Otro registro el mismo día: no modifica la racha ni crea premio extra.
- Día consecutivo: aumenta racha, un día omitido: reinicia la racha.
- Reclamar: se acreditan las monedas exactas y se marca «Recogido».
- Reclamar dos veces o concurrentemente: una única acreditación.
- Un usuario no puede fabricar el día, saldo, XP o racha desde el cliente.
- Cuenta con racha histórica: la ve, sin premios económicos retroactivos.
- Al completarse un nuevo día verificado aparece el diálogo «Ver premio».


## Mejoras de esta revisión

- Regla explícita: **primera sesión del día en cualquier hábito** crea una única marca global; las sesiones adicionales del mismo día no aumentan racha ni premio.
- Se separó la operación de cobro en `streak_claim_transaction.js` para probarla directamente en el emulador. El endpoint `claimDailyStreakReward` queda restringido por ahora a `FUNCTIONS_EMULATOR=true` y proyecto `demo-healthy-habit`, incluso si accidentalmente se despliega el código.
- `DailyStreakDisplay.current` unifica Inicio, Perfil y Progreso. Una racha con última sesión anteayer o antes se muestra como cero, pero su récord persiste.
- Pruebas añadidas: política, fecha imposible, doble sesión el mismo día, salto de día, reclamos simultáneos y segundo reclamo sin premio adicional.
- **Para verificar localmente:** usar el worktree `Healthy-Habit-racha` y ejecutar `node --test`, el emulador de Firestore y `flutter test test/daily_streak_display_test.dart`. Estas pruebas están añadidas, no se afirma que hayan pasado.

## Integración de la ventana y el reclamo (siguiente fase)

- `RegistrarHabitoScreen` usa el resultado de `registerOfficialHabitDemo` para abrir `DailyStreakRewardDialog` solo cuando `dailyStreakNew == true`. Se muestran tres acciones: **Recoger**, **Más tarde**, **Ver racha**.
- `OfficialHabitEmulatorService.claimDailyStreakReward` usa la misma conexión aislada a Functions que el registro. La identidad del usuario y la cantidad de monedas se validan en el servidor.
- Al tocar **Recoger**, Flutter espera respuesta confirmada de la transacción. Un fallo deja el diálogo abierto y no concede monedas visualmente. Se distingue explícitamente entre un pago nuevo y uno previamente reclamado.
- `DailyStreakScreen` reutiliza el mismo servicio en lugar de llamar directamente a Functions desde un cliente que podría estar en producción. El documento de usuario se actualiza en vivo mediante su `StreamBuilder`.
- Pruebas widget nuevas: cobro correcto, diferir, excepción de conexión y recompensa ya cobrada.

### Comandos para validación en el worktree

```bash
cd ~/Documentos/Integradora/Healthy-Habit-racha
git status --short
git fetch origin feature/daily-streak-rewards-20261122
git merge --ff-only origin/feature/daily-streak-rewards-20261122
flutter analyze --no-fatal-infos lib
flutter test test/daily_streak_display_test.dart test/daily_streak_reward_dialog_test.dart
npm --prefix functions test
firebase emulators:exec --config firebase.emulator.json --project demo-healthy-habit --only firestore "cd functions && npm run test:integration"
```

**Limitación:** Esta mejora cierra el flujo UI de reclamo **solo para sesiones del backend oficial en Emulator**. No transforma el registro normal actual en una operación segura. No ejecutar `firebase deploy` desde esta rama.

## Corrección de presentación del día civil (23 nov 2026)

La prueba de usuario mostró que el premio podía cobrarse mientras el contador de racha no aumentaba visualmente. Causa compatible con ese síntoma: el servidor almacena `serverLastStreakDay` en la zona fijada para el hábito (puede ser `UTC`); Flutter antes lo comparaba exclusivamente con `DateTime.now()` local y descartaba un día UTC posterior como «fecha futura».

- `DailyStreakDisplay` usa la zona `calendarTimeZone` del perfil al comparar fechas verificadas; utiliza `UTC` si la cuenta oficial conserva el valor por defecto.
- `DailyStreakScreen`, Inicio, Perfil y Progreso comparten el mismo helper de presentación.
- La lógica de acreditación no cambia: el backend ya persiste `serverStreakDays` en la transacción de la primera sesión, y el reclamo de Habit Coins es independiente.
- Se agregaron pruebas del cruce UTC del día `2026-11-22/23`, `America/Monterrey` y zona no reconocida.

Validación local: `flutter analyze --no-fatal-infos lib`; `flutter test test/daily_streak_display_test.dart`; `flutter test test/daily_streak_reward_dialog_test.dart`. Comprobar en `users/{uid}` del emulador los campos `serverLastStreakDay`, `serverStreakDays`, `serverLongestStreak` y `calendarTimeZone`, no los campos heredados `currentStreak` y `streakDays`. El primer día verificado de una cuenta de demo nueva debe indicar **1 día**, no heredar automáticamente días anteriores.

## Racha global con calendario estable — revisión siguiente

- El motor oficial fija `serverStreakTimeZone` al emitir el primer día verificado. La prioridad es zona ya fijada, `calendarTimeZone` del usuario, zona del intento; la zona no se solicita al cliente al registrar.
- `DailyStreakDisplay` lee `serverStreakTimeZone` para todas las vistas (Inicio, Perfil, Progreso, Racha), incluso si otra configuración de hábito tiene calendario diferente.
- `firestore.candidate.rules` prohíbe al propietario modificar el campo. **La regla sigue siendo candidata y no está desplegada.**
- La pantalla de racha muestra la última fecha verificada y su zona; sirve para comprobar el momento exacto en el que el servidor reconoce un nuevo día.
- Pruebas añadidas: Flutter respeta la zona fijada y la integración Firestore registra el 22 de noviembre en `America/Monterrey` aunque en UTC ya sea 23.

### Actualización local

```bash
cd ~/Documentos/Integradora/Healthy-Habit-racha
git status --short
git fetch origin feature/daily-streak-rewards-20261122
git merge --ff-only origin/feature/daily-streak-rewards-20261122
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/daily_streak_display_test.dart test/daily_streak_reward_dialog_test.dart
npm --prefix functions test
firebase emulators:exec --config firebase.emulator.json --project demo-healthy-habit --only firestore "cd functions && npm run test:integration"
```

**Atención:** no se fusionó el PR #20 ni se hizo despliegue. Los tests recién añadidos requieren validación local. La racha y el premio siguen aislados hasta migrar el registro normal al backend autorizado.


## Rebalanceo de premios (24 nov 2026)

A partir de los días nuevos verificados en el **emulador oficial**, el premio
por día consecutivo queda entre **10 y 200 Habit Coins**:

| Días de racha | Monedas por día |
|---|---:|
| 1 | 10 |
| 2–3 | 15 |
| 4–6 | 20 |
| 7–13 | 30 |
| 14–20 | 45 |
| 21–29 | 60 |
| 30–44 | 80 |
| 45–59 | 100 |
| 60–89 | 125 |
| 90–119 | 150 |
| 120–179 | 175 |
| 180+ | 200 |

Una sola recompensa por fecha de racha verificada, sin XP adicional.
`functions/streak_day_policy.js` es la fuente autoritativa y
`lib/servicios/daily_streak_reward_tiers.dart` solo muestra la vista previa.
El historial de días ya emitidos con la política anterior (2–5 monedas)
**mantiene el importe guardado en el registro del servidor**, para no
recalcular premios históricos ni rechazar reclamos previamente generados.

**Estado de activación:** NO habilitado en Firebase de producción.
`claimDailyStreakReward` y el registro oficial solo operan en
`demo-healthy-habit` con Functions Emulator. La pantalla ahora indica
explícitamente esta restricción y bloquea el botón de reclamo fuera de demo.
La activación real requiere migrar los registros normales al backend
autoritativo, asegurar las reglas de Firestore, probar idempotencia y
desplegar Functions de forma coordinada. Los iconos de protección/congelación/
recuperación siguen siendo exclusivamente visuales, sin consumo efectivo.

Verificar:
```bash
node --test functions/tests/streak_day_policy.test.js functions/tests/streak_claim_transaction.test.js
flutter test test/daily_streak_reward_tiers_test.dart
flutter analyze --no-fatal-infos lib/páginas/estadisticas/daily_streak_screen.dart lib/servicios/daily_streak_reward_tiers.dart
```
