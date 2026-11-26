# Reconocimiento de imágenes para todas las cuentas — despliegue pendiente

La función `analyzeEvidencePreviewLive` está preparada en la rama `feature/mr-healthy-foundations` para cualquier usuario autenticado de Healthy Habit. **No se ha desplegado ni verificado con dispositivos reales.**

## Seguridad y costos
- Firebase Authentication obligatorio; token App Check obligatorio en Cloud Functions (`enforceAppCheck: true`).
- Android: Play Integrity en producción; proveedor de depuración para compilaciones debug.
- **Registrar la app Android en Firebase Console → App Check** y verificar certificados/Play Integrity antes de desplegar. Para pruebas debug, registrar el token de depuración únicamente en la consola; nunca en GitHub.
- Límites persistentes: 3 análisis/día UTC por usuario, 100 análisis/día UTC globales, y una solicitud por minuto por usuario. Estos controles restringen el consumo, pero no garantizan un límite monetario absoluto. Establecer presupuestos, alertas y cuotas en Google Cloud.
- Imagen de máximo 250 KB; análisis de etiquetas y localización de objetos (dos operaciones potencialmente facturables). No almacenar fotografías en el servicio de IA; el registro normal de evidencias es independiente.
- El análisis no demuestra que la persona haya completado el hábito; no concede XP ni monedas.
- La implementación de Flutter utiliza `firebase_app_check: ^0.3.2+3` para compatibilidad con el SDK Firebase 3.x existente.

## Despliegue controlado

1. En Firebase, habilitar App Check para la app Android del proyecto real `cloud-firestore-d8c61`. Configurar Play Integrity y registrar los tokens de debug en las pruebas.
2. Habilitar Vision API en ese mismo proyecto y comprobar la facturación Blaze, permisos y cuotas.
3. En el directorio raíz del repositorio:

```bash
git fetch origin feature/mr-healthy-foundations
git merge --ff-only origin/feature/mr-healthy-foundations
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/healthy_vision_debug_test.dart
flutter test test/evidence_visual_preview_test.dart
cd vision-functions
npm install
node --check index.js
node --test classifier.test.js
cd ..
firebase deploy --config firebase.vision.json --only functions:vision --project cloud-firestore-d8c61
```

No usar `firebase deploy --only functions` sin la configuración independiente. Si Firebase propone borrar otras funciones, cancelar la operación. La variable `HEALTHY_VISION_TEST_UID` ya no se utiliza.

4. Iniciar la app y probar con al menos dos cuentas distintas. Verificar límites, rechazo sin App Check, errores sin sesión, diferencias por plataforma y consumo facturable. La función solo tiene soporte de App Check configurado para Android/iOS; para web revisar proveedor antes de lanzamiento.
5. En Google Cloud Console comprobar métricas y presupuesto tras desplegar. Las alertas de presupuesto no detienen los cargos por sí solas.

**Estado: código modificado; compilación, pruebas y despliegue pendientes.**
