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
3. `firebase_app_check: ^0.3.2+10` está incorporado en
   `pubspec.yaml` y se activa en `lib/main.dart` solo bajo
   `HH_BETA_HABITS_CLIENT=true`. Falta registrar el proveedor en Firebase
   Console y verificar un Android real con App Check antes de habilitar el modo.
   El archivo `pubspec.lock` debe regenerarse con `flutter pub get`
   y quedar versionado tras confirmar la resolución de dependencias.
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

## Configuración App Check (NO activar todavía)

En Firebase Console > App Check, registra la aplicación Android y configura
**Play Integrity** para el proyecto `cloud-firestore-d8c61`. Verifica
el identificador `com.example.healthy_habit`, SHA-256 de la firma usada
en beta y la asociación con Google Play si corresponde. El release de
Android aún firma con clave de depuración: antes de distribuir debe
configurarse una firma apropiada.

Por defecto, el arranque **no inicializa App Check** porque
`HH_BETA_HABITS_CLIENT=false`. Una vez endurecidas y comprobadas las
reglas, el cliente se prepara en Android con:

```bash
flutter run --dart-define=HH_BETA_HABITS_CLIENT=true
```

Esto **no garantiza** que las peticiones funcionen: las Cloud Functions
siguen bloqueadas hasta configurar sus variables del servidor y UIDs, además
de App Check. Para un dispositivo de depuración, y **solo en modo debug**,
se admite `--dart-define=HH_BETA_APP_CHECK_DEBUG=true` acompañado de
`HH_BETA_HABITS_CLIENT=true`. Registra el token que genera el proveedor
de depuración en Firebase Console; nunca publiques ese token ni compiles
una beta release con esta bandera. En modo release se rechaza expresamente
ese proveedor.

No actives enforcement de otros productos de Firebase de manera general
antes de verificar todos los flujos y versiones instaladas. App Check
**no sustituye las reglas de Firestore ni Auth**; las reglas actualmente
desplegadas en `default` siguen abiertas.

Fuentes de implementación:
- https://firebase.google.com/docs/app-check/flutter/default-providers
- https://firebase.google.com/docs/app-check/flutter/debug-provider
