# Integración de cosméticos — Healthy Habit (22 nov 2026)

## Resumen

Se registraron **27 ilustraciones existentes** en `assets/cosmeticos/` y se agregaron al `shopCatalog`:

- 9 accesorios físicos para Mr. Healthy: tres accesorios de cabeza, guantes, dos accesorios de espalda, máscara de roca, casco espacial y antifaz.
- 4 marcos de foto de perfil.
- 4 banners de perfil.
- 4 avatares de perfil: tres imágenes y un GIF animado.
- 6 stickers/reacciones sociales.

**No existe actualmente ningún archivo de skin completa** en `assets/cosmeticos/mr_healthy/skins/`; por tanto, no se registró una skin inexistente.

Los precios en Habit Coins son **provisionales**, definidos en Flutter, el catálogo backend y las reglas candidatas. Confirmarlos con el equipo antes del lanzamiento.

## Dónde aparece cada artículo

- Tienda: categorías `Cabeza`, `Ropa`, `Accesorios`, `Marcos`, `Banners`, `Avatares`, `Reacciones`.
- Guardarropa: los artículos adquiridos se pueden equipar, los bloqueados aparecen sin poder equiparse. No se compra desde el guardarropa.
- Mr. Healthy: las capas de accesorios aparecen en el guardarropa y en `Mi Healthy` de los perfiles públicos. El encuadre de cada capa es inicial y necesita revisión visual en Android.
- Banners, marcos y avatares: aparecen en la cabecera del perfil propio y del perfil de amigos. El guardarropa incluye una vista previa del perfil.
- Avatar GIF: `HealthyProfileAvatar` usa `Image.asset` para reproducirlo.
- Stickers: se adquieren en la tienda, se envían desde el selector social, y se muestran en el panel de reacciones recibidas. Se codifican como `challengeId: sticker:<itemId>` usando el documento existente de `interactions`.
- Los ajustes clásicos de avatar, foto, banner y marco permiten volver a la apariencia gratuita sin borrar compras.

## Integración segura

- Los archivos se registran en `lib/tema/healthy_cosmetics.dart`, `shop_service.dart` y `pubspec.yaml`.
- Los 47 artículos (20 anteriores + 27 nuevos) deben conservar paridad de precios en `functions/official_shop_catalog.js`.
- `firestore.candidate.rules` valida precio y ranura de los nuevos artículos, junto con la posesión de stickers sociales.
- **No se han desplegado reglas ni Cloud Functions a Firebase**. Las pruebas locales o los emuladores son imprescindibles antes de publicar; no reemplazar reglas de producción sin comparar su contenido actual. De lo contrario, algunas compras o equipamientos nuevos pueden recibir `permission-denied`.
- La proyección pública contiene solo IDs de artículos equipados, no inventario ni Habit Coins. Cuando se equipa un avatar coleccionable, la proyección ya no muestra el URL de la foto previa.

## Validación local

En la carpeta original `Healthy-Habit`, rama `main`:

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/tienda/shop_assets_test.dart test/healthy_public_profile_service_test.dart test/profile_banner_test.dart
npm --prefix functions test
```

Para pruebas de reglas, con un emulador Firestore corriendo en el puerto 8080:

```bash
firebase emulators:exec --only firestore "npm --prefix tests/firestore test"
```

## Prueba manual con dos cuentas

1. Verificar imágenes de los 27 artículos en la tienda, sin errores de `Unable to load asset`.
2. Adquirir un marco, equiparlo en el guardarropa, comprobar la vista previa y abrir el perfil.
3. Repetir con banner, avatar y accesorio de Mr. Healthy. Reiniciar la app para comprobar persistencia.
4. Desde la segunda cuenta, abrir el perfil público y comprobar marco, banner, avatar y `Mi Healthy`.
5. Adquirir un sticker desde la primera cuenta; enviarlo a una persona amiga; comprobar que la imagen aparece en reacciones recibidas.
6. Verificar que un sticker no adquirido no se ofrece para enviar.
7. Cambiar a un avatar/banderola gratuitos y comprobar que el cosmético queda desequipado, pero aún pertenece a la colección.
8. Comprobar en Android si los PNG contienen transparencia real. Los assets generados pueden requerir recorte, eliminación de fondos falsos o ajustes de tamaño.
9. Probar con red lenta y en dispositivo estrecho.

## Límites de esta entrega

No se han ejecutado pruebas Flutter ni Firebase desde el entorno de edición, y no se puede dar por probado un flujo de compra real en el dispositivo. El listado de imágenes se verificó contra los nombres exactos de archivos presentes en GitHub. La implementación necesita la validación local y, posteriormente, una revisión específica de las reglas realmente publicadas.
