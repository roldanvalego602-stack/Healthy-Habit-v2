# Banners para perfiles — Healthy Habit

## Formato maestro

- Diseño: **1200 × 450 px (8:3)**.
- Ambos perfiles utilizan el mismo widget `ProfileBanner` y un `AspectRatio(8 / 3)`.
- Se muestra con `BoxFit.cover` y `Alignment.center`, sin estiramientos.
- Los bordes del contenedor son redondeados (`22` px lógicos).
- No insertar texto permanente en el propio PNG: las etiquetas pertenecen al widget.

## Zona segura

- Dejar **12 % de margen horizontal a izquierda y derecha** (144 px por lado en el maestro).
- Evitar detalles importantes en **la zona inferior central**: la foto del usuario se superpone al borde inferior y oculta aproximadamente los últimos 35 % de la altura en torno al centro en móviles.
- Colocar figuras principales hacia las zonas laterales/intermedias, sin depender de un punto exacto que pueda tapar el avatar.
- Los efectos, hojas, brillos y fondos pueden alcanzar los bordes; las figuras, símbolos y textos importantes no.
- Las etiquetas dinámicas aparecen arriba a la izquierda; evitar detalles indispensables en esa esquina.
- No generar variantes diferentes para el perfil propio y el ajeno: ambos comparten una única imagen de banner.

## Integración

Los banners actuales se resuelven desde `HealthyAssetCatalog.banners`.
Para añadir un nuevo banner a futuro:
1. Exportar el PNG con la proporción 8:3 y añadirlo a `assets/banners/`.
2. Registrar el nombre y ruta en `HealthyAssetCatalog.banners`.
3. Ampliar las opciones admitidas por el selector de perfil, la proyección pública y las reglas correspondientes de Firestore **antes de habilitarlo**. No asumir que un recurso nuevo es seleccionable automáticamente.
4. Probar en Android la cabecera propia y la de otro usuario, con avatar superpuesto.

## Verificación

```bash
flutter analyze --no-fatal-infos lib
flutter test test/profile_banner_test.dart
```

Este cambio modifica únicamente la presentación de los banners; **no añade banners gráficos nuevos ni despliega reglas de Firebase**.
