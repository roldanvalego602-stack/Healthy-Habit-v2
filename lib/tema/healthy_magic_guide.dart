import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../guia/healthy_ufo_visual.dart';
import '../servicios/healthy_retro_sound_service.dart';
import '../guia/guide_step.dart';
import '../guia/guide_screen_routes.dart';
import '../guia/guide_target.dart';
import '../guia/healthy_guide_overlay.dart';

/// Pasos de ayuda elaborados según las funciones reales de Healthy Habit.
/// No hace inferencias de IA ni concede permisos o recompensas.
class HealthyGuideStep {
  const HealthyGuideStep(this.title, this.description, this.icon);
  final String title;
  final String description;
  final IconData icon;
}

class HealthyMagicGuide {
  const HealthyMagicGuide._();

  static const sections = <String, List<HealthyGuideStep>>{
    'inicio': [
      HealthyGuideStep('Tu centro de actividad',
        'Aquí encuentras el resumen de tu progreso y los accesos a las funciones principales.',
        Icons.home_rounded),
      HealthyGuideStep('Resumen, XP y rachas',
        'Estas tarjetas muestran el avance de tus hábitos, experiencia y constancia. Toca una tarjeta para ver los detalles cuando tenga una acción disponible.',
        Icons.insights_rounded),
      HealthyGuideStep('Mr. Healthy',
        'Puedes abrir el asistente para consultar información sobre la aplicación o pedir ayuda con hábitos.',
        Icons.auto_awesome_rounded),
      HealthyGuideStep('Barra de navegación',
        'Utiliza la barra inferior para entrar a Hábitos, Tienda, Catálogo o Perfil. Este botón mágico te guía en cada sección.',
        Icons.touch_app_rounded),
    ],
    'habitos': [
      HealthyGuideStep('Tus hábitos activos',
        'Aquí aparecen las actividades que elegiste y cuánto te falta para alcanzar sus metas.',
        Icons.check_circle_outline),
      HealthyGuideStep('Agregar y explorar',
        'Puedes buscar actividades y filtrar por categoría o dificultad. Al elegir una, revisa sus requisitos antes de agregarla.',
        Icons.add_circle_outline),
      HealthyGuideStep('Registrar avances',
        'Abre un hábito para registrar el progreso. Algunas actividades incluyen contador, temporizador u otras herramientas.',
        Icons.edit_note_rounded),
      HealthyGuideStep('Rutinas y hábitos en pareja',
        'Hay accesos a rutinas personales y actividades compartidas. Algunas funciones requieren usuarios conectados y permisos.',
        Icons.groups_outlined),
    ],
    'tienda': [
      HealthyGuideStep('Tus Habit Coins',
        'El saldo es una recompensa virtual. No equivale a dinero real.',
        Icons.toll_rounded),
      HealthyGuideStep('Artículos y categorías',
        'Explora objetos y cosméticos. Antes de comprar, revisa su costo y si ya lo tienes.',
        Icons.storefront_outlined),
      HealthyGuideStep('Compras e inventario',
        'Una compra confirmada descuenta monedas y agrega el artículo al inventario. La tienda no procesa pagos reales.',
        Icons.shopping_bag_outlined),
      HealthyGuideStep('Tu armario',
        'Abre el armario para equipar accesorios y personalizar a Mr. Healthy o la presentación de tu perfil.',
        Icons.checkroom_rounded),
    ],
    'catalogo': [
      HealthyGuideStep('Explora contenido',
        'Consulta fichas educativas de alimentos, bebidas, ejercicios y bienestar.',
        Icons.menu_book_rounded),
      HealthyGuideStep('Buscar y filtrar',
        'Utiliza el buscador, las categorías y los filtros para encontrar algo concreto.',
        Icons.search_rounded),
      HealthyGuideStep('Abrir detalles',
        'Toca una tarjeta para ver su descripción, imágenes y recomendaciones disponibles.',
        Icons.info_outline_rounded),
      HealthyGuideStep('Comparar elementos',
        'Selecciona dos o más elementos compatibles para abrir la comparación cuando esté disponible.',
        Icons.compare_arrows_rounded),
    ],
    'perfil': [
      HealthyGuideStep('Tu identidad',
        'Aquí puedes revisar y editar información visible de tu perfil y su presentación.',
        Icons.person_outline_rounded),
      HealthyGuideStep('Progreso y logros',
        'Consulta tus estadísticas, niveles, medallas y otros indicadores de avance.',
        Icons.emoji_events_outlined),
      HealthyGuideStep('Amigos y comunidad',
        'Puedes buscar usuarios, enviar solicitudes y consultar actividades sociales permitidas.',
        Icons.people_outline_rounded),
      HealthyGuideStep('Configuración',
        'Personaliza tema, tamaño de texto, recordatorios y sonidos. Los cambios pueden depender de tu sesión.',
        Icons.settings_outlined),
    ],
    'registro': [
      HealthyGuideStep('Meta del hábito',
        'Revisa qué actividad vas a registrar y cuánto progreso requiere.',
        Icons.flag_outlined),
      HealthyGuideStep('Herramienta de registro',
        'Según el hábito, puedes utilizar controles manuales, temporizador, contador o herramientas guiadas.',
        Icons.timer_outlined),
      HealthyGuideStep('Agregar fotografía',
        'Puedes tomar o seleccionar una foto. Una imagen es evidencia orientativa, no prueba definitiva de cumplimiento.',
        Icons.add_a_photo_outlined),
      HealthyGuideStep('Reconocimiento visual',
        'ML Kit intenta identificar objetos y compararlos con lo esperado. Coincidencia visual no significa que la actividad se realizó.',
        Icons.document_scanner_outlined),
      HealthyGuideStep('Guardar el registro',
        'Revisa los datos antes de confirmar. El servidor o el flujo activo determina el registro y las recompensas aplicables.',
        Icons.save_outlined),
    ],
    'chatbot': [
      HealthyGuideStep('Pregunta a Mr. Healthy',
        'Escribe una consulta sobre hábitos, monedas, catálogo, progreso u otras funciones compatibles.',
        Icons.chat_bubble_outline),
      HealthyGuideStep('Mensajes y sugerencias',
        'El asistente interpreta intenciones y puede ofrecer tarjetas para consultar o abrir funciones de la app.',
        Icons.lightbulb_outline),
      HealthyGuideStep('Voz y audio',
        'Cuando el teléfono y los permisos lo permiten, puedes dictar mensajes y activar respuestas habladas.',
        Icons.mic_none_rounded),
      HealthyGuideStep('Historial',
        'Revisa conversaciones guardadas o inicia una nueva desde los botones de la parte superior.',
        Icons.history_rounded),
    ],
    'amigos': [
      HealthyGuideStep('Buscar personas',
        'Encuentra usuarios mediante el buscador y abre perfiles para consultar información compartida.',
        Icons.person_search_outlined),
      HealthyGuideStep('Solicitudes',
        'Envía, cancela, acepta o rechaza solicitudes. La amistad se establece cuando ambas cuentas quedan vinculadas.',
        Icons.person_add_alt_1_outlined),
      HealthyGuideStep('Actividad social',
        'Consulta eventos compartidos, como logros o niveles, si están disponibles y permitidos.',
        Icons.dynamic_feed_outlined),
    ],
    'notificaciones': [
      HealthyGuideStep('Actividad y avisos',
        'La pantalla separa recordatorios de actividad y comunicaciones sociales.',
        Icons.notifications_outlined),
      HealthyGuideStep('Recordatorios de Android',
        'Revisa los permisos y horarios. Android puede retrasar avisos por restricciones de batería.',
        Icons.schedule_outlined),
      HealthyGuideStep('Solicitudes y reacciones',
        'La sección social muestra solicitudes, invitaciones y reacciones disponibles para tu cuenta.',
        Icons.favorite_outline),
    ],
    'armario': [
      HealthyGuideStep('Elige una ranura',
        'Selecciona la parte de Mr. Healthy o de tu perfil que quieres personalizar.',
        Icons.checkroom_outlined),
      HealthyGuideStep('Equipar artículos',
        'Toca los objetos que tienes disponibles para equiparlos o quitarlos.',
        Icons.style_outlined),
      HealthyGuideStep('Editar colocación',
        'Cuando esté disponible, mueve, cambia el tamaño o gira el accesorio. El ángulo admite valores negativos.',
        Icons.open_with_rounded),
      HealthyGuideStep('Guardar diseño',
        'Los cambios de colocación se almacenan para reutilizar tu diseño.',
        Icons.save_outlined),
    ],
    'imagenes': [
      HealthyGuideStep('Cámara o galería',
        'Elige una fotografía de alimento, agua u otro elemento que quieras analizar.',
        Icons.camera_alt_outlined),
      HealthyGuideStep('Perfil esperado',
        'Elige qué debería aparecer en la foto: agua, frutas y verduras o comida.',
        Icons.category_outlined),
      HealthyGuideStep('Resultado visual',
        'La herramienta muestra etiquetas y confianza. Una coincidencia no verifica consumo ni entrega monedas.',
        Icons.document_scanner_outlined),
    ],
  };

  static Future<void> open(BuildContext context, String section) async {
    final steps = sections[section];
    if (steps == null || steps.isEmpty) return;
    HealthyRetroSoundService.play('guide');
    if (HealthyGuideScreenRoutes.supported.contains(section)) {
      await HealthyGuideOverlay.show(
        context,
        sectionTitle: _titles[section] ?? 'Healthy Habit',
        steps: HealthyGuideScreenRoutes.forSection(section),
      );
      return;
    }
    if (section == 'habitos') {
      await HealthyGuideOverlay.show(context,
        sectionTitle: 'Hábitos',
        steps: [
          HealthySpotlightStep(
            title: 'Conoce tus hábitos',
            description: 'Mr. Healthy te mostrará las herramientas '
                'de esta pantalla. Durante el recorrido no se '
                'realizarán registros ni cambios en tu cuenta.',
            icon: Icons.auto_awesome_rounded,
            targetKey: HealthyGuideTargets.habitsHeader,
          ),
          for (final i in const [1, 3, 0, 2]) ...[
            HealthySpotlightStep(
              title: steps[i].title,
              description: steps[i].description,
              icon: steps[i].icon,
              targetKey: HealthyGuideTargets.forHabitsStep(i),
              extract: i == 1,
            ),
            if (i == 0)
              HealthySpotlightStep(
                title: 'Una tarjeta, de cerca',
                description: 'Si tienes hábitos activos, aquí puedes '
                    'examinar una tarjeta real: nombre, progreso y XP. '
                    'La vista ampliada es solo informativa; '
                    'no activa Registrar ni Abandonar hábito.',
                icon: Icons.zoom_in_rounded,
                targetKey: HealthyGuideTargets.habitsCard,
                extract: true,
              ),
          ],
        ],
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _GuideWalkthrough(
        title: _titles[section] ?? 'Healthy Habit',
        steps: steps,
      ),
    );
  }

  static const _titles = <String, String>{
    'inicio': 'Inicio', 'habitos': 'Hábitos', 'tienda': 'Tienda',
    'catalogo': 'Catálogo', 'perfil': 'Perfil', 'registro': 'Registro',
    'chatbot': 'Mr. Healthy', 'amigos': 'Amigos',
    'notificaciones': 'Notificaciones', 'armario': 'Armario',
    'imagenes': 'Reconocimiento visual',
  };
}

/// Botón de ayuda arrastrable, compartido por todas las pantallas.
/// Un toque abre la guía; arrastrarlo solo modifica su posición visual.
class HealthyMagicGuideButton extends StatefulWidget {
  const HealthyMagicGuideButton({super.key, required this.section});
  final String section;

  @override
  State<HealthyMagicGuideButton> createState() =>
      _HealthyMagicGuideButtonState();
}

class _HealthyMagicGuideButtonState extends State<HealthyMagicGuideButton>
    with SingleTickerProviderStateMixin {
  static const double _diameter = 84;
  static const double _radarDiameter = 44;
  static const double _margin = 8;
  static Offset? _savedRelativePosition;

  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _hover;
  bool _dragging = false;
  bool _expanded = false;
  bool _guideOpen = false;
  double _tilt = 0;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
  }

  Future<void> _openGuide() async {
    if (_guideOpen) return;
    setState(() => _guideOpen = true);
    try {
      await HealthyMagicGuide.open(context, widget.section);
    } finally {
      if (mounted) {
        setState(() {
          _guideOpen = false;
          _expanded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (overlayContext) {
        if (_guideOpen) return const SizedBox.shrink();
        final media = MediaQuery.of(overlayContext);
        final screen = media.size;
        // Reservar siempre el diámetro expandido para evitar saltos al
        // desplegar el radar cerca de los límites del dispositivo.
        final minX = _margin;
        final minY = media.padding.top + _margin;
        final maxX = math.max(minX, screen.width - _diameter - _margin);
        final maxY = math.max(minY, screen.height -
            media.padding.bottom - media.viewInsets.bottom -
            _diameter - _margin);
        final relative = _savedRelativePosition;
        final x = relative == null
            ? minX
            : (minX + (maxX - minX) * relative.dx)
                .clamp(minX, maxX).toDouble();
        final y = relative == null
            ? (maxY - 72).clamp(minY, maxY).toDouble()
            : (minY + (maxY - minY) * relative.dy)
                .clamp(minY, maxY).toDouble();

        return Positioned(
          left: x,
          top: y,
          child: Semantics(
            label: _expanded
                ? 'Mr. Healthy desplegado. Toca para iniciar la guía.'
                : 'Mini radar de Mr. Healthy. Toca para desplegarlo.',
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onPanStart: (_) => setState(() => _dragging = true),
              onPanUpdate: (details) {
                final nx = (x + details.delta.dx).clamp(minX, maxX).toDouble();
                final ny = (y + details.delta.dy).clamp(minY, maxY).toDouble();
                setState(() {
                  _savedRelativePosition = Offset(
                    maxX > minX ? (nx - minX) / (maxX - minX) : 0,
                    maxY > minY ? (ny - minY) / (maxY - minY) : 0,
                  );
                  _tilt = (details.delta.dx * .018)
                      .clamp(-.14, .14).toDouble();
                });
              },
              onPanEnd: (_) => setState(() {
                _dragging = false;
                _tilt = 0;
              }),
              onPanCancel: () => setState(() {
                _dragging = false;
                _tilt = 0;
              }),
              onTap: () {
                if (_expanded) {
                  _openGuide();
                } else {
                  setState(() => _expanded = true);
                }
              },
              onLongPress: () {
                if (_expanded) setState(() => _expanded = false);
              },
              child: Tooltip(
                message: _expanded
                    ? 'Explícame esta pantalla'
                    : 'Desplegar mini radar de Mr. Healthy',
                child: SizedBox(
                  width: _diameter,
                  height: _diameter,
                  child: Align(
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: _expanded
                          ? SizedBox(
                              key: const ValueKey('healthy-ufo-expanded'),
                              width: _diameter,
                              height: _diameter,
                              child: HealthyUfoVisual(
                                phase: _hover,
                                dragging: _dragging,
                                tilt: _tilt,
                              ),
                            )
                          : AnimatedBuilder(
                              key: const ValueKey('healthy-ufo-mini-radar'),
                              animation: _hover,
                              builder: (context, _) => Container(
                                width: _radarDiameter,
                                height: _radarDiameter,
                                decoration: BoxDecoration(
                                  color: const Color(0xE9162931),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF70E8BB)
                                        .withValues(alpha: .65 + .3 *
                                            math.sin(_hover.value * math.pi * 2)
                                                .abs()),
                                    width: 1.6,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x6632D7A0),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.radar_rounded,
                                      size: 29, color: Color(0xFF80E5BC)),
                                    Transform.rotate(
                                      angle: _hover.value * math.pi * 2,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          width: 4, height: 4,
                                          margin: const EdgeInsets.only(top: 7),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF9BFFE1),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: const SizedBox(width: _diameter, height: _diameter),
    );
  }
}

class _GuideWalkthrough extends StatefulWidget {
  const _GuideWalkthrough({required this.title, required this.steps});
  final String title;
  final List<HealthyGuideStep> steps;
  @override
  State<_GuideWalkthrough> createState() => _GuideWalkthroughState();
}

class _GuideWalkthroughState extends State<_GuideWalkthrough> {
  int _index = 0;

  void _next() {
    if (_index + 1 == widget.steps.length) {
      Navigator.of(context).pop();
      return;
    }
    HealthyRetroSoundService.play('tap');
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22, 10, 22, 22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Image.asset(HealthyUfoVisual.asset, width: 36, height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_awesome_rounded, color: Color(0xFF7547D7))),
            const SizedBox(width: 9),
            Expanded(child: Text('Guía mágica · ${widget.title}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold))),
            IconButton(
              tooltip: 'Cerrar guía',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded)),
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_index + 1) / widget.steps.length,
            minHeight: 5,
          ),
          const SizedBox(height: 14),
          Text('Paso ${_index + 1} de ${widget.steps.length}',
            style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0x227547D7),
              child: Icon(step.icon, color: const Color(0xFF7547D7)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(step.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 12),
          Text(step.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5)),
          const SizedBox(height: 22),
          Row(children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Salir')),
            const Spacer(),
            if (_index > 0)
              TextButton(
                onPressed: () {
                  HealthyRetroSoundService.play('tap');
                  setState(() => _index--);
                },
                child: const Text('Anterior')),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _next,
              icon: Icon(_index + 1 == widget.steps.length
                  ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(_index + 1 == widget.steps.length
                  ? 'Entendido' : 'Siguiente'),
            ),
          ]),
        ],
      ),
    );
  }
}
