# Healthy Habit — puerta de publicación de Firestore Rules

**Estado: BLOQUEADO PARA PUBLICACIÓN.**

El conjunto original de 17 pruebas pasó en el equipo del usuario.
La suite ampliada en `tools/firestore-tests/rules.test.mjs` contiene
comprobaciones adicionales de autenticación simulada, datos privados,
cuentas, economía, tienda, perfiles públicos, hábitos, desafíos,
notificaciones sociales, inventario y configuración del sistema.
**La suite ampliada aún no ha sido ejecutada por el usuario.**

## Resultados conocidos

- Solicitudes, aceptación recíproca, eliminación de amigos,
  reacciones entre amigos e invitaciones: 17/17 pruebas iniciales aprobadas.
- El código candidato ya deshabilita crear nuevos `following/followers`.
- El perfil público se limita a reflejar el XP del documento
  `users/{uid}`, pero **eso no garantiza que el XP privado sea auténtico**.
- La evidencia temporal tiene campos requeridos, límite de tamaño,
  titular y expiración; aún falta validar su ciclo de vida completo.
- Las escrituras sobre `users/{uid}/user_habits/**` y
  `users/{uid}/achievements/**` siguen autorizadas al propietario.
  **No pueden considerarse prueba verificable del progreso.**

## Hallazgos de seguridad pendientes — no son detalles cosméticos

### 1. XP y monedas autoadjudicables

`validOwnerUpdate()` permite cambios arbitrarios sobre XP y saldo
cuando no se modifica inventario ni se realiza un descuento con
marcador de cancelación. Los tests adversariales deben detectar esto:

- `gamificación: no se puede regalar XP sin registro válido`
- `economía: no se pueden crear monedas desde el cliente`
- `economía: no se pueden falsificar recompensas de niveles`
- `integridad: no se pueden publicar estadísticas manipuladas`

**No resolver con un límite arbitrario por actualización:** un atacante
puede repetir incrementos pequeños. Hacen falta transiciones
verificables y un mecanismo confiable de adjudicación de recompensas.

### 2. Progreso de hábitos y logros autodeclarado

El cliente actualmente escribe:
- `users/{uid}/user_habits/{habitId}`
- `.../attempts/{attemptId}`
- `.../logs/{logId}`
- `users/{uid}/achievements/{achievementId}`

Las pruebas de manipulación de estados, intentos, registros y logros
requieren que estas escrituras fraudulentas sean rechazadas. El
control actual por propietario no es suficiente. Transferir la
adjudicación al servidor (por ejemplo, Callable Function
autenticada con validación de catálogo, estado y duplicados) y
endurecer las reglas antes de activar recompensas fiables.

### 3. Funciones existentes y compatibilidad

El repositorio incluye Cloud Functions administrativas para
monedas y herramientas de prueba, pero no debe asumirse que
`previewOfficialHabitRegistration` concede XP:
es un previsualizador, no una operación de adjudicación segura.
Verificar igualmente el código Dart de registro, perfil y tienda.

## Matriz de aprobación necesaria

1. **Reglas:** todos los tests de `rules.test.mjs` pasan,
   incluidos los de abuso, sin borrarlos ni convertir
   `assertFails` en `assertSucceeds`.
2. **Compatibilidad:** probar con emuladores el alta y edición de
   cuentas, lista de hábitos, registro, cancelación y repetición,
   compra/equipado de artículos, desafíos, evidencias, ranking,
   amigos, invitaciones y notificaciones.
3. **Integridad:** XP, nivel, racha, Habit Coins, recompensas de nivel,
   logros e inventario no pueden elevarse arbitrariamente desde
   el SDK cliente.
4. **Permisos:** no hay reglas recursivas de lectura o escritura
   abiertas a cualquier cuenta autenticada.
5. **Datos existentes:** los documentos de cuentas antiguas tienen
   campos compatibles; preparar migración o corrección antes de
   publicar si el nuevo esquema los rechaza.
6. **Emulator Auth vs Firestore:** pruebas de Rules Unit Testing
   simulan `request.auth`; no sustituyen las pruebas de registro
   y autenticación completas de la aplicación.
7. **Storage:** verificar sus reglas por separado si se habilita
   almacenamiento de fotografías; estas pruebas sólo cubren Firestore.
8. **Despliegue:** hacer copia de seguridad de reglas actuales,
   revisar el diff y usar `firebase deploy --only firestore:rules`
   sólo cuando todas las condiciones anteriores estén comprobadas.
   No desplegar funciones ni datos por accidente.

## Comandos

Desde la raíz del proyecto, con los emuladores iniciados y en otra
terminal:

```bash
git fetch origin feature/habits-discovery-routines
git merge --ff-only FETCH_HEAD

node --test tools/firestore-tests/rules.test.mjs
```

**Si hay un solo test de autorización fallido, no desplegar.**
Algunas denegaciones en el log son esperables porque los casos
adversariales usan `assertFails`; la clave es el resultado
final de la suite.

Esta documentación es un control de calidad, no una
certificación de seguridad completa.
