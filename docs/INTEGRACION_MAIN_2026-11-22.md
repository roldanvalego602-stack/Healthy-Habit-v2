# Integración de main — 22 de noviembre de 2026

## Estrategia

Esta rama parte de `repair/chatbot-integration-20261122` y combina su
historial con `main` mediante un commit de **dos padres**, sin modificar
`main`. La rama de reparación pasó 269 pruebas automatizadas y
`flutter analyze --no-fatal-infos lib test` sin errores ni warnings
(se observaron 10 lints informativos sobre importaciones en tests).
Estos resultados **son anteriores al merge** y deben repetirse.

## Resoluciones conscientes

- **Hábitos**: se conserva `HabitActionService` con previsualización,
  comprobación de versión y transacción para saldo/activación. Se integra
  el selector de ocho herramientas de `main` junto con su persistencia.
  `habits_screen.dart`, `habit_interaction_card.dart` y
  `registrar_habito_screen.dart` son las versiones reparadas y probadas.
- **Calculadora**: se adopta el flujo ampliado de `main` para IMC/GET,
  unidades, confirmación de datos, alternativas de sexo y opciones
  contextualizadas. Se compatibiliza con el protocolo de interrupción
  de la rama Mijo y se reinicia al cambiar de sesión.
- **Mr. Healthy**: se conserva el chat avanzado, reconocimiento de voz,
  conocimiento híbrido, controles y navegación. La implementación
  `chat_historial.dart` de `main` es un segundo almacenamiento
  exclusivamente en memoria, que no se copia para evitar una fuente de
  verdad duplicada frente a `HealthyChatHistory`, persistente.
- **Dependencias**: se conserva el `pubspec.yaml` de la rama reparada,
  que abarca las dependencias de ambas versiones. Se mantiene el
  `pubspec.lock` preexistente hasta resolverlo de forma reproducible.
- **Archivos generados, respaldos y archivo ZIP**: no se copian
  cambios accesorios de `main` que puedan sobreescribir el árbol
  funcional o los respaldos existentes. No se purga ningún archivo
  histórico en esta rama.
- **Análisis**: se incorpora la intención de excluir
  `copias de seguridad/**` presente en `main`, corrigiendo su
  indentación YAML, sin eliminar exclusiones de plataformas.
- **Logros y adaptaciones visuales**: se conserva la versión reparada
  que se probó con el conjunto completo.

## Validación requerida antes de publicar en main

1. `flutter pub get`
2. `flutter analyze --no-fatal-infos lib test`
3. `flutter test` (referencia previa: 269 pruebas aprobadas)
4. Validación manual en Android de registro, podómetro, voz, permisos,
   cálculo IMC/GET, saldo y reglas de Firestore, preferentemente en
   emulador o entorno de pruebas.
5. Auditar archivos no versionados/locales de la carpeta original y
   el lockfile; **no sobrescribir cambios locales ni fusionar sin revisión**.

Este merge documenta la resolución de diferencias de código; no
certifica un despliegue a producción ni un comportamiento remoto de Firebase.
