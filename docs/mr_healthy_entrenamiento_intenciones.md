# Mr. Healthy — primera etapa de entrenamiento de intenciones

**Estado:** corpus y entrenador implementados en la rama `feature/mr-healthy-voice-knowledge-motion`. **Experimento aislado:** el modelo NO está conectado al chatbot Flutter ni autoriza operaciones. La lógica de cuenta, hábitos y economía continúa con sus controles actuales.

## 1. Por qué empezar con un clasificador

El problema observado en Android es una clasificación incorrecta de intenciones: «¿Cuántas monedas tengo?» se trataba como conversación general y «Quiero borrar mi cuenta» se confundía con abandonar un hábito. Antes de incorporar un LLM, debemos medir si una representación entrenable reconoce variantes no codificadas y qué errores introduce.

**Entrenamiento real en esta fase:** el algoritmo ajusta sus representaciones y pesos TF-IDF a partir de ejemplos etiquetados y calcula centroides por clase. No entrena un modelo generativo ni un Transformer. Es una línea base interpretable, reproducible y ejecutable con Python estándar sin API ni facturación.

## 2. Datos (sin información personal)

- `datasets/chat_intents_es_v1.json`: **315 expresiones sintéticas y etiquetadas**, redactadas para Healthy Habit; 15 intenciones, 225 ejemplos `train` (15 por clase) y 90 `test` (6 por clase).
- Los conjuntos están separados mediante un campo `split`; el validador rechaza frases duplicadas normalizadas, IDs repetidos, etiquetas desconocidas y clases sin ejemplos suficientes.
- **No** se copiaron conversaciones privadas de usuarios. El corpus no incorpora credenciales, IDs, correos, saldos reales ni historial de alimentación personal.
- `datasets/chat_dialogues_es_v1.json`: **20 conversaciones** con 42 turnos anotados; se reservan para evaluación de contexto/memoria en una fase posterior. No se usan para entrenar el modelo de una sola pregunta.
- Etiquetas: `consultar_saldo`, `consultar_xp_nivel`, `consultar_racha_progreso`, `agregar_habito`, `eliminar_habito`, `eliminar_cuenta`, `editar_perfil`, `abrir_tienda`, `consultar_logros_desafios`, `consultar_nutricion`, `consultar_movimiento`, `consultar_descanso_hidratacion`, `ayuda_aplicacion`, `fuera_de_alcance`, `ambiguo_necesita_aclaracion`.

**Limitación:** el corpus inicial es sintético y pequeño. Puede no representar todas las abreviaturas, acentos regionales, errores de escritura, usuarios reales o diálogos largos. La evaluación reservada NO demuestra generalización en producción.

## 3. Algoritmo e independencia de evaluación

`tools/chat_intent_train.py`:

1. Normaliza acentos y signos.
2. Extrae unigramas, bigramas y n-gramas de caracteres de 3 a 5 posiciones.
3. Calcula TF-IDF solo con las frases de entrenamiento.
4. Ajusta un centroide normalizado por intención.
5. Usa los últimos tres ejemplos **del split train de cada clase** como conjunto interno de desarrollo para calibrar un umbral de similitud y margen entre la primera y segunda clase. El conjunto `test` no participa en esta calibración.
6. Reentrena los centroides con las 225 frases `train` y calcula métricas **una sola vez** en las 90 frases `test`.
7. Exporta `outputs/mr_healthy_intent_model_v1.json` y `outputs/mr_healthy_intent_report_v1.json`: exactitud, cobertura, abstenciones, macro-F1, precisión/recobrado/F1 por clase, matriz de confusión y ejemplos mal clasificados.

El modelo se **abstiene** cuando no alcanza la similitud o separación mínima; una abstención no ejecuta ninguna acción.

**Criterio de aprobación experimental:** macro-F1 >= 0.85 y **cero enrutamientos críticos** en el test (p. ej. una pregunta ambigua predicha como eliminación de cuenta/hábito, confundir editar perfil con eliminar cuenta o confundir borrar cuenta con borrar hábito). Si no se cumple, el entrenador devuelve código 2 **después de escribir el informe**, para permitir análisis de fallos. Estos criterios no son autorización para desplegarlo: todavía harían falta evaluación en otros usuarios y garantías del cliente.

## 4. Cómo reproducir en tu computadora

Desde el directorio raíz de Healthy Habit:

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion

python3 -m unittest discover -s tools -p 'test_chat_intent_train.py' -v
python3 tools/chat_intent_train.py
python3 tools/chat_intent_train.py --predict "¿Cuántas monedas me quedan?"
```

Se utiliza la biblioteca estándar de Python 3. No hay que instalar PyTorch, scikit-learn, TensorFlow, paquetes de terceros, claves ni un backend.

Si el entrenador sale con código 2, **no significa que haya fallado la ejecución del programa**: significa que el clasificador no alcanzó las métricas de aceptación. Revisa el JSON de reporte para identificar clases confundidas. El comando `--predict` utiliza el modelo generado previamente.

Para la aplicación Flutter, las pruebas siguen siendo independientes:

```bash
flutter analyze --no-fatal-infos lib
flutter test test/chatbot
```

## 5. Resultado preliminar y siguientes iteraciones

En una comprobación exploratoria externa a la ejecución oficial del script se reprodujo el cálculo del clasificador TF-IDF con los 315 ejemplos y se observaron **66/90 predicciones correctas (~73.3 %) sin aplicar los umbrales de abstención**. Esta comprobación es diagnóstica; **no reemplaza el informe generado por Python**, cuya calibración y macro-F1 deben calcularse localmente.

Entre las confusiones preliminares estaban saldo frente a tienda, edición frente a eliminación de cuenta, movimiento frente a descanso y preguntas ambiguas. **No es apto para sustituir las reglas actuales**. La siguiente iteración debe mejorar datos y características usando el conjunto de desarrollo; no reescribir ejemplos simplemente para aprobar el test reservado. Para un resultado más fiable, reservar un segundo conjunto nunca consultado y posteriormente recopilar, con consentimiento, expresiones reales anonimizadas.

## 6. Reglas de seguridad

- Este modelo **solo propone una intención**; nunca recibe permisos de escritura, identificadores ni tokens de Firebase.
- **Nunca** llamar acciones sensibles basándose únicamente en la predicción. Borrado de cuenta sigue deshabilitado hasta contar con un servicio backend; los hábitos y compras requieren comprobaciones y confirmación de usuario.
- **Nunca** permitir que un LLM o dataset calcule o conceda XP o Habit Coins. Se leen y modifican solo mediante rutas autorizadas del backend.
- Consultas educativas siguen `healthy_hybrid_knowledge.dart` y sus fuentes; el clasificador no sustituye la base de nutrición ni emite consejos clínicos.
- Si la similitud es baja, las clases compiten o falta contexto, la respuesta apropiada es pedir una aclaración, no adivinar ni ejecutar acciones.
- No utilizar el conjunto reservado de 90 preguntas para ajustar palabras clave o hiperparámetros: se degradaría la validez de la evaluación.

**Próximo hito:** revisar informe de Python y matriz de confusión, enriquecer ejemplos de desarrollo y comparar un segundo modelo ligero con las mismas separaciones de entrenamiento. Solo después considerar uso del clasificador como señal adicional, nunca como autoridad, en `HealthyAssistantEngine`.
