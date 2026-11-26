# Healthy Habit — cierre de trabajo y preparación de demostración

**Corte:** noche del 25 de noviembre de 2026 (México).  
**Proyecto:** Healthy Habit / Integradora.  
**Repositorio:** `roldanvalego602-stack/Healthy-Habit-v2`, rama `main`.  
**Decisión del equipo:** **posponer el trabajo de beta y priorizar una demostración de avances mañana**. Esta nota no autoriza despliegue ni activación de flags.

## 1. Estado confirmado

### Funcionalidad desarrollada
- App Flutter con Firebase, catálogo de **36 hábitos** y funciones de gamificación: progreso, XP, Habit Coins, tienda y personalización.
- Backend de hábitos en Cloud Functions: activación, cancelación, registro, control de cupos, frecuencias, recompensas, penalizaciones, rachas e idempotencia.
- Se añadió soporte de **configuración interactiva** en activaciones oficiales (contador, hidratación, pasos, cronómetro/temporizador, respiración, Pomodoro). La configuración por sí sola no acredita XP ni constituye evidencia verificada.
- Backend transaccional de tienda con catálogo de **62 artículos (60 pagados y 2 gratuitos)**, compras únicas, inventario y equipamiento.
- Los cobros directos de desafíos desde Flutter se retiraron; los cobros de beta no deben habilitarse hasta que el servidor tenga constancias verificadas independientes.

### Pruebas ejecutadas y resultados reportados por el desarrollador
- Reglas restrictivas Firestore: **23/23** (ejecuciones anteriores).
- Seguridad estática de desafíos: **2/2**.
- Rutas estáticas de hábitos beta: **3/3** en la ejecución previa; posteriormente se añadió cobertura de parámetros interactivos.
- Laboratorio de **36 hábitos**, activación y cancelación: aprobado.
- Laboratorio de **36 hábitos**, registro inicial, XP, nivel 20 y reintentos: aprobado.
- Laboratorio de **herramienta interactiva** y reintentos inalterados: aprobado dentro de los **3/3 casos integrales** reportados.
- Pruebas unitarias de Functions y seguridad estática de la ruta beta: el desarrollador reportó que **las tres suites de comandos pasaron**.
- Laboratorio de tienda `test:tienda:emulador`: **2 pruebas aprobadas**, según el último reporte del desarrollador.
- Lo anterior valida principalmente las transacciones de servidor en emuladores, **NO** toda la experiencia Flutter ni una beta publicable.

### Último trabajo de esta sesión
- `functions/tests-emulator/shop_catalog.integration.js`: prueba funcional para todos los artículos de tienda.
- `tools/firestore-tests/package.json`: script `test:tienda:emulador`.
- Documentación de pruebas en `docs/beta_flutter_integration_2026-11-25.md`.
- Último commit de código antes de este documento: `1d0f91c2f11016a3e0773f74bdbbce1e3828e11c`.
- Este documento fija el punto de reanudación; **no cambia código ni reglas**.

## 2. Beta: pausa explícita y pendientes para reanudar

**NO DISTRIBUIR beta conectada al Firebase real. NO desplegar `firestore.candidate.rules`.**

El verificador `node tools/beta_readiness_gate.mjs` reportaba **4 bloqueos estáticos** en su última ejecución comunicada:

1. `lib/páginas/habitos/registrar_habito_screen.dart`: transacción directa de registro, progreso y XP en el cliente normal.
2. `lib/páginas/habitos/habit_action_service.dart`: transacciones directas de activación y cancelación del cliente normal.
3. `lib/páginas/tienda/shop_service.dart`: transacciones directas de compras/equipamiento.
4. El recorrido seguro aún depende de banderas de laboratorio y no está preparado como flujo normal publicado.

**Punto exacto de reanudación:** comenzar por `HabitActionService.execute` en `lib/páginas/habitos/habit_action_service.dart`, donde las ramas demo/beta ya despachan a Functions, pero la rama normal aún ejecuta `_db.runTransaction`. Migrar sin perder compatibilidad con selección de herramientas y sin habilitar las reglas candidatas antes de que todas las rutas estén listas. Luego migrar registro y tienda. No quitar transacciones directamente sin preservar la funcionalidad y validar el recorrido completo en Flutter.

Aspectos adicionales por verificar: App Check en Android real, allowlist de testers, recuperación de operaciones pendientes tras reinicio, evidencias y fotos, verificaciones de desafíos, perfiles existentes, permisos de Firestore, pruebas completas de cliente y procesos de distribución.

`HH_BETA_HABITS_CLIENT` permanece deshabilitada por defecto. `HH_SHOP_DEMO_FIREBASE`, `HH_DEMO_SHOP_PURCHASE` y `HH_DEMO_OFFICIAL_HABITS` pertenecen únicamente al laboratorio `demo-healthy-habit`, no al proyecto real `cloud-firestore-d8c61`. Base Firestore de la aplicación: **`default`** (nombre literal), no `(default)`.

## 3. Prioridad para la presentación de avances de mañana

**Meta:** mostrar una aplicación útil y visualmente coherente con funciones existentes, sin promocionarla como una beta segura, sin ejecutar cambios económicos sobre cuentas reales y sin hacer nuevas migraciones arriesgadas antes de exponer.

### Plan de la demostración
1. **Compilación y arranque:** confirmar `flutter pub get`, `flutter analyze` y ejecución en el dispositivo disponible. Resolver únicamente errores que impidan la demostración.
2. **Recorrido visual:** presentar inicio, catálogo de 36 hábitos, detalles y filtros, selección de hábitos, herramientas configurables, registro/progreso, retos, perfil y tienda. Verificar antes qué acciones son seguras y realmente funcionan en el entorno elegido.
3. **Gamificación:** mostrar XP, rachas, Habit Coins, progresos, recompensas, inventario y personalización con **datos de prueba**. Evitar hacer promesas sobre características no terminadas.
4. **Seguridad como avance de ingeniería:** enseñar evidencias de las pruebas del emulador (36 hábitos y tienda), explicar que los saldos y el progreso se verifican en el servidor y mostrar que el despliegue de reglas está deliberadamente bloqueado.
5. **Contingencia:** preparar capturas o una grabación corta de las pantallas críticas, sin datos personales; no improvisar un despliegue de última hora.
6. **Guion breve:** problema (abandono de hábitos) → solución (seguimiento gamificado) → recorrido en vivo → arquitectura Flutter/Firebase → pruebas realizadas → próximos pasos.

### Precauciones para la demo
- **No ejecutar en vivo** `firebase deploy`, `firestore.candidate.rules`, ni activar `HH_BETA_HABITS_CLIENT`.
- Si se usa el laboratorio aislado, arrancar solamente los emuladores necesarios con el proyecto **`demo-healthy-habit`** y sus tres banderas de demo; no conectar esta modalidad al proyecto real.
- Si se muestra la app normal, evitar ejecutar compras, cobros de desafíos o modificaciones sensibles sin comprobar el comportamiento y el estado de la cuenta de prueba; privilegiar la navegación y las pantallas de solo lectura.
- Las funciones de beta y el cobro de desafíos pueden estar deshabilitados por diseño. No presentarlos como un fallo inesperado en la demo.
- Comprobar Wi-Fi, cargador, dispositivo/emulador Android, sesión de prueba y plan alternativo de capturas antes de presentarse.
- El objetivo de mañana es **demostrar avances** y recoger retroalimentación, no habilitar el lanzamiento.

## 4. Comandos de referencia

Desde la raíz del proyecto:

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze
```

Pruebas de backend (solo cuando sea necesario verificar regresiones):

```bash
npm --prefix functions test
node --test tools/tests/challenge_client_security.test.mjs
node --test tools/tests/habit_action_beta_security.test.mjs
npm --prefix tools/firestore-tests run test:36-habitos:emulador
npm --prefix tools/firestore-tests run test:tienda:emulador
```

El verificador de beta **debe continuar bloqueando** la publicación; su salida no es una señal de fallo de la demostración:

```bash
node tools/beta_readiness_gate.mjs
```

## 5. Orden de trabajo al retomar beta

1. `habit_action_service.dart`: migrar ejecución normal de activación/cancelación y completar pruebas Flutter.
2. `registrar_habito_screen.dart`: migrar registro, XP, evidencias y herramientas, sin vías de escritura económica del cliente.
3. `shop_service.dart`: migrar compra, equipamiento y restauración a Functions.
4. Comprobar todas las demás rutas de escritura relevantes, permisos, App Check y recuperación/idempotencia.
5. Ejecutar suites y pruebas manuales en Android; recién entonces revisar despliegue escalonado con reglas candidatas.

**Criterio de cierre:** no considerar la beta lista solo porque las pruebas de emulador hayan pasado. Deben desaparecer los bloqueos reales y aprobarse los recorridos Android completos.
