# Healthy Guide Interactive — Fase 1 (Hábitos)

## Estado y alcance

La primera fase integra un recorrido visual real en la pantalla **Hábitos** sin sustituir ni duplicar las explicaciones existentes.

- **Punto de entrada:** botón flotante «Explícame esta pantalla» en `lib/páginas/inicio.dart`, conservado.
- **Guía fuente:** `lib/tema/healthy_magic_guide.dart`. Para `habitos`, ahora abre `HealthyGuideOverlay`; el resto de las secciones conserva su modal original.
- **Objetivos registrados:** cabecera, accesos «Mis rutinas»/«En pareja», categorías y encabezado «Mis hábitos activos» de `lib/páginas/habitos/habits_screen.dart`.
- **Efectos:** fondo atenuado con recorte, contorno luminoso pulsante, puntero orientado hacia el objetivo, avatar de Mr. Healthy con flotación ligera, tarjeta superpuesta con progreso y botones Anterior/Siguiente/Finalizar/Cerrar.
- **Seguridad:** `ModalBarrier` bloquea acciones de fondo durante el recorrido. No modifica hábitos, monedas, XP, registros ni Firebase.
- **Objetivos ausentes:** si el widget todavía no está construido (por ejemplo, contenido perezoso de una lista), la guía muestra la explicación sin recorte. Si está construido, se intenta desplazar mediante `Scrollable.ensureVisible`.
- **Compatibilidad:** tema claro/oscuro; respeto básico de `MediaQuery.disableAnimations`. Los efectos Cosmos específicos aún no se implementan.

## Archivos

| Ruta | Propósito |
|---|---|
| `lib/guia/guide_step.dart` | Modelo de paso visual |
| `lib/guia/guide_controller.dart` | Navegación y estado del tour |
| `lib/guia/guide_target.dart` | Identificadores estables de widgets |
| `lib/guia/guide_spotlight_painter.dart` | Máscara y halo |
| `lib/guia/healthy_guide_overlay.dart` | Overlay modal y tarjeta |
| `lib/tema/healthy_magic_guide.dart` | Enrutamiento de la guía |
| `lib/páginas/habitos/habits_screen.dart` | Objetivos marcados |
| `test/healthy_guide_phase1_test.dart` | Pruebas de controlador y UI |

## Comprobación

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/healthy_guide_phase1_test.dart
```

Abrir la app en Android, entrar a **Hábitos** y pulsar **Explícame esta pantalla**. Verificar:

1. Foco sobre elementos visibles y fallback cuando no lo están.
2. Siguiente, Anterior, Finalizar y Cerrar.
3. El fondo no responde a toques mientras la guía está activa.
4. Recorrido con y sin hábitos; no hay errores al faltar datos.
5. Navegar a Tienda o Inicio y comprobar que su guía anterior sigue funcionando.
6. Prueba en modo oscuro, Cosmos, distintas densidades y pantalla pequeña.

**No se ha ejecutado Flutter en este entorno remoto**. Esta primera fase es infraestructura y spotlight. Las inclinaciones, gestos complejos, extracción visual de tarjetas, partículas y coreografías corresponden a fases posteriores.

## Criterio de salida de Fase 1

Sin errores de análisis, suite de widget tests aprobada y revisión en Android sin bloqueos, objetivos duplicados, desbordamientos ni toques a acciones reales.

**Secuencia inicial:** introducción enfocada en la cabecera y cuatro pasos editoriales (explorar, rutinas, hábitos activos y registro). Cuando un elemento de la lista aún no está construido, la explicación continúa sin recorte y sin forzar una operación.

## Fase 2 — Personaje presentador y orientación animada

El motor de Hábitos ahora incorpora a **Mr. Healthy como personaje independiente de la tarjeta**. Utiliza el recurso original `assets/mascot/healthy.png` en primer plano, con animaciones de llegada (escala y opacidad), flotación, inclinación hacia el objetivo, orientación de su indicador y transición de posición entre pasos.

Se añadieron tres módulos:
- `lib/guia/guide_character_pose.dart`: algoritmo de geometría que evalúa ubicaciones alrededor del objetivo y penaliza superposiciones con la tarjeta o el objetivo. Mantiene límites de área segura y configura la orientación.
- `lib/guia/assistant_guide_character.dart`: sprite de Mr. Healthy con entrada por paso, balanceo suave, flotación y aura bajo el personaje. Usa `RepaintBoundary` y `IgnorePointer`; no intercepta interacciones ni modifica el estado de la cuenta.
- `lib/guia/guide_pointer.dart`: línea curva decorativa con brillo tenue, punta de flecha e indicador sobre el objetivo, dibujada por `CustomPainter`.

El overlay `lib/guia/healthy_guide_overlay.dart` integra estos componentes, manteniendo el bloqueo modal del fondo, la tarjeta informativa y la localización del elemento. **Se respeta la configuración de animaciones** mediante `HealthyVisualEffects.enabled(context)`: en modo Lite o con movimiento reducido se detiene el ticker y las transiciones se vuelven inmediatas.

La mascota existente es una imagen/sprite plano, no un personaje esquelético con articulaciones. Por ello, en esta fase **se simulan movimientos de cuerpo completo** y se dibuja un señalador externo; no se afirma que exista un brazo animado o seguimiento ocular real. La animación articulada requeriría sprites por pose o recursos Rive adecuados, que no están incluidos.

### Validación

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/healthy_guide_phase1_test.dart
flutter test test/healthy_guide_phase2_test.dart
```

En Android: abrir Hábitos, activar la guía, revisar el desplazamiento de Mr. Healthy al avanzar/retroceder, la línea indicadora y la ausencia de superposición con la tarjeta en pantallas pequeñas. Revisar también modo Lite y la preferencia de movimiento reducido.

**Pendiente:** validar compilación y pruebas en la instalación de Flutter del proyecto. Esta fase no incluye extracción/ampliación de widgets ni nuevos recursos gráficos articulados. 

## Fase 3 — Extracción cinematográfica de widgets

Se incorporó la posibilidad de **extraer y ampliar visualmente** elementos de Hábitos mediante una captura temporal `RepaintBoundary.toImage()`. La animación se realiza exclusivamente sobre una imagen PNG de la interfaz visible; el widget original permanece intacto, los botones del duplicado no reciben eventos y el bloqueo modal de la guía sigue activo.

### Nuevas piezas

- `lib/guia/guide_extraction.dart`: posiciona y anima el fotograma entre su rectángulo original y una zona reservada de primer plano, con borde luminoso, sombra y regreso a su origen.
- `lib/guia/guide_step.dart`: permite marcar un paso con `extract: true`.
- `lib/guia/healthy_guide_overlay.dart`: toma la captura después del fotograma de pintura, usa un presupuesto de píxeles limitado, libera el `ui.Image` nativo y anima la representación inerte; antes de avanzar o retroceder intenta mostrar la animación de retorno. El spotlight y el señalador siguen la representación ampliada.
- `lib/páginas/habitos/habits_screen.dart`: marca la cuadrícula de categorías y la primera tarjeta visible de hábito activo con `RepaintBoundary`.
- `lib/tema/healthy_magic_guide.dart`: activa la extracción durante el recorrido de categorías y añade un paso específico para examinar una tarjeta de hábito real.

### Casos de ausencia

Si no existen hábitos activos, la primera tarjeta no está montada, falla la captura, o el dispositivo no ofrece espacio suficiente para una ampliación, se mantiene el recorrido normal con texto y spotlight cuando sea posible. No se inventan datos de progreso ni se construye un hábito ficticio para la demostración.

La captura es de **solo lectura**, puede contener el contenido que el usuario ya está viendo y no se guarda en Firebase, disco ni historial; permanece en memoria temporal del recorrido. No se añade capacidad de hacer compras, registrar hábitos o abandonar actividades desde la vista extraída.

### Validación

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/healthy_guide_phase1_test.dart
flutter test test/healthy_guide_phase2_test.dart
flutter test test/healthy_guide_phase3_test.dart
```

Verificar visualmente en Android: llegada de la captura al primer plano, zoom y retorno, bloqueo de botones bajo la máscara, ausencia de desbordamiento en teléfonos pequeños, experiencia con y sin hábitos y reducción de movimiento. La extracción aún no está habilitada en otras pantallas.

**Estado:** archivos integrados en GitHub; el análisis y los widget tests todavía deben ejecutarse en el equipo con Flutter.

## Fase 4 — Coreografía, partículas y temas visuales

Se añadieron efectos coordinados al recorrido de Hábitos, sin cambiar sus operaciones ni permisos.

### Componentes nuevos
- `lib/guia/guide_fx_theme.dart`: selecciona la paleta de la guía a partir del tema ya equipado. Healthy utiliza verdes; Navidad Esmeralda introduce un acento cálido; Cosmos utiliza cian y violeta de `CosmosPalette`. La guía **no desbloquea** Cosmos ni modifica inventarios.
- `lib/guia/guide_choreography.dart`: un único `CustomPainter` dibuja halo radial, anillo de llegada y un número fijo de partículas decorativas alrededor del objetivo. Cosmos usa destellos en cruz, sin imágenes, timers individuales ni widgets por partícula.
- `lib/guia/healthy_guide_overlay.dart`: incorpora una animación corta de llegada a cada paso, cambia dinámicamente la paleta, desplaza de manera coordinada el inicio de la línea curva con Mr. Healthy y realiza la transición de texto mediante `AnimatedSwitcher`.
- `lib/guia/guide_extraction.dart`: añade una inclinación muy discreta durante la ampliación, reversible al regresar al elemento original.
- `test/healthy_guide_phase4_test.dart`: cubre paletas, cambio de paso, dibujo con y sin objetivo y reducción de movimiento.

### Seguridad, rendimiento y accesibilidad
- Los efectos usan la misma animación de pulso existente y un controlador corto de llegada. No se crean partículas interactivas ni se consultan datos nuevos.
- En modo Lite, si se desactivan las animaciones de la app o si el sistema pide reducir movimiento, las transiciones decorativas se detienen o pasan a duración cero y se conserva el contenido educativo.
- `IgnorePointer` y el bloqueo modal continúan impidiendo activar registros, compras u otras acciones detrás de la guía.
- La mascota continúa siendo un sprite plano; el brazo articulado, las expresiones faciales y las poses dibujadas individualmente requerirían materiales gráficos específicos.
- Esta fase permanece limitada a **Hábitos**. El resto de las pantallas conserva la guía anterior.

### Comprobación

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/healthy_guide_phase1_test.dart
flutter test test/healthy_guide_phase2_test.dart
flutter test test/healthy_guide_phase3_test.dart
flutter test test/healthy_guide_phase4_test.dart
```

En Android comprobar paso adelante/atrás, aparición del halo, comportamiento de Cosmos solo cuando está equipado, retorno de tarjetas y ausencia de animaciones en Lite. También revisar teléfonos pequeños, accesibilidad y cierres durante las transiciones.

**Estado:** los cambios están en GitHub. La ejecución de Flutter y la validación visual siguen siendo necesarias desde el equipo de desarrollo.

## Corrección de incidencias detectadas en pruebas — noviembre de 2026

A partir del registro de Flutter proporcionado se corrigió:

1. **Error de compilación de Fase 4:** el icono de cabecera tenía `const Icon(... color: accent)` aunque `accent` depende del tema en tiempo de ejecución. Se retiró `const`.
2. **Lint de Fase 4:** se encerró en llaves el `if` del filtro de partículas de `guide_choreography.dart`.
3. **Pruebas de Fase 3:** las pruebas visuales utilizaban directamente la rasterización asíncrona `RepaintBoundary.toImage()`, una dependencia inestable para comprobar la lógica del overlay en widget tests. Se agregó el parámetro opcional `HealthyGuideCapture capture` a `HealthyGuideOverlay.show`, que permite suministrar una imagen PNG de prueba reproducible. En producción, sin ese parámetro, **continúa utilizándose la captura real del widget**. Las pruebas de extracción, retorno y bloqueo ahora inyectan una pequeña imagen válida y esperan con varios `pump` hasta que aparezca la representación.

Importante: las pruebas de Fase 3 con captura simulada verifican el flujo de la interfaz, **no la fidelidad de una captura GPU real**. Se mantiene como comprobación manual en Android la ampliación de una tarjeta auténtica. Los fallos posteriores de «Modo alternativo» en el registro probablemente fueron consecuencia de que una prueba previa interrumpió su ejecución sin cerrar el overlay global; se debe repetir la batería completa para confirmar el resultado.

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/healthy_guide_phase1_test.dart
flutter test test/healthy_guide_phase2_test.dart
flutter test test/healthy_guide_phase3_test.dart
flutter test test/healthy_guide_phase4_test.dart
```

## Corrección de accesibilidad del overlay raíz

Después de que las fases 1, 2 y 3 pasaran y el análisis quedara sin advertencias, la prueba `reducir movimiento desactiva transiciones del texto` de la fase 4 detectó una pérdida de contexto: el overlay se monta con `rootOverlay: true` y puede quedar **por encima del `MediaQuery` de la ruta de origen**, por lo que no veía `disableAnimations: true`.

`HealthyGuideOverlay.show` ahora toma `MediaQuery.of(context)` desde la pantalla que solicitó el recorrido y envuelve la escena en ese `MediaQuery` al insertarla en el overlay raíz. Así conserva la configuración de reducción de movimiento, el tamaño, la escala de texto y los márgenes de la pantalla que abrió la guía. La prueba `healthy_guide_phase4_test.dart` comprueba explícitamente que la escena recibe `disableAnimations: true` y que `AnimatedSwitcher.duration` es cero.

Esta modificación no altera la lógica de la Fase 3 ni la animación normal de quien no solicitó movimiento reducido. La ejecución real de Flutter está pendiente en el equipo del proyecto.

## Ajuste de viewport y cierre en Fase 4

La prueba de reducción de movimiento ya verificaba correctamente `disableAnimations: true`, pero su `MediaQueryData` local no incluía dimensiones de pantalla y el botón `Finalizar` se situaba fuera de los límites reales del test (`800 × 600`). En el overlay raíz, se toma ahora **el tamaño del `MediaQuery` del overlay** y se combina con las preferencias de accesibilidad del origen. De este modo, la guía mantiene `disableAnimations` y coloca la tarjeta dentro del viewport efectivo.

La prueba de Fase 4 también comprueba el tamaño heredado, los límites del botón y que se pueda pulsar realmente. No se ocultó la advertencia `tap()` ni se desactivaron las comprobaciones de hit testing. Verificar con `flutter analyze --no-fatal-infos lib` y `flutter test test/healthy_guide_phase4_test.dart`.
