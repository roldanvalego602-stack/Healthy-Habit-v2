# Cloud Vision — piloto controlado sobre Firebase Blaze

**Preparado en código; NO desplegado automáticamente.** Usa el proyecto
`cloud-firestore-d8c61`, no `demo-healthy-habit`. No modifica
el archivo `firebase.json` original ni publica las funciones antiguas.

## Arquitectura

- Codebase independiente: `vision-functions/`, desplegado con
  `firebase.vision.json` (solo este codebase).
- Callable: `analyzeEvidencePreviewLive` región `us-central1`.
- Flutter usa la sesión real Firebase Auth SOLO con ambas banderas
  `HH_VISION_DEBUG=true` y `HH_VISION_LIVE_BACKEND=true` en modo debug.
- El servidor rechaza cualquier UID distinto de `HEALTHY_VISION_TEST_UID`.
- Límite persistente: 1 solicitud cada 60 s y máximo 15 por día UTC
  por UID autorizado. Hay una escritura de contador en la colección
  técnica `_vision_preview_pilot_limits` del Firestore real.
- Máximo 250 KB, JPEG/PNG/WebP. Dos operaciones potencialmente facturables
  por análisis: etiquetas y localización de objetos.
- No almacena la fotografía, no escribe registros del hábito,
  no modifica XP ni monedas. Analizar la foto no prueba consumo o conducta.
- `enforceAppCheck:false` es una excepción provisional: piloto privado
  por UID únicamente. **Antes de habilitar para otros usuarios,
  integrar App Check y controles adicionales.**

## Preparación en Google Cloud y Firebase

1. Confirma que el plan Blaze del **proyecto real**
   `cloud-firestore-d8c61` tiene una cuenta de facturación vinculada.
2. Habilita Vision API **en este proyecto** (la que habilitaste en
   `healthy-habit-vision-test` no habilita automáticamente el proyecto real):
   `gcloud services enable vision.googleapis.com --project cloud-firestore-d8c61`
   Necesitas permisos suficientes; no cambies el proyecto predeterminado.
3. Configura una alerta de presupuesto de Cloud Billing y, si procede,
   cuotas de Vision. **Las alertas no detienen el gasto automáticamente.**
4. Comprueba la identidad de servicio de Cloud Functions Gen 2:
   debe tener autorización de uso de Vision API y Firestore. No crees ni
   incluyas claves JSON ni tokens en el repositorio.
5. Busca en Firebase Console → Authentication → Users el **UID de una
   cuenta de pruebas bajo tu control**. No lo publiques ni lo compartas.
   La función rechazará cuentas que no coincidan.

## Comandos en Linux, desde raíz del repositorio

```bash
git fetch origin main
git merge --ff-only origin/main
cd vision-functions
npm install
node --check index.js
cd ..

# Archivo LOCAL que Git ignora:
printf 'HEALTHY_VISION_TEST_UID=%s\n' 'PEGA_AQUI_UID_CUENTA_TEST' \
  > vision-functions/.env.cloud-firestore-d8c61

# Inspecciona qué se desplegará antes de confirmar:
cat firebase.vision.json
firebase deploy --config firebase.vision.json \
  --only functions:vision \
  --project cloud-firestore-d8c61
```

Usa `--only functions:vision` y **NUNCA**
`firebase deploy --only functions` sin la configuración separada.
Se solicita al CLI desplegar solo las funciones del codebase vision.
Si Firebase muestra funciones ajenas para eliminar o modificar,
**cancela el despliegue**.

En caso de que el CLI pida valores de parámetros, configura
`HEALTHY_VISION_TEST_UID` con el UID de pruebas y revisa el archivo
de entorno privado, sin incluirlo en Git.

## Probar la app REAL tras despliegue

```bash
flutter test test/healthy_vision_debug_test.dart
flutter test test/evidence_visual_preview_test.dart
flutter analyze --no-fatal-infos \
  lib/servicios/healthy_vision_debug_service.dart \
  lib/páginas/habitos/healthy_vision_preview_panel.dart

flutter run -t lib/main.dart \
  --dart-define=HH_VISION_DEBUG=true \
  --dart-define=HH_VISION_LIVE_BACKEND=true
```

No necesitas `adb reverse`, ni abrir Firebase Emulator. Utiliza en
Healthy Habit la misma cuenta cuyo UID autorizaste; adjunta la fotografía
a un hábito y pulsa SOLO «Analizar con IA (sin XP)».
No pulses «Guardar registro» si no quieres alterar el registro real.

Los mensajes `permission-denied` indican una cuenta no autorizada;
`not-found` indica falta de despliegue/región incorrecta;
`resource-exhausted` indica límite de solicitudes.
Si ves `unavailable`, consulta los logs
`firebase functions:log --only analyzeEvidencePreviewLive --project cloud-firestore-d8c61`
y comprueba IAM/API/cuotas. No compartas tokens ni datos sensibles.

## Limitaciones

- La lógica de clasificación visual es heurística y orientativa, no una
  prueba suficiente para conceder recompensas.
- El código es preparatorio hasta completar pruebas locales y deployment
  exitoso. No activar para toda la base de usuarios todavía.
- Firestore real sí recibe los contadores técnicos de uso del piloto.
- Revisa la facturación: Blaze no implica que Vision sea gratuito.
