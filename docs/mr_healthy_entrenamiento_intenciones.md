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

## 7. Segunda etapa: comparar un modelo supervisado adicional

Se añadió `tools/chat_intent_compare.py`, que entrena un **Naive Bayes multinomial** a partir de las mismas expresiones etiquetadas y lo contrasta con el clasificador de centroides TF-IDF. Ambos utilizan exclusivamente bibliotecas estándar de Python. Los dos modelos ajustan pesos a partir de ejemplos; ninguno es un modelo generativo ni entiende semántica neuronal.

**Protocolo:**
1. De las 225 frases de entrenamiento, reservar 45 para calibración/desarrollo y usar 180 para ajustar y escoger configuraciones de los dos modelos.
2. Seleccionar alfa, umbrales y modelo favorito mediante métricas de **desarrollo**, penalizando primero predicciones potencialmente destructivas.
3. Entrenar cada modelo final con las 225 frases `train`, aplicando los parámetros elegidos.
4. Evaluar por separado ambos modelos finales con las 90 frases `test`; publicar exactitud, macro-F1, abstenciones, cobertura, matriz de confusión y errores críticos. **No elegir modelos ni umbrales a partir de esos 90 resultados.**
5. Mantener todo **fuera de Flutter y Firebase**. El ganador experimental no puede escribir en la base de datos ni suplantar confirmaciones.

Para ejecutar:

```bash
python3 -m unittest discover -s tools -p 'test_chat_intent_*.py' -v
python3 tools/chat_intent_train.py
python3 tools/chat_intent_compare.py
```

La comparación guarda `outputs/mr_healthy_intent_comparison_v1.json`. Si devuelve código 2, el experimento no alcanzó los objetivos y **no debe integrarse**. Las pruebas comprueban separación entre desarrollo y evaluación, predicciones deterministas, abstención cuando no hay coincidencia y que no se devuelvan acciones ni identificadores de cuenta.

### Ejecución automática

También existe `.github/workflows/mr_healthy_intent_benchmark.yml`, que se dispara al cambiar datasets o herramientas de entrenamiento en la rama de trabajo, o manualmente desde GitHub Actions. Ejecuta pruebas, genera informes del clasificador original y la comparación, y publica dos JSON como artefactos descargables durante 14 días. Un modelo que no alcance el umbral **no se incorpora a la aplicación**; un error de código sí debería marcar el workflow como fallido.

**Estado de validación:** cambios integrados en GitHub. No atribuir puntajes nuevos ni afirmar pruebas aprobadas hasta obtener la ejecución local o los resultados del workflow.

### Límites de este benchmark

- La distribución de 6 frases de evaluación por clase es pequeña. No extraer conclusiones de seguridad para cuentas reales con un solo conjunto.
- Aunque un clasificador supere métricas, la autorización de hábitos/tienda/cuenta debe continuar en los servicios existentes y nunca basarse exclusivamente en la predicción estadística.
- Los mensajes breves como «bórralo», o «¿y ese?» dependen de contexto: evaluar con `datasets/chat_dialogues_es_v1.json` una vez implementado un estado conversacional explícito, no simular que el modelo de un solo turno tiene memoria.
- No afinar las reglas o los ejemplos entrenados con conocimiento de las frases del conjunto `test` usado para medir. Al incorporar nuevos casos, preservar un nuevo conjunto verdaderamente reservado.

## 8. Resultados ejecutados en el equipo (20-nov-2026)

El usuario ejecutó los scripts sobre el commit `d201fdb` y proporcionó la salida de consola:

- **13/13 pruebas unitarias Python** aprobadas.
- **Clasificador inicial TF-IDF**, sin abstención: exactitud **73.3 %**, macro-F1 **0.733**, cobertura **100 %**, **4 errores críticos**.
- **Comparación con calibración de desarrollo:**
  - TF-IDF: exactitud **65.6 %**, macro-F1 **0.708**, cobertura **82.2 %**, **2 errores críticos**.
  - Naive Bayes multinomial: exactitud **68.9 %**, macro-F1 **0.708**, cobertura **95.6 %**, **5 errores críticos**.
- El candidato seleccionado **solo mediante desarrollo** fue TF-IDF. Ninguno alcanzó el criterio de aprobación; ambos siguen desconectados de Flutter.
- Las salidas `REVISAR` y `NO APROBADO` indican **rechazo por métricas**, no fallos en los tests unitarios.

### Diagnóstico sin contaminar la evaluación

Se incorporó `tools/chat_intent_audit.py`, que lee los JSON de resultados existentes y muestra clases con peor F1, pares de confusiones habituales y ejemplos críticos. No entrena, no selecciona parámetros y no cambia el corpus.

```bash
python3 tools/chat_intent_audit.py
python3 tools/chat_intent_audit.py --json
python3 -m unittest discover -s tools -p 'test_chat_intent_*.py' -v
```

La salida incluye preguntas de test ya evaluadas. **No añadirlas sin más al entrenamiento ni ajustar reglas para memorizar sus respuestas**, porque ya no serían una evaluación realmente reservada. Para una nueva versión del clasificador, mejorar exclusivamente datos de desarrollo y obtener **un nuevo test independiente** antes de afirmar mejoría.

**Plan siguiente:** (1) obtener distribución de errores con el auditor; (2) definir un conjunto adicional de ejemplos de desarrollo y casos adversariales sin usar el test anterior como referencia de ajuste; (3) comparar con pruebas nuevas independientes y buscar macro-F1 ≥ 0.85 con cero errores críticos; (4) integrar solamente como señal auxiliar tras validar acciones y confirmaciones en Flutter. La eliminación de cuenta continúa deshabilitada y el clasificador nunca ejecutará escrituras sensibles.

## 9. Auditoría recibida y cortafuegos experimental (20-nov-2026)

El usuario ejecutó las 15 pruebas unitarias correctamente y compartió la auditoría:

| Modelo | Exactitud | Macro-F1 | Cobertura | Errores críticos |
|---|---:|---:|---:|---:|
| TF-IDF calibrado | 65.6 % | 0.708 | 82.2 % | 2 |
| Naive Bayes | 68.9 % | 0.708 | 95.6 % | 5 |

Errores relevantes: editar foto/perfil confundido con eliminar cuenta; consulta matemática confundida con eliminación de hábito; «Bórralo» y «No quiero ese» confundidos con eliminar cuenta. También existe confusión entre **agregar** y **eliminar** hábitos y entre saldo y tienda.

Se añadieron `tools/chat_intent_safety.py` y `tools/test_chat_intent_safety.py`: un filtro **solo de rechazo** que, cuando la predicción del modelo apunta a `eliminar_cuenta`, `eliminar_habito` o `agregar_habito`, comprueba que el texto indique un verbo relevante y el objeto correspondiente. Si el objeto no está expresado, hay conflicto entre cuenta y hábitos o se trata de una referencia ambigua, devuelve `abstenerse`. Todas las salidas incluyen `may_execute_action: false`. **No se integra a Flutter ni sustituye las confirmaciones actuales.**

Este filtro se diseñó tras conocer la evaluación v1, por lo que **no debemos utilizar ese mismo conjunto para presentar ganancias de precisión o seguridad generalizables**. Las pruebas unitarias de comportamiento del filtro tampoco constituyen prueba de eficacia en mensajes reales. Se necesita otro conjunto independiente antes de medir mejoras y considerar su adopción.

Pruebas:

```bash
python3 -m unittest discover -s tools -p 'test_chat_intent_*.py' -v
python3 tools/chat_intent_audit.py
```

El siguiente experimento debe incluir frases **nuevas** en español coloquial, errores tipográficos, solicitudes elípticas y temas no relacionados, con separación explícita de entrenamiento/desarrollo/test. No alterar los 90 ejemplos de `datasets/chat_intents_es_v1.json` para elevar artificialmente los indicadores.

## 10. Tercera etapa: corpus independiente V2 y prueba de seguridad (20-nov-2026)

**Resultados de auditoría V1 suministrados por el usuario:** 15/15 tests Python correctos; TF-IDF calibrado: 65.6 % exactitud, macro-F1 0.708, cobertura 82.2 %, 2 errores críticos. Naive Bayes: 68.9 % exactitud, macro-F1 0.708, cobertura 95.6 %, 5 errores críticos. Ambos **rechazados**.

La nueva iteración **no entrena con las 90 frases V1/test** ni las convierte en ejemplos de entrenamiento. Los archivos son:

- `datasets/chat_intents_es_v2_new.json`: **210 frases nuevas**, 150 para train (10 por intención) y 60 para test (4 por intención), sin duplicados normalizados frente a V1.
- `tools/chat_intent_v2.py`: combina **225 ejemplos V1/train + 150 V2/train = 375 ejemplos** para el ajuste final. Antes de seleccionar parámetros, reserva **45 frases V2/train para desarrollo** y ajusta con las 330 restantes. Las **60 preguntas V2/test** se utilizan exclusivamente al calcular métricas finales, nunca en selección de modelo o umbrales.
- `tools/chat_intent_safety.py`: filtro de abstención para propuestas peligrosas sobre cuenta/hábito, **solo rechaza** y no puede ejecutar ninguna operación.
- `tools/test_chat_intent_v2.py`: comprueba separación de datos, rechaza filtración del test anterior y valida las condiciones de evaluación.
- Workflow CI `.github/workflows/mr_healthy_intent_benchmark.yml` actualizado para publicar `outputs/mr_healthy_intent_v2_report.json` junto a los informes V1.

Se comparan en una misma evaluación cuatro estrategias: **TF-IDF original**, **TF-IDF + filtro**, **Naive Bayes original** y **Naive Bayes + filtro**. Se calculan exactitud, macro-F1, cobertura, abstenciones y errores críticos por estrategia. El candidato se selecciona **solo con métricas de desarrollo** y sus resultados de test no pueden cambiar esa selección. El informe marca `production_ready: false` incluso si alcanza criterios experimentales.

Ejecutar después de actualizar la rama:

```bash
python3 -m unittest discover -s tools -p 'test_chat_intent_*.py' -v
python3 tools/chat_intent_v2.py
```

**Importante:** un programa que devuelve código 2 ha generado su informe, pero no ha satisfecho los criterios de aceptación. Es esperable en esta fase, no es autorización para instalar el clasificador en la aplicación. No se modificaron `nutrichat.dart`, Firebase, reglas de seguridad ni la economía de Healthy Habit.

### Restricciones de inferencia

Este experimento sigue utilizando **datos sintéticos**, no pruebas reales de usuarios. Un pequeño conjunto adicional permite diagnosticar, pero no demuestra fiabilidad clínica, accesibilidad, seguridad estadística ni robustez frente a conversaciones prolongadas. Las fichas educativas continúan siendo la fuente de conocimiento, el modelo solo intenta clasificar intenciones. Antes de habilitarlo se requieren pruebas del sistema completo, consentimientos pertinentes para cualquier uso de conversaciones reales y validación de rutas sensibles.

## 11. Resultado V2 en Ubuntu y corrección de prueba de fugas (20-nov-2026)

Salida del usuario de `python3 tools/chat_intent_v2.py`:

| Configuración | Exactitud | Macro-F1 | Cobertura | Errores críticos |
|---|---:|---:|---:|---:|
| `tfidf_raw` | 76.7 % | 0.829 | 80.0 % | 0 |
| `tfidf_safety` | 76.7 % | 0.826 | 80.0 % | 0 |
| `bayes_raw` | 90.0 % | 0.897 | 100.0 % | 1 |
| `bayes_safety` | 81.7 % | 0.847 | 86.7 % | 0 |

La configuración **`bayes_safety` se eligió únicamente en desarrollo**, pero se rechazó en el conjunto nuevo de 60 frases por quedar por debajo de macro-F1 0.85. `bayes_raw` supera esa cifra, pero presenta un error crítico. No se autoriza ninguno para producción ni se integra a Flutter.

**Incidente de pruebas:** de las 28 pruebas de la suite, falló `test_rejects_leakage_of_previous_evaluation`: el test sustituía `V2` con `patch.object`, pero `v2_rows(path: Path = V2)` había capturado la ruta original al definirse. Así, la prueba no estaba leyendo el dataset adulterado. Se reparó la firma a `v2_rows(path: Path | None = None)` y `prepare(v2_path: Path | None = None)`, resolviendo la ruta en tiempo de llamada. La regresión ahora comprueba tanto inyección explícita como sustitución de ruta, y exige `ValueError` con «Fuga de evaluación». Este arreglo no modifica el dataset, los clasificadores ni el procedimiento estadístico que produjo los números anteriores.

**Validación pendiente tras el arreglo:**

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion
python3 -m unittest discover -s tools -p 'test_chat_intent_*.py' -v
python3 tools/chat_intent_audit.py outputs/mr_healthy_intent_v2_report.json
```

El auditor acepta la estructura `models` del reporte V2 y presenta las confusiones por versión, permitiendo identificar la abstención y el error crítico del modelo sin filtro. Como este test V2 ya fue observado, **no optimizar parámetros contra sus 60 preguntas reservadas y volver a anunciar el resultado como no contaminado**. Reservar un tercer lote independiente para cualquier medición generalizable de una arquitectura modificada.

## 12. V2 confirmada y separación de comprensión vs. seguridad (20-nov-2026)

El usuario confirmó **28/28 pruebas Python aprobadas**, incluida la detección de fugas. Auditoría V2:

| Modelo | Exactitud | Macro-F1 | Cobertura | Críticos |
|---|---:|---:|---:|---:|
| TF-IDF | 76.7 % | 0.829 | 80.0 % | 0 |
| TF-IDF + abstención | 76.7 % | 0.826 | 80.0 % | 0 |
| Naive Bayes | 90.0 % | 0.897 | 100.0 % | 1 |
| Naive Bayes + abstención | 81.7 % | 0.847 | 86.7 % | 0 |

**Problema identificado:** en la evaluación V2, `safe_prediction` reemplaza intenciones sospechosas por `abstenerse`. Esto altera las métricas de reconocimiento y puede reducir drásticamente la recuperación de peticiones legítimas. En la variante Bayes protegida, `agregar_habito` y `eliminar_cuenta` tienen recall 0.25 (1 de 4 cada una), aunque el modelo sin filtro obtenga mejor exactitud. Esta penalización puede ser aceptable en decisiones sensibles, pero debe cuantificarse por separado y no confundirse con la capacidad del modelo para comprender lenguaje.

**Nueva auditoría retrospectiva:** `tools/chat_intent_policy_report.py` vuelve a usar los clasificadores, parámetros seleccionados en desarrollo y corpus V2 ya observado, pero calcula **dos métricas distintas**:

1. **Reconocimiento**: predicción de intención *antes* de cualquier política de seguridad; exactitud, macro-F1, cobertura y confusiones.
2. **Elegibilidad operativa**: sugerencias sensibles incorrectas bloqueadas, sugerencias sensibles incorrectas que permanecen, e intenciones legítimas rechazadas por la política. Una salida de la política nunca autoriza la ejecución: `permission_to_act=false`.

Se añadieron pruebas unitarias `tools/test_chat_intent_policy_report.py` que demuestran que bloquear un falso positivo no convierte retrospectivamente la predicción original en un acierto y que bloquear una intención correcta se contabiliza como rechazo. GitHub Actions generará `outputs/mr_healthy_intent_policy_audit_v2.json` junto al resto de informes.

Comandos:

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion
python3 -m unittest discover -s tools -p 'test_chat_intent_*.py' -v
python3 tools/chat_intent_policy_report.py
```

**Interpretación importante:** esta auditoría usa el conjunto V2/test que ya hemos inspeccionado; es diagnóstica, **no una tercera evaluación independiente ni una nueva mejora medida**. No se han afinado parámetros ni se han modificado el modelo, la política de rechazo o los datos para optimizar estos resultados. La próxima versión con cambios de algoritmo necesitará un nuevo conjunto de evaluación no observado; una eventual integración a Flutter mantendrá autenticación, autorizaciones del backend y confirmación explícita de acciones en rutas separadas.
