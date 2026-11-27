# Healthy Habit — Plan de evolución (27 noviembre 2026)

## Fase 1 · Guía UFO — implementada, pendiente de validar en Android
- Estado inicial: mini radar de 44 dp, animado y arrastrable.
- Primer toque: despliega el OVNI de 84 dp; segundo toque: abre la guía. Pulsación larga en modo desplegado: contrae.
- Durante cualquier tutorial abierto por ese lanzador, ocultar el OVNI lanzador; el personaje de la guía es el único visible.
- Limitar las ampliaciones a objetivos reales pequeños; no ampliar contenedores que superen 420 × 220 dp.
- Prioridad visual: control enfocado → personaje → tarjeta explicativa → fondo atenuado. Superponer personaje sobre capturas ampliadas.
- Validar: tiendas, perfiles, catálogo, hábitos, teléfonos pequeños, accesibilidad/reducir animaciones, orientación y teclado.

## Fase 2 · Chatbot híbrido — decisión de producto, no implementada aquí
- Prioridad estricta: seguridad/urgencias → acciones confirmables y datos internos con permisos → base editorial local y contexto → búsqueda web explícita.
- La búsqueda web debe usar servicio backend propio, no scraping ni claves privadas en Flutter. Dominios permitidos, cuotas, timeout, caché, trazabilidad, respuestas con URL/título/fecha y aviso de información externa.
- Sin respuesta externa fiable: reconocer falta de información; no inventar fuentes ni usar web para diagnósticos.
- Clarificaciones y sugerencias de opciones pertinentes en lugar de respuestas genéricas repetidas.
- No escribir datos ni disparar compras desde resultados externos.

## Fase 3 · Easter egg y cosméticos — decisión de diseño, no implementada aquí
- Sala secreta: cueva oscura, rejas metálicas, señales de criatura encerrada, acertijo justo con pistas.
- Premio único no comercializable: skin musculosa legendaria de Mr. Healthy (nombre de trabajo «Titan»).
- Desbloqueo verificable en backend, una sola vez por cuenta, sin conceder monedas por responder localmente.
- Mostrar estado bloqueado / disponible / obtenido; animación de liberación accesible.
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
