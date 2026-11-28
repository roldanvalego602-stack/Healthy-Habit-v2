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
| Evidencia fotográfica por cámara/galería | Piloto / demo | No equivale a verificación de consumo |
| Google ML Kit y laboratorio Google Cloud Vision | Piloto restringido | Etiquetas indicativas; sin validación automática de XP; costes y privacidad |
| Verificación fiable por evidencia, confianza y borrado temporal | Diseñado / parcial | Objetivo: niveles de confianza; exige servidor, privacidad, antifraude y pruebas reales |
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
| Diálogo guiado de metas (meta, plazo, primer paso) | **Implementado en esta etapa / validar** | No registra hábitos ni crea recordatorios |
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
| Sala de Easter eggs | Espacio existente / revisar | La interfaz/laboratorio existe; mecánica final por integrar |
| Lore: cueva, rejas y criatura peligrosa | Diseñado / pendiente | Escena ambiental y narración |
| Acertijo con pistas dentro de la cueva | Diseñado / pendiente | Definir respuesta, límites de intentos y accesibilidad |
| Skin musculosa exclusiva «Mr. Healthy Titan» | Diseñado / pendiente | Arte, inventario y desbloqueo único en servidor |
| Anuncio y animación de liberación de la criatura | Diseñado / pendiente | Efecto sin recompensa anticipada |
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
| Suite `functions` | **173/173 reportadas como aprobadas el 27/11** | Repetir tras cambios de backend |
| Suite Flutter y pruebas en Android | **Pendiente de confirmar para cambios recientes** | `flutter analyze`, tests y recorrido funcional |
| Beta pública conectada a Firebase real | **No autorizada** | Cerrar seguridad, migraciones, reglas y pruebas de distribución |

## Prioridad acordada

**P0 — Calidad y riesgos bloqueantes**
1. Validar el nuevo UFO mini radar y la guía en Android.
2. Ejecutar análisis y pruebas Flutter del chatbot; verificar búsquedas reales con cuenta autenticada.
3. Corregir incompatibilidades de datos y revisar seguridad antes de distribuir.
4. No habilitar compras reales ni recompensas no verificadas.

**P1 — Experiencia principal**
1. Continuar mejorando criterios conversacionales y diálogo contextual con pruebas.
2. Crear escena de cueva, acertijo y recompensa exclusiva de skin musculosa.
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
| 27/11/2026 | Easter egg de cueva con acertijo y skin Titan exclusiva | Diseño aprobado |
| 27/11/2026 | UFO primitivo y UFO zanahoria, además de otras skins | Diseño aprobado |
| 27/11/2026 | Tienda 45/35/20, rarezas y revisión de precios | Diseño aprobado |

## Documentación vinculada

- [Roadmap de UFO, chatbot y tienda](ROADMAP_UFO_CHATBOT_TIENDA.md)
- [Estado de cierre y restricciones de beta](CIERRE_AVANCES_Y_DEMO_2026-11-25.md)
- [Mr. Healthy 2.0](MR_HEALTHY_2_0.md)
- [Avances del armario, temporada y herramientas](DEMO_PASE_TEMPORADA_ARMARIO_RESPIRACION_2026-11-26.md)
- [Reconocimiento visual en modo demo](DEMO_RECONOCIMIENTO_IMAGENES_2026-11-26.md)
- [Feed social, push y hábitos en pareja](PLAN_FEED_PUSH_PAREJA_AUDIO_2026-11-25.md)
- [Cierre funcional previo](cierre-funcional-2026.md)

**Nota editorial:** este inventario sintetiza código inspeccionado y documentos de etapas previas; cuando los documentos discrepan o la validación no consta, se conserva el estado prudente.
