# Editor visual del armario — Healthy Habit

## Nuevo comportamiento
La pantalla de Armario presenta exclusivamente un **escenario fijo** y un **inventario de altura acotada**. No existe un scroll vertical que englobe ambas regiones. Al desplazarse por los objetos, Mr. Healthy o el perfil nunca se desplazan fuera de pantalla.

El selector superior tiene dos modos: **Mr. Healthy** (predeterminado) y **Perfil**. Cada modo muestra un solo escenario, sin combinarlos.

### Mr. Healthy
- La mascota aparece centrada sobre una sombra suave.
- Los objetos se agrupan por ranura real de Firestore: Cabeza, Rostro (ojos), Cuello, Torso, Brazos, Manos, Pies, Espalda, Skins y Aura.
- El botón de reinicio elimina los cosméticos equipados de la mascota, pero conserva las compras y no altera la personalización del perfil.
- «Pies» aparece como ranura preparada, aunque todavía no tiene artículos registrados.

### Perfil
- El escenario muestra el banner, avatar y marco que estén equipados.
- Las ranuras son Avatar, Marco, Banner y Expositor.
- El perfil no se muestra mientras está seleccionado el modo mascota.

### Inventario
- Los iconos de ranura se desplazan horizontalmente en su propia barra.
- La cuadrícula de objetos se desplaza verticalmente **dentro de su contenedor**, sin afectar el escenario.
- Los objetos no comprados conservan un candado y no se pueden equipar.
- Los objetos equipados muestran una marca de verificación.
- Al equipar o quitar se usa la transacción y respuesta háptica existentes.

## Validación local
```bash
cd ~/Documentos/Integradora/Healthy-Habit
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/tienda/wardrobe_slots_test.dart test/tienda/shop_assets_test.dart
flutter run
```

Probar con un celular Android: abrir Armario, desplazarse por Cabeza y Banner, verificar que el escenario no se mueva, alternar entre Perfil y Mr. Healthy, comprobar los candados y equipamiento, y observar el comportamiento en pantallas de poca altura.

Los cambios se han guardado en GitHub, **pero no se ejecutó Flutter en este entorno**. Validar el análisis y el diseño final en dispositivo antes de considerarlo terminado.
