# Healthy Habit — Tema premium Cosmos (primera implementación)

Fecha: 26 de noviembre de 2026. Rama: main.

## Experiencia

**Cosmos** es un tema comprable por **1,800 Habit Coins**. Cambia la paleta global a azul noche, violeta, cian y blanco estelar; agrega un fondo con nebulosas, estrellas parpadeantes y astros; dota a tarjetas de brillos y adornos, y aplica movimientos de órbita a iconos de hábitos y nivel. También sustituye automáticamente los once efectos de interfaz por versiones sonoras espaciales sintetizadas en Android. Ningún sonido externo es necesario.

**Limitación visual actual:** el fondo se dibuja detrás de las rutas. Las pantallas que todavía usan colores fijos opacos pueden ocultar parte de ese fondo. El tema ya usa tokens compartidos para las pantallas principales, pero una migración gradual de componentes heredados mejorará la cobertura visual.

## Compra y equipamiento

1. Entra en **Tienda** y busca la tarjeta destacada **COSMOS · TEMA ANIMADO** (también aparece bajo la categoría Temas mientras esté sin comprar).
2. Si tienes al menos 1,800 Habit Coins, pulsa **Desbloquear**. Se utiliza el mismo servicio de compras del inventario; no se entregan monedas gratis ni se modifica el saldo fuera del flujo de compra.
3. Cuando Firestore confirme la compra, aparece **Equipar Cosmos**. Debes tocarlo para activarlo.
4. Una vez equipado, el botón cambia a **Equipado · Quitar tema**. Puedes volver al estilo anterior sin perder el artículo.
5. Los cambios de compra y equipamiento quedan en los campos de la cuenta `shopInventory` y `shopEquipped.app_theme`. El cliente **nunca activa** el tema únicamente por una preferencia de dispositivo: requiere que el artículo exista en el inventario de la cuenta.

La apariencia anterior de Claro/Oscuro, Healthy Original o Navidad Esmeralda se conserva como preferencia para utilizarse nuevamente al quitar Cosmos. El comando Restaurar de Mr. Healthy no borra `app_theme`.

### Backend de beta

Se han actualizado el catálogo autorizado del servidor `functions/official_shop_catalog.js` y las ranuras autorizadas de `functions/shop_appearance_transaction.js` para permitir `theme_cosmos`.

**Los cambios del repositorio no despliegan Cloud Functions automáticamente.** Antes de intentar adquirir Cosmos en una beta conectada a las funciones oficiales, es necesario desplegar la versión del backend que incorpora el producto y validar las reglas de Firestore y App Check. No cambiar a la ruta cliente de demostración como solución temporal cuando falle una función de beta.

## Archivos importantes

- `lib/tema/cosmos_theme.dart`: paleta, nebulosas, estrellas, decoraciones y microórbitas, respetando el ajuste Lite.
- `lib/tema/cosmos_theme_sync.dart`: escucha sesión e inventario y autoriza la experiencia Cosmos para el usuario autenticado.
- `lib/tema/healthy_theme.dart`: tokens globales y ThemeData para Cosmos.
- `lib/tema/healthy_motion.dart`: adornos de tarjetas mediante un componente reutilizable.
- `lib/páginas/inicio.dart`, `lib/páginas/habitos/habits_screen.dart`, `lib/páginas/catalogo/catalogo_screen.dart`: progresos, hábitos y catálogo.
- `lib/páginas/tienda/store_screen.dart`: compra, equipamiento y desactivación.
- `lib/páginas/tienda/shop_service.dart`: producto de tienda y ruta de compra.
- `android/app/src/main/kotlin/com/example/healthy_habit/HealthySoundEngine.kt`: sonidos espaciales originales sin recursos externos.

## Comprobación en Linux y Android

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/cosmos_theme_test.dart
flutter run -t lib/main.dart
```

Pruebas de backend con Node instalando dependencias en `functions`, según el entorno de desarrollo habitual:

```bash
cd functions
npm test
```

El motor de sonido modifica código Kotlin; no basta Hot Reload para instalar los nuevos efectos. Conviene reiniciar la aplicación o recompilar en Android.

**Checklist de prueba manual:** compra con saldo suficiente, saldo insuficiente, compra repetida, equipar/desactivar, relanzar app, cerrar/cambiar sesión, comprobar sonidos con multimedia activado, modo Lite y al menos tres pantallas distintas. Revisar particularmente legibilidad en tarjetas que todavía tengan colores escritos directamente.

## Pruebas realizadas desde el editor

Se verificó por inspección de `main` que el catálogo de Flutter y el catálogo autorizado del servidor contienen 63 artículos y comparten exactamente los mismos IDs y precios; Cosmos figura a 1,800 Habit Coins y su ranura en el backend es `app_theme`.

**No se ha ejecutado Flutter ni compilado Android desde el entorno de edición.** Los resultados de pruebas de Node y Flutter deben comprobarse en el equipo del desarrollador antes de declarar que la funcionalidad está lista para beta.

## Fase 2 — Integración visual (26 de noviembre de 2026)

Se extendió Cosmos para que la transformación visual llegue a los módulos y no se limite a un fondo global:

- **Inicio:** pestaña seleccionada de la barra inferior con halo holográfico, tarjeta de nivel galáctica y progreso de XP como flujo de energía.
- **Hábitos:** colores propios para Alimentación, Hidratación, Energía y Bienestar que conservan contraste sobre fondos oscuros; iconos orbitales y barra de avance energética.
- **Tienda:** paletas cósmicas para las tarjetas de sus distintas categorías, filtros con colores legibles en seleccionados y bordes de contraste.
- **Perfil:** nivel y barra de XP espaciales, borde del perfil y módulo de amistades con identidad holográfica.
- **Catálogo:** envolturas reutilizables con brillos de esquinas y bordes estelares.
- **Desafíos:** cabecera de temporada espacial, barras de progreso energéticas y contornos de tarjetas adaptados al estado.
- **Rendimiento:** los controladores de órbita, fondo y brillo se pausan cuando se activa `Lite` o la preferencia del sistema de reducir animaciones.

**Importante:** las paletas heredadas de ciertas subpantallas pueden seguir mostrando colores de la experiencia original; corregirlas requiere revisar en dispositivo los flujos restantes, sin degradar la legibilidad.

### Validación específica

```bash
flutter analyze --no-fatal-infos lib
flutter test test/cosmos_theme_test.dart
flutter test test/healthy_emerald_christmas_theme_test.dart
flutter run -t lib/main.dart
```

En el dispositivo, probar la barra inferior, tarjetas de hábitos de las cuatro categorías, progreso en Perfil y Desafíos, fichas de Catálogo y filtros de la Tienda. Cambiar a modo Lite mientras Cosmos está equipado; la animación debe detenerse y los contenidos deben permanecer visibles.

No afirmar que esta fase está certificada para beta hasta realizar pruebas reales de navegación y contraste, pruebas Flutter y verificación de compra/equipamiento con backend desplegado.
