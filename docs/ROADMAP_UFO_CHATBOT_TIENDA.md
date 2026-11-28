# Healthy Habit — Plan de evolución (27 noviembre 2026)

## Fase 1 · Guía UFO — implementada, pendiente de validar en Android
- Estado inicial: mini radar de 44 dp, animado y arrastrable.
- Primer toque: despliega el OVNI de 84 dp; segundo toque: abre la guía. Pulsación larga en modo desplegado: contrae.
- Durante cualquier tutorial abierto por ese lanzador, ocultar el OVNI lanzador; el personaje de la guía es el único visible.
- Limitar las ampliaciones a objetivos reales pequeños; no ampliar contenedores que superen 420 × 220 dp.
- Prioridad visual: control enfocado → personaje → tarjeta explicativa → fondo atenuado. Superponer personaje sobre capturas ampliadas.
- Validar: tiendas, perfiles, catálogo, hábitos, teléfonos pequeños, accesibilidad/reducir animaciones, orientación y teclado.

## Fase 2 · Chatbot híbrido — primera integración de búsqueda, pendiente de desplegar y validar
- Prioridad estricta: seguridad/urgencias → acciones confirmables y datos internos con permisos → base editorial local y contexto → búsqueda web explícita.
- Implementado piloto: consulta explícita a Wikipedia en español mediante Firebase Callable `searchMrHealthyEncyclopedia`; límites de entrada, timeout, 3 resultados, autenticación, máximo 25 consultas/día por cuenta en transacción, URL fuente controlada y resultados marcados como externos. No es búsqueda global ni razonamiento generativo.\n- Pendiente para búsqueda general: proveedor autorizado mediante backend, cuotas y caché más completos, fuentes fechadas, criterios de confianza y política de privacidad antes del despliegue público.
- Sin respuesta externa fiable: reconocer falta de información; no inventar fuentes ni usar web para diagnósticos.
- Clarificaciones y sugerencias de opciones pertinentes en lugar de respuestas genéricas repetidas.
- No escribir datos ni disparar compras desde resultados externos.

## Fase 3 · Easter egg y cosméticos — Titán implementado, skins UFO pendientes
- **Implementado en código:** cueva oscura, rejas metálicas animadas, criatura oculta, tres pistas, entrada de siete toques y ruta Inicio → Tienda → Santuario.
- **Implementado en código:** skin musculosa legendaria «Mr. Healthy · Titán» (ID `skin_titan_secret`), ilustración vectorial y equipamiento en Armario.
- **Implementado pero no desplegado:** validación por Firebase Callable y transacción de premio único sin monedas, con cinco intentos por día civil mexicano; liberación de producción bloqueada por bandera de servidor y App Check.
- **Implementado / probar en Android:** estado bloqueado/disponible/obtenido, animación de liberación, efectos sonoros y accesibilidad básica. [Dossier del santuario](EASTER_EGG_SANTUARIO_TITAN.md).
- Familias de aspectos del OVNI: clásico, cosmos, neón, oro, sombrío, vegetal, glitch, lava, primitivo tipo caricatura prehistórica, zanahoria cómica.
- Separar cosméticos del OVNI de cosméticos del avatar; usar identificadores estables y equipamiento persistido.

## Fase 4 · Economía de tienda — reglas propuestas, requieren medición
- Mezcla objetivo de slots: 45% fijo, 35% rotación, 20% especiales/oferta. Ajustar por enteros manteniendo totalidad visible.
- El catálogo total permanece consultable en una sección informativa aunque los artículos rotativos no estén disponibles para comprar.
- Rotación diaria consistente para todos los usuarios según zona horaria de la tienda; generar oferta en servidor y guardar precio aplicado al momento de transacción.
- Los artículos comprados siguen disponibles en inventario aunque desaparezcan de rotación.
- Descuentos honestos: precio de referencia estable, no manipular precio anterior; no presión artificial ni relojes falsos.
- Rarezas orientativas: común (degradados básicos, gorra), poco común, raro (OVNI elaborados), épico, legendario/secretos.
- Recalibrar precios con costo percibido y tasa real de obtención de Habit Coins antes de editar el catálogo.
- Transacciones atómicas de saldo y propiedad; no fiarse de precios calculados por cliente.

## Cómo desplegar el piloto (requiere permisos Firebase)
1. Actualizar rama main y ejecutar `flutter analyze --no-fatal-infos lib`.
2. Ejecutar `flutter test test/healthy_web_search_service_test.dart`.
3. Ejecutar `cd functions && npm ci && npm test && cd ..` (el proyecto usa Node.js 24 en Cloud Functions).
4. Verificar el proyecto Firebase seleccionado con `firebase use`. Revisar costes, IAM y si Firebase App Check está listo para exigirlo.
5. Desplegar solo la función nueva: `firebase deploy --only functions:searchMrHealthyEncyclopedia`.
6. En Android autenticado, escribir `Busca en Wikipedia Marte`. Debe mostrar hasta tres resultados y enlaces, nunca ejecutar acciones.
7. Probar sin conexión, cuenta no autenticada, frase ambigua y límite diario.
8. Si falta la función, el cliente devuelve un mensaje explicativo y mantiene la conversación local.

**Aviso:** la búsqueda solo funciona en el dispositivo tras publicar el backend; un git pull o flutter run no despliegan funciones. La versión piloto no hace diagnóstico ni ofrece datos actuales generales y no está lista para presentarse como IA generativa.
