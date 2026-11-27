# Mr. Healthy — Banco de 11,500 preguntas/respuestas (v2)

Fecha: 26 de noviembre de 2026.

## Qué se desarrolló

Se amplió el chatbot local de Healthy Habit con **115 temas editoriales**, distribuidos así:

| Dominio | Temas |
|---|---:|
| Uso de Healthy Habit, configuración, tienda, catálogo y privacidad | 30 |
| Alimentación y nutrición general | 30 |
| Ejercicio, actividad física y recuperación | 20 |
| Productos alimenticios y factores de riesgo | 20 |
| Conversación social, entretenimiento y curiosidades | 15 |
| **Total** | **115** |

Cada tema contiene 4 expresiones o alias, una respuesta base, una explicación adicional contextual y una invitación a seguir conversando. Mediante **25 patrones de pregunta por alias**, hay **11,500 formulaciones diferentes** que el sistema puede reconocer con un índice exacto. Las colisiones entre temas se descartan.

Esto representa **11,500 pares de pregunta-respuesta**, no 11,500 contenidos médicos originales ni 11,500 respuestas editoriales independientes. El clasificador sigue siendo léxico/determinista. **No se entrenó una red neuronal, no se agregó LLM y no se requiere API externa.**

## Archivos

- `assets/knowledge/mr_healthy_topics_v2.json`: 115 entradas editoriales, con detalle y seguimiento.
- `lib/páginas/chatbot/mr_healthy_topic_service.dart`: carga diferida, índice de formulaciones, coincidencias seguras y seguimiento de hasta 3 referencias.
- `lib/páginas/chatbot/nutrichat.dart`: integración sin tocar la lógica de compras, XP, perfil, registros y consultas de datos.
- `tools/generate_mr_healthy_qa.js`: genera el conjunto materializado en JSONL para inspección humana.
- `test/mr_healthy_topic_service_test.dart`: pruebas de cobertura, reconocimiento, continuidad y preguntas sensibles.

## Exportar los 11,500 pares para revisar

Desde la raíz del proyecto:

```bash
node tools/generate_mr_healthy_qa.js
```

Se genera `mr_healthy_qa_11500.jsonl` con una línea JSON por pareja. El archivo exportado no es necesario para ejecutar la app y no debe utilizarse como evidencia de entrenamiento real. Para generar en otra ruta:

```bash
node tools/generate_mr_healthy_qa.js /tmp/mr_healthy_qa.jsonl
```

## Jerarquía de respuesta

1. Moderación de mensajes de autolesión, abuso discriminatorio y señales de urgencia médica.
2. Operaciones confirmadas de calculadora y consultas meteorológicas solicitadas.
3. Motor de intenciones verificadas de Healthy Habit: saldo, hábitos, tienda, catálogo, perfil; nunca ejecuta escrituras desde una respuesta.
4. Banco editorial v2: 115 temas, 11,500 formulaciones y contexto corto.
5. Base educativa anterior: 44 fichas con fuentes y casos detallados de huevo/seguridad.
6. Conversación local de propósito general y fallback.

El contenido de salud es **educativo y general**. No pretende diagnosticar enfermedades ni dar dosis, calorías exactas sin etiqueta, tratamientos, dietas individualizadas o estimaciones médicas. Las referencias de la base anterior incluyen OMS, USDA FoodData Central y FDA; las entradas nuevas requieren **revisión de un profesional** antes de presentarse como contenido clínico o consejo validado.

## Continuidad de conversación

El chat conserva en memoria de la sesión el último identificador de tema y hasta tres referencias consecutivas. Por ejemplo:

```text
Usuario: Háblame de bebidas energéticas.
Mr. Healthy: [explicación y pregunta orientadora]
Usuario: ¿Qué más?
Mr. Healthy: [explicación complementaria sobre bebidas deportivas vs. energéticas]
Usuario: ¿Y si la tomo en la noche?
Mr. Healthy: [continúa el tema y pide aclaración sin suponer dosis]
```

El identificador del último tema se guarda con el mensaje en el historial para permitir retomar **esa misma conversación** cuando se reabre. Al comenzar un chat nuevo se reinicia el contexto. No se conserva un perfil psicológico ni se usan datos privados de otros usuarios. Las preguntas sobre historial o acciones de cuenta se rigen por el motor existente. No hay contexto multi-turno de tipo generativo; algunas conversaciones abiertas seguirán necesitando aclaraciones.

## Validar en Flutter

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/mr_healthy_topic_service_test.dart
flutter run -t lib/main.dart
```

Verifica manualmente consultas como:
- «¿Cómo funciona el tema Cosmos?» → indicaciones de uso; sin comprarlo automáticamente.
- «Explícame entrenamiento de fuerza» → orientación general.
- «¿Qué me puedes decir de bebidas energéticas?» → orientación prudente.
- «¿Qué más?» → detalle relevante del último tema.
- «¿Y si la tomo en la noche?» → referencia contextual, sin inventar dosis.
- «¿Cuántas calorías exactas debo consumir?» → no inventar cifras.
- «No puedo respirar» → urgencia, no consejo ordinario.
- «¿Cuántas Habit Coins tengo?» → verificar datos reales, no responder con el banco editorial.

**Pendiente:** ejecutar Flutter/tests en el equipo, inspeccionar una muestra aleatoria del JSONL y evaluar comprensión con preguntas auténticas de beta. El número de plantillas no equivale a una tasa de acierto probada.

## Fase de calidad conversacional — pruebas de regresión

Se añadió `test/mr_healthy_dialogue_regression_test.dart` con preguntas de los cinco dominios, preguntas habituales con artículos («¿qué es la tienda?»), continuidad del tema, preguntas elípticas, cambio de tema, rechazo de órdenes que no corresponden al banco y consultas médicas o privadas que no deben tratarse con una ficha genérica.

Se endureció `MrHealthyResponseBank` para:
- Priorizar las preguntas explícitas y descartar continuaciones cuando el usuario cambia de asunto.
- Aplicar exclusiones a preguntas de dosis, diagnósticos, intoxicaciones y datos personales.
- Reducir coincidencias de alias incidentales dentro de preguntas largas.
- Entender algunos artículos de preguntas naturales sin ampliar indiscriminadamente la búsqueda.

Estos controles no transforman el banco en un LLM y tampoco demuestran comprensión lingüística general. **Las preguntas reales aún deben probarse con usuarios, sin registrar datos sensibles en informes públicos.**

```bash
flutter analyze --no-fatal-infos lib
flutter test test/mr_healthy_topic_service_test.dart
flutter test test/mr_healthy_dialogue_regression_test.dart
```

No se ejecutaron estas pruebas desde el editor remoto del repositorio: **pendiente validar el resultado local**.

## Fase siguiente — Preferencias y selección de alternativas

El chatbot ahora consulta la **última respuesta real de Mr. Healthy** antes de interpretar elecciones. Se creó `lib/páginas/chatbot/mr_healthy_choice_resolver.dart`, un componente determinista que distingue:

- **Elección ordinal:** «la primera», «la segunda», «la tercera». Solo selecciona si la respuesta anterior contiene una secuencia reconocible de alternativas.
- **Preferencias explícitas:** «prefiero algo barato», «sin lácteos», «en casa», «sin equipo», «misterio» o «aventura».
- **Rechazo:** «no me gusta esa opción», «prefiero otra», sin presumir cuál alternativa desea el usuario.
- **Cambio de tema y preguntas sensibles:** se mantiene la prioridad del detector de seguridad, el motor de operaciones y las consultas verificables de la cuenta.

El alcance inicial abarca **14 menús editoriales**: desayunos, cenas, almuerzos, proteínas, fibra, agua, ejercicio inicial, ejercicios en casa, fuerza, motivación, historias, entretenimiento, tienda y Cosmos. Los demás temas conservan el seguimiento general desarrollado anteriormente. No se inventan recomendaciones personalizadas ni se realizan compras desde el selector.

La integración usa `previousAssistantText` únicamente del chat actual (el último mensaje recibido del bot). Así no basta con que una palabra aparezca en el historial: debe existir una propuesta reciente coherente. Al reabrir una conversación, la última respuesta guardada aporta ese contexto si sigue siendo pertinente.

### Ejemplos de regresión

```text
Usuario: Háblame de desayuno saludable.
Mr. Healthy: ... ¿Prefieres una opción rápida, económica o sin lácteos?
Usuario: La segunda.
Mr. Healthy: Para un desayuno económico, puedes preparar...
Usuario: No me gusta esa opción.
Mr. Healthy: ¿Quieres probar otra alternativa: rápida, económica, sin lácteos?

Usuario: ¿Qué es empezar ejercicio?
Mr. Healthy: ... ¿Prefieres una rutina breve de casa o caminata?
Usuario: Prefiero hacerlo en casa.
Mr. Healthy: Para empezar en casa, prueba marcha suave...
```

**Limitación:** esto sigue siendo un sistema de opciones guionizadas, no comprensión libre de lenguaje natural. Los menús no detectados deben pedir aclaración, no asumir decisiones.

Pruebas incluidas en `test/mr_healthy_choices_test.dart`:

```bash
flutter analyze --no-fatal-infos lib
flutter test test/mr_healthy_choices_test.dart
flutter test test/mr_healthy_topic_service_test.dart
flutter test test/mr_healthy_dialogue_regression_test.dart
```

Estado: **cambios guardados en GitHub; no compilados en Android ni ejecutados localmente desde este entorno**.

## Fase de variedad y mayor cobertura de preferencias

La capa conversacional ahora incluye **30 menús editoriales** (los 14 anteriores más 16 nuevos). Se añadieron menús para Inicio, Hábitos, registros, Catálogo, Misiones, plato equilibrado, colaciones, carbohidratos, verduras, frutas, cardio, ejercicios sin equipo, planchas, estiramientos, planetas y Luna.

El motor también dispone de respuestas alternativas redactadas para distintas preferencias frecuentes. El índice de turno se conserva **solo en la conversación actual y mientras el tema no cambie**, con lo que una preferencia repetida puede recibir otra opción apropiada. Los textos no se crean con IA generativa y no se inventan cambios de saldo, XP ni tratamientos.

Reglas:
- La última intervención del asistente debe mostrar **al menos dos opciones identificables**: mencionar incidentalmente un alimento o una actividad no constituye un menú.
- Las elecciones ordinales utilizan el orden de las opciones de la **última propuesta**, no palabras que aparezcan antes en la explicación.
- No se repite exactamente el mismo cierre en cada turno; se alternan tres fórmulas de seguimiento.
- Preguntas médicas sensibles, comandos que requieren confirmación y cambios de tema continúan fuera del selector editorial.
- El contador de variedad vuelve a cero al cambiar de asunto, comenzar una nueva conversación o resolver una acción de la cuenta.

Se agregó `test/mr_healthy_variety_test.dart` para comprobar cobertura de opciones, orden, cambios de tema, ausencia de menús falsos, seguridad y variedad por turno.

Validación recomendada:

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/mr_healthy_topic_service_test.dart
flutter test test/mr_healthy_choices_test.dart
flutter test test/mr_healthy_dialogue_regression_test.dart
flutter test test/mr_healthy_variety_test.dart
```

**Estado:** revisión estática de catálogos y de opciones completada desde GitHub, con 30 menús y al menos dos opciones verificables en cada propuesta. No se ejecutaron pruebas de Flutter desde el editor remoto; es obligatorio confirmarlas en el entorno de desarrollo antes de asegurar que la versión compila.

## Fase de preferencias combinadas — 26 de noviembre de 2026

Se añadió soporte para **12 combinaciones de dos condiciones**, distribuidas en nueve temas de alimentación y ejercicio. El selector conserva prioridad para operaciones verificables, preguntas clínicas sensibles y cambios de tema. Solo funciona cuando hay un tema reciente y una propuesta real de Mr. Healthy, sin crear acciones ni consultar datos privados.

Combinaciones cubiertas: desayuno rápido sin lácteos; desayuno barato sin lácteos; desayuno rápido y barato; cena vegetariana económica; comida o fibra económica para llevar; colación económica sin refrigeración; ejercicio en casa sin equipo; caminar sin equipo; fuerza en casa sin equipo; cardio caminando con poco tiempo; y ejercicio suave ante cansancio y falta de tiempo.

El motor usa respuestas editoriales completas para cada par; **no concatena automáticamente dos respuestas** que podrían contradecirse. Si la frase activa varias combinaciones a la vez (por ejemplo, rápido, barato y sin leche), pide que el usuario indique cuáles son imprescindibles. No se equipara «para llevar» con «sin refrigeración», ni una preferencia negada con una afirmación.

Archivo de implementación: `lib/páginas/chatbot/mr_healthy_choice_resolver.dart`.
Pruebas: `test/mr_healthy_combined_preferences_test.dart`.

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/mr_healthy_combined_preferences_test.dart
flutter test test/mr_healthy_choices_test.dart
flutter test test/mr_healthy_variety_test.dart
flutter test test/mr_healthy_dialogue_regression_test.dart
flutter test test/mr_healthy_topic_service_test.dart
```

**Limitación:** esto es una matriz finita de combinaciones revisadas, no razonamiento lingüístico generativo. Las combinaciones no incluidas pueden pedir aclaración o continuar por el sistema anterior. La implementación aún requiere validación con Flutter en el equipo de desarrollo.
