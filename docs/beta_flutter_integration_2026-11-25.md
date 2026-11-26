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
2. El gateway está **conectado condicionalmente** a
   `HabitActionService.execute` y `RegistrarHabitoScreen._guardarRegistro`.
   Con `HH_BETA_HABITS_CLIENT=false` se mantiene el comportamiento
   anterior; con la bandera activa se usan las tres callables de beta y
   nunca las transacciones directas de esas rutas. Aún faltan pruebas
   instrumentadas de extremo a extremo y la recuperación visible tras
   reiniciar el dispositivo.
3. `firebase_app_check: ^0.3.2+10` está incorporado en
   `pubspec.yaml` y se activa en `lib/main.dart` solo bajo
   `HH_BETA_HABITS_CLIENT=true`. Falta registrar el proveedor en Firebase
   Console y verificar un Android real con App Check antes de habilitar el modo.
   El archivo `pubspec.lock` debe regenerarse con `flutter pub get`
   y quedar versionado tras confirmar la resolución de dependencias.
4. La pantalla de hábitos ya muestra solicitudes pendientes de beta
   y exige confirmación antes de recuperarlas, sin generar nuevos IDs.
   Falta verificar esta ruta con una prueba de integración real en Firebase
   Emulator que simule pérdida de respuesta y reinicio.
5. En beta, la pantalla deshabilita la selección de imágenes y
   rechaza toda fotografía antes de registrar. La ruta de evidencia sigue
   aislada en `demo-healthy-habit`; no se rebaja silenciosamente un
   registro con foto a uno sin ella.
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

## Estado de la conexión de pantallas

- `HabitActionService.execute`: activar y cancelar usan
  `PendingBetaHabitOperations.execute` con `chargedCoins` proveniente
  del servidor, cuando el modo beta está activo.
- `RegistrarHabitoScreen._guardarRegistro`: envía notas y actividad
  autodeclarada a `registerOfficialHabitBeta`; usa `xpAwarded`,
  `coinsAwarded`, `progress` y `completed` de la respuesta del servidor.
- La recompensa diaria de racha en su diálogo sigue exclusiva del modo
  demo; **no** se invoca `claimDailyStreakReward` desde beta.
- `main.dart` impide activar demo y beta simultáneamente.

Esta entrega no autoriza distribuir ni habilitar la beta real. Falta la
interfaz de recuperación tras pérdida de respuesta, la migración de tienda
y recompensas, y el bloqueo de las reglas de Firestore en `default`.

## Recuperación manual de operaciones de beta

La sección de hábitos detecta solicitudes locales guardadas por la sesión
actual y muestra un panel independiente del emulador. El usuario puede
reintentar la solicitud con el mismo `operationId`, `attemptId`, nota,
interacción y penalización máxima. No se envían operaciones al mostrar el
panel; el reintento exige confirmación expresa.

Un registro dañado, perteneciente a otra sesión, o cuya carga haya cambiado
desde su lectura, **no se reenvía automáticamente**. Las solicitudes
persistidas no se eliminan ante errores de red o pérdida de respuesta.

La idempotencia económica depende de las transacciones del servidor:
la recuperación local solo conserva el identificador que las transacciones
necesitan para reconocer un reintento.

Sigue pendiente realizar pruebas de extremo a extremo con Firebase Emulator
y migrar compras, logros y otras escrituras económicas.

## Compras de tienda — preparación beta

Se agregó `purchaseOfficialShopBeta`, protegida por
`requireBetaHabitAccess` y `enforceAppCheck: true`, que usa el
catálogo oficial y la transacción idempotente del servidor ya probada
en el emulador. Ni el precio ni el saldo se aceptan del cliente.

`ShopService.buy()` usa `BetaShopPurchaseGateway` cuando
`HH_BETA_HABITS_CLIENT=true` y no vuelve a escrituras directas
ante errores de Firebase. El diario de compras `hh_beta_shop_pending_v1_`
guarda `operationId` antes del envío y lo reutiliza. La tienda
muestra compras pendientes con confirmación manual para recuperarlas.

La compra NO está habilitada para usuarios reales. Faltan validar
las reglas activas de Firestore `default`, App Check, recuperación con
pérdida de respuesta, concurrencia y casos de tienda con dos usuarios.
También quedan las escrituras de equipamiento y otras operaciones
económicas o de gamificación por auditar.

No ejecutar `firebase deploy` ni habilitar las banderas de beta
con las reglas globales abiertas compartidas anteriormente.

## Reclamación autoritativa de desafíos

La pantalla `DesafiosScreen` utiliza en beta
`claimVerifiedChallengeBeta` en lugar de acreditar XP o monedas
mediante la transacción del cliente. El backend valida el estado y
la marca de progreso verificado, calcula el XP, los premios de nivel
y las monedas, y cambia `status` a `claimed` dentro de una sola
transacción. Una segunda reclamación se rechaza sin volver a abonar.

La versión de reglas **del laboratorio solamente** también impide
que Flutter marque desafíos como reclamados; se añadió una prueba
adversarial específica en `security_release_gate.test.mjs`.

**Bloqueante:** aún no existe un emisor de progreso de desafío
verificado por el servidor. Los documentos demostrativos deben
continuar sin premios. Además, los documentos creados mientras
Firestore tenía permisos globales abiertos **no son evidencia
confiable**: antes de activar la reclamación, deben eliminarse o
invalidarse los indicadores de verificación antiguos y volver a
certificarse mediante una ruta exclusivamente de servidor. No
se autoriza la beta hasta completar ese procedimiento, cerrar las
reglas y ejecutar pruebas integrales.

## Equipamiento de tienda — beta

Se creó `functions/shop_appearance_transaction.js` y la callable
`changeShopAppearanceBeta` con `enforceAppCheck: true` y el mismo
bloqueo de acceso cerrado de la beta. La transacción comprueba la
propiedad desde `shopInventory`, permite artículos gratuitos, valida
el `slot` contra una réplica del catálogo Flutter y actualiza
`shopEquipped` en el perfil autenticado. No admite `uid`, ranuras,
precios ni monedas aportados por el cliente.

En `ShopService.equip()` y `resetLook()`, la beta invoca únicamente
esa callable y **no** vuelve a ejecutar escrituras Firestore desde
Flutter cuando existe un error. El comportamiento ordinario permanece
intacto porque el cliente de beta está deshabilitado.

El comando `reset` conserva solamente los elementos de ranuras
`perfil_*`; se requieren pruebas en dispositivos para perfiles
existentes y combinaciones heredadas. Si el mapa guardado incluye
valores no reconocidos o artículos no poseídos, la función rechaza
sin actualizar el perfil, para no sobrescribir datos anómalos.

**Nota de confianza:** la lista `shopInventory` de usuarios existentes
no puede considerarse autorizada mientras las reglas globales
actuales hayan permitido que cualquier usuario autenticado la
modifique. Antes de habilitar las operaciones, hay que cerrar las
reglas y auditar o reconstruir inventarios e historial de compras.
