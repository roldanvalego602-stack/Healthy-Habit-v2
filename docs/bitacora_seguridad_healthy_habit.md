# Bitácora de seguridad de Healthy Habit

**Actualizada:** 20 de noviembre de 2026  
**Estado:** auditoría en curso; reglas candidatas solo para emulador. **NO DESPLEGAR.**  
**Repositorio:** `roldanvalego602-stack/Healthy-Habit-v2`  
**Rama:** `feature/mr-healthy-voice-knowledge-motion`  
**Último resultado confirmado por el usuario:** **39/39 pruebas aprobadas (0 fallidas)**.

## ¿Qué estamos haciendo y por qué?

Se están migrando los permisos de Firebase Firestore porque las reglas actuales de producción contienen una autorización recursiva para usuarios autenticados que puede exponer datos privados. En la candidata se han separado los perfiles privados de los públicos, establecido permisos de relaciones sociales y limitado algunas operaciones sobre tienda, desafíos y reacciones.

**Las pruebas aprobadas NO significan que la app ya sea completamente segura ni que las reglas puedan publicarse.** También pasan pruebas que describen vulnerabilidades existentes.

## Historial de etapas

| Etapa | Resultado comprobado | Trabajo |
| --- | --- | --- |
| Privacidad | Pruebas aprobadas | Usuario solo accede a su perfil, hábitos y evidencia |
| Perfiles públicos | Pruebas Flutter aprobadas | Ranking, búsqueda y perfiles ajenos pasan a `public_profiles` |
| Solicitudes y seguimiento | 18/18 | Solicitudes con espejo, aceptar/rechazar/cancelar, seguir/dejar de seguir |
| Compras | 27/27 | Precio de catálogo, único artículo nuevo y rechazo de débitos/compras inválidos |
| Transacciones de recompensa | 30/30 | Casos de compatibilidad de hábitos y desafíos; se documenta el riesgo económico |
| Desafíos demo | 34/34 | Impedir cambios fraudulentos de premios/verificación; aceptar desafíos |
| Reacciones sociales | 39/39 | Emisor crea, receptor consulta/actualiza, terceros sin acceso |

## Archivos involucrados

- `firestore.candidate.rules`: reglas de prueba del emulador, no publicar todavía.
- `firestore.rules`: reglas de producción, pendientes de sustitución segura.
- `firebase.emulator.json`: configuración de pruebas aisladas.
- `tests/firestore/rules.test.cjs`: suite automatizada de seguridad.
- `lib/servicios/healthy_public_profile_service.dart`: proyección de datos públicos.
- `lib/páginas/perfil/amigos_servicio.dart`: solicitudes y seguimiento.
- `lib/páginas/perfil/interaction_service.dart`: reacciones.
- `lib/páginas/habitos/registrar_habito_screen.dart`: registros y XP.
- `lib/páginas/desafios/desafios_screen.dart`: desafíos y recompensas.
- `lib/páginas/tienda/shop_service.dart`: compras/equipamiento.
- `docs/plan_seguridad_firestore_spark.md`: detalles técnicos y decisiones cronológicas.

## Qué falta antes de publicar

1. **Economía confiable:** actualmente cada usuario puede falsificar su propio XP y Habit Coins. La candidata protege parcialmente compras, no la procedencia del saldo.
2. **Origen verificable de recompensas:** no basta con comprobar que existe un log de hábito; un cliente modificado también puede escribir logs.
3. **Cobertura de colecciones:** auditar todas las rutas de lectura/escritura de Flutter; ya se detectó que `interactions` requería permisos específicos.
4. **Pruebas de integración reales:** verificar inicio de sesión, hábitos, evidencias, tienda, desafíos, ranking, amigos y reacciones con dos cuentas de prueba conectadas al emulador.
5. **Depurar `evaluation error`:** algunos casos negativos dan errores de evaluación además de `PERMISSION_DENIED`. Los rechazos son esperados, pero conviene mejorar las condiciones.
6. **Respaldo y despliegue controlado:** no desplegar hasta establecer un plan de reversión y verificar que se bloquean los accesos indebidos sin romper funciones.

### Comando de regresión

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion
firebase emulators:exec --config firebase.emulator.json --only firestore --project demo-healthy-habit "npm --prefix tests/firestore test"
```

**Último resultado real recibido:** `tests 39`, `pass 39`, `fail 0`, `Script exited successfully (code 0)`. Los errores `PERMISSION_DENIED` de pruebas negativas son esperados.

## Cómo mantener esta bitácora

En cada actualización, anotar: fecha, objetivo, archivos cambiados, resultado de pruebas **ejecutadas**, resultado de pruebas **pendientes**, vulnerabilidades abiertas, commit y siguiente acción. No confundir el commit de código preparado con una validación local.

**Documento ampliado:** el archivo Word `Bitacora_seguridad_Healthy_Habit.docx` fue generado en la conversación y contiene explicación, cronología, glosario, criterios de cierre y comandos. El documento técnico `docs/plan_seguridad_firestore_spark.md` continúa siendo el registro detallado.

## Actualización — auditoría de integración Flutter (20-nov-2026)

**Resultado previo validado por el usuario:** 39/39 pruebas del emulador aprobadas.

**Trabajo realizado en esta revisión:** inspección de `firebase_servicios.dart`, `habits_screen.dart`, `registrar_habito_screen.dart`, `progreso_screen.dart`, `logros_screen.dart`, `nutrichat.dart`, `profile_screen.dart`, `editar_perfil_screen.dart`, `ranking_screen.dart`, `amigos_servicio.dart`, `interaction_service.dart`, `shop_service.dart`, `desafios_screen.dart`, `temporary_evidence_service.dart` y sus rutas relevantes.

**Se detectaron riesgos nuevos a priorizar:** creación/eliminación de perfil sin límites económicos, posibilidad de equipar artículos sin demostrar propiedad desde reglas, logs propios arbitrarios, ranking público basado en XP del cliente y ausencia de un verificador confiable de progreso de desafíos.

**Pruebas añadidas:** equipamiento, edición de perfil, privacidad/borrado de evidencias y consultas de logs anidados. **Nuevo total esperado: 43, todavía sin ejecutar.** Se creó `docs/auditoria_compatibilidad_firestore_flutter.md` con matriz de compatibilidad, riesgos y checklist manual.

**Siguiente acción:** validar las 43 pruebas en emulador; luego revisar y corregir permisos de equipamiento y creación de perfiles con pruebas negativas adicionales. No alterar reglas de producción hasta resolver el modelo de confianza de XP/monedas y verificar recorridos completos de Flutter.

## Etapa 9 — Validación de alta y equipamiento (20-nov-2026)

**Confirmado por el usuario:** 43/43 pruebas aprobadas. **Código nuevo, aún sin validar:** 5 pruebas adicionales (total esperado 48).

- `validInitialUser(uid)`: solo se puede crear un perfil con estructura inicial coincidente con `FirebaseService.saveUserData`: `xp=0`, `level=1`, `habitCoins=100`, `currentStreak=0`, UID del usuario y marca de tiempo del servidor. Se rechazan artículos preadquiridos y campos adicionales en el alta.
- `validEquipped()`: cada ranura solo acepta artículos de su categoría y que estén en inventario, salvo los cosméticos gratuitos `sunglasses` y `bandana`. Mantiene `ShopService.equip` y `resetLook`.
- Se agregaron 5 pruebas: alta realista, creación con economía falsa, cosméticos gratuitos, equipamiento inválido, restablecimiento conservando inventario.
- **Alerta:** `users/{uid}` aún permite `delete` del propietario y escritura posterior; aunque una recreación debe iniciar con saldo predeterminado, el borrado de perfil necesita un flujo propio y pruebas de integridad.
- **Alerta:** `habits_screen.dart` incluye penalizaciones que descuentan `habitCoins` sin compra. La regla existente puede bloquear ese flujo. No se ha alterado esa lógica; requerirá política propia y pruebas, antes de publicar.
- No se alteró `firestore.rules`, `firebase.json` ni la configuración de producción.

**Siguiente acción:** ejecutar 48 pruebas en emulador, luego diseñar permisos seguros para penalizaciones/ingresos y probar los recorridos Flutter.
