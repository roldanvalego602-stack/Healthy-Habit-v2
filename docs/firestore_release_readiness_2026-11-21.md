# Auditoría final previa a publicar reglas — Healthy Habit
Fecha: 21 de noviembre de 2026
Rama: `feature/habits-discovery-routines`

## Alcance realmente confirmado

- La suite de **17 pruebas sociales** ejecutada por el desarrollador
  pasó completamente antes de los últimos cambios.
- En `firestore.candidate.rules` se introdujeron protecciones
  adicionales: nuevos seguimientos deshabilitados, reacción desactivable,
  solicitudes entre amigos bloqueadas, evidencia temporal limitada
  por destinatario, tamaño y expiración, y perfil público consistente
  con el XP almacenado.
- Se incorporaron **pruebas adicionales** de registro, preferencias,
  compra, perfil, evidencia, sistema y seguimientos. **Aún deben
  ejecutarse después de actualizar la rama.**
- Ninguna regla se desplegó.

## Hallazgos bloqueantes para producción

### 1. Economía modificable desde Flutter

La función `validOwnerUpdate(uid)` del archivo de reglas acepta
cambios de `xp`, `currentXp`, `level`, `habitCoins`, racha
y recompensas mientras no activen las vías especiales de compra
o cancelación. Ejemplo: un cliente autenticado con `users/alice`
puede intentar establecer `xp: 100000` y
`habitCoins: 999999`.

La prueba `tools/firestore-tests/security_release_gate.test.mjs`
**exige que esto se rechace**. Se espera un fallo hasta migrar
recompensas y nivel a una transacción de servidor.

### 2. Hábitos y medallas autoacreditables

`users/{uid}/user_habits/{path=**}` y
`users/{uid}/achievements/{path=**}` conservan escritura para el
propietario, por compatibilidad con la app. Eso permite fabricar
progreso, registros y logros. El hecho de que los cambios queden
asociados al propio UID **no los convierte en verificados**.

La puerta de publicación exige que estos documentos no puedan
atribuirse progreso verificable desde un cliente alterado.

### 3. Cloud Functions de prueba no sustituyen el flujo real

`functions/habit_registration_transaction.js` y
`functions/habit_activation_transaction.js` contienen una base
transaccional, pero sus endpoints en `functions/index.js`
se limitan explícitamente al emulador del proyecto demo. Además
el piloto solo admite tres hábitos y registro sin evidencia.

Para producción se requiere:
- Activar **los 36 hábitos oficiales** en servidor con sus catálogos,
  niveles, requisitos, cupos, ventanas horarias y penalizaciones.
- Trasladar la activación y el registro de sesiones a funciones de
  servidor y eliminar escrituras directas de XP, progreso y monedas.
- Calcular y conceder recompensas una sola vez por operación,
  con clave idempotente y control de concurrencia.
- Diferenciar registro declarado de evidencia auténticamente
  verificada; la fotografía subida no demuestra por sí sola un hábito.
- Dar acceso sólo lectura al cliente para los agregados y medallas
  realmente acreditados por servidor.
- Crear políticas explícitas para borrar datos propios e historial,
  conservando integridad de operaciones económicas.

## Pruebas disponibles

Desde la raíz del repositorio, con auth/firestore emulados:

```bash
node --test tools/firestore-tests/rules.test.mjs
npm --prefix tools/firestore-tests run test:release
```

`test:release` ejecuta también el archivo de bloqueos
`security_release_gate.test.mjs` y **debe terminar con errores**
mientras se sigan pudiendo fabricar XP, hábitos y medallas.

Este resultado es deliberado: evita interpretar el éxito de la suite
de privacidad como un certificado de seguridad de economía.

## Antes de desplegar

1. Pasar la suite funcional completa para todas las rutas efectivamente
   usadas por Flutter.
2. Resolver los tres bloqueos económicos anteriores.
3. Confirmar que el cambio no rompe registro, tienda, desafíos,
   rachas, catálogo, perfiles, navegación y eliminación de cuenta.
4. Verificar las reglas en Emulator con usuarios de prueba y
   transacciones; revisar que no se superen los límites de
   `get()`/`getAfter()` en operaciones atómicas.
5. Revisar las vulnerabilidades de npm (`npm audit`),
   sin `npm audit fix --force` indiscriminado.
6. Guardar copia del conjunto de reglas activo antes de desplegar.
7. Publicar a través de un proceso controlado, validar casos
   positivos/negativos y preparar reversión.

## Conclusión

El borrador es sustancialmente mejor que el conjunto original,
que autorizaba lectura y escritura a cualquier usuario autenticado
sobre cualquier documento. No obstante, **todavía NO está
certificado para reemplazar las reglas productivas**. Un resultado
verde en las pruebas sociales no resuelve la economía autoacreditable.
