# Podómetro y auditoría de evidencia temporal — 25/11/2026

## Implementado: pasos en registro oficial demo

`HabitInteractionCard` ya emplea `Pedometer.stepCountStream` y solicita
`Permission.activityRecognition` en dispositivos compatibles. El conteo
parte de una lectura base cuando se activa la herramienta. Un sensor
del teléfono **no es prueba criptográfica** de actividad física; el
cliente puede ser alterado.

Se habilitó la ruta de registro oficial experimental para `steps`
con `interaction: {type: "steps", value, target, unit: "pasos"}`.
El backend admite valores enteros, `value >= target` y máximo 10 000,
guarda `verified: false` y rechaza cualquier campo económico,
`verified: true` o unidad distinta. No concede XP extra por pasos.
La recuperación local reutiliza la solicitud original. Las reglas
restrictivas existentes impiden acreditar progreso directamente.

En Chrome el podómetro puede no estar disponible; requiere dispositivo
y plugin compatibles, y permisos de actividad física. No inventar
pasos como alternativa ni atribuir verificación al sensor.

## Auditoría: fotografías (todavía no habilitadas)

El circuito anterior `RegistrarHabitoScreen` codifica la imagen como
`imageBase64` en una subcolección privada
`users/{uid}/temporary_habit_evidence/{logId}`.
`TemporaryEvidenceService.cleanExpiredForCurrentUser()` elimina
documentos vencidos solo cuando se ejecuta la aplicación.
Las reglas candidatas permiten al dueño crear imágenes de hasta
350 000 caracteres en Base64, con expiración máxima de 25 horas,
y prohíben actualizar los documentos. Esto **no equivale** a
eliminación garantizada a las 25 horas.

Por seguridad, el piloto nuevo sigue bloqueando fotos. Antes de
habilitarlas se requiere:

1. **Separar imagen y economía:** el registro debe mantener las
   recompensas ordinarias hasta que exista una verificación real.
   Nunca conceder +XP por mero envío de una imagen.
2. **Almacenamiento privado:** preferir Firebase Storage con rutas
   por UID/operación y reglas de lectura privadas; no ampliar escrituras
   directas a Firestore para acreditar evidencias.
3. **Integridad y metadatos:** validar formato real, tamaño en bytes,
   relación UID/hábito/intento y una referencia de evidencia asociada
   a la operación confirmada del servidor.
4. **Ciclo de vida:** eliminación administrativa periódica con mecanismo
   independiente de que el usuario abra la app; limpiar también
   archivos huérfanos y definir política de retención.
5. **Privacidad:** considerar geolocalización EXIF, información
   identificable, consentimiento, abuso y borrado por el usuario.
6. **Pruebas:** subida ajena, manipulación de UID, vencimiento,
   reintento, error de red, sustitución de evidencia y ausencia de
   recompensas adicionales.

No se han desplegado reglas ni servicios de producción.

## Pruebas locales de podómetro

```bash
git fetch origin main
git merge --ff-only origin/main

flutter analyze \
  lib/páginas/habitos/habit_interaction_card.dart \
  lib/páginas/habitos/registrar_habito_screen.dart \
  lib/servicios/operaciones_habitos_pendientes.dart \
  lib/servicios/official_habit_emulator_service.dart

npm --prefix functions test
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
```

Se añadió un séptimo escenario de integración para pasos. El resultado
esperado es **7 pruebas integrales aprobadas** y cero fallidas.
Esta versión todavía requiere ejecución y verificación local.
