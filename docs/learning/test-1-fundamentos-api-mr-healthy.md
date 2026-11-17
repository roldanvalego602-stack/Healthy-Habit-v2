# Test 1 — Fundamentos de APIs y Mr. Healthy

**Estado:** Pendiente de responder.  
**Proyecto:** Healthy Habit — Mr. Healthy  
**Origen:** Lección 01, primera API y Firebase Emulator Suite.  
**Indicaciones:** Responder sin consultar la explicación. No se ha realizado ni calificado.

## Cuestionario

### 1. ¿Cuál es la función principal de una API en nuestro proyecto?

A. Mostrar animaciones en Flutter.  
B. Permitir la comunicación entre componentes mediante un contrato definido.  
C. Almacenar automáticamente las contraseñas.

### 2. ¿Para qué utilizamos Authentication Emulator?

A. Para crear identidades de prueba sin usar usuarios reales.  
B. Para entrenar nuestro clasificador.  
C. Para convertir Dart en JavaScript.

### 3. ¿Qué sucede cuando `classifyIntent` recibe una frase reconocida?

A. Actualiza inmediatamente Firestore.  
B. Entrena un modelo nuevo.  
C. Devuelve una intención estructurada.

### 4. ¿Por qué las seis pruebas de Dart no demostraron conectividad real?

A. Porque utilizaron respuestas simuladas.  
B. Porque Dart no admite HTTP.  
C. Porque Firebase exige utilizar Python.

### 5. ¿Qué significa `UNAUTHENTICATED` en nuestra primera prueba?

A. El clasificador no entendió la frase.  
B. El servidor rechazó la solicitud sin una identidad autenticada.  
C. El servidor no estaba ejecutándose.

## Ejercicio práctico

Diseña una nueva intención `OPEN_STORE` para el archivo `functions/intent_classifier.js`. Debe reconocer, como mínimo:

- «Quiero abrir la tienda».
- «Muéstrame las recompensas».
- «¿Dónde puedo gastar mis Habit Coins?».

Explica qué regla o reglas agregarías, cómo las probarías y qué JSON debería responder el servidor. **No modificar el repositorio solo para contestar el examen.**

---

## Clave de respuestas — No consultar antes de responder

1. **B.** Una API permite la comunicación entre componentes con un contrato definido.
2. **A.** Authentication Emulator permite probar identidades sin emplear usuarios reales.
3. **C.** El clasificador devuelve datos estructurados y no modifica hábitos.
4. **A.** Las pruebas de Dart usaron un transporte simulado.
5. **B.** La función rechazó una solicitud sin autenticación válida.

**Para retomarlo:** pedir «Quiero responder el Test 1 de Mr. Healthy». Presentar primero las preguntas y el ejercicio, sin mostrar esta clave; corregir cuando el usuario termine.
