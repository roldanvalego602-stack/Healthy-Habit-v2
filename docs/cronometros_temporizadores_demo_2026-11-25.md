# Cronómetros y temporizadores autodeclarados — 25/11/2026

## Alcance implementado

La interfaz Flutter del registro oficial del entorno demo admite ahora
`timer` y `stopwatch` además de `manual`, `counter` y
`hydration`. El componente de interfaz usa el `Stopwatch` local
de Dart, incluyendo pausas y reanudaciones, y remite el resultado a
`registerOfficialHabitDemo` por el diario local de operaciones.

El servidor exige un objeto `interaction` con exactamente `type`,
`target`, `value` y `unit`:

- Tipos admitidos: `counter`, `hydration`, `timer`, `stopwatch`.
- Tiempos: enteros entre 1 y 86 400 segundos. Se exige
  `unit: "segundos"` y `value >= target`.
- Contadores e hidratación: mantienen su rango original de 1 a 10 000.
  Hidratación exige `unit: "ml"`.
- Se guarda `verified: false` en el registro. El cliente nunca puede
  indicar `verified`, `xp`, `habitCoins` ni `progress`.
- El backend calcula la recompensa normal exclusivamente con el catálogo
  y el estado persistido. La cifra de segundos NO concede XP adicional.
- Reutilizar un mismo identificador de operación con valores diferentes
  produce error `already-exists`; una recuperación idéntica devuelve
  `alreadyProcessed` sin duplicar resultados.

## Límite de confianza — fundamental

El cronómetro de Flutter mide tiempo en la aplicación, pero **un cliente
modificado puede falsificar la cantidad declarada**. No llamamos
`verified` a una sesión por haber alcanzado la meta local. Esto
es un registro autodeclarado; la futura verificación de duración
requeriría un ciclo de inicio/finalización controlado por servidor,
considerando pausas, pérdida de conexión, sesiones expiradas y reintentos.

No se han habilitado `breathing`, `pomodoro`, `steps` ni fotos.
No se modificaron las funciones o reglas desplegadas en producción.

## Validación

Ejecutar desde la raíz del proyecto:

```bash
git fetch origin main
git merge --ff-only origin/main

flutter analyze \
  lib/servicios/operaciones_habitos_pendientes.dart \
  lib/servicios/official_habit_emulator_service.dart \
  lib/páginas/habitos/registrar_habito_screen.dart \
  lib/páginas/habitos/habit_interaction_card.dart

npm --prefix functions test
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
```

El quinto escenario integral comprueba un cronómetro, su almacenamiento
con `verified: false`, la recuperación idempotente, unidades y límites
inválidos y el bloqueo de un atributo `verified` inyectado por el cliente.

**Todavía requiere ejecución local; no afirmar que las cinco pruebas
aprobaron antes de ver el resultado. No ejecutar `firebase deploy`.**
