# Mr. Healthy 2.0 — fase 1

## Estado funcional

- FAQ existente y calculadoras IMC/GET: preservadas.
- Motor local de intenciones en `healthy_assistant_engine.dart`: consulta perfil, XP, Habit Coins, racha, hábitos, tienda, camino de niveles, ranking y acceso al directorio de profesionales.
- Respuestas visuales: tarjetas de perfil y barra de XP; botones de acceso directo a pantallas reales.
- Gestión de hábitos: abre la pantalla con búsqueda precargada. **El usuario sigue confirmando altas/bajas** con el flujo existente; no se eluden cupos, requisitos ni penalizaciones.
- Conocimiento: seis fichas educativas iniciales con referencia a USDA/OMS, sin valores numéricos inventados. No se ha importado todavía FoodData Central ni conectado la API.
- Memoria: la conversación activa retiene el tema inmediato para seguimientos sencillos. El historial completo por sesión se guarda bajo el UID y permite recuperar hasta los últimos 80 mensajes de la conversación y consultar los 35 chats recientes.
- Historial: nuevo chat, recuperación y borrado explícito. La función de borrado también elimina documentos de mensajes.
- Profesionales: la pantalla existente contiene datos **de demostración**. No anunciarla como una red de prestadores verificados.
- **No hay todavía modelo generativo, llamada a LLM ni memoria semántica persistente**. Las consultas fuera del catálogo siguen recurriendo a respuestas locales prudentes.

## Reglas de seguridad de Firestore — revisión requerida

No se ha localizado `firestore.rules` en la rama. Integra una regla como la siguiente **dentro del `match /users/{userId}` existente**; no sustituyas el resto de las reglas.

```javascript
match /healthy_chats/{chatId} {
  allow read, create, update, delete: if request.auth != null &&
      request.auth.uid == userId;
  match /messages/{messageId} {
    allow read, create, update, delete: if request.auth != null &&
        request.auth.uid == userId;
  }
}
```

Esto define el aislamiento por UID de la nueva ruta, pero no sustituye auditorías de validación de campos, tamaños, límites de escritura ni prevención de abuso. Para producción, restringir esquemas, longitud de mensajes, titularidad de sesiones, acceso entre usuarios y tráfico malicioso; usar pruebas con el emulador de Firestore.

**No desplegar reglas permisivas globales** (`allow read, write: if true`). Si las reglas actuales niegan las subcolecciones, el chat todavía responderá localmente, pero avisará que no logró guardar el historial.

## Pruebas sugeridas

```bash
flutter analyze --no-fatal-infos lib
flutter test test/healthy_assistant_engine_test.dart
flutter test
```

Validación en Android con sesión autenticada:
1. Preguntar "¿Cómo va mi perfil?" y comprobar XP, monedas, nivel y racha contra Firebase.
2. Preguntar "Agrega Incluir una fruta", usar la tarjeta y confirmar en Hábitos. No debe activarse sin la confirmación.
3. Preguntar "Elimina Incluir una fruta" y verificar la advertencia de penalización del flujo existente.
4. Consultar nutrientes de lentejas y abrir su fuente.
5. Abrir Estadísticas, Mi camino, Ranking, Tienda y Profesionales desde mensajes.
6. Crear un segundo chat, cerrar y reabrir la app, recuperar el primero y eliminar el segundo.
7. Probar modo Lite y oscuro; comprobar textos extensos en 320 dp.
8. Negar temporalmente permisos del historial y confirmar que no se presenta guardado como si hubiera sido exitoso.

## Siguiente implementación

1. Refactorizar operaciones de hábitos a un servicio común para permitir confirmaciones seguras **desde el propio chat**.
2. Indexar un dataset versionado con estructura, fuentes, licencia y revisión, con búsqueda léxica/semántica.
3. Añadir acciones y tarjetas de los módulos Desafíos, Catálogo, Progreso, Logros, Tienda, perfil y profesionales reales.
4. Implementar memoria resumida opt-in con controles de edición y borrado.
5. Incorporar backend generativo opcional en Cloud Functions, con credenciales solo en servidor, consentimiento de transferencia y generación fundamentada en fuentes. Nunca confiar en un modelo para otorgar XP, cobrar monedas o ejecutar efectos sin autorización.
