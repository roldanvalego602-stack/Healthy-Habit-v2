# Migración de operaciones de hábitos a Firebase Admin

## Estado actual (sin despliegue)

Flutter ejecuta transacciones del cliente en:
- `lib/páginas/habitos/habit_action_service.dart`: activación y cancelación.
- `lib/páginas/habitos/registrar_habito_screen.dart`: registros,
  XP, niveles, rachas, monedas y evidencias temporales.

La candidata `firestore.candidate.rules` permite a propietarios escribir
`users/{uid}/user_habits/**` y determinados campos de perfil. Por tanto,
ni `latestStatus`, ni `progress`, ni recompensas almacenadas pueden
considerarse verificadas de forma independiente.

## Primera etapa implementada

`previewOfficialHabitRegistration` es un callable autenticado y
**exclusivamente de lectura**. Consulta el hábito y el intento bajo el
UID del token del usuario y rechaza IDs ajenos al catálogo oficial,
identificadores con rutas, intentos finalizados o cancelados,
progreso inválido y objetivos completos.

La lógica pura vive en `functions/habit_registration_policy.js` y
tiene cuatro pruebas en `functions/tests/habit_registration_policy.test.js`.

**Limitaciones:** la consulta lee documentos que el cliente actual puede
alterar. No autentica que ocurrió una actividad, no verifica fotos, no
concede XP, no registra hábitos y **no habilita la publicación de
popularidad**. La aplicación sigue usando los flujos existentes.

## Siguientes requisitos para una operación de escritura confiable

1. Versionar el catálogo oficial en el servidor como fuente autorizada
   de IDs, objetivos, dificultad, desbloqueos y penalizaciones. No
   confiar en los datos del hábito enviados por el cliente.
2. Introducir una transacción de Admin SDK para activar, cancelar y
   registrar, con control de idempotencia (ID único de operación),
   validación de estado, límites y cupos; no repetir una recompensa.
3. Calcular XP, monedas, niveles y rachas exclusivamente en el servidor,
   sin aceptar importes de la petición. Fijar reglas sobre el huso horario,
   frecuencia y número de registros por periodo.
4. Tratar el contenido de la imagen como evidencia pendiente de
   comprobación, no como verificación de actividad; regular tamaño,
   acceso y caducidad de su almacenamiento.
5. Crear pruebas integrales en emulador para registros repetidos,
   solicitudes concurrentes, cancelaciones, accesos de terceros,
   manipulación de XP y monedas, y migración de intentos existentes.
6. Cambiar los clientes Flutter a los callables nuevos y bloquear
   **en la misma entrega** las escrituras directas sobre estados,
   registros y economía mediante reglas revisadas y desplegadas.
7. Reconciliar datos históricos y solo entonces habilitar la creación
   de agregados de popularidad con una política de privacidad adecuada.

No desplegar `firestore.candidate.rules` en producción: actualmente
incluye políticas vulnerables de economía y se destina únicamente al
emulador de pruebas.
