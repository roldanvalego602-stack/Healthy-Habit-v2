# Healthy Habit · Archivo 001: El Santuario del Titán

**Corte:** 27 de noviembre de 2026.  
**Estado:** experiencia y recompensa implementadas en el repositorio; pruebas Flutter/emulador y validación visual Android pendientes. **No disponible para cuentas de producción por defecto.**  
**Diseño:** misterio ambiental, progresión por observación y recompensa cosmética única.

## 1. Historia: el prisionero del umbral

En lo profundo de Healthy Habit existe una cavidad olvidada: la **Cueva de los Siete Latidos**. Un guardián verde, enorme, permanece encerrado detrás de barrotes metálicos. Las leyendas afirman que su fuerza no proviene de ganar una batalla, sino de una virtud repetida diariamente. El jugador debe encontrar el umbral, leer las inscripciones y decir la palabra correcta. Al lograrlo, se abren las rejas y aparece **Mr. Healthy · Titán**.

El personaje conserva el rostro, la hoja y la personalidad de Mr. Healthy, pero tiene brazos enormes, torso marcado y emblema dorado. La ilustración original se realiza con `CustomPainter` en Flutter; no depende de imágenes externas ni de descargas en ejecución.

## 2. Ruta de descubrimiento por toda la aplicación

1. **Inicio · Pista 1:** en la tarjeta de Mr. Healthy aparece un mensaje pequeño: *«Una fuerza duerme tras siete latidos…»*. Tocarlo conduce a la Tienda, sin conceder ningún objeto.
2. **Chat · Pista 2:** preguntar por la cueva, el santuario, Titán, un prisionero o los siete latidos abre un relato breve que sitúa la entrada junto al lugar donde se cuentan las monedas.
3. **Tienda · Pista 3:** bajo el título aparece *«¿Escuchaste la leyenda de los siete latidos?»*. Abre una explicación del mecanismo.
4. **Entrada:** tocar siete veces el contador de Habit Coins en menos de cinco segundos. El contador de toques se muestra como una pista; las monedas no cambian.
5. **Santuario:** las rejas y una silueta muscular se iluminan. Se pueden descifrar hasta tres inscripciones gradualmente.
6. **Acertijo:** enviar una palabra a Firebase para comprobarla. Nunca se verifica localmente; el cliente no contiene la respuesta.
7. **Desbloqueo:** cuando el servidor confirma el éxito, el metal se abre, suena un efecto retro original y el jugador obtiene la skin en `shopInventory`. Desde Armario → Skins puede equiparla.
8. **Reingreso:** el servidor devuelve el estado conseguido sin volver a otorgar el premio.

**Inscripciones progresivas:**
- «No nazco de un solo esfuerzo».
- «Crezco cada día que regresas».
- «No soy fuerza ni velocidad; soy la virtud de seguir intentando».

**Accesibilidad y UX:** escena desplazable, campo de texto con etiqueta, controles accesibles, feedback textual y animación reducida cuando el sistema solicita menos movimiento. La ilustración no afecta controles de la app. Los intentos se cuentan en la fecha civil de `America/Mexico_City`.

## 3. Recompensa y seguridad

- ID inmutable: `skin_titan_secret`.
- Rareza: **legendaria secreta**, no comercializable.
- Precio en catálogo técnico: 0, pero **no es un artículo gratuito**: `ShopState.owns()` exige poseerlo explícitamente. Está oculto de Tienda y visible en Armario para gestión de la skin.
- La recompensa se concede una vez por UID mediante `claimTitanSecret`: `users/{uid}.shopInventory` recibe `FieldValue.arrayUnion`, con documento servidor de desbloqueo `healthy_secret_rewards/{uid}_titan_cave_v1`.
- No concede XP, Habit Coins, niveles ni otras recompensas monetarias.
- Máximo **5 intentos por día**; se controla mediante `healthy_secret_attempts/{uid}_titan_cave_v1_YYYY-MM-DD` y transacción Firestore; la cuota no depende de contadores del cliente.
- El backend de equipamiento valida que el usuario tenga el ID en el inventario aunque el precio técnico sea cero.
- La UI solo muestra «liberado» tras una confirmación remota.
- El antiguo `SecretTestBonusScreen` y su bono de 1,000 monedas son **laboratorio anterior independiente**: no forman parte del acertijo.

### Barrera de producción

La callable `titanSecret` **permanece deshabilitada en Firebase real** salvo que el entorno del servidor configure `HH_TITAN_SECRET_RELEASE=enabled` y la solicitud traiga App Check válido. No activar esta bandera mientras no estén auditadas y desplegadas las reglas de Firestore para impedir que el cliente añada por su cuenta `skin_titan_secret` a `shopInventory` o modifique `shopEquipped` indebidamente.

**No desplegar reglas candidatas por implementar este Easter egg.** La beta general de la app continúa pausada por motivos de seguridad independientes.

En Android normal, la cueva inicializa App Check con Play Integrity; en depuración se puede utilizar `--dart-define=HH_TITAN_APP_CHECK_DEBUG=true`, pero requiere registrar el token de depuración del dispositivo en Firebase App Check. Jamás utilizar el token como secreto en el repositorio. La modalidad emulador demo está aislada del proyecto de producción.

## 4. Componentes

| Archivo | Rol |
|---|---|
| `lib/páginas/tienda/healthy_titan_cave_screen.dart` | Escena, acertijo, animaciones, estado remoto, pistas |
| `lib/páginas/tienda/healthy_titan_skin.dart` | Ilustración vectorial de la skin |
| `lib/páginas/tienda/store_screen.dart` | Entrada de siete pulsaciones y pista |
| `lib/páginas/inicio.dart` | Pista inicial |
| `lib/páginas/chatbot/healthy_conversation_service.dart` | Pista narrativa opcional |
| `lib/páginas/tienda/shop_service.dart` | Catálogo técnico y propiedad explícita |
| `lib/páginas/tienda/wardrobe_screen.dart` | Selección de la skin en Armario |
| `lib/páginas/tienda/healthy_mascot_outfit.dart` | Skin equipada en mascota |
| `lib/páginas/tienda/shop_item_artwork.dart` | Miniatura del cosmético |
| `functions/titan_secret_reward.js` | Lógica server-side, transacción, límites |
| `functions/index.js` | Callable autenticada y protegida por App Check/flag |
| `functions/official_shop_catalog.js` y `shop_appearance_transaction.js` | Paridad y restricción de equipamiento |

## 5. Verificación antes de usar

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/healthy_titan_easter_egg_test.dart
flutter test test/healthy_conversation_context_test.dart
npm --prefix functions test
```

El archivo de pruebas de Functions cubre respuesta correcta, error, límite, cuota local, usuario inválido, recompensa única y ausencia de créditos. Las pruebas de Flutter cubren invisibilidad comercial, propiedad, selección en Armario y render vectorial. **Son pruebas añadidas, no ejecutadas aquí con Flutter ni en emulador**.

### Laboratorio Firebase Emulator

El backend permite `titanSecret` en `FUNCTIONS_EMULATOR=true`, solo para sesiones autentificadas del proyecto demo. La pantalla usa el emulador `us-central1:5001` cuando `HH_SHOP_DEMO_FIREBASE` y `HH_DEMO_SHOP_PURCHASE` están habilitadas y el proyecto es `demo-healthy-habit`. Reutilizar la configuración y las cuentas de prueba documentadas en `docs/CIERRE_AVANCES_Y_DEMO_2026-11-25.md`.

**Validación manual obligatoria:** siete toques (en y fuera del intervalo); rejas visibles, pistas, teclado, cinco fallos por día, éxito, volver a entrar, inventario persistido, equipar/quitar, logout/login, cuenta distinta, dispositivo pequeño, modo oscuro, modo Lite, sonido desactivado, sin conexión, Android real y emulador.

## 6. Futuras leyendas (solo diseño, sin código)

1. **La Semilla del Primer Día:** una marca discreta en una gráfica de progreso conduce a un relato sobre comienzos, sin premios de XP.
2. **La Biblioteca de las Raíces:** una ficha oculta del Catálogo abre fragmentos de historia al explorar contenidos educativos, con pistas no clínicas.
3. **El Cometa de las Siete Hojas:** un visitante ocasional del UFO deja constelaciones efímeras como experiencia decorativa, sin cambiar balances.
4. **La Zanahoria Errante:** una skin graciosa del UFO se puede obtener mediante evento futuro; requerirá autorización del servidor y una ranura independiente.

Ninguno de estos cuatro secretos existe todavía en la app. No deben presentarse como funcionalidad disponible.

## 7. Criterios de aceptación final

- No hay premios falsos, duplicados ni disponibles sin desbloqueo.
- Los intentos se controlan en el servidor, no solo en Flutter.
- La experiencia narrativa es alcanzable por las pistas, sin herramientas de desarrollo.
- El premio aparece y se puede equipar solo en el inventario del usuario correcto.
- Ninguna ruta modifica monedas o XP.
- No se habilita producción sin reglas y App Check auditados.
- El resultado visual funciona en Android pequeño y con reducir animaciones.
