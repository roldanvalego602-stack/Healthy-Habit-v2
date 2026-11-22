# Mr. Healthy — arquitectura híbrida v1

**Implementación:** rama `feature/mr-healthy-voice-knowledge-motion`.  
**Objetivo:** utilizar conocimiento educativo local sin alterar las acciones de Healthy Habit (Hábitos, Tienda, Perfil, XP, retos o estadísticas).

## Componentes

1. **Interfaz y orquestación:** `lib/páginas/chatbot/nutrichat.dart`.
2. **Contrato común:** `lib/páginas/chatbot/healthy_assistant_reply.dart` (`HealthyAssistantReply`).
3. **Acciones de la aplicación:** `lib/páginas/chatbot/healthy_assistant_engine.dart`. Resuelve solicitudes sobre cuenta, navegación y acciones con confirmación. Sigue reutilizando los servicios de Firebase del proyecto; **no debe mutar datos desde una ficha educativa**.
4. **Conocimiento educativo:** `lib/páginas/chatbot/healthy_hybrid_knowledge.dart`. Carga una sola vez el asset JSON, normaliza las consultas, obtiene candidatos y prepara la respuesta con procedencia.
5. **Dataset:** `assets/knowledge/mr_healthy_es_v1.json`, `schemaVersion: 1`, `language: es`, **44 fichas** clasificadas en alimentación, hidratación, descanso, movimiento y hábitos.
6. **Conversación y cálculos existentes:** `healthy_conversation_service.dart`, `nutri_respuestas_service.dart` y `nutri_calculator_service.dart`. Siguen utilizándose cuando corresponde.

## Prioridad de las rutas

```text
Entrada usuario (texto o voz)
  → controles de seguridad y moderación existentes
  → IMC/GET activos y clima (cuando corresponde)
  → lectura de datos de cuenta cuando se requiere y existe autorización
  → HealthyAssistantEngine: acciones de app / tarjeta / confirmación
  → HealthyHybridKnowledge: consulta educativa
  → conversación general y respuestas programadas
```

Una ficha no permite conceder XP, gastar monedas, registrar hábitos ni actualizar Firebase. Una solicitud sobre saldo o progreso no se responde a partir del dataset.

## Recuperación y límites reales

- **V1 no es un modelo de lenguaje ni búsqueda semántica neuronal.** Es una búsqueda léxica mejorada: normalización de acentos, tokenización, eliminación de palabras vacías, alias y señales ponderadas por título/etiquetas.
- La búsqueda exige puntuación mínima y evita elegir una ficha cuando dos candidatos están demasiado próximos. Preguntas fuera de cobertura devuelven una negativa controlada en lugar de inventar datos.
- El dataset no incluye información cuantitativa de macronutrientes, calorías, dosis ni recomendaciones clínicas. Cuando se solicitan cantidades, responde explícitamente que no dispone de cantidades verificadas.
- Se conservan la tarjeta y el enlace a **OMS** o **USDA FoodData Central** cuando la ficha contiene URL del dominio permitido. Para orientaciones internas sin enlace oficial no se ofrece un enlace ficticio.
- Las fuentes son **referencias de consulta**. Su presencia no significa que cada frase haya pasado una revisión científica formal: conviene revisar fecha de actualización, contexto y atribución antes de publicar el contenido como consejo avalado.
- Al faltar el asset, el sistema comunica que la base educativa no está disponible; las acciones de la cuenta no dependen de ese archivo.
- El archivo `healthy_knowledge_base.dart` es contenido heredado y **ya no es consultado** por `nutrichat.dart` ni por `nutri_respuestas_service.dart`; no deben volver a mezclarse las dos fuentes de respuestas sin una migración explícita.

## Esquema de las fichas

```json
{
  "id": "avena",
  "category": "alimentacion",
  "title": "Avena",
  "aliases": ["avena", "hojuelas de avena"],
  "tags": ["fibra", "cereal", "desayuno"],
  "answer": "Texto educativo general...",
  "source": {
    "name": "USDA — FoodData Central",
    "url": "https://fdc.nal.usda.gov/"
  }
}
```

Los valores anteriores son un ejemplo de esquema, no una copia completa. Para agregar fichas, editar el JSON manteniendo IDs únicos, `schemaVersion: 1`, `language: es` y fuentes honestas. Evitar respuestas que impliquen diagnósticos, dosificaciones o cálculos sin datos validados.

## Pruebas

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/chatbot/healthy_hybrid_knowledge_test.dart
flutter run
```

Validar manualmente:

| Pregunta de ejemplo | Ruta esperada |
|---|---|
| «¿Cuántas Habit Coins tengo?» | Perfil/Firestore; nunca dataset |
| «Quiero agregar un hábito» | Acción guiada, requiere confirmación |
| «¿Qué es la avena?» | Ficha local + referencia |
| «¿Cómo obtener más fibra?» | Ficha local con alias |
| «¿Cuántas calorías tiene la avena?» | Ficha educativa sin inventar cantidades; la ficha del catálogo anterior puede tener prioridad |
| «¿Qué es un planeta?» | Conversación general, sin afirmar datos nutricionales |
| «¿Qué alimento cura la diabetes?» | No sugerir curas ni reemplazar atención médica |
| «¿Cuál es mi contraseña?» | No acceder a secretos |

**Estado de validación:** cambios integrados mediante GitHub; las pruebas y el análisis todavía requieren ejecución en Flutter. La suite de reglas de Firestore sigue independiente: no se despliegan reglas ni se modifica la economía.

## Corrección de intenciones y seguimiento (20-nov-2026)

El usuario observó dos errores en un dispositivo: «¿Cuántas monedas tengo?» respondía con conversación genérica; «Quiero borrar mi cuenta» regresaba una tarjeta para abandonar hábitos. También las preguntas sobre el huevo repetían una descripción genérica, incluso para riesgos o preparaciones con jamón.

**Cambios:**

- `healthy_intent_router.dart`: clasifica consultas de saldo expresadas como «cuántas monedas», «mi saldo», «cuánto dinero me queda», «Habit Coins» y solicitudes para borrar la cuenta; el objeto de la acción importa, no solamente el verbo «borrar». Preguntas sobre compras/precios no se confunden con saldo.
- `healthy_assistant_engine.dart`: verifica eliminación de cuenta y saldo **antes** de las acciones sobre hábitos. La respuesta sobre la cuenta aclara que **no hay backend de borrado integral** y no borra absolutamente nada. El saldo solo se deriva del perfil previamente consultado.
- `nutrichat.dart`: cuando se solicita saldo con las expresiones reconocidas, refresca los datos del perfil. Guarda el ID de la ficha educativa usada para una pregunta consecutiva y lo reinicia al cambiar de tema o sesión.
- `healthy_hybrid_knowledge.dart`: preserva contexto para frases como «¿y si le agrego jamón?» después de hablar del huevo; prioriza fichas específicas sobre la ficha general. Diferencia preparación, seguridad, cocción y frecuencia del consumo. El contrato compartido `HealthyAssistantReply` contiene `knowledgeId` sin permitir escribir en Firebase.
- Dataset actualizado a **44 fichas** con referencias de FDA para cocción segura de huevos y OMS para carnes procesadas; las referencias siguen siendo enlaces de consulta y requieren revisión editorial.
- La lista permitida de enlaces oficiales en `nutrichat.dart` incluye `www.fda.gov`.
- Nueva batería de pruebas: `test/chatbot/healthy_intent_regression_test.dart`. Comprueba variaciones de saldo, borrado de cuenta, borrado de hábito, huevo genérico, daño, jamón, pronombres de seguimiento, frecuencia y enlaces.

**Validación pendiente:** `flutter analyze --no-fatal-infos lib` y `flutter test test/chatbot`. Los cambios se hicieron en GitHub sin ejecutar Flutter localmente; una prueba solo está confirmada cuando el usuario aporta el resultado.

**Límite importante:** no hay entrenamiento de un LLM ni aprendizaje automático continuo. Las mejoras provienen de datos especializados, alias, detección de intención, reglas de prioridad y continuidad conversacional. Para más temas harán falta fichas contrastadas y pruebas de diálogo.
