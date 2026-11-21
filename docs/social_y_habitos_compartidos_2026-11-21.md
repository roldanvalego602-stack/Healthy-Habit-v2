# Healthy Habit — interacción social y hábitos compartidos

Fecha: 2026-11-21
Rama: feature/habits-discovery-routines

## Auditoría de la implementación actual

**Ya implementado previamente:**
- `AmigosServicio`: solicitudes de amistad, su aceptación y rechazo,
  seguimiento y listas de seguidores mediante subcolecciones en `users`.
- `FeedAmigosScreen`: progreso real desde `public_profiles`.
- `ReactionPickerDialog`: 6 emojis enviados mediante `InteractionService`.
- `NotificationsScreen`: recordatorios locales reales en Android.

**Conectado en este cambio:**
- El feed permite pulsar «Animar» y abrir el selector existente de emojis.
- Se respeta `public_profiles/{uid}.settings.permitirReacciones == false`
  ocultando la acción en el feed. Nota: la restricción debe validarse
  también del lado del servidor; el UI no es un control de seguridad.
- `InteractionService.enviarReaccion` valida la identidad de la sesión,
  destino y emoji antes de intentar una escritura.
- `ReaccionesRecibidasPanel` muestra las últimas 15 reacciones
  realmente obtenidas por `InteractionService`, sin generar datos
  ficticios, y permite marcarlas como leídas.
- `NotificationsScreen` integra el panel social con los avisos del
  dispositivo. Si la consulta Firestore falla, enseña un error.
- `habito_compartido_modelo.dart` define las invitaciones y el
  progreso aislado de cada participante, con pruebas unitarias.

## Especificación de hábitos compartidos (todavía sin backend activo)

### Alcance mínimo
1. El usuario A selecciona un hábito del catálogo oficial.
2. Elige un amigo o seguidor autorizado y le envía una invitación.
3. B puede aceptarla o rechazarla. A puede cancelarla mientras esté
   pendiente. No se activan hábitos por recibir una invitación.
4. Al aceptar se crea una asociación de hábito compartido con
   participantes A y B. **Cada participante registra por separado**
   sus actividades normales; no se copian los registros de otro usuario.
5. Una vista conjunta muestra únicamente progreso agregado autorizado,
   sin evidencia fotográfica, notas, diarios ni datos privados.
6. No se otorga XP, Habit Coins ni récords adicionales por compartir.
7. Los usuarios pueden abandonar la asociación sin borrar historial
   personal. El bloqueo de usuarios debe prevalecer sobre invitaciones.

### Contrato de datos propuesto
- `shared_habit_invites/{inviteId}`:
  `habitId`, `habitTitle`, `senderUid`, `recipientUid`,
  `status`, `createdAt`, `resolvedAt`.
- `shared_habits/{sharedId}`:
  `habitId`, `participantUids`, `createdAt`, `status`.
- `shared_habits/{sharedId}/progress/{uid}`:
  `completedSessions`, `targetSessions`, `updatedAt`.

Esta estructura **es propuesta**, no está creada ni desplegada. Las
lecturas y escrituras requieren comprobación de `firestore.rules` y
preferiblemente una operación transaccional/servidor para que la
aceptación no produzca sesiones duplicadas.

### Restricciones necesarias antes de conectar Firestore
- `request.auth.uid` debe coincidir con el emisor de una invitación.
- Solo el destinatario puede aceptarla o rechazarla.
- Solo el emisor puede cancelarla pendiente.
- No permitir autoinvitaciones ni invitar a usuarios bloqueados.
- Las lecturas de invitaciones solo corresponden a participantes.
- Las lecturas de progreso conjunto requieren membresía aceptada.
- Los contadores de progreso no pueden editarse libremente desde el
  cliente: deben derivarse del registro real validado.
- No publicar `users/{uid}` ni sesiones personales para mostrar
  estadísticas de hábitos compartidos.
- Verificar reglas de `interactions` para que el emisor autenticado sea
  `fromUid`, el receptor sea `toUid` y solo este pueda marcar `leido`.

**Pendiente:** revisar las reglas activas en Firebase Console. No se
encontró `firestore.rules` en la rama y no se ha modificado la
configuración remota ni realizado despliegues.

## Comprobación local

```bash
flutter analyze lib/páginas/perfil/feed_amigos_screen.dart
flutter analyze lib/páginas/perfil/interaction_service.dart
flutter analyze lib/páginas/perfil/reacciones_recibidas_panel.dart
flutter analyze lib/páginas/notifications_screen.dart
flutter analyze lib/páginas/habitos/habito_compartido_modelo.dart
flutter test test/habitos_compartidos_modelo_test.dart
```

Prueba funcional pendiente: dos cuentas reales; A sigue a B, A reacciona
desde el feed, B recibe la reacción y la marca leída. Debe comprobarse
el permiso Firestore para las lecturas/escrituras correspondientes.
