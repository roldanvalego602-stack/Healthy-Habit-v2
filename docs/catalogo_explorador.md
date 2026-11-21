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
