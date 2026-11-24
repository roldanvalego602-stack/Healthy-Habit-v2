# Healthy Habit — Reconocimiento visual, fase 1 (laboratorio)

## Alcance y seguridad

La aplicación principal NO cambia: `lib/páginas/habitos/registrar_habito_screen.dart`
continúa otorgando 10 XP sin imagen o 15 XP por adjuntar imagen.
No existe premio de 20 XP por clasificación visual y el laboratorio
no escribe usuarios, monedas, intentos ni hábitos.

La demo aislada `lib/demo/evidence_demo_main.dart` conecta exclusivamente
a Auth Emulator (9099) y Functions Emulator (5001) del proyecto
`demo-healthy-habit`. La nueva callable `analyzeEvidencePreview`
rechaza cualquier ejecución fuera de ese proyecto y emulador.
Requiere autenticación de prueba y limita la imagen a 250 KB.
No almacena fotografías; solo devuelve hasta 12 etiquetas con confianza
y una coincidencia orientativa o resultado no concluyente.
El resultado siempre contiene `imageVerified: false`,
`xpAwarded: 0` y `coinsAwarded: 0`.

El usuario debe pulsar **Analizar imagen** para enviar la foto al emulador.
Ese emulador llama a Google Cloud Vision si está configurado. El uso real
de Vision API puede implicar facturación y envío de fotografías a Google;
usar únicamente fotografías de prueba sin datos sensibles y con consentimiento.
La demo no garantiza eliminación en la infraestructura de terceros ni
autenticidad temporal de la fotografía. No usarla en producción.

## Pruebas sin facturación

Desde la raíz:

```bash
git pull --ff-only origin main
cd functions
npm test
cd ..
flutter test test/evidence_visual_preview_test.dart
```

Las pruebas de Node usan un detector simulado e imágenes sintéticas.
No consumen la API real de Vision. No asumir que han pasado hasta
ejecutarlas en el entorno local.

## Prueba manual con fotos reales (opcional)

1. Preparar Firebase Emulator Suite (Auth y Functions; Firestore si
   se utiliza el botón de desafío demo) bajo un proyecto **demo**.
2. Configurar de forma deliberada y por separado Google Cloud Vision API,
   su SDK de servidor y credenciales autorizadas para pruebas.
   Revisar costo, cuotas y presupuesto antes de cualquier llamada.
   Desde `functions`: `npm install @google-cloud/vision`.
   Las credenciales deben quedar en el entorno local, nunca en
   Dart, GitHub, Android ni archivos versionados.
3. Iniciar emuladores con el identificador:
   `firebase emulators:start --only auth,functions,firestore --project demo-healthy-habit`.
4. Lanzar Android debug con el entrypoint independiente:
   `flutter run -t lib/demo/evidence_demo_main.dart --dart-define=EMULATOR_HOST=10.0.2.2`
   en emulador Android. En teléfono físico hay que usar IP LAN accesible
   y asegurar reglas de firewall; no usar producción.
5. Conectar sesión demo; seleccionar categoría (hidratación, fruta/verdura,
   comida); tomar fotografía de prueba; pulsar **Analizar imagen**.
   Se muestran objetos y porcentajes estimados; no se registra el hábito.

Si el proveedor no está instalado o autenticado, la llamada responde
error informativo y no afecta progreso ni XP.

## Límites conocidos

- Las etiquetas no demuestran consumo ni cumplimiento de un hábito.
- La detección de "water", "glass" o "food" puede ofrecer falsos positivos.
  Las reglas de vocabulario se calibrarán con fotografías de prueba.
- No hay OCR, comprobación de imagen actual, control de abuso productivo
  ni pruebas con imágenes reales todavía.
- No desplegar la callable sin rediseñar la seguridad y facturación.
- Las fotos de registros normales siguen el mecanismo temporal existente
  (Base64 en Firestore); NO se ha cambiado su almacenamiento ni retención.
