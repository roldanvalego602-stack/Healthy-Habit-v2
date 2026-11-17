# Mr. Healthy — API experimental

Esta implementacion es **basada en reglas, no entrenada con IA**. Permite probar
el contrato entre Flutter y el backend antes de incorporar un modelo propio.

## Firebase callable function

Nombre: `interpretMrHealthyIntent`. Region: `us-central1`. Requiere autenticar usuario.

Solicitud: `{"text":"Quiero ver mis estadisticas"}`
Respuesta: `{"intent":"SHOW_PROGRESS","method":"rules_v1","requiresConfirmation":false}`

Intenciones: `SHOW_PENDING_HABITS`, `SHOW_PROGRESS`, `SHOW_STREAK`,
`OPEN_CHALLENGES`, `REGISTER_HABIT`, `UNKNOWN`.

La funcion no lee ni escribe Firestore. `REGISTER_HABIT` no registra nada:
el usuario debe confirmar un habito concreto antes de escribir a la base.

## Pruebas

Desde `functions/`, ejecutar `npm test` (Node.js con soporte node:test).

## Pendiente

Validar reglas de Firestore, integrar cliente Flutter, medir falsos positivos,
configurar App Check y evaluar el clasificador entrenado. No desplegar sin revision.
