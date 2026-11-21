# Catálogo interactivo — primera etapa

El módulo `lib/páginas/catalogo/catalogo_screen.dart` es independiente
del catálogo oficial de **hábitos**. Contiene fichas informativas de
alimentos, ejercicios y consejos. No activa hábitos ni concede XP.

## Funcionalidades

- Búsqueda reactiva por título, descripción, etiquetas, beneficios,
  dificultad y metadatos; no distingue acentos ni mayúsculas.
- Filtros por etiquetas reales de la categoría seleccionada.
- Cuatro vistas: **lista**, **imágenes**, **detalles** y **exploración
  por grupos**. La última reúne alimentos por grupo orientativo,
  ejercicios por zona corporal registrada y consejos por objetivo.
- Orden alfabético para todas las categorías y orden descendente
  de proteína, grasas, carbohidratos o fibra en alimentos.
- Comparación informativa de dos o tres elementos con las fichas
  disponibles; no se calculan ni inventan nutrientes ausentes.
- Transiciones suaves al cambiar vistas o filtros y botón flotante
  cuando hay al menos dos elementos seleccionados.

## Alcance de los datos

El catálogo contiene actualmente **3 alimentos, 3 ejercicios y
3 consejos**. Los valores nutricionales, cuando existen, son
estimaciones por 100 g tomadas de las fichas demostrativas y
no necesariamente equivalentes entre alimentos crudos y cocidos.
No se ofrecen clasificaciones fiables de ejercicios para brazo o
flexibilidad cuando no hay fichas con esos metadatos. Agregar
opciones reales requiere ampliar el dataset con fuentes y detalles
válidos, no crear filtros vacíos.

La vista por grupos se inspira en la exploración del plato del
buen comer, pero **no** representa proporciones ni recomendaciones
individualizadas. Una implementación gráfica completa del plato
requiere primero fichas de verduras, frutas y otros grupos faltantes.

## Segunda etapa: contenido enriquecido y navegación visual

El conjunto de fichas se amplió de **9 a 28** entradas (12 alimentos,
10 ejercicios y 6 consejos), en
`lib/páginas/catalogo/datos/catalogo_ampliado.dart`.

- Alimentos añadidos: manzana, zanahoria, espinaca, arroz integral,
  tortilla de maíz, frijoles, garbanzos, pollo y yogur natural.
  Ahora hay contenido real para la exploración de frutas/verduras,
  cereales y leguminosas/origen animal. Lácteos aparecen en «Otros
  alimentos» porque el esquema visual tiene tres sectores simplificados.
- Ejercicios añadidos: flexiones en pared, curl de bíceps, movilidad de
  hombros, puente de glúteos, movilidad de cadera, estiramiento de
  pantorrilla y equilibrio con apoyo. Los filtros «Brazos»,
  «Flexibilidad», «Tren superior» y «Tren inferior» ya encuentran
  elementos reales.
- Consejos añadidos: recuperación después de actividad, rutina
  nocturna y pausas al estudiar. Las etiquetas «Recuperación» y «Sueño»
  ya reúnen contenidos pertinentes.

La vista Explorar muestra ahora un **plato circular interactivo con tres
sectores seleccionables** y un selector de zonas de movimiento.
Tocar una sección limita los grupos de resultados, y volver a tocarla
restablece la vista. El círculo es una navegación de contenidos
y **no expresa cantidades ni proporciones de alimentos**.

No hay todavía archivos fotográficos nuevos en
`assets/images/catalogo`: las nuevas fichas usan tarjetas con
ilustraciones gráficas de respaldo. No se atribuyeron cifras de
proteína, grasa ni otros macronutrientes a las nuevas fichas.
Las ordenaciones numéricas muestran primero los alimentos existentes
con valores y relegan las fichas sin medidas; además advierten
que las preparaciones crudas/cocidas no son directamente comparables.

Se actualizaron las 8 pruebas originales y se añadieron 4 casos nuevos
para las áreas corporales, grupos del plato, unicidad de IDs y ausencia
de nutrientes inventados.

## Verificación

Desde la raíz del repositorio:

```bash
git fetch origin feature/habits-discovery-routines
git merge --ff-only FETCH_HEAD
flutter analyze lib/páginas/catalogo
flutter test test/catalogo_explorador_test.dart
```

Pruebas agregadas: **8** pruebas unitarias del explorador.
También revisar visualmente en teléfono angosto y pantalla grande:
navegación por pestañas, vistas, ausencia de resultados, comparación,
accesibilidad y fallback si falta una imagen.

No se modifican los datos oficiales de hábitos, Firebase ni el
módulo de administración.


## Tercera etapa: continuidad visual y limpieza del análisis

- Se corrigieron las tres recomendaciones `curly_braces_in_flow_control_structures`
  del explorador. No hubo cambios en los cálculos de filtros.
- `CatalogoMedia` es ahora el elemento compartido para representar
  fotografías, SVG o ilustraciones propias de reserva según el tipo
  de ficha. Las fichas nuevas sin archivo no intentan cargar una ruta
  vacía del bundle.
- Tarjetas y ficha de detalle utilizan el mismo componente e
  identificador `Hero` para una transición visual continua al abrir
  el elemento.
- La cuadrícula de imágenes responde a pantallas angostas
  (una columna), teléfonos medianos (dos) y vistas amplias (tres).
- Se añadió `test/catalogo_media_test.dart` para las ilustraciones
  de reserva y la identificación de las transiciones.

Validar:

```bash
flutter analyze lib/páginas/catalogo
flutter test test/catalogo_explorador_test.dart
flutter test test/catalogo_media_test.dart
```

Además de las pruebas, inspeccionar manualmente el catálogo en
pantallas estrechas, el contraste en modo oscuro y la transición
al detalle de fichas sin imagen. Los recursos visuales nuevos son
ilustraciones integradas por código; no se han incluido fotografías
ni se ha modificado el contenido nutricional.
