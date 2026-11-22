# Correcciones verificables — Mr. Healthy, foto, Mi camino y páginas informativas

Fecha: 18 de noviembre de 2026.
Rama: `feature/mr-healthy-foundations`.

## Conversación
- `healthy_conversation_service.dart`: nuevo motor **local y programado** de
  conversación cotidiana, humor, historias, acertijos, emociones, identidad
  y glosario de ciencia y tecnología.
- `nutrichat.dart`: consulta este motor antes de la respuesta FAQ genérica
  cuando el motor de acciones no reconoce una instrucción.
- `nutri_respuestas_service.dart`: se mejoró la respuesta a temas no reconocidos.
- Prioridades mantenidas: seguridad, cálculos, clima, consulta Firestore,
  hábitos, canjes y tarjetas interactivas.
- No se ha integrado un modelo generativo externo. Para responder preguntas
  completamente abiertas se necesitará un backend con un proveedor LLM,
  consentimiento informado para compartir mensajes, controles de coste,
  seguridad, transparencia y límites de uso.
- Pruebas: `test/healthy_conversation_service_test.dart`.

## Mi camino
- `camino_niveles_screen.dart`: sustituye el Row rígido que causaba
  `RenderFlex overflowed by 31 pixels` por
  `HealthyLevelRewardLine`, que permite distribuir etiqueta y monedas.
- Prueba con pantalla estrecha y escala de texto: `test/healthy_ui_regressions_test.dart`.

## Tema
- `informacion_app_screen.dart`: las cuatro secciones (`acerca`,
  `terminos`, `privacidad`, `ayuda`) utilizan `HealthyAdaptive`
  para fondo, iconos y texto.
- Pruebas: `test/healthy_ui_regressions_test.dart`.

## Fotos de perfil
- `profile_photo_service.dart`: si falla la subida, informa el paso
  (`Firestore` lectura, `Storage` escritura, obtención de URL,
  `Firestore` escritura) y el código de Firebase cuando está disponible.
- `editar_perfil_screen.dart`: informa errores de cámara y galería por separado
  y muestra los mensajes por 7 segundos.
- El almacenamiento en la nube **no puede garantizarse únicamente con cambios
  de Flutter**. Deben existir bucket, reglas adecuadas, sesión autenticada
  y plan Blaze de Firebase. Desde 2026, Cloud Storage no funciona en Spark.
  No se han cambiado ni desplegado reglas Storage.
- Ver `docs/FOTO_PERFIL_FIREBASE.md` para identificar el bucket de este
  proyecto, comprobar su plan y revisar las reglas sin afectar evidencias.
- Pruebas: `test/profile_photo_service_test.dart`.

## Cómo probar (desde la carpeta raíz)

```bash
git fetch origin feature/mr-healthy-foundations
git merge --ff-only FETCH_HEAD
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/healthy_conversation_service_test.dart
flutter test test/healthy_ui_regressions_test.dart
flutter test test/profile_photo_service_test.dart
flutter run
```

Validación manual:
1. Mr. Healthy: preguntar «¿Soy una princesa?», «Háblame sobre ti»,
   «¿Qué es un algoritmo?», «Cuéntame un cuento» y «Otra historia».
2. Mi camino: abrir con texto del sistema ampliado y revisar recompensa.
3. Configuración → Información: abrir Términos, Privacidad, Ayuda y Acerca de
   en claro/oscuro.
4. Editar perfil: intentar subir foto y copiar **el código exacto del error**.
   Si es bucket o permiso, verificar Storage en Firebase Console antes de
   cambiar código o adquirir facturación.

Validación: código guardado en GitHub; `flutter analyze`, pruebas y app
no ejecutadas desde este entorno.
