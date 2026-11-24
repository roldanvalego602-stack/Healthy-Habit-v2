# Healthy Habit · Reconocimiento visual (segunda fase)

La primera prueba real de Google Cloud Vision se completó con una captura del clima:
el proveedor devolvió etiquetas como **text**, **font** y **screenshot**.
Elegir «Comida» produjo correctamente un resultado no concluyente.

## Cambios preparados en GitHub (NO desplegados)

- `vision-functions/classifier.js`: clasificador separado y conservador;
  no acepta coincidencias por substring (por ejemplo, «food app») y evita
  que solo «glass» o «bottle» se interpreten como hidratación.
- Umbral orientativo de 0.70 y vocabulario explícito, susceptible de
  falsos positivos y negativos. No certifica ingestión de agua ni comida.
- `vision-functions/classifier.test.js`: pruebas unitarias sin invocar
  Google Cloud Vision ni consumir cuotas.
- `lib/páginas/habitos/healthy_vision_preview_panel.dart`: mensajes
  explicativos, traducción local de etiquetas frecuentes al español,
  seis etiquetas principales y aclaración de qué significa el porcentaje.
- Sin cambios en XP, monedas, Firestore de hábitos ni registro oficial.
  La Cloud Function continúa limitada por UID y cuota (15/día, 1/min).

## Verificación antes de actualizar el backend REAL

```bash
cd ~/Documentos/Integradora/Healthy-Habit
git fetch origin main
git merge --ff-only origin/main
node --check vision-functions/index.js
node --check vision-functions/classifier.js
node --test vision-functions/classifier.test.js
flutter test test/healthy_vision_debug_test.dart
flutter analyze --no-fatal-infos lib/páginas/habitos/healthy_vision_preview_panel.dart
```

El siguiente comando modifica una función del proyecto Blaze real:
ejecutarlo solo después de revisar y aprobar los cambios y confirmar
que el código local pasó las pruebas:

```bash
firebase deploy --config firebase.vision.json \
  --only functions:vision --project cloud-firestore-d8c61
```

Al acabar un despliegue autorizado, reconstruir Flutter para mostrar
los cambios de UI (el backend se actualiza por separado):

```bash
flutter run -t lib/main.dart \
  --dart-define=HH_VISION_DEBUG=true \
  --dart-define=HH_VISION_LIVE_BACKEND=true
```

Probar con una fotografía clara de una fruta, una comida y una imagen
ajena al hábito. El piloto puede cobrar por análisis, así que respetar
el intervalo de 60 segundos entre solicitudes. El sistema sigue siendo
una ayuda de identificación visual, no una prueba de cumplimiento.
