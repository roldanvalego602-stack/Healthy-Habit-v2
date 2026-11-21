# Migración de recompensas al servidor — etapa 1

Fecha: 21-11-2026. **No se ha desplegado ninguna función ni regla.**

## Implementado

- `functions/official_habit_reward_policy.js`: política pura de cálculo
  para los **36 hábitos oficiales** replicados desde
  `lib/páginas/habitos/catalogo.dart`.
- `functions/tests/official_habit_reward_policy.test.js`:
  pruebas de los 36 IDs, XP según dificultad, campos adulterados,
  cupos diarios/semanales, estados inválidos y premios de nivel.
- Se preservó `registerDemoOfficialHabit` sin habilitarlo en producción.
- Ningún cambio en Flutter ni en las reglas de Firestore productivas.

## Contrato propuesto para el futuro endpoint

Entrada estricta: `habitId`, `attemptId`, `operationId`.

Nunca aceptar del cliente: UID objetivo, XP, monedas, nivel,
progreso, supuesta verificación, registros completados ni racha.

El servidor debe obtener `uid` del token de Auth y cargar el
estado existente desde Firestore Admin SDK; la política calcula
recompensas exclusivamente a partir del catálogo oficial.
La operación futura necesita transacción atómica e idempotente que
verifique estado, cupo del periodo, versiones de intento y operación
repetida, y que actualice usuario, intento, hábito y log juntos.

**Importante:** `planOfficialReward` es sólo un cálculo y NO hace
escrituras ni evita por sí solo registros repetidos. El controlador
transaccional, la verificación de zonas horarias, los vencimientos,
la política de días perdidos, el progreso de desafíos y el consumo
de costes quedan para las etapas siguientes.

## Diferencia con el piloto actual

`registerDemoHabit` actualmente utiliza 10 XP constantes.
La nueva política emplea los XP del catálogo:
- Sencillo: 10
- Moderado: 15
- Difícil: 20

No se ha modificado el piloto heredado para evitar romper sus
pruebas existentes antes de migrarlo de forma controlada.

## Pruebas para ejecutar en Spark local

```bash
git fetch origin feature/habits-discovery-routines
git merge --ff-only FETCH_HEAD
npm --prefix functions test
```

El nuevo archivo se incluye en `functions/tests/*.test.js`.
Estas pruebas son unitarias y no requieren Blaze.

## Condición de publicación

Las 8 vulnerabilidades detectadas en la batería de 77 pruebas
siguen pendientes: las reglas actuales permiten editar XP,
Habit Coins, racha, intentos, logs y medallas desde Flutter.

**No publicar `firestore.candidate.rules` todavía.** Esta primera
etapa sólo prepara y comprueba el contrato de recompensas. El
siguiente paso es integrar esta política con un controlador
transaccional de servidor en emulador y ampliar la validación
a los 36 hábitos antes de adaptar Flutter.

## Etapa 2: motor transaccional de registro para 36 hábitos

Se añadió `registerOfficialHabitTransaction` a
`functions/habit_registration_transaction.js`, utilizando el mismo
motor transaccional que el piloto, pero con la política estricta de
recompensas para los 36 hábitos. El piloto
`registerDemoHabit` mantiene su lista de tres hábitos y su cálculo
histórico de 10 XP, para no romper sus flujos existentes.

El motor oficial, **todavía no expuesto por un endpoint**, prepara en
una única transacción:
- Operación idempotente `registration_operations/{operationId}`;
- Comprobación del intento activo y calendario persistido;
- Límite de registros del periodo y actualización del contador;
- Registro de actividad y progreso de hábito/intento;
- XP correspondiente al catálogo (10/15/20), nivel y monedas de nivel.

Se añadieron pruebas con `FakeFirestore` de los 36 hábitos,
duplicados, reintentos cambiando de hábito e inyección de campos
económicos en el payload.

**Pendiente:** validar estas nuevas pruebas en el equipo local,
probar el motor con Firestore Emulator real y condiciones concurrentes,
integrar la activación y cancelación de los 36 hábitos,
migrar el cliente Flutter y verificar la compatibilidad del calendario
y los registros históricos. `FakeFirestore` no simula bloqueo real
ni concurrencia del servicio y no sustituye una prueba de integración.

Para ejecutar:

```bash
npm --prefix functions test
```

No cambia las ocho vulnerabilidades actuales hasta que las escrituras
directas de Flutter se bloqueen de forma coordinada con un servidor
disponible para producción.
