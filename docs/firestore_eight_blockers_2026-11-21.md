# Auditoría de Firestore: ocho fallos confirmados

Fecha: 21-11-2026. Fuente: ejecución local de 77 tests en Emulator
`demo-healthy-habit` compartida por el desarrollador.

**Resultado: 69 aprobadas / 8 fallidas. Estado: NO PUBLICAR.**

## Qué sigue siendo explotable

| Prueba fallida | Defecto real | Escritura que debe protegerse |
|---|---|---|
| gamificación: regalar XP | El propietario puede subir XP y nivel libremente | `users/{uid}`: `xp,currentXp,level` |
| economía: crear monedas | El propietario puede incrementar el saldo | `users/{uid}`: `habitCoins` |
| economía: falsificar recompensas | Permite simular niveles reclamados | `users/{uid}`: `claimedLevelRewards,habitCoins` |
| integridad: falsificar finalización | Se aceptan estados y progreso inventados | `users/{uid}/user_habits/{habitId}` |
| integridad: acreditar intento | Se aceptan XP y finalización arbitraria en intento | `.../attempts/{attemptId}` |
| integridad: registro inventado | Se aceptan logs con XP y progreso inventados | `.../logs/{logId}` |
| integridad: logro premium | Se aceptan medallas verificadas autoasignadas | `users/{uid}/achievements/{id}` |
| integridad: estadísticas | Permite racha y hábitos completados ficticios | `users/{uid}`: `completedHabits,currentStreak` |

Estos **no son falsos positivos**: cada test requería `assertFails()`
y la escritura maliciosa **se completó con éxito**.

Los `PERMISSION_DENIED` de otros tests son denegaciones esperadas,
no corrigen las ocho fallas anteriores.

## Por qué un arreglo de reglas aislado no basta

- `registrar_habito_screen.dart` escribe los intentos, logs, XP,
  niveles, monedas y rachas en la misma transacción desde Flutter.
- `habit_action_service.dart` activa y cancela hábitos y descuenta
  monedas desde Flutter.
- `desafios_screen.dart` intenta reclamar premios desde Flutter.
- Las reglas actuales de subcolecciones permiten al propietario
  modificar cualquier intento y logro, por lo que no se puede confiar
  en ese contenido como acreditación de recompensas.
- Añadir límites por operación (ej. `xp += 10`) no arregla esto:
  un cliente alterado puede repetir la operación o fabricar registros.
- El piloto de Cloud Functions `registerDemoOfficialHabit` usa Admin SDK
  transaccional pero opera únicamente en Emulator y solo admite
  `hidr_001`, `bien_007`, `alim_004`. **No es la solución de
  producción para los 36 hábitos del catálogo.**

## Implementación necesaria para cerrar las ocho fallas

1. **Servidor autoritativo:** implementar y probar endpoints autenticados
   para activar/cancelar hábitos, registrar progreso y reclamar recompensas.
   Reutilizar las políticas del catálogo de 36 hábitos y estados de
   la app, con una única fuente de verdad y transacciones idempotentes.
2. **Control de duplicados y concurrencia:** operación única por
   registro, verificación de estado previo, contador de periodo y racha
   calculados por el servidor, no enviados por Flutter.
3. **Integrar Flutter:** sustituir escrituras directas de XP, monedas,
   progreso e intentos por llamadas a los endpoints. Mantener intacta
   la lectura en tiempo real de Firestore.
4. **Reglas finales:** denegar por defecto cualquier modificación cliente
   de métricas, estados acreditados, logs verificados y medallas; permitir
   solo preferencias, perfil, tienda con débito legítimo, amistades,
   solicitudes e invitaciones, sin comodines globales.
5. **Pruebas:** además de los 77 tests de reglas, pruebas de integración
   de Functions para los 36 hábitos y su ciclo completo: altas,
   activación, registro, repetición, cupos, desbloqueos, día/semana,
   cancelación, compra, nivel, premios, errores, reintentos y concurrencia.
   Probar reglas y rutas Flutter en Emulator con cuentas reales simuladas.
6. **Migración y despliegue:** verificar documentos históricos, copia
   de seguridad de reglas y despliegue coordinado de funciones, clientes
   y Firestore. No sustituir reglas actuales solo para lograr tests verdes:
   bloquearía el registro de hábitos vigente.

## Comprobación actual

```bash
node --test tools/firestore-tests/rules.test.mjs
npm --prefix tools/firestore-tests run test:release
```

Estos comandos **no deben aprobar el criterio de publicación** con el
sistema económico actual. No se han cambiado las reglas productivas ni
se certifican como seguras por ejecutar únicamente el emulador.
