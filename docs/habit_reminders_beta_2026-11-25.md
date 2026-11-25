# Recordatorios inteligentes de hábitos — beta Android

Fecha: 25 de noviembre de 2026. Solo código, **sin desplegar reglas**.

## Comportamiento
- Reemplaza el recordatorio diario recurrente y genérico por **un aviso local
  de una sola ocasión**, programado exclusivamente para la fecha actual.
- Obtiene los hábitos del usuario desde Firestore **servidor**, busca intentos
  con `status = inProgress` y compara `progress / target` y
  `frequencyType = daily`.
- Cuenta registros en `attempts/{id}/logs` con `createdAt` dentro del
  calendario local del Android, y solo avisa cuando faltan registros frente
  a `registrationsPerPeriod`.
- Ignora hábitos semanales, finalizados, cancelados y sin registros pendientes.
- El mensaje solo muestra cantidad de hábitos pendientes, no nombres en
  pantalla bloqueada. No modifica datos, recompensas ni rachas.
- Respeta permiso, interruptor de avisos, horario elegido y descanso dominical.
- La programación se reconstruye al iniciar sesión, reanudar app, guardar
  un registro y activar o abandonar un hábito desde la pantalla Hábitos.
- Los recordatorios de racha y desafíos mantienen sus reglas anteriores.

## Limitaciones y pruebas
- No se realiza una consulta de Firestore cuando la alarma se entrega:
  si el progreso cambia en otro dispositivo después de agendarla, la
  notificación podría ser obsoleta hasta que el usuario vuelva a abrir
  Healthy Habit. Los textos evitan exponer el detalle de la actividad.
- Si no hay conexión con el servidor, no se inventa un número de pendientes.
- Si la hora elegida ya pasó, no se agenda ese aviso para hoy.
- No se programa automáticamente para el día siguiente con datos de hoy.
  Se necesita volver a abrir la app para reconstruir la agenda.
- Los hábitos semanales necesitan lógica de periodo propio, no una copia
  de la lógica diaria.
- Los registros se interpretan en calendario local Android. Si hay cambios
  de zona horaria, verificar que esto concuerde con las reglas de cada hábito.
- No se ejecutaron pruebas Flutter ni físicas desde el conector GitHub.

```bash
flutter analyze --no-fatal-infos lib
flutter test test/habit_reminder_policy_test.dart
flutter test
flutter run -t lib/main.dart
```

## Pruebas en Android
1. Crear/activar hábito diario; activar recordatorios y fijar hora futura.
2. Verificar un aviso programado y confirmar que no revele el hábito.
3. Registrar una actividad antes de la hora y comprobar que el aviso se cancele
   cuando el objetivo diario ya esté cubierto.
4. Probar un hábito con `registrationsPerPeriod = 2`: un registro no basta,
   dos deben cancelar.
5. Probar hábito semanal y hábito completado: no deben generar aviso diario.
6. Cambiar preferencias o cerrar sesión: verificar agenda vacía o reprogramada.
7. Probar sin conexión y otro dispositivo; documentar limitaciones de beta.
