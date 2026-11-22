# Mr. Healthy: conversación, voz y movimiento

## Integración

Esta mejora parte de `feature/mr-healthy-foundations`, no sobrescribe la rama principal. Conserva el motor de acciones de la app, el historial, las calculadoras de IMC/GET y el selector de temas.

### Conversación

- `lib/páginas/chatbot/healthy_knowledge_base.dart`: 30+ entradas educativas sobre alimentación, ingredientes, actividad física, fuerza, movilidad, descanso y hábitos económicos. Las coincidencias se normalizan y priorizan frases completas.
- `nutri_respuestas_service.dart`: cinco estilos (amigable, divertido, serio, motivador y tranquilo). Se pueden seleccionar en el menú del chat o mediante el texto «modo serio», «modo divertido», etc.
- Moderación: reconoce insultos comunes y ataques explícitos racistas u homofóbicos, sin bloquear preguntas neutrales. Los mensajes sobre autolesión reciben una respuesta de seguridad prioritaria.
- Respuestas sobre cantidades exactas de calorías, recomendaciones clínicas y datos que no se tienen: el asistente evita inventar cifras.
- La base es local; **no** es un modelo generativo ni ofrece infinitas respuestas. Para preguntas abiertas fuera del catálogo, el motor actual conserva su mecanismo de aclaración.

### Voz

- Pulsar el micrófono en la caja de texto: solicitar permiso, dictar hasta 25 segundos, revisar el texto reconocido y enviar con el botón existente.
- Menú de personalidad > «Activar voz»: leer las respuestas en voz alta mediante el sintetizador disponible en el dispositivo.
- El micrófono no permanece activo fuera de una escucha iniciada por el usuario. El dictado usa servicios de reconocimiento disponibles en el sistema, sujetos a sus propias condiciones de privacidad y conectividad. El chat no promete reconocimiento offline.
- La voz es opcional: el chat de texto continúa funcionando si el dispositivo no ofrece reconocimiento.
- Android e iOS tienen configuraciones de permisos. La disponibilidad exacta depende de plataforma, idioma, permisos y motor de voz instalado. En Linux, `speech_to_text` no ofrece reconocimiento soportado.

### Animación

- `HealthyPageSwitch`: entrada/salida breve entre pestañas de Inicio, Hábitos, Tienda, Catálogo y Perfil, y entre las pestañas del `HomeScreen` principal.
- `HealthyRouteTransitions`: transiciones rápidas al abrir otras pantallas mediante rutas Material.
- Las tarjetas y mensajes ya animados en la rama base se conservan.
- Se deshabilitan las transiciones nuevas al elegir modo Lite o cuando el sistema solicita reducir animaciones. No se añaden bucles decorativos perpetuos.

## Verificación necesaria en entorno Flutter

```bash
flutter pub get
dart format lib/páginas/chatbot/healthy_knowledge_base.dart lib/páginas/chatbot/nutri_respuestas_service.dart lib/páginas/chatbot/nutrichat.dart lib/tema/healthy_motion.dart lib/tema/healthy_theme.dart lib/main.dart lib/páginas/inicio.dart test/healthy_chat_knowledge_test.dart
flutter analyze --no-fatal-infos lib test
flutter test test/healthy_chat_knowledge_test.dart
flutter test
flutter run
```

Probar Android físico: negar y aceptar permiso de micrófono, dictado breve, texto final editable, varias preguntas consecutivas, lectura activada/desactivada, cancelación de escucha, salida del chat, recuperación de historial, y temas claro/oscuro con visual normal/Lite. Confirmar además que el menú de personalidad no desborda con fuente grande.

**Estado:** cambios de código integrados en la rama de trabajo, **no validados en ejecución** desde este entorno. No fusionar con `main` hasta verificar análisis, pruebas y experiencia en dispositivo.

## Criterios para próximas ampliaciones

Para respuesta abierta genuinamente generativa se requerirá un proveedor de IA con backend seguro, control de costes, consentimiento de privacidad, minimización de datos personales y políticas específicas de salud. Nunca colocar claves privadas en Flutter. Para datos numéricos por alimentos usar un catálogo de composición con procedencia, unidades, porción, preparación y vigencia identificables.
