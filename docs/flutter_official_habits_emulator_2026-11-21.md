# Flutter + hábitos oficiales: puente exclusivo para Emulator

## Estado
Implementación experimental en la rama `feature/habits-discovery-routines`.
**No usar ni publicar en Firebase producción.** No elimina todavía
las ocho vulnerabilidades de las reglas actuales ni reemplaza
el backend necesario para Blaze.

## Qué hace
El arranque Flutter existente tenía el modo Firebase de demostración
`HH_SHOP_DEMO_FIREBASE` y `HH_DEMO_SHOP_PURCHASE`. Se introdujo
un tercer interruptor opt-in:
`HH_DEMO_OFFICIAL_HABITS`.

Con los tres activados:
- `Firebase.initializeApp` debe apuntar a `demo-healthy-habit`;
- Auth se conecta al emulador 9099;
- Firestore se conecta al emulador 8080;
- Functions se conecta al emulador 5001, región `us-central1`;
- `HabitActionService.execute` activa y cancela hábitos oficiales mediante
  `activateOfficialHabitDemo` y `cancelOfficialHabitDemo`;
- `RegistrarHabitoScreen` llama `registerOfficialHabitDemo` para
  declaraciones simples y muestra recompensas devueltas por el servidor.

Los tres endpoints están protegidos en el servidor:
`FUNCTIONS_EMULATOR === "true"` y
`GCLOUD_PROJECT === "demo-healthy-habit"`, además de Auth.
El usuario/UID proviene del token, no de campos enviados por Flutter.

### Límites intencionados
- El registro experimental **NO acepta imagen, nota ni interacción
  especial**. En esos casos la pantalla muestra un error explícito,
  sin acreditar XP ni descartar datos silenciosamente.
- El servidor guarda un log de declaración, **no verifica físicamente**
  que el hábito se haya realizado. La verificación de evidencia
  requiere otro diseño.
- Las operaciones utilizan identificadores generados por Firestore;
  todavía falta una cola de reintentos persistente para los casos de
  pérdida de conexión antes de confirmar el resultado.
- Las recompensas en producción siguen calculándose en Flutter.
  El nuevo modo se desactiva por defecto.
- El modo de demostración existente está restringido a un proyecto
  Firebase aislado. Algunos builds Android con inicialización nativa
  previa pueden bloquear el arranque por seguridad; no eliminar
  esa protección para forzar su funcionamiento.

## Ejecutar emuladores

Cerrar procesos anteriores en los puertos 8080/9099/5001 y ejecutar
desde la raíz del repositorio:

```bash
firebase emulators:start \\
  --config firebase.emulator.json \\
  --project demo-healthy-habit \\
  --only auth,firestore,functions
```

En otra terminal, usando el **emulador Android** (host `10.0.2.2`):

```bash
flutter run \\
  --dart-define=HH_SHOP_DEMO_FIREBASE=true \\
  --dart-define=HH_DEMO_SHOP_PURCHASE=true \\
  --dart-define=HH_DEMO_OFFICIAL_HABITS=true \\
  --dart-define=HH_EMULATOR_HOST=10.0.2.2
```

Para Linux desktop, usar `127.0.0.1` si la aplicación está preparada
para esa plataforma. Para móvil físico no forzar una IP LAN
sin revisar primero el modelo de seguridad y la configuración
del emulador.

## Comprobaciones locales

```bash
flutter analyze lib/main.dart lib/servicios/shop_demo_bootstrap.dart \\
  lib/servicios/official_habit_emulator_service.dart \\
  lib/páginas/habitos/habit_action_service.dart \\
  lib/páginas/habitos/registrar_habito_screen.dart
npm --prefix functions test
```

Verificar con Auth Emulator y un usuario de prueba: crear perfil,
activar un hábito, registrar sin foto/nota, repetir en un periodo
válido, cancelar y confirmar los importes devueltos.
Una operación repetida con el **mismo** `operationId` debe devolver
el resultado previo, sin crédito doble.

## Prohibido para producción

No ejecutar `firebase deploy` desde esta rama.
El archivo `firestore.candidate.rules` continúa con bloqueos de
integridad pendientes: el cliente real puede alterar XP y registros
si se mantienen las reglas permisivas. El despliegue futuro exige
una migración coordinada de reglas, funciones y cliente.
