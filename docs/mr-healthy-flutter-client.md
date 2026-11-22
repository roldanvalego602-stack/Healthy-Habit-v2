# Cliente Flutter de Mr. Healthy

Esta fase conecta la aplicación con la callable de Firebase mediante
`MrHealthyIntentService` en `lib/servicios/mr_healthy_intent_service.dart`.

## Situación actual

- El servicio Dart y sus pruebas están añadidos.
- No se ha sustituido el chatbot actual ni se han realizado cambios visuales.
- No se ha desplegado `interpretMrHealthyIntent` en Firebase.
- El endpoint requiere un usuario autenticado mediante Firebase Auth.
- La región de cliente y servidor es `us-central1`.
- Solo devuelve una intención: no registra hábitos ni modifica monedas.

## Ejemplo de uso (tras desplegar de forma segura)

```dart
final service = MrHealthyIntentService();
final result = await service.interpret('¿Cómo va mi progreso?');
if (result.intent == MrHealthyIntent.showProgress) {
  // La pantalla decide si muestra estadísticas o navega.
}
```

## Pruebas

Desde la raíz del repositorio:

```bash
flutter pub get
flutter test test/mr_healthy_intent_service_test.dart
flutter analyze
```

Las pruebas utilizan un transporte simulado, **no** contactan con Firebase.
Por lo tanto, comprueban el contrato y la gestión de errores, pero no validan
la comunicación real con el servidor.

## Para probar la comunicación real después

1. Revisar las reglas de Firestore y la autenticación.
2. Revisar costes, límites y App Check antes del despliegue.
3. Ejecutar la Function en Firebase Emulator Suite o desplegarla en un
   entorno de pruebas con una cuenta autorizada.
4. Verificar que el SDK responde a errores `unauthenticated` y `unavailable`.
5. Integrar el servicio con el chat y añadir un fallback local.

**No desplegar, fusionar ni ejecutar acciones sobre hábitos automáticamente.**
