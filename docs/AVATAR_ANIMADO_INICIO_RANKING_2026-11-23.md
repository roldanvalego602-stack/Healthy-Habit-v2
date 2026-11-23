# Avatares equipados en Inicio y Ranking — 23/11/2026

## Problema
Inicio y Ranking utilizaban `photoUrl` o un `CircleAvatar` fijo. Al equipar `avatar_snowman` (GIF) desde el armario, la personalización sí se reflejaba en el perfil, pero no en estas pantallas.

## Correcciones
- `lib/tema/healthy_profile_presentation.dart` resuelve el avatar y la foto correctamente. En Inicio consulta `shopEquipped.perfil_avatar`; en Ranking utiliza `healthyEquipped.perfil_avatar` del perfil público. Si existe un avatar válido equipado, se ignora la URL antigua de fotografía.
- `lib/páginas/inicio.dart` y la pantalla de inicio alternativa `lib/main.dart` muestran `HealthyProfileAvatar` con el `preset` seleccionado. El formato GIF se anima mediante `Image.asset` sin bibliotecas adicionales.
- `lib/páginas/ranking_screen.dart` muestra el avatar personalizado tanto en el podio como en las filas del ranking.
- Todos los participantes son pulsables desde el podio y la lista: al tocar otro usuario se abre `PublicProfileScreen` con su ID; al tocar la propia cuenta, `ProfileScreen`.
- No se modifica el esquema de Firestore ni se realizan consultas a colecciones privadas para el ranking. La clasificación continúa usando `public_profiles`.

## Validación en dispositivo
```bash
cd ~/Documentos/Integradora/Healthy-Habit
git fetch origin main
git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/perfil/healthy_profile_presentation_test.dart test/ranking_profile_navigation_test.dart test/ranking_responsive_test.dart test/ranking_motion_test.dart
flutter run
```

Prueba manual: equipar el muñeco de nieve GIF en Armario > Perfil > Avatar; volver a Inicio y comprobar movimiento; abrir Ranking y observarlo en la fila y el podio del usuario; tocar otro participante y regresar con Android Back; retirar avatar en armario y comprobar que la interfaz vuelve al avatar predeterminado.

La proyección de perfil público puede tardar un momento en sincronizarse con Firestore. Si la vista pública no coincide, comprobar los permisos de `public_profiles` y la sincronización del perfil.

**No se ejecutó Flutter en el entorno de edición.** Los cambios están comprometidos en `main`, pero requieren el análisis y la comprobación visual en Android.
