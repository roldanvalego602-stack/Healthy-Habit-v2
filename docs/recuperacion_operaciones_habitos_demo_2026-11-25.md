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
