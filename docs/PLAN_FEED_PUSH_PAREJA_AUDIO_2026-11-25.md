# Healthy Habit — feed social, hábitos en pareja y audio
**Corte:** 25 de noviembre de 2026. **Rama:** `main`.  
**Alcance:** mejoras de presentación y propuesta de siguientes iteraciones; **beta de Firebase pausada**.

## 1. Implementado en código durante esta etapa (validación Android pendiente)

- Se retiró el selector visual de «personalidades» del encabezado de Mr. Healthy (`lib/páginas/chatbot/nutrichat.dart`). **El servicio heredado de estilos de respuesta todavía existe y no se ha eliminado ni reescrito**; no promocionar estilos como una capacidad completa.
- Sonidos retro originales generados en tiempo de ejecución por `MainActivity.kt`: breves bips no verbales para `talk`, `purchase`, `reward`, `achievement`, `friend`. No se toman muestras ni melodías de Undertale u otro juego.
- `lib/servicios/healthy_retro_sound_service.dart` conecta Flutter con el sintetizador Android y respeta `settings.sonidosApp`. Silencio en web/escritorio o si no existe el motor; los sonidos nunca alteran una transacción.
- El asistente usa bips no verbales al responder y presenta un control de silencio. Se dejó de invocar TTS en ese flujo, pero se conservó el dictado por micrófono. **Probar Android antes de afirmar que el efecto resulta agradable**.
- La tienda reproduce el efecto `purchase` únicamente tras recibir la confirmación de compra; el envío de reacciones reproduce `friend` al guardar la reacción; el reclamo de racha usa `reward` después de confirmación del servidor.
- `DailyStreakRewardDialog`, `DailyStreakScreen`, `HabitAddSheet` y la sala secreta usan el icono `HealthyCoinIcon` o `HealthyCoinAmount` donde se detectaron símbolos genéricos. No se ha completado aún un inventario visual de **todas** las pantallas.
- Los hábitos en pareja aceptados muestran las dos fotos tomadas de `public_profiles`. No se consulta el historial privado de otra persona ni se presenta un estado «registrado» sin fuente válida.

**No se han cambiado reglas desplegadas, recompensas de pareja, servicios push remotos ni el estado de beta.**

## 2. Feed de eventos reales: diseño obligatorio

El feed actual `feed_amigos_screen.dart` usa tarjetas de estado actual de `public_profiles` (nivel, racha, próximos logros), **no un registro cronológico de eventos**.

Nuevo diseño: eventos inmutables con identificador y fecha verificables, creados **por el servidor**, nunca por escritura directa del cliente:
- `level_up`: «Diego alcanzó el nivel N» solo cuando una transacción oficial de XP confirma el cruce de nivel.
- `achievement_unlocked`: logro con ID y metadatos del catálogo; el backend debe confirmar el desbloqueo a partir de registros confiables y crear el evento solo una vez.
- `habit_shared`: el usuario elige compartir **un intento ya completado**. El servidor comprueba titularidad y finalización antes de publicar. No compartir fotografías de evidencia ni notas privadas automáticamente.
- `pair_completed`: únicamente cuando ambas partes tienen intentos oficiales válidos y confirmados para la misma invitación.

Esquema propuesto: `public_profiles/{uid}/activity_events/{eventId}`, con `actorUid`, `kind`, `sourceId`, `createdAt` (timestamp del servidor), `visibility`, `titleId` / `habitId`, `level` opcional. El servidor deriva los títulos del catálogo. Las reglas permitirán lectura solamente al titular y amistades recíprocas autorizadas; **toda escritura de cliente prohibida**.

Cada tarjeta tendrá fotografía pública del autor, título de evento, fecha relativa y reacciones dirigidas al `eventId`. Adaptar `ReactionPickerDialog` y el registro de `interactions` para validar en servidor que el evento existe, corresponde al destinatario y permite reacciones; los stickers comprados deben mantener su validación. El feed utilizará paginación y evitará consultar todos los perfiles de manera ilimitada. No mostrar «acaba» si solo se dispone de una foto de perfil o un contador sin fecha.

**Pendiente código:** persistencia de eventos verificados, reglas candidatas, UI de cronología, publicación voluntaria de hábitos, reacciones vinculadas por evento, privacidad, pruebas de Firestore Emulator y de dos usuarios.

## 3. Push de solicitudes de amistad

**Estado actual:** solicitudes dentro de la app, sin entrega push confirmada.

Implementar con Firebase Cloud Messaging, respetando permisos y sesión:
1. Registrar tokens por dispositivo autenticado en `users/{uid}/push_tokens` con reglas de lectura/escritura solo del dueño; rotación al actualizar token y limpieza al cerrar sesión.
2. Función de servidor disparada en la creación confirmada de `users/{uid}/solicitudes/{senderUid}`, que envía al destinatario un aviso con contenido mínimo (sin datos privados).
3. Comprobar destinatario, bloquear notificación propia, repetición, frecuencia abusiva, usuarios bloqueados y preferencias de alertas antes del envío.
4. Al pulsar la notificación abrir **Solicitudes** dentro de la app, evitando filtrado por nombres del remitente en el cliente.
5. Manejar foreground, background y app terminada; permisos Android 13+, token inválido, reconexión, duplicados y desinstalación.
6. Pruebas con **dos dispositivos o perfiles**; la presencia de una función en código no significa que FCM esté provisionado.

No desplegar funciones push ni reglas antes de completar verificación de privacidad y costes.

## 4. Hábitos en pareja y recompensa adicional

Invitaciones, aceptación y activación ya existen. La UI ahora muestra participantes por perfiles públicos.

Para marcar «Registró / Aún no» se necesita un **resumen compartido de solo lectura** por invitación, calculado por servidor desde intentos oficiales y no por valores editables desde Flutter. Cada persona debe consentir que su estado se muestre a la pareja. Nunca exponer notas/fotografías de evidencia sin autorización individual.

Bono propuesto para discutir con el equipo: **+5 Habit Coins a cada participante una sola vez** cuando **ambos** hayan completado el mismo hábito oficial y la invitación siga aceptada. El valor es **propuesta**, NO una cifra aprobada ni implementada. Se requiere:
- Transacción atómica que lea los dos intentos, historial/periodos y estado de invitación.
- Documento idempotente de recompensa derivado de la invitación (no de un ID arbitrario del cliente), previniendo doble pago o retiro/reenvío.
- Validar que no se pague por solo aceptar, activar o enviar fotos; impedir auto-invitaciones, cuentas ajenas y registros falsos.
- Tope de pagos y controles antifraude que puedan auditarse.

**Pendiente código:** resumen bilateral autoritativo, widgets de estado por participante, lógica de verificación, bono de servidor, pruebas de carrera y reglas.

## 5. Audio y pulido antes de presentación

Ejecutar en Android:
```bash
git fetch origin main && git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib test
flutter test
flutter run
```
Revisar: activación y silenciamiento de la voz retro, volumen con audífonos, grabación por micrófono, compra con saldo autorizado, reacciones, tamaño de fotos en hábitos en pareja, diálogo de racha y iconos reales en móviles estrechos.

**No activar beta:** `HH_BETA_HABITS_CLIENT` sigue desactivado; no desplegar `firestore.candidate.rules`.

## 6. Orden de la siguiente etapa

1. Validar que la tanda Android actual compila y se ve bien; corregir regresiones sin introducir riesgo de despliegue.
2. Crear persistencia segura del evento social y primeras tarjetas de «hábito compartido» y «subida de nivel» con pruebas de emulador.
3. Añadir reacción por evento y publicación voluntaria.
4. Completar push FCM de solicitudes con permisos y dos dispositivos.
5. Añadir progreso bilateral de hábitos en pareja y, tras acordar importe, recompensa atómica.
6. Revisar todos los símbolos de monedas, añadir sonidos de logros y pulir racha/animaciones.

**Advertencia:** los tests de integración de hábitos/tienda previamente aprobados NO incluyen el nuevo feed, FCM, audio Android ni el bono de pareja; esos módulos no deben anunciarse como terminados.

## 7. Primera implementación de cronología auténtica (26 noviembre, laboratorio)

Se añadió una primera versión del feed cronológico en
`lib/páginas/perfil/feed_amigos_screen.dart`: lee hasta 15 eventos por
amigo (máximo 30 amigos), los ordena por `createdAt`, muestra nombre/foto
públicos, fecha local, entrada al perfil y opción de reaccionar a cada
evento. No confunde el nivel actual del perfil con una noticia reciente.
La pantalla indica un error si todavía no hay permisos para consultar
eventos: **sin despliegue de reglas candidatas, esto es esperado**.

El motor oficial de registro (`functions/habit_registration_transaction.js`)
genera noticias inmutables de `level_up` y logros verificables
`achievement_unlocked` por umbrales de nivel, racha y hábitos
completados en el motor oficial. Se añadió el contador
`verifiedCompletedHabits` exclusivamente para los logros basados
en finalizaciones oficiales, separado de métricas heredadas.

Por privacidad, un hábito completado NO genera un evento público de
manera automática; la publicación voluntaria `habit_completed` sigue
pendiente de un endpoint explícito validado por servidor.

Las reacciones vinculan su `challengeId` al identificador inmutable de
actividad. Las reglas candidatas comprueban la existencia del evento
para `level_` y `completed_`. El selector conserva stickers, pero
**los stickers siguen siendo reacciones generales y no están vinculados
a un evento**, pendiente de refinar el modelo de datos de reacciones.

La carpeta `public_profiles/{uid}/activity_events/{eventId}` queda
reservada a escritura administrativa; la lectura de la rama candidata
requiere amistad recíproca o ser dueño del perfil.

La prueba `test:36-habitos:emulador` comprueba que cruzar un umbral
crea una única noticia de nivel y que no aparecen publicaciones
automáticas de hábitos, además de rechazar alteraciones desde el
cliente. Esta prueba **aún requiere ejecución del desarrollador**.

Esta entrega no habilita producción, beta, nuevas rules ni FCM.
Pendiente antes de distribuir: prueba de dos usuarios, consentimientos
de publicación, carga incremental, medidas de privacidad y políticas
de retención, reacciones a logros y módulo de compartir explícitamente.
