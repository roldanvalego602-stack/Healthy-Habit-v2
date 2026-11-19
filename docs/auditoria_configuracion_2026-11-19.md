# Auditoría funcional de Configuración — 19 noviembre 2026

## Criterio de aceptación
Un ajuste se considera **funcional** solo cuando: (1) la UI permite cambiarlo, (2) persiste en Firebase o en dispositivo según corresponda, (3) el módulo consumidor respeta el ajuste, (4) no ofrece permisos falsos, y (5) se comprueba en el dispositivo y, si corresponde, mediante reglas de Firestore.

**Estado de esta auditoría:** revisión estática y cambios de código, sin pruebas Flutter/Android ejecutadas desde el entorno de edición.

## Cuenta
- Editar perfil / fotografía / nombre de usuario: navega a EditarPerfilScreen. Revisar persistencia real en Android.
- Cambiar correo: FirebaseAuth.verifyBeforeUpdateEmail; requiere sesión reciente según Firebase.
- Restablecer contraseña: FirebaseAuth.sendPasswordResetEmail; requiere correo asociado.
- Eliminar cuenta: **NO IMPLEMENTADO**. El diálogo evita eliminar solo Authentication y dejar documentos huérfanos. Crear callable autenticada de eliminación recursiva, reautenticación y limpieza de Storage/Firestore/Auth; revisar permisos y retención.

## Preferencias de hábitos
- Objetivo principal, categorías de interés, dificultad y frecuencia: **GUARDADO, SIN CONSUMIDOR FUNCIONAL**. La UI persiste en users/{uid}.settings; hábitos/recomendador no usa estos campos.
- Máximo de hábitos activos: mensaje informativo; depende del sistema de desbloqueo, no configurable desde esta pantalla.
- Recalcular recomendaciones: mensaje informativo. **NO IMPLEMENTADO**; requiere motor y datasets.

## Asistente IA
- analizarHistorialIA: la consulta de user_habits desde el chatbot ahora queda condicionada a consentimiento afirmativo; sin consentimiento la pregunta de historial explica el ajuste. Revisar que el resto de flujos del asistente no haga otras lecturas indirectas de historial.
- Chat history: el acceso para visualizar conversaciones propias es distinto del análisis automático de hábitos.

## Privacidad y datos
- Aviso de privacidad: documento explicativo provisional, requiere revisión legal para publicación.
- Evidencias temporales: contabilización con consulta Firestore; limpieza oportunista NO equivale a eliminación garantizada a 24 h.
- Eliminar cuenta: pendiente de backend verificado.
- Firestore Security Rules: no existe archivo rules versionado en esta rama. Revisar reglas efectivamente desplegadas desde Firebase Console; sin esa verificación no se puede afirmar privacidad segura.

## Experiencia visual
- Tema Claro/Oscuro/Sistema: controlador persistido en SharedPreferences y aplicado en MaterialApp.
- Modo visual Lite/Normal: controlador global; módulos que usen HealthyVisualEffects lo respetan. Otros efectos requieren auditoría.
- Tamaño de texto: conectado a MaterialApp.builder por PreferenciasApp. Respetar textScaler accesible; verificar pantallas pequeñas y textos largos.
- sonidosApp y vibracionHaptica: ahora consultados por HealthyFeedbackService al comprar en StoreScreen y WardrobeScreen. **PARCIAL**: falta conexión con demás eventos.
- efectosRecompensa y modoDiscreto: consultados al mostrar celebración de compra. **PARCIAL** en otros flujos.
- animacionesDivertidas: consumido ahora por HealthyVisualEffects a través de HealthySettingsScope; **PARCIAL**: solo animaciones que usan ese helper. Modo Lite sigue siendo independiente.
- Idioma: Español es la única opción; no se promete internacionalización.

## Social
- mostrarRachaAmigos: consultado desde FeedAmigosScreen y PublicProfileScreen para ocultar el dato en pantalla. **AÚN SIN CONTROL DE LECTURA** desde Firestore Rules.
- visibilidadLogros: **SOLO GUARDADO**; los destacados de PublicProfileScreen son ejemplos estáticos.
- desafiosDe: **SOLO GUARDADO**; verificar flujo de invitaciones antes de aplicarlo.
- permitirReacciones: **SOLO GUARDADO**.
- Lista de bloqueados: **NO IMPLEMENTADA**; requiere bloquear relaciones, feeds y reglas.
- Datos del perfil público no deben equipararse con permisos de backend; ocultar widgets no asegura que datos no se lean.

## Recordatorios
- permitirRecordatorios, horarioRecordatorio, recordatorioHabito, recordatorioRacha, recordatorioDesafios y descansoSemanal: **SOLO GUARDADO**. No hay planificador de notificaciones del dispositivo; NotificationsScreen contiene notificaciones de ejemplo, no agenda real. Requiere permisos Android, plugin/servicio, horario, zona y cancelación al deshabilitar.

## Gamificación
- mostrarXp, mostrarPuntos, mostrarNivelPerfil, mostrarRachasDiarias y modoDiscreto: aplicados al ProfileScreen, conservan datos subyacentes. **PARCIAL** en otras pantallas como ranking, tienda y chat.
- efectosRecompensa: aplicado en StoreScreen mediante HealthyFeedbackService; otros efectos por auditar.

## Información y soporte
- Sobre nosotros, acerca, términos, privacidad y ayuda: rutas existentes. Textos legales todavía provisionales.
- Versión: versión, build number y paquete consultados con package_info_plus.

## Pruebas mínimas exigidas
1. Cambiar cada ajuste, cerrar y abrir aplicación; verificar persistencia.
2. Cambiar tema y texto sin reiniciar; probar Android accesibilidad y modo Lite.
3. Desactivar XP/monedas/racha; verificar perfil y feed de otro usuario.
4. Desactivar sonidos/vibración/efectos; comprar desde tienda con dos cuentas de prueba.
5. Desactivar analizarHistorialIA; preguntar al asistente por hábitos y verificar que no consulte user_habits.
6. Enviar recordatorio / bloquear persona / borrar cuenta: **NO MARCAR APROBADO** hasta implementar backend/scheduler y probar.
7. Revisar reglas Firestore reales y pruebas de acceso con usuarios distintos.

## Prioridad de cierre
P0: privacidad de datos, permisos backend, no prometer recordatorios o eliminación, persistencia de cuenta.
P1: integración visual y gamificación global, recordatorios si el tiempo permite implementación verificable.
P2: recomendaciones personalizadas, funciones sociales avanzadas y traducciones.
