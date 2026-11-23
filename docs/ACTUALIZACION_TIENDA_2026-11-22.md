# Tienda y armario: ampliación de cosméticos y vibración (22-11-2026)

## Cambios implementados

Se incorporaron **12 recursos adicionales** a los 27 anteriores: tres accesorios de cabeza, una skin completa y ocho banners degradados. El catálogo de la tienda tiene ahora **59 artículos**. Los nuevos precios son provisionales y están sincronizados en:

- `lib/páginas/tienda/shop_service.dart`
- `functions/official_shop_catalog.js`
- `firestore.candidate.rules`

Se verificó mediante lectura de GitHub que los **39 archivos cosméticos registrados** existen en el repositorio. La skin nueva está en `assets/cosmeticos/mr_healthy/skins/skin cartoon.png`.

**Al comprar**, el artículo desaparece de `Recompensas disponibles` y de los destacados en cuanto el stream de Firestore confirma que pertenece al usuario. No se elimina del inventario, no se reembolsa y puede seguirse equipando desde el armario. El filtrado se centralizó en `availableShopItems`.

**En el armario**, los elementos sin comprar muestran un candado encima de la imagen atenuada. No se permite equiparlos desde allí; las compras se hacen solo desde la tienda. Los elementos ya adquiridos se pueden equipar/retirar y muestran la ranura correspondiente. La nueva skin se equipa en la ranura `skin`, que aparece también en la proyección pública de `Mi Healthy`.

**Vibración:** al comprar se usa `HapticFeedback.mediumImpact()`; al equipar o retirar se usa `HapticFeedback.selectionClick()`. Ambas acciones respetan `settings.vibracionHaptica`. Al activar el interruptor de vibración en Configuración también se solicita una pulsación de prueba. El ajuste ya no depende de la sincronización de permisos de notificaciones.

La vibración física depende del dispositivo y de sus ajustes del sistema. En emulador, navegador o móvil con respuesta háptica deshabilitada puede no percibirse.

## Verificación local

En la única carpeta principal del proyecto y la rama `main`:

```bash
cd ~/Documentos/Integradora/Healthy-Habit
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/tienda/shop_assets_test.dart test/healthy_public_profile_service_test.dart
npm --prefix functions test
```

Verificación opcional de reglas con Firebase Emulator:

```bash
firebase emulators:exec --only firestore "npm --prefix tests/firestore test"
```

## Comprobaciones manuales

1. Abrir Tienda, comprar un accesorio y observar su desaparición de artículos disponibles y destacados.
2. Abrir Armario; confirmar que el artículo sigue allí y puede equiparse.
3. Observar el candado en otros artículos sin comprar y confirmar que no se pueden equipar.
4. Equipar y retirar un artículo; comprobar la vibración con `Vibración háptica` encendida y apagada.
5. Probar la vibración en un teléfono Android físico; al activar la opción en Configuración debe sentirse una respuesta, si el sistema permite hápticos.
6. Comprar/equipar la nueva skin; revisar `Mi Healthy` propio y en el perfil de otra cuenta.
7. Comprobar el tamaño y recorte de las nuevas imágenes en Android, especialmente la skin y las capas de la cabeza.

**Pendiente importante:** los cambios en `firestore.candidate.rules` no están desplegados. Si las reglas activas no incluyen nuevos artículos, las compras/equipamientos pueden fallar con `permission-denied`. No desplegar reglas sin comparar primero con la versión de producción y ejecutar la batería de pruebas.
