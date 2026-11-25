# Respiración guiada y Pomodoro — piloto de hábitos oficiales

Fecha: 25 de noviembre de 2026.

## Alcance

El registro `registerOfficialHabitDemo` acepta ahora dos tipos de
herramienta adicional: `breathing` y `pomodoro`, además de los tipos
autodeclarados anteriores.

Se conserva el contrato de `interaction`:
`{type, value, target, unit}`; ambos tipos nuevos deben informar
`unit: "segundos"`, duración objetivo entre 1 y 86 400 segundos y
`value >= target`. El registro del servidor contiene
`verified: false`. Nunca debe recibirse `verified` desde el cliente.

Las funciones calculan XP, monedas, rachas y límites de registros
exclusivamente a partir del catálogo y del estado persistido.
**No conceden recompensas adicionales por el tiempo autodeclarado**.
La repetición de un mismo `operationId` con valores diferentes se
rechaza; su recuperación idéntica no duplica la transacción.

La interfaz `HabitInteractionCard` ya utiliza `Stopwatch` local,
permite pausas/reanudaciones y presenta fases de respiración:
inhala 4 s, mantén 2 s y exhala 6 s. Para Pomodoro presenta un
bloque de concentración y sugiere descanso tras finalizar.

## Modelo de confianza y limitaciones

Este circuito **no demuestra que el usuario respiró, se concentró
o mantuvo abierta la herramienta el tiempo indicado**. Un cliente
modificado puede enviar los segundos que quiera dentro del rango
permitido. Los valores son autodeclarados y deben mostrarse como tales.
No se ha implementado cronometraje remoto, validación de sensores ni
verificación de evidencia.

Las fotografías y el podómetro `steps` continúan bloqueados en
el piloto. Las reglas y funciones de producción no se despliegan.

## Validación local

Desde la raíz del repositorio:

```bash
git fetch origin main
git merge --ff-only origin/main

flutter analyze \
  lib/páginas/habitos/habit_interaction_card.dart \
  lib/páginas/habitos/registrar_habito_screen.dart \
  lib/servicios/operaciones_habitos_pendientes.dart \
  lib/servicios/official_habit_emulator_service.dart

npm --prefix functions test
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
```

Se añadió un **sexto escenario integral** que prueba ambos tipos
en usuarios aislados, la escritura con `verified: false`, el
reintento idempotente y el rechazo de unidades, metas, verificación
y XP manipulados.

La verificación local de los cambios todavía está pendiente.
Resultado esperado: 6 pruebas integrales aprobadas, 0 fallidas.
