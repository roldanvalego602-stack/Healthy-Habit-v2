# Registros de contador e hidratación — piloto aislado

Fecha: 25 de noviembre de 2026.

## Alcance

El endpoint `registerOfficialHabitDemo` acepta un objeto opcional
`interaction` solo cuando `type` es `counter` o `hydration`.
El objeto contiene exclusivamente `type`, `value`, `target` y `unit`.

- `value` y `target`: enteros; objetivo entre 1 y 10 000; valor mayor
  o igual al objetivo y no superior a 10 000.
- `unit`: texto corto de 1 a 40 caracteres. Para `hydration`,
  necesariamente `ml`.
- El backend guarda `verified: false` en el registro. El cliente **no**
  puede enviar `verified` ni campos de economía.
- Son **actividades autodeclaradas**, no verificadas por sensores ni
  evidencia. Un usuario con un cliente modificado puede inventar el valor.
  Por esa razón no se otorga XP adicional según `value`: las recompensas,
  límites por periodo y rachas siguen calculándose con el catálogo oficial
  y estado persistido. No se presentan estos datos como mediciones fiables.
- El identificador de operación conserva el objeto para impedir usar
  el mismo `operationId` con valores distintos.
- El diario local conserva el objeto original para el proceso de
  recuperación del resultado. No se introduce carga fotográfica ni
  sincronización en segundo plano.

## Limitaciones

La pantalla puede recibir `interaction` desde configuración persistida
del hábito. Por ahora se valida que los tipos y rangos son aceptables;
**el servidor todavía no cuenta con una definición de herramienta y
objetivo fija para cada hábito**. No confiar en esos valores para
validación física ni aumentar recompensas.

No se incluyen sensores de pasos, temporizadores, cronómetros,
respiración o pomodoro. El diseño de esas herramientas requiere
un contrato de duración o evidencia más robusto.

## Verificación local

Desde la raíz de Healthy Habit:

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze \
  lib/servicios/operaciones_habitos_pendientes.dart \
  lib/servicios/official_habit_emulator_service.dart \
  lib/páginas/habitos/registrar_habito_screen.dart
npm --prefix functions test
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
```

La prueba integral incluye ahora un cuarto caso con hidratación
autodeclarada y validaciones de idempotencia, formato y rechazo de
campos manipulados. **No se ha ejecutado todavía en el equipo del
usuario.** Debe mostrar cuatro pruebas aprobadas y cero fallidas.

No ejecutar `firebase deploy`, no usar el entorno real.
