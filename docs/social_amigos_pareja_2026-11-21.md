# Healthy Habit — Amigos, notificaciones sociales y hábitos en pareja

Fecha: 2026-11-21
Rama: `feature/habits-discovery-routines`

## Cambio funcional

1. La navegación social se centra en **Amigos** (relación recíproca), no
   en seguir/seguidores. El perfil muestra Amigos y Solicitudes.
2. El usuario envía una solicitud; la otra persona acepta o rechaza.
   Aceptarla crea `users/A/friends/B` y `users/B/friends/A` mediante
   una transacción, y borra los documentos de solicitud.
3. Eliminar un amigo borra ambos documentos de amistad mediante un
   batch. La UI exige confirmación. No se escriben nuevas relaciones
   `following/followers`; sus documentos anteriores NO se han migrado
   ni borrado automáticamente para evitar acciones destructivas.
4. Las solicitudes recibidas aparecen en Notificaciones mediante un
   listener real, con acceso directo a Aceptar/Rechazar en Amigos.
5. El feed ahora consulta amigos en lugar de `following` y muestra
   datos reales publicados en `public_profiles`: nivel, racha
   (cuando se permite), XP, hábitos completados y próximo logro cuando
   exista. No lee listas privadas de hábitos ni fotografías de evidencia.
6. Las reacciones comprueban la identidad del remitente, amistad
   vigente y preferencia `permitirReacciones` antes de enviar.
   Se conserva el panel de reacciones recibidas y marcar como leída.
7. Hábitos en pareja: el usuario elige un hábito oficial y un amigo,
   envía una invitación, el destinatario acepta/rechaza, el emisor
   cancela invitaciones pendientes, y cualquiera puede activar el
   hábito en su propia cuenta tras aceptar mediante
   `HabitActionService.preview/execute`. Aplican los cupos, requisitos
   y costos normales. **Sin XP adicional por compartir**.
8. Se muestran avisos in-app de invitaciones a hábitos en Notificaciones.
   El apartado Hábitos incluye acceso a la pantalla de pareja y botón
   «En pareja» en los hábitos activos.

## Esquema adicional de Firestore, NO desplegado

`shared_habit_invites/{inviteId}`
- `senderUid`, `recipientUid`, `habitId`, `habitTitle`
- `status`: pendiente | aceptada | rechazada | cancelada | finalizada
- `createdAt`, `resolvedAt`

El ID es determinista por emisor/receptor/hábito para evitar duplicados
en el mismo sentido. Se verifica `users/{emisor}/friends/{receptor}`
antes de enviar y `users/{receptor}/friends/{emisor}` antes de aceptar.

## Reglas y seguridad — requisito previo a considerar el módulo listo

**No se ha modificado ni desplegado ninguna regla de Firestore.**
El repositorio no expone las reglas activas en Firebase Console.
Las validaciones Dart no protegen contra clientes maliciosos.

Revisar e implementar reglas para:
- Amistad simétrica aceptada y eliminación por cualquiera de las partes,
  evitando que un usuario cree amistades sin solicitud autorizada.
- Sólo el emisor autenticado puede crear/cancelar la invitación.
- Sólo el destinatario puede aceptar/rechazar una invitación pendiente.
- Sólo ambos participantes pueden leer sus invitaciones.
- Campos/estados y transiciones inmutables validados (no permitir que
  se cambien los UID o el hábito tras crear).
- Reacciones solo entre amigos, respetando preferencias y limitando
  abuso; el receptor puede marcar como leída su propia reacción.
- Los clientes no pueden modificar libremente XP, recompensas,
  registros privados o progreso de otras cuentas.

La interfaz mostrará `permission-denied` cuando las reglas existentes
no permitan estas rutas. No habilitar escrituras públicas como
solución rápida.

## Lo que falta

- **Migración controlada**: vínculos `following/followers` heredados no
  se convierten automáticamente en `friends`. La migración debe
  comprobar los datos reales y obtener autorización.
- **Progreso conjunto**: la invitación permite que ambos tengan el
  mismo hábito oficial, pero aún no ofrece un contador compartido en
  tiempo real. Para eso se necesita publicar un resumen permitido de
  cada cuenta, sin exponer registros personales ni aceptar números
  manipulados desde el cliente.
- **Notificaciones push**: el centro in-app tiene listeners reales.
  Para avisar cuando la app está cerrada sería necesario un proceso
  servidor/FCM autorizado.
- **Prueba con dos cuentas**: verificar reglas, lectura, escritura,
  visibilidad y cancelación antes de confirmar funcionamiento.
- **Cierre de asociación**: ya hay acción «Terminar pareja» que marca
  la invitación como finalizada sin borrar los registros personales.
  Falta automatizar qué sucede con una invitación aceptada cuando se
  elimina la amistad.

## Validación local

```bash
git fetch origin feature/habits-discovery-routines
git merge --ff-only FETCH_HEAD
flutter analyze lib/páginas/perfil
flutter analyze lib/páginas/habitos
flutter analyze lib/páginas/notifications_screen.dart
flutter test test/habitos_compartidos_modelo_test.dart
flutter test test/habitos_pareja_flujo_test.dart
```

Después: cuenta A solicita amistad a B, B acepta, ambos consultan
«Mis amigos», A envía reacción, B consulta Notificaciones, A envía un
hábito en pareja, B lo acepta y ambos intentan activar el mismo hábito
respetando las reglas normales. Eliminar amistad y comprobar que
desaparece en ambos dispositivos.
