# Plan prioritario · Evidencia visual y beta cerrada

**Fecha de corte:** 27 de noviembre de 2026.  
**Rama:** main. **Proyecto Firebase real:** `cloud-firestore-d8c61`.  
**Estado:** diagnóstico de código y documentación, **sin autorización de despliegue**.

## Estado de implementación (27/11/2026)

Se completaron en código **E1** (reserva, subida, asociación, estado, reintentos, cuota y limpieza bloqueada) y la primera versión de **E2** (análisis local por ML Kit, análisis remoto optativo de contenido mediante Vision con fuente de imagen exclusivamente servidor, comprobación de contexto y metadatos mínimos). **E3** está conectado al registro oficial y es idempotente: no añade XP por foto. Sin embargo, la validación **fuerte** del cumplimiento sigue pendiente porque ni ML Kit ni Vision pueden demostrar que se haya ingerido comida, bebido agua o cumplido tiempo de actividad.

La beta **no está lista para distribuirse**: el recorrido normal todavía contiene escrituras económicas desde Flutter, las reglas reales no están auditadas y el sistema de evidencias está apagado por defecto. Se añadió un laboratorio integrado `firebase.evidence-demo.emulator.json` con tests de reserva, subida, registro, asociación, análisis simulado y limpieza. **Pruebas automáticas aprobadas en GitHub Actions (28/11 UTC): 567 Flutter, 193 Functions, 15 Vision y un flujo completo en emuladores; Android físico y seguridad de reglas reales pendientes.**

La guía de ejecución y los criterios de lanzamiento están en [Implementación de evidencias 27/11](IMPLEMENTACION_EVIDENCIAS_2026-11-27.md).

## Objetivo de producto

Healthy Habit debe permitir registrar un hábito, adjuntar una foto opcional, mostrar qué pudo reconocer el sistema y mantener la integridad del registro y de las recompensas. Una foto, incluso clasificada correctamente, no demuestra por sí misma consumo o cumplimiento. La meta no es dar más XP por cualquier imagen, sino registrar **procedencia, incertidumbre y comprobaciones independientes**.

La beta será **cerrada, limitada a testers autorizados y con operaciones económicas avaladas exclusivamente por servidor**. Ningún cambio de este plan permite publicar reglas, activar banderas o conceder nuevas recompensas.

## Estado observado en el código

| Flujo | Estado confirmado | Bloqueo |
|---|---|---|
| Elegir foto, cámara/galería y preparar JPEG | Implementado en Flutter | Pruebas Android y privacidad |
| Google ML Kit local | Módulo existente y accesible | Clasificación indicativa, no acredita consumo |
| Google Cloud Vision | Piloto restringido por UID, 15 solicitudes/día UTC y 60 s entre llamadas | Sin autorización de beta general ni App Check obligatorio |
| Panel de resultados | Etiquetas y confianza existentes | Falta separar claramente similitud visual de cumplimiento real |
| Subida temporal y asociación a intento | Laboratorio demo y servicios aislados | Integración beta incompleta |
| Registro oficial con foto en beta | **Bloqueado intencionalmente** en `registrar_habito_screen.dart` | El código rechaza imágenes antes de invocar la beta |
| Activación/cancelación/registro de 36 hábitos | Callables beta y pruebas de servidor existentes | Validación completa cliente-reglas-servidor |
| Rutas normales de progreso/XP/monedas/tienda | Conservan escrituras directas de Firestore | **Bloqueo de seguridad de producción** |
| Reglas restrictivas y App Check | Preparados parcialmente para beta | No publicar ni dar por auditados |
| Easter egg Titán | Código preparado | En pausa; no habilitar su función de producción |

## Contrato de evidencia propuesto

`captured` → `uploaded` → `analyzed` → `needs_review` / `compatible` / `incompatible` → `expired`.

- `captured`: imagen local seleccionada; no constituye evidencia remota.
- `uploaded`: el servidor acredita que un objeto privado vinculado al UID/hábito/intento existe realmente, con MIME y tamaño válidos.
- `analyzed`: un resultado firmado o persistido por backend recoge etiquetas, confianza, modelo/versión y fecha de análisis; **no** acredita automáticamente XP.
- `compatible`: las detecciones son coherentes con un criterio específico de hábito; no certifica ingestión ni duración de actividades.
- `needs_review`: análisis dudoso, foto ambigua o hábito que no puede verificarse visualmente.
- `incompatible`: evidencia claramente no relacionada con el objetivo; mantener la posibilidad de registro declarado según política del hábito.
- `expired`: eliminación física del objeto temporal con trazabilidad mínima de operación, sin retener la imagen indefinidamente.

**No** aceptar del cliente campos como `imageVerified`, `confidenceVerified`, `xpAwarded`, `habitCoins` o `rewardTier` para acreditar premios. El backend debe generar esos datos o calcularlos desde constancias propias.

## Arquitectura para el siguiente desarrollo

1. **Captura**: `HabitEvidenceImagePreparer` recibe cámara/galería, comprime, elimina metadatos y valida dimensiones, bytes y JPEG. No subir antes de confirmación del usuario.
2. **Reserva autorizada**: callable autenticada y con App Check; recibe exclusivamente `habitId`, `attemptId` e `operationId`. Verifica que el intento pertenece a la cuenta, está activo y admite fotos; entrega un destino privado de un solo uso.
3. **Subida temporal**: Firebase Storage, ruta ligada a UID e intento. Reglas restringidas, comprobación de MIME/tamaño y caducidad. No exponer URL pública.
4. **Validación de objeto**: el servidor coteja nombre, contenido, hash opcional, tamaño, dueño e intento; impide reutilizar una foto de otro intento.
5. **Análisis**: primero clasificador visual con categorías conocidas; Cloud Vision únicamente desde servidor, con costes y cuota. Persistir la versión del clasificador y el resultado con fecha y motivo.
6. **Política por hábito**: determinar si una foto sirve como indicio, es insuficiente o exige otro método. Para hidratación, por ejemplo, una botella visible no acredita beber su contenido.
7. **Registro**: transacción oficial con `operationId` estable; nunca duplicar progreso o monedas por reintentos. El estado `analyzed` no puede convertirse por sí solo en XP verificado.
8. **Retroalimentación**: mostrar «fotografía compatible», «inconclusa» o «no relacionada» sin presentar un diagnóstico ni un cumplimiento certificado.
9. **Borrado**: programar purga de imagen temporal y comprobarla en Emulator; retener solo la constancia mínima necesaria y consentida.

## Fases de ejecución

### E1. Integridad y trazabilidad de evidencias — prioridad inmediata
- Auditar rutas `temporary_evidence_service`, `habit_evidence_image_preparer`, servicios de reserva/subida/asociación/limpieza y Storage Rules.
- Crear contrato unificado entre Flutter y Functions; casos negativos de foto ajena, archivo reemplazado, intento caducado, doble solicitud, MIME falsificado y pérdida de red.
- **Criterio de salida:** una foto puede subirse y asociarse de forma privada a un intento en Emulator, sin premios.

### E2. Análisis responsable
- Integrar la salida del clasificador por hábitos/categorías; no depender exclusivamente de nombres ingleses de etiquetas.
- Probar fruta, verduras, comida, botella, pantalla y fotos no relacionadas; declarar falsos positivos/falsos negativos.
- **Criterio:** informe explicable y almacenado por backend, sin atribuir consumo ni XP extra.

### E3. Registro y economía
- Conectar el informe visual con registro oficial en una transacción idempotente.
- Separar registro declarado, foto asociada y evidencia compatible; reservar «verificado» para métodos realmente defendibles.
- **Criterio:** reintentos y fotos manipuladas no elevan recompensas; se puede completar un hábito permitido sin foto.

### B1. Cerrar escrituras de cliente
- Migrar rutas normales `HabitActionService.execute`, `RegistrarHabitoScreen._guardarRegistro`, tienda, desafíos y cualquier otro flujo económico a callables.
- No borrar rutas normales ni bloquear Firestore hasta validar sus reemplazos.
- **Criterio:** ninguna escritura de cliente cambia XP, monedas, rachas, logros o logs oficiales.

### B2. Reglas y pruebas
- Ejecutar suites positivas/adversariales de Firestore, Storage y Functions en Emulator, dos cuentas, App Check y recuperación de operaciones.
- Resolver discrepancias, incluyendo pruebas de relaciones sociales y archivos de evidencia, sin convertir expectativas de rechazo en aprobaciones.
- **Criterio:** ninguna falsificación es aceptada y los flujos legítimos siguen funcionando.

### B3. Beta cerrada
- Verificar firma Android, identificación de proyecto y base `default`, proveedores App Check y allowlist.
- Comprobar sesión, permisos, borrado, errores offline, reintentos, recuperación tras reinicio, cuotas y costes.
- Distribuir a un grupo pequeño solo cuando los criterios previos estén documentados y aprobados.

## Pruebas de diagnóstico para ejecutar localmente

```bash
git fetch origin main && git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/healthy_vision_demo_screen_test.dart
flutter test test/healthy_vision_debug_test.dart
flutter test test/beta_habit_gateway_test.dart
npm --prefix functions test
node tools/beta_readiness_gate.mjs
```

El último comando es deliberadamente una barrera: actualmente se esperan bloqueos. No ejecutar `firebase deploy` ni `npm audit fix --force` para «arreglar» un resultado.

## Evidencia documental relacionada

- [Cierre previo y riesgos de beta](CIERRE_AVANCES_Y_DEMO_2026-11-25.md)
- [Integración Flutter de beta](beta_flutter_integration_2026-11-25.md)
- [Plan de seguridad](beta_security_migration_2026-11-24.md)
- [Reconocimiento local Android](RECONOCIMIENTO_LOCAL_ANDROID_2026-11-26.md)
- [Piloto de Cloud Vision](DEMO_RECONOCIMIENTO_IMAGENES_2026-11-26.md)
- [Inventario maestro](INVENTARIO_MAESTRO_FUNCIONALIDADES.md)

**Regla de actualización:** toda fase deberá registrar commit, pruebas reproducibles, estado de despliegue y bloqueos pendientes. Ningún módulo pasará de «implementado» a «validado» solo porque su código compile.
