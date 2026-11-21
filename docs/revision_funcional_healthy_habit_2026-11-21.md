# Revisión funcional de Healthy Habit — 21 de noviembre de 2026

La fecha objetivo de demostración al jurado es **3 de diciembre de 2026**.
Los siguientes cambios se realizaron en la rama
`feature/habits-discovery-routines`, sin tocar la pestaña de
administración.

## Implementado en esta revisión (pendiente de validación local)

### Hábitos y rutinas

- Los hábitos recomendados explican la diferencia entre «sugeridos»
  y «ver todos», y tienen modos **Lista**, **Tarjetas** y **Deslizar**.
- El modo Deslizar usa ahora `PageView` real con flechas,
  indicador de posición y control independiente para sugeridos y
  populares. No depende de fotografías inexistentes.
- Se explica que **Crear rutina** permite varios ejercicios
  y **Crear meta** admite una única actividad. El editor muestra
  el número de ejercicios agregados y cómo añadir el siguiente.
  La persistencia de rutinas sigue siendo local en el dispositivo.
- El registro de un hábito ofrece **Todo junto** o **Por pasos**.
  El recorrido guiado incluye: (1) interacción/evidencia,
  (2) nota opcional y (3) confirmación y recompensa. Mantiene el
  mecanismo actual de guardado.

### Catálogo

- Seleccionar un grupo del plato oculta el selector mediante
  fundido y muestra los resultados, con una acción para volver.
- Se diferencian la barra **Filtrar por etiquetas** y la
  herramienta **Ordenar**, que no hacen la misma operación.
- Todas las fichas incorporan «Resumir o consultar un dato» con
  información existente de la ficha: explicación breve, beneficios,
  pasos, precauciones o datos. Se puede copiar la respuesta.
  No se utiliza generación externa ni se inventan cifras.
- Los consejos se pueden explorar mediante objetivos visuales
  (sueño/recuperación, seguridad, bienestar cotidiano).
- La cuarta pestaña **Bebidas** contiene siete fichas y una
  **Jarra del Buen Beber** interactiva por grupos descriptivos.
  No se representan niveles en litros, recomendaciones de volumen,
  ni límites personales. Las referencias usan CDC.
- Prueba de widgets nueva:
  `test/catalogo_nuevas_vistas_test.dart`.

### Notificaciones

- La antigua pantalla contenía mensajes estáticos ficticios
  de amistad, desafíos y recompensas; **no** era una bandeja
  conectada a eventos reales. Se sustituyó por un centro de
  configuración: estado real de la cuenta, horario, cantidad de
  notificaciones locales pendientes, prueba en Android,
  reprogramación y enlace a Ajustes.
- `HealthyRemindersService.pendingCount()` permite inspeccionar
  cuántos avisos propios están en la agenda Android.
- Las notificaciones locales dependen del permiso del usuario,
  la configuración activa, Android y restricciones de batería.
  Esta revisión **no implementa** una bandeja de eventos sociales
  ni push remotos.

### Perfil

- La subida de foto ya usaba `ProfilePhotoService` con
  Firebase Storage. Ahora el editor mantiene visible el
  detalle del error y puede ayudar a identificar permisos,
  bucket/rules y conexión. **No se afirma que los permisos
  remotos estén corregidos** sin probarlos en el dispositivo.

## Problemas abiertos de prioridad alta

1. **Verificación semántica de imágenes de hábitos.** El sistema
   registra evidencia adjunta, pero no analiza automáticamente
   si la fotografía demuestra la actividad. Los 15 XP actuales
   corresponden al registro respaldado, **no** a la verificación
   de contenido. Es necesario definir y probar un proceso
   confiable de verificación del lado del servidor antes
   de introducir un nuevo estado o premios.
2. **Bandeja de eventos reales.** Se necesitan eventos
   persistidos, fuentes verificadas y reglas de acceso antes de
   mostrar invitaciones, logros o interacciones entre usuarios.
3. **Subida de fotografía real en Android.** Recoger el error
   visible tras la subida para corregir la causa concreta
   (permisos Android, Storage, bucket o Firestore).
4. **Entrega efectiva de recordatorios.** Con permisos habilitados,
   confirmar que `Enviar aviso de prueba` aparece en el teléfono,
   que los recordatorios programados son mayores que cero y
   que Android los muestra en el horario esperado.

## Idea de siguiente módulo: diario gráfico de alimentación

La propuesta es un **registro de consumo** con interfaz que muestra
un recipiente/estómago ilustrado y se actualiza según la relación
entre lo registrado y un objetivo configurable. La ilustración NO
representaría el volumen gástrico real ni debería sugerir que
una persona debe comer hasta «llenar el estómago».

MVP sugerido:
- Añadir alimentos/bebidas por búsqueda, guardar cantidad, unidad,
  hora y origen del dato (etiqueta, base alimentaria o usuario).
- Conversión de cucharadas a gramos **solo cuando exista densidad
  o peso por cucharada del alimento específico**. Una cucharada
  puede equivaler a un volumen, pero no a un peso universal.
- Mostrar por separado calorías, proteína, grasas, carbohidratos,
  fibra, azúcares totales y **azúcares añadidos** cuando estén
  documentados; distinguir valores desconocidos de cero.
- Registrar comidas poco frecuentes sin emitir juicios de
  «bueno/malo». Ofrecer resumen de nutrientes registrados y
  referencia utilizada.
- Visualización animada configurable por nutriente u objetivo,
  con aviso de que es una **barra de progreso educativa**,
  no una medición corporal ni recomendación clínica.
- Mantener datos alimentarios separados de rachas/recompensas
  hasta definir reglas de privacidad, integridad y propósito.

No se implementó aún este módulo; antes debe definirse una fuente de
nutrientes verificada y las reglas para cantidades y objetivos.

## Pruebas que ejecutar antes de una demostración

```bash
git fetch origin feature/habits-discovery-routines
git merge --ff-only FETCH_HEAD

flutter analyze lib/páginas/catalogo
flutter analyze lib/páginas/habitos
flutter analyze lib/páginas/perfil/editar_perfil_screen.dart
flutter analyze lib/páginas/notifications_screen.dart
flutter analyze lib/servicios/healthy_reminders_service.dart

flutter test test/catalogo_explorador_test.dart
flutter test test/catalogo_media_test.dart
flutter test test/catalogo_detalle_interactivo_test.dart
flutter test test/catalogo_comparacion_test.dart
flutter test test/catalogo_nuevas_vistas_test.dart
```

Probar también en teléfono Android real: navegación, desbordamiento
horizontal, cambios de vista, flujo de rutina con varios ejercicios,
ambas modalidades de registro, fotografía, avisos y configuración
de la cuenta. No modificar datos de producción innecesariamente.
