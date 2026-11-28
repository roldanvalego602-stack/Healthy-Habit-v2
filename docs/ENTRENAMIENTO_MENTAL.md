# Healthy Habit — Entrena tu mente

**Estado de implementación:** Sudoku y sopa de letras interactivos desde Hábitos → Entrena tu mente. Pruebas de algoritmo y widgets añadidas, verificación Android manual pendiente.

## Experiencia

La sección Hábitos contiene una tarjeta visible **Entrena tu mente** que abre un centro de dos ejercicios complementarios. Muestra dos retos diarios, porcentaje de progreso y racha local por días consecutivos de actividad. El contenido es recreativo y no sustituye evaluación o atención clínica.

### Sudoku
- Cuadrícula 9×9 con números fijos, entrada numérica y borrado.
- Se verifican fila, columna y subcuadro antes de guardar cada cifra; no se inscriben cifras incorrectas.
- Hasta tres pistas por tablero.
- Se conserva la partida al cerrar o volver a abrir, en `SharedPreferences`.
- Generación diaria determinista mediante una transformación de un tablero clásico con solución única; se reorganizan las bandas de filas, pilas de columnas y símbolos, conservando la solución válida.
- Finalización solo cuando las 81 celdas reproducen la solución de la partida.

### Sopa de letras
- Cuadrícula de 12×12 generada por día con 7 palabras sobre reflexión, lectura, memoria y atención.
- Las palabras se colocan de manera verificable en ocho direcciones; se rechazan líneas no rectas o palabras ajenas.
- Seleccionar primera y última letra, en el orden normal o invertido. Palabras encontradas resaltadas.
- Hasta tres pistas, cada una ilumina la primera letra de una palabra faltante.
- Registro local de palabras descubiertas y finalización al encontrar las siete.

## Privacidad y seguridad

- Los juegos funcionan sin cámara, sin imágenes, sin geolocalización ni subida de resultados.
- No hay modificación de `users/{uid}`, `habitCoins`, `xp` o logs de hábitos oficiales desde el cliente.
- El progreso se guarda en el teléfono y está separado por UID de Firebase o invitado.
- La racha refleja actividad local, NO una racha certificada en el servidor ni un logro académico o médico.
- Cambiar la fecha del dispositivo puede alterar el día visible: no se considera prueba autoritativa de cumplimiento.

## Pruebas

```bash
git fetch origin main && git merge --ff-only origin/main
flutter analyze --no-fatal-infos lib
flutter test test/mental_daily_puzzles_test.dart
flutter test test/mental_training_widget_test.dart
flutter run
```

Pruebas propuestas: varias fechas, tableros válidos y estables, conjunto de palabras encontrables, persistencia, navegación, selección de celdas, prohibición de números erróneos, solicitud de pistas, accesibilidad y pantallas pequeñas.

## Integración futura al catálogo oficial

Si se desea premiar esos ejercicios con XP o Habit Coins, se necesitará una API propia con desafío diario y recibos transaccionales server-side, cuotas y autenticación; **incluso entonces, conocer la solución de un Sudoku no demuestra quién lo resolvió**. Por ese motivo los dos ejercicios de esta etapa no están registrados en el catálogo económico oficial de los 36 hábitos. Se ofrecen como hábitos de práctica local, con progreso y rachas independientes.

Futuros ejercicios sugeridos: memoria visual por parejas, cálculo mental, asociaciones de palabras y series lógicas. Estos son diseños posteriores, no funcionalidades implementadas.
