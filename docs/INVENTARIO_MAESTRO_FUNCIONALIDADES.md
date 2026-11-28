# Healthy Habit — Inventario maestro de funcionalidades y estado

**Actualizado:** 27 de noviembre de 2026.  
**Proyecto:** Integradora · Healthy Habit.  
**Repositorio:** `roldanvalego602-stack/Healthy-Habit-v2` · rama `main`.  
**Entrega prevista del proyecto:** 7 de diciembre de 2026.  
**Alcance:** funcionalidades existentes, desarrollos parciales, pilotos, ideas aprobadas y obligaciones de seguridad. Este documento es **vivo** y debe actualizarse con cada fase.

> **Advertencia:** «Implementado» significa que existe código; no equivale a «validado en Android», «publicado» ni «apto para producción». La beta con reglas estrictas y cambios económicos permanece **pausada** según los informes de cierre de noviembre. No desplegar reglas candidatas ni activar banderas de laboratorio sin revisión.

## Estados y criterios de actualización

- **Implementado / validar:** hay código y, a veces, pruebas; falta validación integral en Android o contra el backend real.
- **Backend probado:** existen pruebas unitarias/de emulador o un despliegue concreto; no implica que todos los flujos cliente estén listos.
- **Piloto / demo:** interfaz o servicio experimental, con límites intencionales y sin atribuir recompensas reales.
- **Parcial:** funciona parte del flujo; faltan integraciones, reglas, datos o experiencias.
- **Diseñado / pendiente:** especificación o decisión aprobada, sin implementación del flujo final.
- **Bloqueado para producción:** requiere seguridad, permisos, verificación de recompensas, pagos o validación.

## A. Identidad, navegación y experiencia

| Funcionalidad | Estado | Evidencia / próximo paso |
|---|---|---|
| App móvil Flutter con Firebase Auth/Firestore | Implementado / validar | Inicio de sesión, perfil y rutas existentes; pruebas integrales pendientes |
| Pantalla Inicio con resúmenes de progreso | Implementado / validar | Revisar datos reales, vacíos y pantallas pequeñas |
| Barra de navegación, tema claro/oscuro y modo Lite | Implementado / validar | Verificar contraste, accesibilidad y animaciones reducidas |
| Mascota Mr. Healthy y vestimenta sincronizada visualmente | Implementado / validar | `HealthyMascotLive`; comprobar escalas y recortes |
| Sonidos retro originales y vibración contextual | Implementado / validar | Configuración y sintetizador Android; auditar dispositivos |
| Tutorial interactivo por pantalla | Implementado / validar | Spotlight, explicación, flechas, avance y bloqueo de toques |
| UFO flotante en mini radar | Implementado / validar | Radar de 44 dp; UFO de 84 dp tras toque, pulsación larga para cerrar |
| Ocultar lanzador mientras está activo el tutorial | Implementado / validar | Evitar dos UFO simultáneos; prueba en todas las pantallas |
| Jerarquía visual, foco y ampliación limitada del tutorial | Implementado / validar | Ampliar solo objetivos de hasta 420×220 dp; pruebas de superposición |
| Efectos avanzados adicionales para navegación y guía | Parcial | Ajustar layouts compactos, teclado, accesibilidad y efectos por tema |

## B. Hábitos, seguimiento y herramientas

| Funcionalidad | Estado | Evidencia / próximo paso |
|---|---|---|
| Catálogo de 36 hábitos oficiales | Implementado / validar | Catálogo Flutter/backend y pruebas de consistencia |
| Agregar, activar, cancelar y registrar hábitos | Parcial / backend probado | Funciones transaccionales; flujo cliente normal necesita migración segura |
| Checklist y progreso cotidiano | Implementado / validar | Revisar integración con registros oficiales |
| Frecuencias, objetivos, límites diarios/semanales, zonas horarias | Backend probado | Cobertura en pruebas `functions`, integración Android pendiente |
| XP, niveles, Habit Coins y rachas | Parcial / backend probado | Recompensas del servidor disponibles; rutas antiguas de cliente requieren auditoría |
| Penalización de cancelación de hábito difícil | Backend probado | Validación de máximo autorizado y saldo; no saltarse confirmación |
| Temporizadores, contadores, hidratación y podómetro | Piloto / parcial | Configuración e interacciones; no acreditan XP sin registro oficial |
| Respiración guiada y Pomodoro | Implementado / demo | Verificar cronometraje, pausas y reanudación en Android |
| Recordatorios de hábitos locales | Parcial / beta | Revisar permisos, recurrencia, zona y notificaciones en dispositivo |
| Evidencia fotográfica por cámara/galería | Implementado / pruebas automáticas aprobadas | Captura JPEG sin EXIF; ruta beta de reserva, subida, registro y asociación; **sin desplegar al Firebase real** |
| Google ML Kit y laboratorio Google Cloud Vision | Implementado en código / validar | ML Kit local; Vision remoto opcional para foto ya asociada con consentimiento, cuota y estado visual indicativo; no prueba consumo |
| Identificación nominal de alimentos (ML Kit + modelo especializado) | **Modelo ONNX integrado en Android / probar en dispositivo** | Descarga opcional verificada, 65 clases con sandía/manzana/plátano/zanahoria; inferencia privada con ML Kit como respaldo; no acredita consumo ni XP |
| Verificación fiable por evidencia, confianza y borrado temporal | Parcial / backend bloqueado | Asociación y borrado programado en código; verificación fuerte de realización no implementada; pruebas beta/precisión pendientes |
| Entrenamiento mental: Sudoku diario | **Implementado / pruebas Android pendientes** | Cuadrícula 9×9 con pistas, validación de reglas, guardado por día, progreso local, sin recompensas económicas |
| Entrenamiento mental: Sopa de letras | **Implementado / pruebas Android pendientes** | Cuadrícula 12×12 con siete palabras, selección bidireccional, pistas, rachas locales sin XP |
| Eliminación del bono de XP por adjuntar cualquier imagen | **Implementado en código / validar** | Registro cliente normal asigna 10 XP declarado; no guarda fotos Base64 ni indica evidencia real |
| Consulta de estado y recuperación de imágenes de beta | **Implementado en código / validar** | Retoma mismo operationId, permite reseleccionar foto y no crea recompensas duplicadas |
| Control diario de solicitudes fotográficas y Vision | Backend implementado / apagado | 12 reservas al día, hasta 8 evaluaciones diarias, intervalo de 60 s para Vision |
| Limpieza administrativa de fotos temporales | Código preparado / no desplegado | Tarea horaria tras caducidad; habilitación requiere beta, reglas y banderas independientes |
| Pruebas integrales de evidencias en emuladores | **1/1 aprobada en CI** | Auth, Firestore, Storage y Functions en proyecto demo; foto adjunta, reintento y borrado sin duplicar XP |
| Estadísticas, gráficas y retroalimentación | Implementado / validar | Comprobar coherencia con fuente autoritativa y estados vacíos |
| Desafíos y misiones diarias, semanales y mensuales | Parcial | Pantallas/tarjetas disponibles; progresos y recompensas requieren auditoría |
| Logros, insignias y estante de exhibición | Implementado / validar | Validar fuente de eventos y propiedad de elementos |

## C. Tienda, cosméticos y economía

| Funcionalidad | Estado | Evidencia / próximo paso |
|---|---|---|
| Tienda con Habit Coins e inventario | Implementado / validar | Catálogo y compra/equipamiento; integración normal bajo auditoría |
| Compras únicas y equipamiento transaccional en servidor | Backend probado | Pruebas de inventario, precios, idempotencia y saldo |
| Armario de Mr. Healthy con capas, ranuras y skins | Implementado / validar | Posición, tamaño y rotación; transformaciones personalizadas locales |
| Banners, marcos, accesorios, aura y títulos | Implementado / validar | Verificar estado de propiedad, raridades y visualización |
| Pase de temporada y paquetes de moneda con precios MXN | **Solo demo** | Sin pasarela, cobros ni propiedad; los importes son ficticios |
| Skin de UFO comprable y equipable | Diseñado / pendiente | Separar inventario/equipamiento de UFO frente a mascota |
| Skins UFO: cosmos, neón, oro, sombrío, vegetal, glitch, lava | Diseñado / pendiente | Arte, IDs, ranuras y precios según rareza |
| Skin UFO primitiva tipo caricatura prehistórica | Diseñado / pendiente | Concepto aprobado; arte y catálogo por crear |
| Skin UFO de zanahoria cómica | Diseñado / pendiente | Concepto aprobado; arte y catálogo por crear |
| Oferta del día y descuentos ocasionales | Diseñado / pendiente | Precio de referencia honesto y transacción server-side |
| Rotación diaria de artículos | Diseñado / pendiente | Objetivo: **45 % fijos, 35 % rotativos, 20 % especiales** |
| Rarezas común, poco común, raro, épico y legendario/secreto | Diseñado / pendiente | Definir clasificación y beneficios exclusivamente cosméticos |
| Rebajar banners degradados y gorra básica | Diseñado / pendiente | Medir ingresos diarios en Habit Coins y sincronizar precios Flutter/backend |
| Historial y consulta de catálogo completo sin compra | Diseñado / parcial | Los objetos comprados nunca desaparecen del inventario |

**Dato de referencia:** un informe del 25/11 registra 62 artículos (60 de pago y 2 gratuitos). Otras notas anteriores citan 59. **No fijar un total definitivo sin auditar el catálogo actual**.

## D. Mr. Healthy: asistente, chat y fuentes

| Funcionalidad | Estado | Evidencia / próximo paso |
|---|---|---|
| Chat local de FAQ y navegación | Implementado / validar | Motor de intenciones, tarjetas y enlaces a pantallas |
| Consultar perfil, hábitos, XP, monedas, retos y logros | Implementado / validar | Los datos proceden de servicios internos cuando están disponibles |
| Agregar/abandonar hábitos y adquirir/equipar desde tarjetas | Implementado / condicionado | Confirmaciones explícitas; depende de seguridad del backend activo |
| Calculadoras IMC y GET | Implementado / validar | Herramientas orientativas, no diagnósticos |
| Dictado por micrófono y bips retro | Implementado / validar | No confundir bips con síntesis de voz hablada |
| Historial de conversaciones por sesión | Implementado / validar | Contexto limitado; política de borrado y sesión |
| Estilos de respuesta y densidad visual | Implementado / validar | Natural/directo/guiado y compacto/equilibrado/lectura |
| FAQ editorial y banco amplio de formulaciones | Implementado / validar | Respuestas locales, no modelo neuronal |
| Seguimientos de historias, acertijos y correcciones | Implementado / validar | Contexto reciente con pruebas por escenario |
| Aclaraciones ante preguntas no reconocidas | Implementado / validar | Preguntas específicas, sin falsificar certeza |
| Selección de fuente: local, enciclopédica, privada o sensible | Implementado / validar | Enrutador local antes de llamar a internet |
| Diálogo guiado de comparación (opciones, criterio, evaluación) | Implementado / validar | Varias intervenciones y rechazo de acciones sensibles |
| Diálogo guiado de metas (meta, plazo, primer paso) | Implementado / validar | No registra hábitos ni crea recordatorios |
| Revisión de metas (hecho, no realizado, obstáculo, ajustar paso, cancelar plan) | **Implementado en esta etapa / validar** | Respuestas acotadas al turno previo; no registra XP, rachas ni recordatorios |
| Consulta explícita a Wikipedia en español | Backend **desplegado** / Android por comprobar | Firebase `searchMrHealthyEncyclopedia` en `cloud-firestore-d8c61` |
| Fuentes y enlaces verificados en respuestas externas | Implementado / validar | Hasta 3 resultados; solo `es.wikipedia.org` y HTTPS |
| Límite de consultas y protección de datos | Backend desplegado / revisar | 25 por cuenta/día; App Check de esta callable aún no se exige |
| Búsqueda general en múltiples fuentes actuales | Diseñado / pendiente | Backend proveedor, calidad, fechas, consentimiento y privacidad |
| Motor de IA generativa con razonamiento abierto | Diseñado / pendiente | Elegir proveedor, servidor con secretos, cuotas, moderación y evaluación |
| Memoria semántica persistente y autonomía de acciones | No implementado | Nunca asumir permisos ni operaciones por lenguaje libre |

## E. Perfil, comunidad y participación

| Funcionalidad | Estado | Evidencia / próximo paso |
|---|---|---|
| Perfil público/privado, fotografía, biografía, edición | Implementado / validar | Autorizaciones, valores reales y fotos |
| Sistema de amigos, solicitudes, seguir y reacciones | Parcial / validar | Revisar privacidad, animaciones y operaciones multiusuario |
| Hábitos en pareja e invitaciones | Parcial | Interfaz e invitaciones; finalización simultánea verificable pendiente |
| Feed social con eventos reales | Diseñado / pendiente | Actualmente tarjetas de estado; eventos inmutables aún no implementados |
| Push remoto de solicitudes de amistad | Diseñado / pendiente | FCM, tokens, preferencias, reglas y emulador |
| Ranking, niveles y perfiles públicos | Implementado / validar | Comprobar datos reales y restricciones de lectura |
| Mensajería y acciones sociales adicionales | Parcial / diseñado | Auditar alcance; no asegurar chat social completo sin evidencia |

## F. Secretos, eventos y monetización

| Funcionalidad | Estado | Evidencia / próximo paso |
|---|---|---|
| Sala de Easter eggs | **Implementado en código / validar** | Entrada de siete toques desde Tienda, pistas en Inicio/Tienda/Chat, cueva nueva y estado por cuenta; backend sin desplegar |
| Lore: cueva, rejas y criatura peligrosa | **Implementado en código / validar** | Escena dibujada en Flutter, barrotes, iluminación animada y pistas de piedra |
| Acertijo con pistas dentro de la cueva | **Implementado en código / validar** | Tres pistas progresivas, validación remota, cinco intentos/día y mensajes de errores; no exponer solución en Flutter |
| Skin musculosa exclusiva «Mr. Healthy Titan» | **Implementado en código / bloquear despliegue hasta auditar reglas** | Arte vectorial, inventario especial, equipamiento y transacción de recompensa única |
| Anuncio y animación de liberación de la criatura | **Implementado en código / validar** | Rejas deslizantes, luz, audio original y confirmación de Firebase antes del anuncio de premio |
| Pistas del secreto en Inicio, Tienda y Mr. Healthy | **Implementado en código / validar** | Rastro de tres puntos; la solución no se entrega automáticamente |
| Bonificación secreta de 1000 monedas | **Solo laboratorio** | Pruebas de `secret_test_bonus.js`; no confundir con el nuevo lore |
| Micropagos y pase de temporada real | Diseñado / bloqueado | Pagos oficiales, validación server-side, fraude y cumplimiento |

## G. Seguridad, calidad y publicación

| Funcionalidad | Estado | Próximo paso |
|---|---|---|
| Firebase Cloud Functions para operaciones oficiales | Backend probado | Migrar rutas normales Flutter sin romper su funcionamiento |
| Reglas Firestore candidatas restrictivas | Diseñado / **no desplegar** | Resolver bloqueos de clientes y repetir emulador |
| Idempotencia y contabilidad en backend | Backend probado | Auditar casos de concurrencia en app real |
| Firebase App Check para APIs sensibles | Parcial | Registrar dispositivos, probar y activar exigencia gradualmente |
| Verificación de evidencias y recompensas no falsificables | **Bloqueado para producción** | Exigir evidencia independiente, no basada solo en cliente |
| Revisión `npm audit` | Pendiente | Último reporte: 28 vulnerabilidades moderadas, sin diagnóstico individual |
| Búsqueda Wikipedia con límites de servidor | Backend desplegado | Pruebas Android, costes, permisos y política de cuota |
| Accesibilidad, distintos tamaños y reducir movimiento | Parcial | Pruebas manuales UI completas |
| Suite `functions` | **193/193 aprobadas en CI; Vision 15/15** | Se incluyen pruebas de evidencia, consentimiento, idempotencia y privacidad; despliegue real pendiente |
| Suite Flutter y pruebas en Android | **567 tests Flutter aprobados en CI; Android físico pendiente** | Análisis sin errores bloqueantes; validar cámara, captura, permisos y fluidez en dispositivo |
| Beta pública conectada a Firebase real | **No autorizada** | Nuevas callables de evidencia y Vision apagadas por defecto; migrar economía Flutter, aprobar reglas y App Check antes de publicar |

## Prioridad acordada

**P0 — Evidencia real y beta cerrada (nueva prioridad)**
1. Auditar e integrar el contrato de evidencia temporal y privada entre Flutter, Storage y Functions en Emulator.
2. Evaluar imágenes con resultado explicable sin confundir detección con cumplimiento, y conectarlo al registro autoritativo.
3. Migrar escrituras económicas de Flutter; validar reglas negativas y positivas, App Check, reintentos y dos cuentas.
4. No habilitar producción, compras reales ni recompensas no verificadas.
5. Documentar avances en [Plan prioritario de evidencias y beta](PLAN_PRIORITARIO_EVIDENCIAS_BETA.md).

**P1 — Experiencia principal, en pausa mientras se cierra P0**
1. Continuar mejorando criterios conversacionales y diálogo contextual con pruebas.
2. Validar en Android la cueva, el acertijo y el equipamiento de Titán; auditar Firestore y App Check antes de publicar el callable.
3. Integrar skins comprables del UFO (prehistórica y zanahoria incluidas).
4. Rebalancear precios, rotación de la tienda y descuentos del día.

**P2 — Evolución**
1. Conectar fuentes web adicionales con criterios de verificación.
2. Evaluar IA generativa y costes sin exponer claves en Flutter.
3. Feed social basado en eventos reales y push remotas.
4. Convertir pases de temporada y otras demostraciones en funciones reales solo con backend autorizado.

## Cómo actualizar este documento

En cada cambio de código:
1. Cambiar el estado de la fila correspondiente; agregarla si aún no existe.
2. Anotar fecha, commit y evidencia de prueba ejecutada.
3. No promover de «implementado» a «validado» sin resultados reproducibles.
4. Mantener decisiones de diseño separadas de funcionalidades operativas.
5. Para ideas nuevas, añadir módulo, alcance, dependencias, prioridad y estado.

## Registro de decisiones recientes

| Fecha | Decisión | Estado |
|---|---|---|
| 27/11/2026 | UFO flotante se oculta durante tutorial; reposo como mini radar | Código implementado, Android pendiente |
| 27/11/2026 | Corregir jerarquía, límites de spotlight y ampliaciones | Código implementado, Android pendiente |
| 27/11/2026 | Chat híbrido: local + consulta explícita Wikipedia con fuentes | Backend desplegado, dispositivo por validar |
| 27/11/2026 | Chat: aclaraciones, fuente segura, comparaciones y metas guiadas | Código implementado, tests Flutter pendientes |
| 27/11/2026 | Easter egg de cueva con acertijo y skin Titán exclusiva | Implementado en código, pruebas Firebase/Flutter y despliegue pendientes |
| 27/11/2026 | UFO primitivo y UFO zanahoria, además de otras skins | Diseño aprobado |
| 27/11/2026 | Tienda 45/35/20, rarezas y revisión de precios | Diseño aprobado |
| 27/11/2026 | Seguimiento de metas: avance, obstáculos y cambios de paso | Código implementado; nuevas pruebas Flutter pendientes |
| 27/11/2026 | Repriorización: reconocimiento de evidencias y beta cerrada | Diagnóstico y plan definidos; desarrollo por etapas E1–E3 y B1–B3 |
| 27/11/2026 | Evidencia fotográfica: fotos privadas beta, recuperación, Vision y limpieza | Implementado en código; verificación visual orientativa; suites y despliegue seguros pendientes |
| 27/11/2026 | Identificación específica conservadora de alimentos, sin inferir desde categorías | Código y pruebas añadidas; falta modelo especializado real y validación de precisión |
| 27/11/2026 | Reconocimiento ONNX descargable y hábitos mentales con minijuegos | Integrados en código; compilación nativa, precisión real y verificación Android pendientes |

## Documentación vinculada

- [Plan prioritario de evidencias y beta](PLAN_PRIORITARIO_EVIDENCIAS_BETA.md)
- [Modelo alimentario ONNX en Android](RECONOCIMIENTO_ONNX_ALIMENTOS.md)
- [Entrena tu mente: Sudoku y sopa de letras](ENTRENAMIENTO_MENTAL.md)
- [Implementación de evidencias y protocolo de pruebas](IMPLEMENTACION_EVIDENCIAS_2026-11-27.md)
- [Roadmap de UFO, chatbot y tienda](ROADMAP_UFO_CHATBOT_TIENDA.md)
- [Estado de cierre y restricciones de beta](CIERRE_AVANCES_Y_DEMO_2026-11-25.md)
- [Mr. Healthy 2.0](MR_HEALTHY_2_0.md)
- [Avances del armario, temporada y herramientas](DEMO_PASE_TEMPORADA_ARMARIO_RESPIRACION_2026-11-26.md)
- [Reconocimiento visual en modo demo](DEMO_RECONOCIMIENTO_IMAGENES_2026-11-26.md)
- [Feed social, push y hábitos en pareja](PLAN_FEED_PUSH_PAREJA_AUDIO_2026-11-25.md)
- [Cierre funcional previo](cierre-funcional-2026.md)

**Nota editorial:** este inventario sintetiza código inspeccionado y documentos de etapas previas; cuando los documentos discrepan o la validación no consta, se conserva el estado prudente.
