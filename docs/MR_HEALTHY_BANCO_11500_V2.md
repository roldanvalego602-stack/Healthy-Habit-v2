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
