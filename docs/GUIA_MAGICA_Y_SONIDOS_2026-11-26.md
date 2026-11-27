# Healthy Habit — Guía mágica y sonidos de interfaz

## Objetivo

Reducir la curva de aprendizaje sin obligar a aprender todas las pantallas antes de usar la app.

## Qué está implementado

- Botón flotante **violeta con destellos** en Inicio, Hábitos, Tienda, Catálogo y Perfil, además de pantallas específicas: registro de hábitos, chatbot, amigos, notificaciones, armario y reconocimiento visual.
- Al pulsarlo se abre una guía **contextual por sección** con pasos sucesivos, indicador de progreso, Anterior, Siguiente, Salir y Entendido.
- El contenido está redactado con conocimiento de los módulos reales, sin enviar información del usuario a modelos externos ni consultar IA. **No identifica dinámicamente los widgets en pantalla ni resalta cada control individual**. Es una primera versión reutilizable y confiable; el resaltado con claves de los elementos es un paso posterior.
- Sonidos originales **sintetizados en Android**, sin archivos externos: `tap` para navegación, `guide` al abrir ayuda, `open` al abrir ficha del catálogo y `friend` cuando se acepta una solicitud. Los sonidos preexistentes `talk`, `purchase`, `reward` y `achievement` siguen disponibles.
- Respeta `Configuración → Sonidos de la app` mediante la preferencia `sonidosApp` guardada en la cuenta. Se utiliza una caché breve en el servicio para evitar lecturas Firestore por cada pulsación; los cambios recientes de configuración pueden tardar hasta tres minutos en aplicarse al sonido.

## Archivos

- `lib/tema/healthy_magic_guide.dart`: contenido por módulo y widget reutilizable `HealthyMagicGuideButton`.
- `lib/servicios/healthy_retro_sound_service.dart`: reproducción y preferencia de sonidos.
- `android/app/src/main/kotlin/com/example/healthy_habit/MainActivity.kt`: sintetizador Android.
- `lib/páginas/inicio.dart`: barra de pestañas y acceso a guía.
- `test/healthy_magic_guide_test.dart`: pruebas de pasos y navegación.

## Instalación y verificación

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/healthy_magic_guide_test.dart
flutter run -t lib/main.dart
```

**Reconstruir Android**: los sonidos añaden tipos al canal nativo Kotlin; Hot Reload por sí solo no instala estos cambios.

## Prueba manual recomendada

1. Inicia sesión y entra a **Inicio**. Busca el botón flotante violeta.
2. Ábrelo, avanza cuatro explicaciones y sal.
3. Cambia entre Hábitos, Tienda, Catálogo y Perfil. Cada una debe mostrar contenido diferente y sonar suavemente cuando cambias pestaña.
4. Abre una ficha del catálogo y comprueba el sonido corto.
5. En Configuración, desactiva **Sonidos de la app**. Tras actualizar o cuando expire la caché, los efectos no deben reproducirse.
6. Repite pruebas en un dispositivo Android real. La reproducción sonora no debe bloquear ninguna operación.

## Límites

La guía actual es una orientación integrada por módulo, no un agente que interprete cada nuevo control que aparezca. Una siguiente versión puede incorporar `GlobalKey`, registro de controles y resaltado con una capa traslúcida para guiar acciones puntuales. El motor de sonidos es Android-only y su volumen depende del canal multimedia del teléfono.
