# Healthy Habit — notificaciones para beta Android (24 nov 2026)

## Qué se implementó

- Recordatorios Android locales configurables, permiso solicitado cuando el
  usuario opta por activarlos, zona horaria de Android y programación aproximada.
- El recordatorio de racha dejó de ser recurrente e independiente de los datos:
  ahora compara la última fecha de actividad con la fecha del calendario
  reconocido en el perfil (`StreakNoticePolicy`).
- Estados: sin racha, actividad registrada hoy, registro pendiente hoy,
  interrupción por más de un día y estado no verificable.
- Si se inicia la racha, se programa un aviso único de activación;
  si ya se completó hoy, se prepara el siguiente día; si falta actividad
  de hoy, se agenda el recordatorio que corresponda.
- Segundo aviso condicional tres horas antes de la medianoche del calendario
  de racha; se calcula en la zona almacenada en el perfil, que puede
  diferir de la zona del Android.
- Los avisos de racha programados se cancelan y reconstruyen tras confirmar
  el guardado de una actividad, al iniciar sesión, al cambiar configuración
  y cuando se reanuda la aplicación.
- En Inicio se muestra un SnackBar flotante de Mr. Healthy una vez por día
  con estado de racha; la interrupción se avisa una sola vez por fecha de
  última actividad; una cuenta nueva recibe una bienvenida una vez.
- La agenda respeta permiso, horario, sonido, vibración y descanso semanal.
- No se conceden XP, Habit Coins, protecciones o días de racha mediante avisos.

## Limitaciones explícitas

- Son **notificaciones locales**, no FCM push. El teléfono no consulta
  Firestore en el instante exacto de entrega. Si el usuario registra una
  actividad desde otro dispositivo sin volver a abrir Healthy Habit aquí,
  podría llegar un aviso condicional anticuado. El mensaje dice «si aún
  no registraste...» para evitar afirmaciones inexactas.
- Si el teléfono impide ejecución en segundo plano, cambia zona horaria,
  se reinstala la app o la cuenta no sincroniza, la entrega puede retrasarse
  o requerir abrir la app y reprogramar.
- Los avisos «perdiste tu racha» se presentan al abrir la app con un estado
  verificable. **No hay push remoto garantizado** para una pérdida ocurrida
  mientras la aplicación está cerrada.
- No hay notificaciones push sociales remotas; las alertas sociales en la
  app requieren eventos reales y siguen su flujo independiente.
- Estas modificaciones requieren análisis, tests de widget y pruebas físicas
  en Android. No se afirma que se hayan ejecutado en el equipo del usuario.

## Validación recomendada

```bash
flutter analyze --no-fatal-infos lib/servicios/streak_notice_policy.dart lib/servicios/healthy_reminders_service.dart lib/páginas/inicio.dart lib/main.dart lib/páginas/habitos/registrar_habito_screen.dart lib/páginas/perfil/configuracion_screen.dart lib/páginas/notifications_screen.dart
flutter test test/streak_notice_policy_test.dart
flutter test
```

En un dispositivo Android real:

1. Abrir Ajustes -> permitir recordatorios; seleccionar horario y
   preferencias; comprobar permiso desde Notificaciones.
2. Enviar notificación inmediata y programar prueba +2 minutos.
   Bloquear pantalla, revisar entrega, sin asumir tiempo exacto.
3. Ver la cantidad de avisos pendientes. Probar activación de racha en
   cuenta nueva, primero sin registro y luego con registro completado.
4. Registrar un hábito correctamente: comprobar que se cancelen avisos
   antiguos y aparezcan los correspondientes a la siguiente fecha.
5. Reanudar la app y comprobar mensaje de bienvenida; cerrarla y abrirla
   de nuevo ese día para confirmar que no se repita.
6. Cambiar fecha usando cuentas de prueba, sin alterar los datos reales,
   para verificar racha pendiente, pérdida, recuperación visual y zona.
7. Desactivar recordatorios, cerrar sesión y confirmar que los avisos
   propios desaparezcan de la programación Android.
8. Probar un reinicio y un dispositivo con restricciones de batería.

**Publicación beta:** además de esto, revisar las reglas de Firestore y
privacidad de datos; los avisos no subsanan esos bloqueos.
