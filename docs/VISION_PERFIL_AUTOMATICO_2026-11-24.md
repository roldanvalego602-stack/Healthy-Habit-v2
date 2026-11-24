# Healthy Habit — perfil visual sugerido por hábito (fase 3)

## Qué cambia

Al adjuntar una fotografía en **Registrar hábito**, el panel experimental usa
el título y la categoría del hábito real para sugerir un perfil visual:

- «Tomar 6 vasos de agua» → Hidratación.
- «Comer fruta» / «Incluir verduras» → Frutas y verduras.
- «Preparar desayuno» / «Almuerzo equilibrado» → Comida.
- «Caminar» / «Dormir» / «Leer» / categoría desconocida → Sin perfil automático.

Las coincidencias específicas en el título prevalecen sobre la categoría
general. La selección se muestra y puede cambiarse manualmente para
experimentación. Cuando no hay perfil, no se envía ninguna fotografía a
Vision hasta que el usuario elija explícitamente uno.

Al sustituir la fotografía o cambiar el hábito, se descarta el resultado
anterior, con el fin de evitar mostrar un diagnóstico de una foto diferente.

## Alcance y seguridad

- Esta mejora es exclusivamente del cliente Flutter.
- **No** despliega ni modifica Cloud Functions reales.
- Se conserva el control de UID y cuotas del backend ya desplegado.
- No se modifica XP, Habit Coins, rachas o registro de hábitos.
- El perfil automático sirve para decidir **qué buscar**, NO verifica
  que se haya cumplido el hábito.
- En debug se requiere `HH_VISION_DEBUG=true`. Para el backend real,
  también `HH_VISION_LIVE_BACKEND=true`.

## Comprobación local

```bash
cd ~/Documentos/Integradora/Healthy-Habit
git fetch origin main
git merge --ff-only origin/main
flutter test test/habit_vision_profile_test.dart
flutter test test/healthy_vision_debug_test.dart
flutter analyze --no-fatal-infos \
  lib/servicios/habit_vision_profile.dart \
  lib/páginas/habitos/healthy_vision_preview_panel.dart \
  lib/páginas/habitos/registrar_habito_screen.dart
```

Luego, en teléfono Android con sesión Firebase real:

```bash
flutter run -t lib/main.dart \
  --dart-define=HH_VISION_DEBUG=true \
  --dart-define=HH_VISION_LIVE_BACKEND=true
```

No se necesita Firebase Emulator ni desplegar de nuevo el backend.
La fotografía solo se envía cuando se pulsa Analizar.
El análisis real consume cuotas de Google Cloud Vision; respeta
el límite de 1 solicitud por minuto y 15 por día del piloto.
Evita fotos de personas y documentos privados.
