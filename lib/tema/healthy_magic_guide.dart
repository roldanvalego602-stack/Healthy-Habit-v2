import 'package:flutter/material.dart';
import 'cosmos_theme.dart';
import 'healthy_theme.dart';
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

class _HealthyMagicGuideButtonState extends State<HealthyMagicGuideButton> {
  static const double _diameter = 72;
  static const double _margin = 12;

  // Mantiene la última ubicación cuando el usuario cambia de sección.
  // El valor es relativo al área disponible para adaptarse a otros tamaños.
  static Offset? _savedRelativePosition;

  final OverlayPortalController _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (overlayContext) {
        final media = MediaQuery.of(overlayContext);
        final screen = media.size;
        final minX = _margin;
        final minY = media.padding.top + _margin;
        final maxX = (screen.width - _diameter - _margin)
            .clamp(minX, double.infinity).toDouble();
        final maxY = (screen.height -
                media.padding.bottom -
                media.viewInsets.bottom -
                _diameter -
                _margin)
            .clamp(minY, double.infinity).toDouble();
        final relative = _savedRelativePosition;
        final x = relative == null
            ? minX
            : (minX + (maxX - minX) * relative.dx).clamp(minX, maxX)
                .toDouble();
        final y = relative == null
            ? (maxY - 72).clamp(minY, maxY).toDouble()
            : (minY + (maxY - minY) * relative.dy).clamp(minY, maxY)
                .toDouble();

        return Positioned(
          left: x,
          top: y,
          child: Semantics(
            label: 'Guía de esta pantalla. Mantén pulsado y arrastra para mover.',
            button: true,
            child: GestureDetector(
              onPanUpdate: (details) {
                final nx = (x + details.delta.dx).clamp(minX, maxX).toDouble();
                final ny = (y + details.delta.dy).clamp(minY, maxY).toDouble();
                setState(() {
                  _savedRelativePosition = Offset(
                    maxX > minX ? (nx - minX) / (maxX - minX) : 0,
                    maxY > minY ? (ny - minY) / (maxY - minY) : 0,
                  );
                });
              },
              onTap: () => HealthyMagicGuide.open(context, widget.section),
              child: Tooltip(
                message: 'Explícame esta pantalla',
                child: SizedBox(
                  width: _diameter,
                  height: _diameter,
                  child: Image.asset(
                    'assets/UFO/Mascota de Hábitos Saludables en Ovni.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) =>
                        DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HealthyAdaptive.isCosmos
                            ? CosmosPalette.cyan
                            : const Color(0xFF7547D7),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      // El botón real se pinta sobre la ruta; este espacio solo conserva
      // compatibilidad con los Scaffold existentes.
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
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7547D7)),
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
