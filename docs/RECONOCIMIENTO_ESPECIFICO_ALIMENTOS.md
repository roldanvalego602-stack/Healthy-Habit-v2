# Reconocimiento específico de alimentos: contrato y estado

**Estado:** etapa 2.1 implementada en Flutter, sin instalar un modelo especializado nuevo.  
**Objetivo:** mostrar el nombre de un alimento solamente cuando un motor visual haya devuelto explícitamente esa etiqueta con confianza suficiente. No convertir categorías genéricas en nombres de alimentos.

## Comportamiento real

El etiquetador general de Google ML Kit devuelve hipótesis generales como `Fruit`, `Food`, `Vegetable`. El servicio `HealthySpecificFoodRecognition` examina esas etiquetas e identifica nombres conocidos (por ejemplo `Watermelon → sandía`, `Apple → manzana`, `Carrot → zanahoria`) **solo si la etiqueta concreta está presente** y su confianza es por lo menos 70 %.

Si el modelo devuelve `Food 74 %`, `Fruit 63 %` y `Vegetable 35 %`, se conserva la coincidencia de categoría, pero el resultado específico es **«Alimento específico no identificado»**. No se puede concluir «sandía» a partir de ese conjunto de etiquetas, incluso cuando una persona la vea claramente.

La tarjeta visible es independiente de la coincidencia general y no acredita consumo, movimiento, actividad, XP ni Habit Coins. El porcentaje representa la puntuación del etiquetador para ese nombre, **no** la probabilidad de cumplimiento.

## Limitación: todavía no hay un modelo especializado

Esta etapa es una capa de interpretación conservadora, no un clasificador entrenado para alimentos. Para obtener precisión específica real se necesitará un conjunto etiquetado representativo, entrenamiento o selección de un modelo apropiado, evaluación con imágenes no vistas y publicación local del modelo con su versión y atribuciones compatibles. No debe añadirse un archivo `.tflite` arbitrario ni etiquetar fotos manualmente como si fueran inferencias reales.

### Plan del modelo especializado

1. Seleccionar un conjunto inicial de alimentos frecuentes y visualmente distinguibles (sandía, manzana, plátano, zanahoria, tomate, brócoli, huevo y otros), equilibrar clases, iluminación, fondos, encuadres y distintos dispositivos.
2. Separar entrenamiento, validación y prueba por fotografía/fuente, sin permitir que imágenes de una misma sesión aparezcan en ambos conjuntos.
3. Evaluar métricas por clase (precisión, recall, matriz de confusión), detección fuera de catálogo y umbrales por categoría en Android real.
4. Integrar inferencia local en dispositivo, con licencia y modelo versionado; no subir imágenes ni guardar fotos de usuarios para entrenar sin autorización independiente.
5. Mantener posibilidad de resultado inconcluso. Comparar con el etiquetador anterior sin habilitar recompensas automáticas.
6. Repetir pruebas adversariales: imágenes mostradas en pantalla, platos vacíos, comida ilustrada, alimentos parecidos y objetos no relacionados.

## Pruebas de esta etapa

```bash
git fetch origin main && git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/healthy_specific_food_recognition_test.dart
flutter test test/healthy_visual_match_test.dart
flutter run
```

**Resultado visual esperado con la sandía de prueba actual:** «Fruta» como categoría probable y «Alimento específico no identificado» hasta que el detector produzca explícitamente `Watermelon`. No se deben generar cifras de precisión que no procedan del modelo.

**Próxima dependencia:** datos de entrenamiento autorizados o un modelo especializado comprobable. Hasta entonces no anunciar identificación específica de sandía como funcionalidad garantizada.
