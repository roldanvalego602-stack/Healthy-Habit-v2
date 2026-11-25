# Centro de notificaciones — preparación de la beta (25 nov 2026)

## Implementado en la pantalla existente

- `NotificationsScreen`: filtros **Todas / Actividad / Social**, sin crear
  otra pantalla ni guardar notificaciones ficticias.
- Actividad: configuración y diagnóstico de recordatorios Android, prueba
  inmediata, prueba programada y reprogramación, con navegación a Ajustes.
- Social: solicitudes de amistad, invitaciones a hábitos en pareja y
  reacciones reales recibidas; conservan los destinos funcionales.
- Las solicitudes de amistad muestran fecha cuando el documento incluye
  `createdAt` y cada fila abre la pestaña de solicitudes en Amigos.
- Las reacciones conservan estado `leido`, fecha y acceso al perfil del
  emisor. Acción **Marcar todas como leídas**: usa las transacciones
  existentes de `InteractionService.marcarComoLeida`, únicamente
  para documentos destinados al usuario autenticado.
- La campana de Inicio suma reacciones sin leer, solicitudes de amistad
  e invitaciones a hábitos compartidos con estado `pendiente`.
- Ninguna acción cambia XP, monedas, rachas o logros.

## Límites que deben quedar claros

- La sección Actividad **no es un historial persistente** de
  notificaciones Android entregadas. La biblioteca expone la programación
  pendiente, no una cronología verificada de entregas.
- Las solicitudes e invitaciones se resuelven por sus flujos de aceptación
  o rechazo; no se marcan artificialmente como leídas.
- No hay Firebase Cloud Messaging ni aviso push cuando la app está cerrada.
- En caso de fallo de reglas o de red, no debe afirmarse que se marcó una
  reacción como leída. La operación conserva las comprobaciones del backend.
- Esta etapa modifica solo código del cliente. No se desplegaron reglas.

## Comprobación local

```bash
flutter analyze --no-fatal-infos lib
flutter test
flutter run -t lib/main.dart
```

Pruebas manuales con dos cuentas Android:
1. Abrir Notificaciones y alternar los tres filtros; comprobar que en
   Actividad solo salen diagnósticos y que Social presenta las tres secciones.
2. Enviar una solicitud de amistad y comprobar el contador de la campana;
   tocar la fila y aceptar/rechazar desde Amigos; verificar actualización.
3. Enviar una reacción: verificar fecha, indicador pendiente y botón
   individual; comprobar que cambia el contador al leerla.
4. Enviar dos o más reacciones nuevas y pulsar **Marcar todas como leídas**;
   verificar que desaparecen del contador y no afectan solicitudes.
5. Crear una invitación de hábito en pareja desde otra cuenta y comprobar
   que se incluye en el contador mientras esté pendiente.
6. Comprobar que se mantienen los avisos locales y las pruebas del teléfono.
7. Verificar en pantalla pequeña que las tres pestañas no desborden.

El módulo necesita resultados de prueba local antes de declararlo validado.
