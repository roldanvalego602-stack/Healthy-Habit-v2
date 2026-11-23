# Recursos de personalización — Healthy Habit

Esta carpeta recibirá los nuevos recursos de la tienda y del perfil, **sin sustituir** los recursos que la app ya utiliza en `assets/banners/`, `assets/vestimenta/` y `assets/avatares/`.

## Estructura

```text
assets/cosmeticos/
├── mr_healthy/
│   ├── cabeza/             # coronas, sombreros, gorros
│   ├── rostro/             # máscaras y gafas
│   ├── torso/              # sudaderas, chalecos, armaduras
│   ├── brazos_manos/       # guantes y objetos de manos
│   ├── pies/               # calzado
│   ├── espalda/            # mochilas, capas, alas
│   ├── skins/              # aspectos completos del personaje
│   └── animaciones/        # gestos/celebraciones
├── perfil/
│   ├── banners/            # cabeceras 1200 × 450 (8:3)
│   ├── marcos/             # aro con centro transparente
│   ├── avatares_animados/
│   ├── efectos/
│   └── insignias_titulos/
├── app/
│   ├── temas/              # paletas/configuraciones de apariencia
│   ├── iconos/             # variantes de iconos internos
│   └── sonidos_mr_healthy/ # sonidos originales de expresión
└── social/
    └── reacciones/         # stickers y reacciones para amigos
```

## Convenciones para los archivos

- Nombre descriptivo en **minúsculas, sin espacios ni acentos**, con guiones bajos: `sombrero_hechicero.png`, `marco_arcano.png`, `bosque_esmeralda.png`.
- Accesorios, marcos y elementos superpuestos: preferiblemente **PNG con transparencia real**. Una cuadrícula dibujada en el fondo **no es transparencia**; revisar el canal alfa antes de incorporarlos.
- Banners: formato **1200 × 450 px** (8:3). Respetar las zonas seguras descritas en `docs/GUIA_BANNERS_PERFIL.md`.
- Accesorios de Mr. Healthy: guardar **solo el objeto**, sin dibujar la mascota detrás. Conservar una plantilla común para que coincidan los puntos de anclaje.
- Animaciones: conservar el original editable y elegir el formato de ejecución después de comprobar la compatibilidad con Flutter.
- Sonidos: archivos originales, breves, de volumen moderado y con posibilidad de silenciarse.

## Nombres propuestos para el primer lote

```text
mr_healthy/cabeza/corona_hojas.png
mr_healthy/cabeza/sombrero_hechicero.png
mr_healthy/cabeza/casco_espacial.png
mr_healthy/cabeza/gafas_aviador.png
mr_healthy/cabeza/gorro_chef.png
mr_healthy/cabeza/audifonos_felinos.png
mr_healthy/cabeza/sombrero_papel.png
mr_healthy/rostro/mascara_heroe.png
mr_healthy/rostro/mascara_piedra.png
perfil/marcos/marco_esmeralda.png
perfil/marcos/marco_naturaleza.png
perfil/marcos/marco_arcano.png
perfil/marcos/marco_galactico.png
perfil/banners/bosque_esmeralda.png
perfil/banners/atardecer_dorado.png
perfil/banners/reino_arcano.png
perfil/banners/horizonte_galactico.png
```

## Integración futura en Flutter

**Estas carpetas están preparadas, pero todavía no se han registrado como recursos de ejecución ni se han añadido artículos a la tienda.**

Las entradas existentes de `pubspec.yaml` apuntan a directorios antiguos y no deben considerarse recursivas: al incorporar imágenes nuevas, declarar cada carpeta de recursos correspondiente bajo `flutter/assets`, registrar las rutas en el catálogo pertinente y ejecutar `flutter pub get` y pruebas de renderizado. Para banners y artículos de tienda, actualizar también la lista de opciones, permisos y persistencia necesarios antes de habilitarlos.

**No reemplazar archivos existentes ni borrar los `.gitkeep` hasta que Git pueda conservar la carpeta por contener recursos reales.**
