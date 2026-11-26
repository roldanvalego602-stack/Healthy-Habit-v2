# Mejoras de interfaz — herramientas, armario y chat

Cambios incorporados en `main` el 25 de noviembre de 2026.

## Registro de hábitos

La pantalla `RegistrarHabitoScreen` ofrece **Cambiar** junto a
**Herramienta de registro**. Es posible seleccionar registro manual,
contador, cronómetro, temporizador, podómetro, respiración, Pomodoro o
hidratación. En actividades parametrizables se puede ajustar la meta
de sesión; el contador permite seleccionar unidad.

La preferencia se conserva en `SharedPreferencesAsync` por UID y
`habitId`, incluso en intentos posteriores. El cambio **no** modifica
Firestore, la meta oficial del catálogo, XP ni Habit Coins. La
medición sigue siendo autodeclarada. El mecanismo funciona en la
aplicación habitual y en las rutas beta que aceptan interacciones.

## Editor de armario

En `WardrobeScreen`, seleccionar una ranura equipada de Mr. Healthy
permite abrir **Mover y escalar accesorio** con el botón correspondiente
en el escenario. Arrastrar cambia la ubicación; el deslizador cambia
el tamaño. Las coordenadas se limitan al lienzo de 280 × 275, y
se guardan por UID y objeto usando `SharedPreferencesAsync`.

**Límite explícito del MVP:** personaliza los accesorios visibles
en el escenario del armario; aún no sincroniza esos ajustes con otros
dispositivos, perfiles públicos ni vistas del personaje fuera del
armario. Las skins, auras y decoraciones del perfil requieren una
implementación específica y conservan su posición base.

La personalización visual no cambia `shopInventory`,
`shopEquipped`, precios ni permisos de Firebase.

## Chatbot

`NutriChatPage` incluye:
- Burbuja superior con una vista cercana de Mr. Healthy mientras el
  usuario tiene texto escrito en el campo del mensaje.
- Mensajes entrantes con escalado y desplazamiento suave tipo pop.
- Indicador de escritura con tres puntos animados y etiqueta accesible.
- Tiempo mínimo de aparición del indicador de 620 ms, incluso si el
  motor local genera una respuesta inmediata.
- Serialización del historial preservada: no se acepta otro mensaje
  hasta terminar de guardar la respuesta anterior.

La UI utiliza la duración adaptativa existente para la animación
de llegada de mensajes. No modifica las reglas de Firestore.

## Validación

```bash
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test
```

Hay prueba de widget para el indicador de escritura. Además, probar
manualmente en Android el movimiento táctil dentro del `FittedBox`,
el deslizador, la persistencia tras cerrar y abrir la pantalla y la
visualización de la foto superior del chat.

Estas mejoras son **independientes** del cierre de seguridad de
Firestore y no autorizan desplegar reglas nuevas ni activar la beta.
