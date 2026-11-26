# Integración de cliente de beta — estado 2026-11-25

Esta entrega prepara el puente Flutter hacia las funciones de beta cerrada,
pero **NO habilita la beta ni modifica las reglas desplegadas** de la base
Firestore nombrada `default`.

## Archivos

- `lib/servicios/beta_habit_gateway.dart`: invoca
  `activateOfficialHabitBeta`, `cancelOfficialHabitBeta` y
  `registerOfficialHabitBeta`.
- `PendingBetaHabitOperations`: persiste un `operationId` antes de la
  llamada y lo reutiliza cuando se repite exactamente la misma solicitud.
  El diario usa claves `hh_beta_pending_v1_` y no comparte claves con demo.
- `test/beta_habit_gateway_test.dart`: valida separación de claves y
  estado deshabilitado por defecto.

## Límites deliberados

1. `HH_BETA_HABITS_CLIENT` es `false` por defecto. **No activarlo**.
2. Este gateway aún **no está conectado a las pantallas** de hábitos.
3. Falta integrar y configurar `firebase_app_check` para Android.
   Los endpoints de beta requieren `enforceAppCheck: true`.
4. Falta una interfaz para listar y recuperar solicitudes pendientes
   después de reiniciar el teléfono; NO se deben descartar sin verificar
   el estado del servidor.
5. No se admiten imágenes en este gateway. La ruta de evidencia sigue
   aislada en `demo-healthy-habit`.
6. El reclamo de premios diarios sigue exclusivo del emulador demo.
7. Quedan pendientes compras, logros, desafíos y cualquier otro flujo
   que escriba XP, Habit Coins o progreso desde Flutter.
8. El proyecto Firebase de destino debe ser verificado con su archivo
   de configuración y la base nombrada `default`; NO usar Firestore
   `(default)` por equivocación.

## Orden de habilitación

1. Pasar pruebas adversariales **y** positivas de reglas restrictivas
   con los emuladores Firestore, Auth, Functions y Storage.
2. Migrar las escrituras económicas restantes; probar flujos de dos
   usuarios diferentes, cancelación, compras, reintentos y rachas.
3. Configurar App Check con proveedor apropiado y probar en Android real.
4. Conectar las pantallas al gateway con control de modo y estado visible.
5. Verificar que las reglas activas de la base `default` son las auditadas
   antes de habilitar las variables `HH_BETA_HABITS_ENABLED`,
   `HH_BETA_RULES_VERIFIED` y los UIDs autorizados en el backend.
6. Distribuir solo a un grupo cerrado, tras una validación extremo a extremo.

**El gateway NO es un mecanismo de control de acceso:** las garantías
de autorización deben residir en Functions y Firestore Rules.

Pruebas locales:

```bash
flutter analyze --no-fatal-infos lib
flutter test test/beta_habit_gateway_test.dart
flutter test
npm --prefix functions test
```
