# Aura de hojas — Mr. Healthy

## Diseño
Cosmético ambiental de la ranura `aura` con identificador `leaf_aura`. Precio: **180 Habit Coins**.

El efecto tiene tres planos:
1. **Entorno:** iluminación radial esmeralda translúcida detrás de la mascota.
2. **Borde:** halo verde-lima perimetral detrás de las prendas para evitar ocultar el rostro.
3. **Suelo y partículas:** anillos concéntricos bajo los pies y ocho hojas que flotan con pequeñas chispas.

La apariencia se dibuja con Flutter (`CustomPainter`) y no depende de un PNG nuevo. El diseño ilustrado sirve como referencia; la imagen completa de Mr. Healthy generada para la propuesta **no se utiliza como capa**, para preservar la mascota y los accesorios originales.

## Comportamiento
- El estado comprado y equipado se guarda en el flujo `shopInventory` / `shopEquipped.aura` existente.
- `HealthyMascotOutfit` compone los efectos con la mascota; la animación de respiración transforma el conjunto completo sin desalinear prendas.
- La vista de la tienda usa una miniatura de los mismos trazos vectoriales.
- El ciclo de hojas dura 5.2 segundos; en modo Lite, movimiento reducido o efectos desactivados queda una versión estática.
- El aura antigua `mint_aura` conserva su ID histórico, pero sigue retirada de la venta.

## Validación y despliegue
Se sincronizaron los precios de Flutter, `functions/official_shop_catalog.js` y **`firestore.candidate.rules`**.

**Importante:** las reglas de Firebase existentes en producción pueden impedir la compra y el equipamiento hasta que se revisen y desplieguen las reglas candidatas. No se desplegaron reglas desde esta sesión. `firebase.json` actualmente no declara una ruta de reglas de Firestore. No desplegar `firestore.strict-habits.rules` como reemplazo: contiene un catálogo histórico más antiguo.

```bash
cd ~/Documentos/Integradora/Healthy-Habit
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/tienda/healthy_leaf_aura_test.dart test/tienda/wardrobe_slots_test.dart
npm --prefix functions test
flutter run
```

Verificar en Android: comprar Aura de hojas, equiparla desde Armario > Mr. Healthy > Aura, revisar hojas, borde y anillo del suelo, equipar también sombrero y skin, activar modo Lite y comprobar que se detiene el movimiento sin desaparecer el efecto, reiniciar aplicación y verificar persistencia.

No se ejecutaron Flutter ni los emuladores durante la edición del repositorio.
