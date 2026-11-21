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

## Segundo paso: piloto transaccional aislado (solo emulador)

La función `registerDemoOfficialHabit` está disponible **únicamente** cuando
`FUNCTIONS_EMULATOR=true` y `GCLOUD_PROJECT=demo-healthy-habit`.

El código transaccional está en `functions/habit_registration_transaction.js`.
En este piloto se habilita exclusivamente `hidr_001` (agua al despertar):
su objetivo de siete registros, frecuencia diaria y premio de **10 XP
por registro sin evidencia** se definen en el servidor, nunca en la petición.

La operación utiliza:
- Un `operationId` único por registro (16 a 128 caracteres ASCII
  alfanuméricos, guion o guion bajo), que puede repetirse de forma segura
  por un reintento de red. Cada operación guardada tiene respuesta estable.
- Una marca `registration_days/YYYY-MM-DD` por intento y día UTC para
  impedir un segundo registro con otro ID el mismo día. Esto es un
  **criterio de prueba**, no la política horaria definitiva de Flutter.
- Una transacción del Admin SDK con lectura previa de usuario, hábito,
  intento, operación y día; después se escriben registro, progreso,
  finalización, XP y monedas por nivel conjuntamente.
- Umbrales de niveles y recompensas basados en `LevelSystem` y los valores
  del flujo actual. No se aceptan fotografías, XP, monedas ni objetivos
  enviados por el cliente.

Los archivos `functions/tests/habit_registration_transaction.test.js`
incluyen ocho pruebas unitarias adicionales: idempotencia, límites diarios,
finalización, cambios de nivel, operaciones malformadas y rechazo de intentos
cancelados.

**Limitaciones importantes:** el piloto no maneja la racha local, tiempos
de gracia, recuperación de hábitos, verificación de imágenes ni migraciones
de datos. Sus datos iniciales en el emulador todavía pueden ser escritos
por los propietarios bajo las reglas candidatas. Por eso no está listo
para usuarios reales, no debe sustituir el flujo Flutter y **no habilita
estadísticas públicas verificadas**.

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
