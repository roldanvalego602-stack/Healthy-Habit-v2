# Implementación de evidencias visuales — Healthy Habit
**Corte:** 27/11/2026 · **Código:** `main` · **Estado:** implementado en código; pruebas automatizadas en GitHub Actions aprobadas. Pruebas manuales Android y auditoría de producción pendientes. **NO DESPLEGADO a beta real.**

## Objetivo y criterio de verificación

El reconocimiento visual debe ayudar a documentar un hábito sin exigir imágenes intrusivas ni confundir la presencia de un objeto con la realización de una acción. El sistema ofrece niveles explícitos:

| Etapa | Qué se demuestra | ¿Cumplimiento de hábito? | Recompensas |
|---|---|---|---|
| Declarado | El usuario registra una actividad | Solo declaración | XP normal determinado por servidor en beta |
| Foto local | ML Kit detecta etiquetas en una imagen preparada | No | Ninguna recompensa adicional |
| Foto asociada | El backend confirma el objeto privado ligado a un UID, hábito, intento y registro | No | Ninguna recompensa adicional |
| Coincidencia visual | Vision, ejecutado desde servidor y previo consentimiento, encuentra etiquetas relacionadas | No demuestra ingestión, duración ni ejecución | Ninguna recompensa adicional |
| Verificación fuerte | Desafío de frescura, contexto, autoría y criterio por hábito; si existen garantías suficientes | **Pendiente de diseñar y evaluar por hábito** | No autorizada |

Nunca se exigen rostro, documento, GPS o grabación continua. La foto es **opcional** y Cloud Vision es un segundo consentimiento optativo.

## A. Qué se implementó

1. **Captura local y protección EXIF:** cámara/galería → `HabitEvidenceImagePreparer` reencodifica JPEG, máximo 250 KB, sin copiar metadatos originales. ML Kit procesa la imagen en Android y presenta resultados indicativos.
2. **Eliminación de incentivo incorrecto:** el registro Flutter heredado ya **no concede 15 XP por una foto**: concede el mismo XP declarado (10). Ese flujo tampoco conserva fotos Base64 en Firestore; el registro guarda `hasEvidence:false`. El paso anterior de 15 XP era falsificable.
3. **Fotos oficiales en beta (bloqueadas por defecto):** nueva ruta cliente `BetaEvidenceService` `HH_BETA_EVIDENCE_CLIENT` + beta general, reserva/subida/asociación/estado, identidad del usuario inferida en Functions. `PendingBetaHabitOperations` conserva `operationId` local en disco, sin guardar bytes; recupera una subida sin repetir recompensas. Si la imagen no llegó, solicita volver a seleccionar archivo, pero no inventa respaldo.
4. **Consentimiento persistido:** la preferencia para analizar en Google Cloud Vision se registra durante la primera reserva de la fotografía como `visionConsent`, asociada al UID y a la operación; los reintentos no pueden cambiarla. El backend de Vision deniega la lectura de la foto si no consta consentimiento expreso.
5. **Funciones beta** `reserveHabitEvidenceBeta`, `uploadReservedEvidenceBeta`, `attachHabitEvidenceBeta`, `getHabitEvidenceStatusBeta` con Auth, App Check y allowlist. Los bytes se transmiten a Functions y de allí a Storage privado, **no Base64 en Firestore**. Hasta 12 reservas/día/UID en una transacción.
6. **Vision opcional en servidor** `analyzeAttachedHabitEvidenceBeta`: solo recibe `habitId/attemptId/operationId`, abre foto ligada a registro real, comprueba tipo/tamaño/propiedad, llama a Vision, clasifica con vocabulario explícito, guarda resultado técnico sin foto ni etiquetas personales completas. Hasta 8 evaluaciones/día/UID UTC y 60 s entre evaluaciones. Proveedor y resultado `visual_match_only/inconclusive/unsupported_habit`; siempre `imageVerified:false`, `contentVerified:false` y cero XP/monedas.
7. **Borrado administrativo:** `purgeHabitEvidenceBeta` (cada hora cuando está realmente habilitada) elimina archivos vencidos y elimina el vínculo al archivo del log, conservando XP y progreso; la caducidad **no garantiza borrado a los 60 minutos exactos**. No habilitar aceptación de fotos sin el proceso de limpieza.
8. **Reglas candidatas:** colecciones de reservas, evaluaciones y cuotas quedan con escrituras solo Admin SDK. **No publicadas**; las reglas actuales de la beta todavía permiten alterar economía en algunas rutas.
9. **Pruebas unitarias/adversariales y de emulador:** suites de Functions, Vision y Flutter, más prueba completa contra Firestore y Storage emulados. **Aprobadas en GitHub Actions el 28/11/2026 (UTC).** La ejecución manual en un teléfono Android aún no consta.

### Categorías soportadas por análisis visual remoto

- `alim_001`, `alim_003`: fruta y verduras.
- `alim_002`, `alim_005`: elementos de comida preparada.
- `hidr_001` a `hidr_009`: objetos visuales asociados a hidratación (vasos/botellas/agua).

Estas correspondencias son **orientativas** y algunas fotos pueden no ser válidas para comprobar la actividad real. Para ejercicio, meditación, sueño, consumo, duración de una caminata y otros objetivos no se asigna «verificado» por una imagen. La prueba visual no interpreta cantidades ingeridas ni indicadores médicos.

## B. Seguridad y despliegue bloqueado

Las evidencias de la beta requieren todas estas condiciones del servidor:

- Proyecto literal `cloud-firestore-d8c61`; base Firestore nombrada `default`, no `(default)`.
- `HH_BETA_HABITS_ENABLED=true`, `HH_BETA_RULES_VERIFIED=true` (solo una vez comprobadas las reglas restrictivas).
- `HH_BETA_TEST_UIDS` limitado a los UIDs de testers, token Firebase Auth y App Check válidos.
- `HH_BETA_EVIDENCE_ENABLED=true` **y** `HH_BETA_EVIDENCE_CLEANUP_ENABLED=true`, con la tarea realmente desplegada y validada.
- Para el análisis remoto: adicionalmente `HH_BETA_VISUAL_ANALYSIS_ENABLED=true`.

Flutter requiere además `HH_BETA_HABITS_CLIENT=true`, `HH_BETA_EVIDENCE_CLIENT=true` y, para la opción en nube, `HH_BETA_VISION_CLIENT=true`. **No activar estas banderas en producción ahora.** No exponer claves privadas, tokens App Check ni UIDs reales en el repositorio.

**Bloqueo mayor previo a beta:** `HabitActionService`, `RegistrarHabitoScreen` (rama de transacción normal), Tienda y otros flujos aún pueden escribir economía/progreso desde el cliente. La prueba `node tools/beta_readiness_gate.mjs` debe seguir denunciándolo. No desplegar `firestore.candidate.rules` ni habilitar beta hasta migrar toda la economía y pasar pruebas adversariales y positivas.

## Verificación automática registrada

El 28/11/2026 UTC, los workflows de GitHub Actions completaron:
- [Integración de beta](https://github.com/roldanvalego602-stack/Healthy-Habit-v2/actions/runs/46097012759): análisis Flutter sin errores bloqueantes, 567 tests Flutter, 193 tests Functions, 15 tests Vision y regresiones de seguridad/funcionalidad aprobadas.
- [Evidencias en emuladores aislados](https://github.com/roldanvalego602-stack/Healthy-Habit-v2/actions/runs/46097089170): 1/1 recorrido integral real contra Auth, Firestore y Storage Emulator, incluyendo recuperación, idempotencia y eliminación.
- Ninguna ejecución desplegó funciones ni alteró el proyecto real. La comprobación no certifica la política de seguridad de las reglas productivas.

## C. Pruebas inmediatas en tu Linux Mint

Desde la raíz del repo, antes de habilitar cualquier flag:

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/beta_evidence_contract_test.dart
flutter test test/habit_evidence_image_preparer_test.dart
flutter test test/healthy_vision_demo_screen_test.dart
flutter test test/beta_habit_gateway_test.dart
npm --prefix functions test
npm --prefix vision-functions test
node tools/beta_readiness_gate.mjs
```

**Nota:** el último comando puede finalizar con bloqueos deliberados. Esto no es un fallo del detector; es la barrera de lanzamiento de la beta.

### Prueba íntegra contra emuladores, sin datos reales

Utiliza el archivo `firebase.evidence-demo.emulator.json`: proyecto `demo-healthy-habit`, Auth 9099, Firestore 8080 (base `default`), Functions 5001 y Storage 9199 con reglas de fotos privadas.

```bash
firebase emulators:exec \
  --config firebase.evidence-demo.emulator.json \
  --only auth,firestore,functions,storage \
  --project demo-healthy-habit \
  "GCLOUD_PROJECT=demo-healthy-habit FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 node --test functions/tests-emulator/habit_evidence_flow.integration.js"
```

**Resultado a confirmar:** reserva → subida → registro oficial de hidratación → asociación → segundo registro idempotente → limpieza → saldo inalterado excepto premios oficiales del registro. Si falla, conservar el error completo; **no** probar en proyecto real como alternativa.

La prueba de emuladores no llama a Google Cloud Vision ni factura, ni necesita fotografías personales. La prueba `vision-functions/evidence_assessment.test.js` usa un proveedor simulado y no consume cuota Cloud Vision.

### Prueba manual Android

Con flags de beta **apagados**, abre Inicio → Mr. Healthy → Reconocimiento de imágenes o Registro de hábito, toma una foto de fruta/comida/botella y revisa las etiquetas y el aviso de análisis local. Verifica que no aparezca una recompensa de 15/20 XP por adjuntar cualquier imagen.

**La integración remota completa aún no debe probarse en tu Firebase real.** El modo demo aislado y las pruebas automáticas son la vía autorizada. Para una beta funcional conectada a Firebase real falta cerrar el resto de las escrituras económicas, auditar reglas y App Check, y validar el flujo con dos dispositivos/cuentas.

## D. Criterios de cierre

- [x] Captura y reducción JPEG sin metadatos de origen (código)
- [x] Análisis local de elementos visuales (código existente)
- [x] Eliminación de XP extra por imagen arbitraria en la ruta normal (código)
- [x] Flujo reservado → subido → registrado → asociado (código)
- [x] Recuperación con identificador original, sin almacenar fotos en diario (código)
- [x] Evaluación opcional de objetos por servidor y sin incentivos (código)
- [x] Consentimiento Vision ligado a una reserva inmutable; sin ese permiso el backend rechaza analizar (código)
- [x] Límites de uso y limpieza programada bloqueada por producción (código)
- [x] Pruebas añadidas
- [x] Análisis Flutter y 567 pruebas Flutter aprobadas en GitHub Actions (Android físico pendiente)
- [x] 193 pruebas de Functions y 15 de Vision aprobadas en GitHub Actions
- [x] Laboratorio integral Auth/Firestore/Storage/Functions Emulator aprobado (1 recorrido completo)
- [ ] Reproducción manual y pruebas con cámara en Android del desarrollador
- [ ] Análisis de precisión con distintas fotografías reales y consentimiento
- [ ] Auditoría de reglas reales + App Check + pruebas adversariales beta
- [ ] Despliegue autorizado y monitorización de costes/retención

**No presentar una foto compatible como validación fuerte del cumplimiento.** El siguiente avance científico será estudiar qué hábitos admiten pruebas de frescura y actividad sin exigir vigilancia ni elementos personales.
