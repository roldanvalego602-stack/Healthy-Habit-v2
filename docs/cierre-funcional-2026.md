# Healthy Habit — cierre funcional (17 nov 2026)

**Objetivo:** completar funcionalidades antes de la entrega del 7 de diciembre de 2026. Este documento distingue código identificado de funcionamiento confirmado. La app completa NO está validada en Android y no se debe presentar como terminada.

## Reglas de trabajo
1. Proteger las modificaciones locales sin subir del desarrollador, especialmente `lib/páginas/habitos/registrar_habito_screen.dart` y `firebase.json`. No usar reset hard ni sobrescribir el archivo de registro sin revisar su diff.
2. Completar un flujo vertical por vez: interfaz → datos → servidor/reglas → manejo de errores → pruebas.
3. Evitar funciones falsas: no llamar «verificado» a una fotografía no analizada; no entregar 20 XP por presencia de imagen ni por escribir el código.
4. Mantener laboratorio de Firebase en emuladores aislado de producción. Posponer diagnóstico de gráficos Android salvo que bloquee funcionalidad indispensable.
5. Para cada módulo: casos de aceptación + evidencia de pruebas + limitaciones pendientes.

## Inventario preliminar confirmado por inspección de código

| Módulo | Evidencia | Estado |
|---|---|---|
| Registro de hábitos | `registrar_habito_screen.dart`: progreso, interacciones y transacción de cliente; imagen opcional | Parcial; revisión de cambios locales pendiente; XP no autoritativo |
| XP/rachas | lógica en pantalla de registro; recompensa +10 sin imagen, +15 con imagen | Parcial; falta protección server-side, deduplicación e integración |
| Mr. Healthy | `interpretMrHealthyIntent` + servicio Flutter; clasificador por reglas | Backend probado; falta vincular a acciones reales del chatbot |
| Verificación de evidencias | política visual simulada + desafíos de cinco minutos y pruebas en emulador | Experimental; falta OCR, foto privada, evaluación, entrega segura de XP |
| Android demo | entrada y pantalla aisladas | No validado en dispositivo; diagnóstico en pausa |
| Misiones/desafíos | pantallas e intención de navegación conocidas | Requiere auditoría funcional |
| Logros | componentes existentes en repo | Requiere auditoría funcional |
| Tienda y monedas | pantalla tienda; callable admin adjustHabitCoins | Requiere auditoría funcional y reglas de compra |
| Estadísticas | datos básicos leídos en `main.dart` | Requiere auditoría funcional |
| Perfil/social | pantallas importadas en `main.dart` | Requiere auditoría funcional |

## Orden de ejecución
1. **Cierre de registro y contabilidad de XP**: reconciliar los cambios locales; definir un ID único por registro/operación; calcular progreso, fecha civil y racha sin duplicar; mantener vía de registro sin imagen.
2. **Racha y niveles**: una sola fuente de verdad para XP y progresión, pruebas de concurrencia, metas completadas y cambios de día.
3. **Misiones, logros y desafíos**: fuente de eventos consistente desde registros, distinción diaria/semanal/mensual, idempotencia.
4. **Tienda**: transacción atómica para compra, comprobación de saldo, catálogo e inventario.
5. **Mr. Healthy**: consultar estado real y navegar sin modificar datos sin confirmación explícita.
6. **Estadísticas y perfil**: consultar la misma fuente de datos de registros, estados vacíos.
7. **Verificación inteligente de foto**: capa privada de almacenamiento, revisión de contenido + OCR + políticas de privacidad + validación de producción + límites de costo, pruebas de imagen real.
8. **Integración final**: pruebas automatizadas y en Android físico, reporte de fallas y criterios de entrega.

## Criterios mínimos de aceptación
- No se duplica XP por pulsar dos veces o reintentar una petición.
- No se registran intentos cancelados o completados.
- Las estadísticas, misiones, niveles y tienda reflejan datos coherentes.
- El usuario puede completar el hábito aunque omita foto.
- Toda mutación de economía (XP y monedas) se valida en el servidor.
- Los errores de Firebase se explican y permiten reintentar sin duplicar cambios.
- El sistema no finge reconocimiento visual mientras OCR/Vision esté desactivado.

**Nota:** clasificar como «pendiente de auditoría» no implica que el módulo carezca de implementación. Se requiere inspección y pruebas antes de afirmarlo.
