# Mr. Healthy 2.0 — fases 1, 2 y 3

## Estado funcional

- FAQ existente y calculadoras IMC/GET: preservadas.
- Motor local de intenciones en `healthy_assistant_engine.dart`: consulta perfil, XP, Habit Coins, racha, hábitos, tienda, camino de niveles, ranking y acceso al directorio de profesionales.
- Respuestas visuales: tarjetas de perfil y barra de XP; botones de acceso directo a pantallas reales.
- Gestión de hábitos (fase 2): puede **agregar o abandonar hábitos oficiales directamente en el chat** mediante una tarjeta animada, verificación de estado y un diálogo de confirmación explícito. Si el usuario no proporciona el nombre, abre un selector con búsqueda. Los hábitos personalizados ajenos al catálogo oficial se siguen administrando desde la pantalla de Hábitos.
- La pantalla de Hábitos y el chat consumen `habit_action_service.dart`: se reutilizan reglas de desbloqueo, cupos, saldo, penalización de hábitos difíciles (hasta 25 Habit Coins), estados de intentos y transacciones de Firestore.
- El servicio incrementa `habitMutationVersion` en el documento de usuario para detectar solicitudes simultáneas generadas por **esta versión del servicio**. Las versiones antiguas de la app no actualizan ese campo: se recomienda actualizar todos los clientes y considerar una función de backend para garantías de concurrencia más fuertes.
- Antes de abandonar se coteja el intento actual y se evita cobrar una penalización superior al máximo expresamente confirmado. Una operación que falla o que el usuario cancela no anuncia éxito.
- Animaciones: entrada de mensajes, tarjeta de operación, transición entre cargando/listo/confirmado y celebración tras una transacción confirmada. En Lite la entrada y las transiciones decorativas son inmediatas.
- Conocimiento: seis fichas educativas iniciales con referencia a USDA/OMS, sin valores numéricos inventados. No se ha importado todavía FoodData Central ni conectado la API.
- Memoria: la conversación activa retiene el tema inmediato para seguimientos sencillos. El historial completo por sesión se guarda bajo el UID y permite recuperar hasta los últimos 80 mensajes de la conversación y consultar los 35 chats recientes.
- Historial: nuevo chat, recuperación y borrado explícito. La función de borrado también elimina documentos de mensajes.
- Profesionales: la pantalla existente contiene datos **de demostración**. No anunciarla como una red de prestadores verificados.
- **No hay todavía modelo generativo, llamada a LLM ni memoria semántica persistente**. Las consultas fuera del catálogo siguen recurriendo a respuestas locales prudentes.

## Fase 3 — acciones y tarjetas por módulo

- **Tienda**: el usuario puede solicitar artículos por nombre o elegirlos de la colección. La tarjeta muestra saldo e inventario desde `ShopService.watch()`, y permite comprar, equipar o quitar artículos con un **diálogo de confirmación antes de cada operación**. Las mutaciones reales siguen usando `ShopService.buy/equip`, no instrucciones generadas por el chatbot. El resultado solo se anuncia después de que la operación termine correctamente.
- **Memoria contextual**: se conserva el último artículo referido en el historial para seguir conversaciones como "quiero comprar corona" → "cómpralo", sin cambiar nada automáticamente.
- **Desafíos**: tarjeta con datos de la subcolección `users/{uid}/challenges`: desafíos activos, disponibles, por reclamar y barras de avance. Aceptar y reclamar permanecen en `DesafiosScreen` para no duplicar la lógica que acredita XP y monedas.
- **Logros**: tarjeta que utiliza el mismo `LogrosService.progreso` que la colección para mostrar cuántos logros se han alcanzado y qué objetivos faltan. No concede premios.
- **Editar perfil**: vista previa de nombre, usuario y biografía actualizados desde Firestore y acceso a `EditarPerfilScreen`. Los cambios exigen usar las validaciones existentes del formulario.
- **Animaciones**: apertura/cambio de contenido de las tarjetas mediante `AnimatedSize`, aparición de barras de progreso con `TweenAnimationBuilder`, botones de confirmación y celebración al terminar un canje/equipamiento. Toda decoración respeta `HealthyVisualEffects` (Lite y reducir movimiento).
- **Limitación significativa**: el módulo de Desafíos contiene un conjunto inicial con progreso de demostración; los datos que el chat presenta proceden de esos documentos, pero **no equivalen necesariamente a actividad real comprobada**. Por eso las reclamaciones NO se ejecutan desde el chat, y la tarjeta advierte de esa limitación. Antes de producción, reemplazar el sembrado de progreso ficticio por estado comprobado y revisar reglas de concesión de XP.
- **Seguridad**: las reglas Firestore deben impedir que un cliente cambie los saldos, `shopInventory`, estados de retos o XP sin validación servidor. Las transacciones del cliente son útiles para consistencia, pero no sustituyen autorizaciones del backend.

### Pruebas adicionales

```bash
flutter test test/healthy_chat_modules_test.dart
flutter test test/healthy_assistant_engine_test.dart
```

Consultar desde Mr. Healthy: "Mis desafíos", "¿Qué logros tengo?", "Quiero comprar corona", "Cómpralo" y "Cambiar mi nombre". Comprobar que los importes y barras reflejen Firestore, que cancelar una compra no cambie las monedas, y que la edición abra el formulario original.

## Integración selectiva de la rama Mijo

Se integraron características específicas de `Mijo` sin hacer merge completo ni reemplazar la arquitectura de Mr. Healthy 2.0:

- `lib/servicios/clima_servicio.dart`: consulta meteorológica basada en el servicio aportado por `Mijo`, con fuente Open-Meteo y consejos de hábitos por clima. **Privacidad reforzada**: se solicita ubicación solo cuando el usuario pregunta por el clima; si deniega permiso, la consulta termina sin geolocalización por IP. Las coordenadas se redondean a dos decimales antes de consultar el clima y nunca se guardan en el historial.
- `nutrichat.dart`: reconoce solicitudes como "¿Cómo está el clima hoy?" y muestra la respuesta real con indicación de ubicación aproximada. Se conserva nuestro motor de intenciones, las tarjetas, las acciones confirmadas y las sesiones de Firestore.
- `nutri_calculator_service.dart`: se adaptó el reconocimiento de cambios claros de tema desde `Mijo`, preservando los cálculos IMC/GET actuales. Si el usuario cambia de tema durante un cálculo, puede elegir "Continuar cálculo" o "Salir del cálculo". Si sale, debe repetir su otra pregunta; no se consulta la ubicación mientras un cálculo espera confirmación.
- Se añadieron las dependencias `geolocator` y `http`, permisos de ubicación de primer plano para Android y descripción de uso en iOS. No se incorporaron `pedometer` ni `permission_handler` porque no son necesarios para esta integración.
- No se copió el historial local `SharedPreferences` de `Mijo`, ya que duplicaría el historial por usuario existente en Firestore. Tampoco se copió su `nutrichat.dart`, ni se mezclaron cambios de autenticación o configuración sin una auditoría propia.

**Verificación local necesaria:**

```bash
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/mijo_selective_integration_test.dart
flutter test test/healthy_assistant_engine_test.dart
flutter run
```

Pruebas manuales recomendadas:
1. Solicitar el clima con permiso de ubicación concedido y comprobar temperatura y consejos; denegar ubicación y comprobar que no haya consulta alternativa basada en IP.
2. Iniciar cálculo de IMC; preguntar por el clima; continuar el cálculo y completar el paso anterior sin perder datos.
3. Repetir y elegir salir: el cálculo debe quedar cancelado sin consultar el clima hasta que el usuario vuelva a pedirlo.
4. Abrir historial, tiendas, hábitos, desafíos y tarjetas previas; confirmar que no se hayan alterado.
5. Ejecutar `flutter pub get` para actualizar el archivo `pubspec.lock` con las nuevas dependencias y subir ese cambio después de revisarlo.

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
flutter test test/habit_action_service_test.dart
flutter test test/healthy_chat_habit_card_test.dart
flutter test test/healthy_chat_habit_picker_test.dart
flutter test
```

Validación en Android con sesión autenticada:
1. Preguntar "¿Cómo va mi perfil?" y comprobar XP, monedas, nivel y racha contra Firebase.
2. Preguntar "Agrega Incluir una fruta": la tarjeta debe mostrar requisitos y permitir agregar **dentro del chat** solo después del diálogo de confirmación.
3. Preguntar "Elimina Incluir una fruta": si está activo, verificar la advertencia de penalización, cancelar el diálogo (sin cambios) y repetir aceptándolo.
4. Preguntar "agregar un hábito" y "abandonar uno": abrir selector y escoger un hábito oficial; no debe activarse antes de confirmar.
5. Abrir dos confirmaciones simultáneas o usar otra sesión entre previsualización y aceptación: la versión de mutación debe invalidar el intento obsoleto.
6. Consultar nutrientes de lentejas y abrir su fuente.
7. Abrir Estadísticas, Mi camino, Ranking, Tienda y Profesionales desde mensajes.
8. Crear un segundo chat, cerrar y reabrir la app, recuperar el primero y eliminar el segundo.
9. Probar modo Lite/Normal y oscuro/claro; comprobar textos y diálogos en 320 dp.
10. Negar temporalmente permisos del historial y confirmar que no se presenta guardado como si hubiera sido exitoso.

## Siguiente implementación

1. Incorporar la administración de hábitos personalizados y ampliar la cobertura de flujos y controles de acceso mediante un backend transaccional.
2. Indexar un dataset versionado con estructura, fuentes, licencia y revisión, con búsqueda léxica/semántica.
3. Añadir acciones y tarjetas de los módulos Desafíos, Catálogo, Progreso, Logros, Tienda, perfil y profesionales reales.
4. Implementar memoria resumida opt-in con controles de edición y borrado.
5. Incorporar backend generativo opcional en Cloud Functions, con credenciales solo en servidor, consentimiento de transferencia y generación fundamentada en fuentes. Nunca confiar en un modelo para otorgar XP, cobrar monedas o ejecutar efectos sin autorización.
