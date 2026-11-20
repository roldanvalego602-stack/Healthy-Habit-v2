# Auditoría de compatibilidad Firestore / Flutter — Healthy Habit

Fecha de revisión: 20 de noviembre de 2026.  
Rama: `feature/mr-healthy-voice-knowledge-motion`.  
Resultado base del usuario: **39/39 pruebas aprobadas**; cuatro pruebas de integración adicionales pendientes de ejecutar (suite esperada: **43**).  
**Alcance:** inspección estática de rutas Dart y reglas candidatas, más pruebas de emulador. No constituye una prueba de interfaz completa ni una certificación de seguridad.

## Matriz de compatibilidad

| Función de Flutter | Ruta Firestore | Reglas candidatas | Conclusión |
| --- | --- | --- | --- |
| Autenticación e inicialización de perfil | `users/{uid}` | `create/get/update` solo dueño; alta sin esquema estricto | Compatible a nivel de acceso; falta validar alta real y valores |
| Inicio y hábitos | `users/{uid}/user_habits/{...}` | propietario, comodín recursivo | Lecturas/escrituras permitidas; **contenido fácilmente falsificable** |
| Registro + progreso de intentos | `user_habits/{habit}/attempts/{attempt}/logs/{log}`, perfil | propietario, escritura amplia | Compatible con transacciones actuales; no verificable anti-trampa |
| Evidencias temporales | `users/{uid}/temporary_habit_evidence/{id}` | propietario | Privacidad básica cubierta; límites de tamaño, TTL y borrado real pendientes |
| Estadísticas y logros | `user_habits`, `achievements` | propietario | Compatible por rutas; comprobar cálculos reales en Flutter |
| Mr. Healthy / chatbot | lecturas de `users/{uid}` y `user_habits` | propietario | Compatible para las rutas observadas; conversaciones mayormente locales |
| Perfil propio / edición | `users/{uid}` | propietario | Compatible; faltan validaciones de campos |
| Ranking | `public_profiles` ordenados por XP | lectura autenticada | Consulta compatible; **ranking no fiable** por XP autodeclarado |
| Buscar amigos y feed | `public_profiles`, espejo social | perfiles públicos + `getAfter` | Probados parcialmente; falta UI real con dos cuentas |
| Solicitudes / seguimiento | `users/{uid}/solicitudes`, `solicitudes_enviadas`, `following`, `followers` | operaciones recíprocas | Pruebas de emulador aprobadas; probar flujos de UI |
| Amistades locales | `users/{uid}/friends` | propietario | Compatible, no autoritativa |
| Reacciones sociales | `interactions/{id}` | crear remitente, leer/responder destinatario | 5 pruebas de emulador aprobadas; validar estados exactos que envía la UI |
| Tienda / compra | `users/{uid}.habitCoins` + `shopInventory` | precio fijo + un artículo nuevo | Mitigación parcial comprobada; fuente de monedas falsificable |
| Tienda / equipar | `users/{uid}.shopEquipped` | actualizaciones propias no bloqueadas | Compatible a nivel de permiso, sin comprobación en reglas de propiedad del artículo |
| Desafíos | `users/{uid}/challenges` | solo demo desde cliente; aceptar, reclamar solo si previamente verificado | La UI puede crear/aceptar demos; no existe un proceso confiable que complete progreso |
| Catálogos del sistema | `system/{...}` | lectura autenticada, escritura denegada | Compatible si la app solo consulta; identificar fuentes de escritura futuras |

## Hallazgos críticos y acciones

**C1 — XP y Habit Coins autoadministrados (bloquea producción).** `validOwnerUpdate` todavía permite incrementar `xp` y `habitCoins` sin justificación. Los documentos fuente de progreso están bajo control del cliente. No presentar ranking como competitivo ni economía como segura.

**C2 — Registros y evidencias con escrituras demasiado amplias (bloquea garantías de progreso).** El comodín `user_habits/{path=**}` autoriza cualquier registro del dueño sin verificar incrementos, límites, duplicados o relación con transacción de XP. Las evidencias pueden ser datos arbitrarios.

**C3 — Permisos de alta y eliminación de `users/{uid}` sin restricción de esquema.** El propietario puede recrear su perfil con monedas y XP arbitrarios; cerrar únicamente `update` no bastaría.

**C4 — Ranking proyectado desde cliente.** `HealthyPublicProfileService` genera `public_profiles` desde el perfil privado, pero ambos valores de XP son editables por el propietario.

**C5 — La funcionalidad de desafíos verificados todavía no tiene autoridad confiable.** La candidata impide inventar verificación desde un cliente, pero por ahora no hay una vía segura implementada que certifique desafíos reales y entregue monedas.

**C6 — Compras / equipo.** La compra comprueba precio y nuevo inventario, pero `shopEquipped` puede ser escrito directamente; la validez de equipamiento se verifica solo en Flutter. Debe agregarse prueba y restricción antes de producción.

**C7 — Registro de errores del emulador.** Los `PERMISSION_DENIED` de las pruebas negativas son esperados. Algunos contienen `evaluation error`, y aunque la operación fue denegada no se debe afirmar que todas esas expresiones fueron evaluadas limpiamente. Registrar una prueba dedicada por caso si se decide depurar esta categoría.

## Pruebas de integración añadidas en esta revisión

En `tests/firestore/rules.test.cjs` se agregaron cuatro casos: (1) equipamiento propio y rechazo de tercero; (2) edición de perfil y rechazo de suplantación; (3) privacidad y borrado de evidencia; (4) lectura privada de intentos y logs anidados. **Pendientes de ejecutar: total esperado 43 casos.**

## Validación manual propuesta con dos cuentas de emulador

1. Crear usuarios de prueba A y B sin usar datos personales.
2. Entrar al inicio, registrar hábito con y sin evidencia, comprobar XP y racha, abrir progreso y logros.
3. Buscar B desde A, enviar solicitud, recibirla desde B, aceptar, confirmar seguimiento, cancelar y dejar de seguir.
4. Enviar reacción A→B, consultar bandeja desde B, marcar leída y responder.
5. Comprar artículo con saldo de prueba, equiparlo y reiniciar aspecto. Intentar compra sin fondos.
6. Abrir ranking y comprobar que solo se consultan `public_profiles`.
7. Probar escenarios negativos de Firestore desde emulador, no editando datos reales.

**No conectar una app Flutter de producción al proyecto demo por accidente.** Para pruebas manuales, configurar explícitamente la conexión local a emuladores y revisar el proyecto Firebase activo. No implementar este paso sin validar en el entorno local.

## Comandos de prueba

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion

firebase emulators:exec --config firebase.emulator.json --only firestore --project demo-healthy-habit "npm --prefix tests/firestore test"
flutter analyze --no-fatal-infos lib test
flutter test
```

## Condición de salida

No desplegar `firestore.candidate.rules` todavía. Se requiere un diseño de autoridad para XP/HC, restricciones sobre escrituras directas de documentos económicos y perfiles, pruebas manuales de flujos Flutter y revisión de migración/rollback. Mantener registro de resultados en `docs/bitacora_seguridad_healthy_habit.md`.
