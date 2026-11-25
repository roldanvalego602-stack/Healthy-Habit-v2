# Recuperación local de operaciones oficiales — 25/11/2026

## Alcance

Primera etapa de recuperación **solo en el entorno aislado** de Healthy Habit
`demo-healthy-habit`. No publica funciones ni reglas y no altera el
funcionamiento de producción.

El archivo `lib/servicios/operaciones_habitos_pendientes.dart` usa
`SharedPreferencesAsync` (dependencia ya presente) para conservar:

- UID de la sesión del emulador, tipo de acción e identificador del hábito.
- Identificador de intento y `operationId` creados **antes** de llamar a
  Functions Emulator.
- Límite de penalización confirmado, únicamente para cancelar.

Cada operación queda ligada al UID autenticado. Una segunda invocación de
la misma acción reutiliza el mismo `operationId`; el backend devuelve
`alreadyProcessed` si había confirmado previamente la transacción.
Al recibir una respuesta correcta, el cliente borra la operación pendiente.
Ante error de red o fallo del emulador, la conserva. Si no se puede
escribir en almacenamiento local, **no llama al servidor**.

### Flujos cubiertos

- `HabitActionService.execute`: activación y cancelación oficiales demo.
- `RegistrarHabitoScreen._guardarRegistro`: registro oficial demo.
- Las funciones `OfficialHabitEmulatorService` conservan sus comprobaciones
  de proyecto, sesión y endpoint del emulador.

### Limitaciones importantes

1. El diario todavía **no implementa una bandeja ni recuperación automática**
   al abrir de nuevo la aplicación. Cuando la interfaz ya muestra el hábito
   activo, completado o cancelado, puede impedir repetir el flujo mediante
   sus prevalidaciones, incluso si quedó una confirmación local pendiente.
   Esa recuperación guiada es la siguiente intervención necesaria.
2. El almacenamiento no es una cola de sincronización offline ni garantiza
   ejecución en segundo plano. No reenviar al cambiar de cuenta.
3. No se guardan notas, imágenes ni contenido personal como parte del diario.
4. No están cubiertas las evidencias, herramientas interactivas o las rutas
   tradicionales de producción.
5. El diario de SharedPreferences no proporciona persistencia transaccional
   a nivel de sistema operativo ante apagones físicos durante la escritura.

## Verificación local pendiente

Ejecutar desde la raíz:

```bash
flutter analyze \
  lib/servicios/operaciones_habitos_pendientes.dart \
  lib/páginas/habitos/habit_action_service.dart \
  lib/páginas/habitos/registrar_habito_screen.dart
```

Después, repetir el recorrido manual de Chrome en
`demo-healthy-habit`. Simular una caída de Functions Emulator entre
el envío y la respuesta, reactivar el servicio y repetir la misma acción
cuando la pantalla lo permita. Verificar que el backend no duplique XP,
monedas o intentos.

**No ejecutar `firebase deploy`.**

## Segunda etapa: recuperación guiada en la pantalla de Hábitos

La pantalla `HabitsScreen` consulta las operaciones guardadas por el UID
actual al abrirse y después de intentar activar, cancelar o registrar.
Si existen, presenta la tarjeta **Operaciones pendientes de confirmar**.

Al pulsar **Recuperar**:
1. Solicita confirmación explícita (la petición original ya fue autorizada
   previamente, pero podría haberse aplicado en el servidor).
2. Reutiliza el `operationId`, `attemptId` y la penalización registrada
   anteriormente. El modo de recuperación tiene `recoveryOnly`: si no
   hay una solicitud previa, **no crea una nueva**.
3. El backend decide si la transacción se había confirmado; devuelve
   `alreadyProcessed` y las recompensas previamente calculadas.
4. Al recibir respuesta correcta, elimina el diario de esa operación y
   actualiza la lista visible y los hábitos. Ante errores, conserva la
   solicitud pendiente para otro intento.

El código valida UID, acción, identificadores y correspondencia entre
la clave del almacenamiento y su contenido antes de mostrar una operación.
No se almacena material de evidencia ni datos personales adicionales.

**Pruebas por ejecutar localmente:**

```bash
flutter analyze \
  lib/servicios/operaciones_habitos_pendientes.dart \
  lib/páginas/habitos/habits_screen.dart \
  lib/páginas/habitos/habit_action_service.dart \
  lib/páginas/habitos/registrar_habito_screen.dart
```

No se ha simulado todavía una desconexión con fallo de respuesta. El
objetivo será confirmar que la tarjeta reaparece al volver a Hábitos y
que **el XP y las monedas no cambian al recuperar una operación ya
procesada**. El entorno de producción permanece intacto.

**Limitación:** si un registro se confirmó pero se perdió su respuesta,
recuperarlo desde Hábitos no reproduce los diálogos de celebración del
registro; recupera el estado persistido sin acreditar nada de nuevo.


## Tercera etapa: prueba automatizada de respuesta perdida

Se incorporó un segundo caso en
`tools/firestore-tests/habitos_cliente_integral.test.mjs`:

- Crea un usuario separado en Auth Emulator y un perfil en la base Firestore
  **nombrada** `default`, con reglas restrictivas.
- Invoca una activación real mediante Callable y **descarta la respuesta**
  a propósito. Comprueba en Firestore que se creó un intento y que la
  versión económica aumentó una sola vez.
- Reenvía el mismo `operationId`/`attemptId`: exige
  `alreadyProcessed: true` y que no aumente la versión.
- Repite la misma simulación para un registro con XP y compara
  `xp`, `habitCoins`, `progress` y `xpEarned` antes y después
  de recuperar la respuesta.
- Repite el procedimiento para cancelar: comprueba que no se vuelve
  a cobrar ninguna penalización ni cambia el estado por duplicado.

**Comando (desde la raíz):**

```bash
git fetch origin main
git merge --ff-only origin/main
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
```

La prueba integral ahora contiene **dos escenarios** y debe terminar
con 2 aprobados y 0 fallidos. La prueba nueva aún requiere ejecución local.

### Qué verifica y qué no

La prueba simula una respuesta perdida **descartando el resultado** del
primer Callable exitoso; no corta realmente una conexión HTTP a mitad
del envío. Comprueba que el backend puede responder idempotentemente al
reintento con idénticos identificadores, independientemente de la interfaz.

No verifica que `SharedPreferencesAsync` persista correctamente entre
cierres del navegador, ni que el usuario vea la tarjeta de recuperación,
ni un corte de red real entre el commit y la recepción. Esas situaciones
se validan mediante pruebas Flutter / integración de navegador aparte.

No desplegar las reglas experimentales ni las Cloud Functions demo.
