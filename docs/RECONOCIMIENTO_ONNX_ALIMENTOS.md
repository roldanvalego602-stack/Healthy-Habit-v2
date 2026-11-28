# Healthy Habit · Modelo específico de frutas y verduras (Android)

**Estado:** integración implementada en el código de Android/Flutter; **requiere comprobar la descarga real y la inferencia en el dispositivo** antes de aprobarla. No concede recompensas ni verifica ingestión.

## Arquitectura

La cámara prepara JPEG privado (máximo 250 KB). Google ML Kit continúa mostrando categorías generales. El usuario puede pulsar **Activar modelo específico** para descargar una sola vez los pesos del modelo. Después, Android ejecuta la inferencia totalmente local mediante Microsoft ONNX Runtime, sin subir fotos a Firebase ni a Hugging Face.

**Modelo elegido:** [SekoKuva Mobile 423K](https://huggingface.co/bcbertenex/sekokuva-mobile-423k), © BC Bertenex Oy, licencia Apache 2.0. El modelo declara 65 clases; incluye `watermelon`, `apple_fruit`, `banana`, `mango`, `carrot`, `broccoli`, `tomato`, entre otras. Fuente de entrenamiento declarada: OpenImages V7, subconjunto con anotación humana (CC BY 4.0). Métrica publicada por el autor: Top-1 67.9 % sobre sus 65 clases; **no se ha comprobado esa precisión en las fotografías de Healthy Habit**.

**Formatos:** archivo ONNX más pesos externos y mapa de clases JSON. Los pesos se descargan desde una revisión fija (`46cc9c69263010519dc471c6f5c74cfd301f25f9`) con HTTPS. Antes de instalarlos se verifica tamaño y el SHA-256 del archivo de pesos:

```
onnx/sekokuva_mobile_classifier.onnx.data
SHA-256: 61c5f90b82503fb1e36f9ffac8a102a2c15856b228ee4dde21654c95c8807fe8
```

Se guardan en el directorio privado de la app. La foto **no se utiliza para entrenar**, ni se adjunta a las solicitudes de descarga; ONNX funciona sin conexión después de instalarse.

### Inferencia

- Entrada: RGB 224×224, redimensionado y recorte central.
- Normalización: media (0.485, 0.456, 0.406) y desviación (0.229, 0.224, 0.225).
- ONNX tensor: FLOAT32 NCHW [1,3,224,224].
- Salida: 65 logits → softmax → mejores cinco hipótesis.
- Regla de presentación: una hipótesis de alimento debe encabezar la lista, tener puntuación por lo menos 40 % y aventajar a la segunda clase por 12 puntos porcentuales. Son **umbrales heurísticos, no calibración estadística**.
- Si no cumple el criterio: «El modelo específico no encontró una clase suficientemente clara».
- Si la instalación o inferencia falla: se mantiene el detector general ML Kit, sin inventar un alimento específico.

## Resultados automáticos y requisitos Android

- **Integridad y ONNX:** el workflow [Verificar modelo ONNX real](https://github.com/roldanvalego602-stack/Healthy-Habit-v2/actions/runs/46101683718) aprobó la descarga desde la revisión fijada, SHA-256 de los pesos, 65 clases, tensor `[1,3,224,224]` y ejecución del grafo.
- **Compatibilidad Android:** la compilación inicial de CI detectó bibliotecas AndroidX que exigen Android Gradle Plugin 8.9.1+, por lo que se actualizó el repositorio a **Gradle 8.11.1, AGP 8.10.1 y Kotlin 2.2.20**. Se requiere **JDK 17** o superior compatible. La compilación del APK debe volver a ejecutarse tras esta actualización.
- El workflow ONNX demuestra compatibilidad de los **pesos en Python**, no prueba todavía su exactitud con fotos reales ni su rendimiento en un móvil Android.

## Comprobación necesaria

```bash
git pull --ff-only origin main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/healthy_specific_food_recognition_test.dart
flutter run
```

Abre **Reconocimiento de imágenes**, selecciona la foto de la sandía y pulsa **Activar modelo específico**. La primera activación descarga solo los pesos; debe mostrar un indicador de descarga, y a continuación ejecutar el modelo. Para comprobar el funcionamiento, prueba también imágenes de plátano, zanahoria, tomate, manzana, un objeto no alimentario y una sopa de letras en pantalla.

Es posible que la sandía siga devolviendo un resultado inconcluso. En ese caso, necesitamos revisar los cinco logits del modelo con fotos variadas y medir sus falsos positivos; **no bajar el umbral a ciegas ni simular un acierto**.

**Pendiente de validación:** compilación Android con ONNX Runtime, disponibilidad de la revisión en Hugging Face y correspondencia real del modelo de 65 etiquetas; verificar en teléfono y medir precisión. Sin esas pruebas, no afirmar reconocimiento fiable.

## Restricción de recompensas

El reconocimiento visual —general o específico— es solo una hipótesis sobre los objetos visibles. **Nunca concede 15/20 XP, monedas ni validez de ingesta**. La ruta de registro oficial de evidencias, Firestore y las funciones de beta siguen separadas, protegidas y deshabilitadas en producción hasta auditoría.

## Requisitos de licencia

Al distribuir la app con este modelo descargable, conservar los avisos de licencia Apache 2.0 y la atribución al autor. Si se modifica el modelo, se debe conservar el registro de cambios y evaluar las obligaciones correspondientes. Las fotos de OpenImages **no se redistribuyen** dentro de la app.

## Referencias

- https://huggingface.co/bcbertenex/sekokuva-mobile-423k
- https://onnxruntime.ai/docs/get-started/with-java
- https://developers.google.com/ml-kit/vision/image-labeling/custom-models/android
