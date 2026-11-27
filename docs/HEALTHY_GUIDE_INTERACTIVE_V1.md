# Healthy Guide Interactive — Fase 1 (Hábitos)

## Estado y alcance

La primera fase integra un recorrido visual real en la pantalla **Hábitos** sin sustituir ni duplicar las explicaciones existentes.

- **Punto de entrada:** botón flotante «Explícame esta pantalla» en `lib/páginas/inicio.dart`, conservado.
- **Guía fuente:** `lib/tema/healthy_magic_guide.dart`. Para `habitos`, ahora abre `HealthyGuideOverlay`; el resto de las secciones conserva su modal original.
- **Objetivos registrados:** cabecera, accesos «Mis rutinas»/«En pareja», categorías y encabezado «Mis hábitos activos» de `lib/páginas/habitos/habits_screen.dart`.
- **Efectos:** fondo atenuado con recorte, contorno luminoso pulsante, indicador de dirección, tarjeta superpuesta con progreso y botones Anterior/Siguiente/Finalizar/Cerrar.
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
