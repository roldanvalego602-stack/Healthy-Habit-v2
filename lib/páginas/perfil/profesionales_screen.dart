import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import 'package:url_launcher/url_launcher.dart';


class ProfesionalesScreen extends StatelessWidget {
  const ProfesionalesScreen({super.key});

  // Estos perfiles son ejemplos: nunca deben poder iniciarse llamadas a ellos.
  static const _profesionales = <_Profesional>[
    _Profesional(
      nombre: 'Laura Méndez',
      especialidad: 'Nutrición · consulta externa',
      telefono: '+1111111111',
      correo: 'laura.mendez@example.com',
      horario: 'Lun–vie · 9:00–17:00 (hora local)',
    ),
    _Profesional(
      nombre: 'Daniel Ríos',
      especialidad: 'Nutrición · consulta externa',
      telefono: '+111111111',
      correo: 'daniel.rios@example.com',
      horario: 'Lun–jue · 10:00–18:00 (hora local)',
    ),
  ];

  Future<void> _abrirEnlace(BuildContext context, Uri uri, String error) async {
    try {
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!abierto && context.mounted) _mostrarError(context, error);
    } catch (_) {
      if (context.mounted) _mostrarError(context, error);
    }
  }

  void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _llamar(BuildContext context, _Profesional profesional) async {
    if (profesional.esEjemplo) {
      _mostrarError(context, 'Contacto de ejemplo: aún no hay un número verificado.');
      return;
    }
    final numero = profesional.telefono.replaceAll(RegExp(r'[^\d+]'), '');
    if (numero.isEmpty) {
      _mostrarError(context, 'Este profesional no tiene teléfono registrado.');
      return;
    }
    await _abrirEnlace(
      context,
      Uri(scheme: 'tel', path: numero),
      'No se pudo abrir la aplicación de llamadas.',
    );
  }

  Future<void> _whatsapp(BuildContext context, _Profesional profesional) async {
    if (profesional.esEjemplo) {
      _mostrarError(context, 'Contacto de ejemplo: WhatsApp no está disponible.');
      return;
    }
    final numero = profesional.telefono.replaceAll(RegExp(r'\D'), '');
    if (numero.isEmpty) {
      _mostrarError(context, 'Este profesional no tiene teléfono registrado.');
      return;
    }
    final mensaje = Uri.encodeComponent(
      'Hola, ${profesional.nombre}. Te contacto desde Healthy Habit para solicitar información sobre una consulta.',
    );
    await _abrirEnlace(
      context,
      Uri.parse('https://wa.me/$numero?text=$mensaje'),
      'No se pudo abrir WhatsApp. Comprueba que el número sea válido y tenga WhatsApp.',
    );
  }

  Future<void> _correo(BuildContext context, _Profesional profesional) async {
    if (profesional.esEjemplo) {
      _mostrarError(context, 'Contacto de ejemplo: todavía no existe un correo verificado.');
      return;
    }
    if (profesional.correo.trim().isEmpty) {
      _mostrarError(
        context,
        'Aún no se ha configurado el correo de ${profesional.nombre}.',
      );
      return;
    }
    await _abrirEnlace(
      context,
      Uri(
        scheme: 'mailto',
        path: profesional.correo,
        query: _encodeQueryParameters({
          'subject': 'Consulta desde Healthy Habit',
          'body':
              'Hola, ${profesional.nombre}.\n\nQuisiera recibir información sobre sus servicios profesionales.\n',
        }),
      ),
      'No se pudo abrir una aplicación de correo electrónico.',
    );
  }

  String _encodeQueryParameters(Map<String, String> params) => params.entries
      .map(
        (entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
      )
      .join('&');

  void _verInformacion(BuildContext context, _Profesional profesional) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profesional.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(profesional.especialidad),
                  const SizedBox(height: 12),
                  Text('Horario: ${profesional.horario}'),
                  const SizedBox(height: 8),
                  Text('Teléfono: ${profesional.telefono}'),
                  const SizedBox(height: 8),
                  Text(
                    'Correo: ${profesional.correo.isEmpty ? 'No disponible' : profesional.correo}',
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: profesional.esEjemplo ? null : () => _llamar(context, profesional),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Llamar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: profesional.esEjemplo ? null : () => _whatsapp(context, profesional),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('WhatsApp'),
                      ),
                      OutlinedButton.icon(
                        onPressed: profesional.esEjemplo ? null : () => _correo(context, profesional),
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Correo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Healthy Habit no verifica automáticamente la disponibilidad de estos contactos. Confirma sus credenciales antes de contratar una consulta.',
                    style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: HealthyAdaptive.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Orientación profesional',
          style: TextStyle(
            color: HealthyAdaptive.text,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contactos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: HealthyAdaptive.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Directorio demostrativo. Aún no tenemos profesionales verificados ni citas disponibles desde Healthy Habit.',
              style: TextStyle(
                fontSize: 13,
                color: HealthyAdaptive.muted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HealthyAdaptive.yellow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Los nombres, horarios, teléfonos y correos siguientes son ejemplos. '
                'No representan profesionales afiliados y las acciones de contacto están deshabilitadas.',
                style: TextStyle(color: HealthyAdaptive.text,
                  fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            for (final profesional in _profesionales) ...[
              _buildProfessionalCard(context, profesional),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HealthyAdaptive.lavender,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '¿Necesitas orientación profesional?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: HealthyAdaptive.text,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mr. Healthy ofrece información general y no sustituye a un profesional de salud. Estos contactos externos son para orientación individual.',
                    style: TextStyle(
                      fontSize: 13,
                      color: HealthyAdaptive.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard(
    BuildContext context,
    _Profesional profesional,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HealthyAdaptive.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: HealthyAdaptive.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: HealthyAdaptive.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profesional.nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: HealthyAdaptive.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profesional.especialidad,
                      style: TextStyle(
                        fontSize: 12,
                        color: HealthyAdaptive.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: profesional.esEjemplo ? null : () => _llamar(context, profesional),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.call_outlined,
                    size: 17,
                    color: HealthyAdaptive.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tel. ${profesional.telefono}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HealthyAdaptive.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profesional.horario,
            style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: profesional.esEjemplo ? null : () => _whatsapp(context, profesional),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HealthyAdaptive.mint,
                      foregroundColor: HealthyAdaptive.text,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: profesional.esEjemplo ? null : () => _correo(context, profesional),
                    icon: const Icon(Icons.email_outlined, size: 17),
                    label: const Text(
                      'Correo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HealthyAdaptive.text,
                      side: BorderSide(color: HealthyAdaptive.border),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _verInformacion(context, profesional),
              child: const Text('Ver información'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Profesional {
  final String nombre;
  final String especialidad;
  final String telefono;
  final String correo;
  final String horario;
  bool get esEjemplo => correo.endsWith('@example.com') ||
      telefono.startsWith('+111');

  const _Profesional({
    required this.nombre,
    required this.especialidad,
    required this.telefono,
    required this.correo,
    required this.horario,
  });
}
