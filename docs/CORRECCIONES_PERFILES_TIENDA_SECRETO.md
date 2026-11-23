# Correcciones: foto de amigos, catálogo y sala secreta

## 1. Foto del perfil público
El avatar público ahora es un control accesible y abre `ProfilePhotoFullScreen`, un visor con zoom mediante `InteractiveViewer`. Funciona tanto para una fotografía HTTPS como para un avatar local PNG/GIF. No añade permisos para consultar fotografías privadas.

## 2. Limpieza de artículos históricos
Los siguientes objetos se **retiran de las interfaces visibles**, pero conservan sus IDs y precios técnicos para evitar perder compatibilidad con compras anteriores:

- `crown`: Corona de bronce
- `mint_aura`: Aura menta
- `elite_avatar`: Avatar Élite
- `banner`: Banner genérico
- `avatar_frame`: Marco genérico sin ilustración
- `streak_guard`: Protector de racha (**pendiente de diseño y de lógica de consumo**)
- `mint_scarf`: Pañuelo Menta
- `bandana`: Bufanda genérica sin ilustración
- `cape`: Capa de héroe genérica
- `pixel_glasses`: Lentes pixel
- `cat_ears`: Orejas felinas

Se mantienen los diseños específicos actuales, incluida la corona vegetal, capa roja real y audífonos con orejas de gato. La prueba de paridad de 59 elementos de Flutter y Functions permanece válida.

**Expositor de logros (`achievement_display`)** no se retira: se equipa desde Perfil > Expositor y modifica visualmente la tarjeta de logros reales en los perfiles propio y público. No inventa insignias ni desactiva la privacidad de los logros. `healthyEquipped.perfil_expositor` debe estar autorizado por las reglas candidatas antes de desplegar.

## 3. Easter egg (exclusivo para pruebas)

Desde **Tienda**, tocar **siete veces el saldo de monedas** en menos de cinco segundos por intervalo de toques abre `Sala secreta`.

La bonificación acredita **1,000 Habit Coins una sola vez por usuario**, pero **solo en el Firebase Emulator del proyecto `demo-healthy-habit`**. En una compilación normal, la página se abre pero la recompensa está deshabilitada. No existe ninguna escritura directa de saldos desde Flutter; el callable `claimSecretTestBonus` exige autenticación, verifica `FUNCTIONS_EMULATOR=true` y `GCLOUD_PROJECT=demo-healthy-habit`, y registra la entrega atómica en `secret_test_bonus_claims/{uid}`. El cliente no envía ni decide el monto.

Para habilitar la llamada de pruebas se requiere el arranque demo existente del proyecto, incluidos `HH_DEMO_SHOP_PURCHASE=true`, `ShopDemoBootstrap.enabled`, un host compatible y los emuladores de Auth, Firestore y Functions. **No desplegar ni eliminar las barreras de entorno para intentar obtener monedas en producción.**

## 4. Validación local

```bash
cd ~/Documentos/Integradora/Healthy-Habit
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/tienda/shop_assets_test.dart test/healthy_public_profile_service_test.dart
npm --prefix functions test
```

Pruebas manuales:
1. Desde otra cuenta, abrir foto de perfil de un amigo y ampliar con dos dedos.
2. Abrir Tienda y Armario; ninguno de los once objetos retirados debe aparecer.
3. Comprobar que el expositor está en Perfil y que la tarjeta de logros cambia cuando se equipa.
4. Pulsar el saldo de Tienda siete veces para encontrar la página secreta.
5. Verificar que, fuera del emulador demo, el botón de otorgamiento esté deshabilitado.
6. En el emulador demo, reclamar una vez, verificar 1,000 monedas y comprobar que una segunda reclamación no acredita monedas.

**Estas modificaciones no fueron compiladas ni probadas en un dispositivo dentro del entorno de edición.** El usuario debe ejecutar las pruebas antes de considerar el resultado final.

## 5. Pendientes

El protector de racha necesita una ilustración original y la implementación de reglas de consumo/reclamación antes de volver a habilitarlo en venta. El catálogo conserva el ID `streak_guard` para evitar migraciones inseguras.
