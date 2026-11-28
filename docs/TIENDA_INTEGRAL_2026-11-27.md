# Tienda integral · 27 noviembre de 2026

**Repositorio:** Healthy-Habit-v2  
**Rama de trabajo:** `feature/tienda-integral-2026-11-27`  
**Estado:** implementación en revisión. **Sin despliegue de reglas ni Functions.** Una inspección de código **no equivale** a un APK validado ni a una beta autorizada.

## Alcance implementado en código

- **Catálogo de 73 IDs:** 64 preexistentes más nueve aspectos nuevos para el OVNI. Los 12 artículos retirados se preservan históricamente, incluyendo la recompensa Titán, y no se vuelven a vender.
- **Aspectos OVNI:** `ufo_cosmos`, `ufo_neon`, `ufo_gold`, `ufo_shadow`, `ufo_botanical`, `ufo_glitch`, `ufo_lava`, `ufo_primitive` y `ufo_carrot`. Sus ilustraciones se dibujan con `CustomPainter` y no modifican el PNG original de Mr. Healthy.
- **Armario:** pestaña OVNI y ranura `ufo_skin`, compra y equipamiento únicos por UID, muestra previa animada, sincronización con el lanzador/guía. Sin skin autorizada se usa la imagen original. Los objetos retirados ya poseídos conservan acceso desde el Armario.
- **Rareza visual:** común, poco común, raro, épico y legendario, etiquetados tanto por texto como por color, sin multiplicadores de XP ni monedas.
- **Merchandising diario:** 20 espacios, de los cuales 9 son fijos seleccionados por variedad de categorías, 7 rotan y 4 provienen de la familia de especiales. Todos los usuarios observan el mismo conjunto para un día comercial UTC−06:00.
- **Ofertas:** un artículo rotativo por día recibe 20 % de descuento en beta/demo **solo** cuando la transacción del servidor acepta `shopDay` y recalcula el precio. En la ruta heredada de producción **no se anuncia** ni aplica descuento.
- **Colección completa:** consulta de artículos visibles fuera de rotación, con precio, rareza y estado, pero sin posibilidad de comprar algo que no se ofrece ese día.
- **Carrusel, animación y accesibilidad:** se reutilizan efectos existentes, `HealthyMotionCard`, `AnimatedSwitcher`, sonido y respuesta háptica. Las nuevas vistas respetan la reducción de movimiento del sistema para el OVNI, el carrusel y el Armario; contienen etiquetas descriptivas y rutas de lectura textual. La accesibilidad integral aún necesita prueba en Android con TalkBack y texto grande.
- **Chat Mr. Healthy:** muestra precio y disponibilidad del día, conservando confirmación explícita de canje y equipamiento.

## Autoridad, seguridad y operación

La oferta es puramente cosmética. Los datos de cliente contienen solo `itemId`, `operationId` y, para el escaparate nuevo, `shopDay`. **El cliente no envía saldo, costo ni porcentaje de descuento.**

El servidor `functions/shop_purchase_transaction.js` valida:

1. Catálogo oficial y visibilidad comercial (se rechazan artículos retirados o gratuitos, incluido Titán).
2. Fecha comercial, presencia del artículo en la selección diaria y su precio con descuento.
3. Saldo suficiente, ausencia del artículo en el inventario, UID autorizado e identificador de operación.
4. Una sola transacción Firestore para costo, propiedad y recibo idempotente. La recuperación reutiliza el mismo ID de operación.

**Compatibilidad de despliegue:** se mantiene temporalmente el contrato anterior sin `shopDay` para clientes previos, que reciben precio base de artículos no retirados. La variable `HH_SHOP_DAILY_REQUIRED=enabled` obliga a todos los clientes a enviar día y solo se habilitará cuando la versión nueva sea la única admitida y la beta esté auditada. Activarla antes podría bloquear dispositivos anteriores. No se debe desplegar por cuenta propia.

**Pendiente de auditoría prebeta:** verificar Firebase App Check, cuentas autorizadas, Firestore rules de producción, concurrencia, doble canje, reconexión, compra después de medianoche, dos UIDs y saldo exacto. `firestore.candidate.rules` se ha actualizado como propuesta **NO DESPLEGADA**; la app normal sigue incluyendo una ruta cliente de escritura económica que debe migrarse al servidor antes de una beta pública.

## Verificación reproducible

Trabajar sobre la rama de desarrollo **sin descartar cambios locales**. Si el árbol de trabajo actual contiene modificaciones, usar una carpeta independiente mediante `git worktree` o guardarlas explícitamente; no hacer `reset --hard` ni sustituir respaldos.

```bash
git fetch origin feature/tienda-integral-2026-11-27
git worktree add ../Healthy-Habit-tienda origin/feature/tienda-integral-2026-11-27
cd ../Healthy-Habit-tienda
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/tienda/shop_daily_rotation_test.dart
flutter test test/tienda/wardrobe_slots_test.dart
flutter test test/tienda/shop_assets_test.dart
flutter test test/healthy_chat_modules_test.dart
flutter test
npm ci --prefix functions
npm --prefix functions test
```

Si se dispone del laboratorio Firebase Emulator de la app, correr las pruebas de `functions/tests-emulator/shop_catalog.integration.js` usando exclusivamente `demo-healthy-habit` con Auth, Firestore y Functions locales; **nunca** contra producción.

## Criterios de aceptación visual / Android

- [ ] Navegación en pantallas de 320 dp, 360 dp y teléfonos grandes, vertical y horizontal.
- [ ] Tema claro, oscuro, Cosmos y modo Lite; texto escalado (1×, 1.3×, 1.8×) y TalkBack.
- [ ] Ver 9 productos OVNI, cada ilustración distinguible; el original permanece intacto.
- [ ] Comprar con saldo, saldo insuficiente, reintentar compra y comprobar idempotencia.
- [ ] Equipar UFO y verlo en Armario, mini radar, tutorial, después de cerrar/reabrir y con otra cuenta; comprobar aislamiento por UID.
- [ ] Las compras desaparecen de la selección y permanecen en Armario.
- [ ] Ver la colección completa: no debe permitir comprar fuera de rotación.
- [ ] Ver el artículo de oferta y comparar costo aplicado por backend con precio de referencia correcto.
- [ ] Probar cambio de día UTC−06:00, sin depender de la zona horaria del dispositivo; un canje del día anterior se rechaza.
- [ ] Verificar que `skin_titan_secret` nunca aparece en ventas ni se concede sin acertijo y confirmación remota.
- [ ] Mantener el modo sin movimiento, botones accesibles, sonidos opcionales y ausencia de overflow.

## Limitaciones y pendientes identificados

- **Sin verificación Flutter/Android en el entorno de edición:** ejecutar las pruebas y revisar resultados CI del pull request; no promocionar a `main` si fallan.
- **Sin backend desplegado:** compras beta de nuevas skins/ofertas requieren actualizar Cloud Functions y revisar/App Check/reglas; no usar escrituras cliente como sustituto.
- **Precios provisionales:** la economía se conserva para los artículos existentes. Antes de rebalancear medir Habit Coins reales ganados por día y la progresión normal del usuario.
- **Historial con fecha de cada compra:** todavía no se expone como pantalla independiente; el Armario refleja propiedad, y las transacciones de beta conservan su identificador idempotente.
- **Animaciones y accesibilidad en Android físico:** pendientes de certificación visual.

**No habilitar monetización real, pagos en MXN ni prometer recompensas de hábitos hasta completar la auditoría de economía y evidencias.**
