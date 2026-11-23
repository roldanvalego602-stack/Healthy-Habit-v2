# Auras estelar y dorada — Mr. Healthy

## Nuevos artículos

| ID | Nombre | Precio | Ranura |
| --- | --- | ---: | --- |
| `stellar_aura` | Aura estelar | 280 Habit Coins | `aura` |
| `golden_aura` | Aura dorada | 400 Habit Coins | `aura` |

Ambas son efectos **ambientales** creados mediante `CustomPainter`, no skins ni PNG con otra versión de Mr. Healthy. El dibujo original, los sombreros, las prendas y la animación de respiración se conservan.

- **Estelar:** halo azul-violeta, órbita brillante alrededor del cuerpo, estrellas de distinto tamaño, chispas y dos anillos luminosos en el suelo.
- **Dorada:** resplandor amarillo-dorado, rayos radiantes detrás del cuerpo, hojas de laurel y estrellas flotantes, más anillos dorados en el suelo.
- Los efectos de borde y luz están **detrás** del conjunto de la mascota; las partículas quedan en la capa frontal, pero se sitúan alrededor y no encima del rostro.
- Ciclo de 6 segundos en modo Normal. En modo Lite o al desactivar animaciones se muestra una versión estática.
- La misma composición vectorial sirve para las miniaturas de tienda y armario.

## Implementación

- `lib/páginas/tienda/healthy_special_auras.dart`: efectos y miniaturas.
- `lib/páginas/tienda/healthy_mascot_outfit.dart`: selecciona una única aura según `shopEquipped.aura`. La animación de reposo existente mueve la composición sin separar accesorios.
- `lib/páginas/tienda/shop_item_artwork.dart`: miniaturas.
- `lib/páginas/tienda/shop_service.dart`: inventario y precios.
- `functions/official_shop_catalog.js` y `firestore.candidate.rules`: precios y permiso para equipar ambas variantes.
- Pruebas en `test/tienda/healthy_special_auras_test.dart`, `test/tienda/wardrobe_slots_test.dart` y la prueba de paridad del backend.

## Validación local

```bash
cd ~/Documentos/Integradora/Healthy-Habit
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/tienda/healthy_leaf_aura_test.dart test/tienda/healthy_special_auras_test.dart test/tienda/wardrobe_slots_test.dart
npm --prefix functions test
flutter run
```

## Pruebas manuales

1. Comprar Aura estelar y Aura dorada (280 y 400 monedas respectivamente).
2. Equipar Aura estelar desde Armario > Mr. Healthy > Aura. Verificar borde, estrellas, órbita y suelo.
3. Equipar Aura dorada: debe sustituir completamente a la estelar, no acumularse.
4. Combinar cada una con una skin y un sombrero. Ningún accesorio debe quedar oculto ni desprenderse durante la respiración.
5. Activar modo Lite y movimiento reducido: los efectos permanecen estáticos.
6. Reiniciar la app y comprobar que solo queda equipada la última aura elegida.

**Despliegue:** cambios hechos en `firestore.candidate.rules`, no en las reglas reales. Si Firebase rechaza compra o equipamiento, revisar y desplegar de forma controlada las reglas vigentes de la base de datos; no reemplazarlas sin comparar su configuración de seguridad. `firebase.json` no contiene actualmente una entrada para reglas de Firestore.

**No se ejecutó Flutter, el emulador ni pruebas de dispositivo desde el entorno de edición.**
