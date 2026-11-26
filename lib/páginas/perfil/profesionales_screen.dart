import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tema/healthy_theme.dart';


class ProfesionalesScreen extends StatelessWidget {
  const ProfesionalesScreen({super.key});


  // Perfiles ficticios para la demostración universitaria.
  static const _profesionales = <_Profesional>[
    _Profesional(nombre: 'Nicol Ramírez',
      especialidad: 'Alimentación e hidratación · Perfil de demostración',
      telefono: '+52 000 000 0001', correo: 'nicol.ramirez@example.com',
      horario: 'Lun–vie · 9:00–14:00 (simulado)',
      descripcion: 'Ejemplo de acompañamiento en organización de comidas, hidratación y metas alimentarias. Credenciales y disponibilidad por confirmar para la beta.'),
    _Profesional(nombre: 'Fernando López',
      especialidad: 'Bienestar y hábitos · Perfil de demostración',
      telefono: '+52 000 000 0002', correo: 'fernando.lopez@example.com',
      horario: 'Lun–vie · 15:00–19:00 (simulado)',
      descripcion: 'Ejemplo de seguimiento de rutinas, bienestar y constancia. Credenciales y disponibilidad por confirmar para la beta.'),
  ];

  Future<void> _simular(BuildContext context, _Profesional p, String accion) async {
    final destino = accion == 'Correo' ? p.correo : p.telefono;
    final mensaje = accion == 'WhatsApp'
        ? 'Hola, ${p.nombre}. Te escribo desde Healthy Habit para solicitar información.'
        : accion == 'Correo'
            ? 'Asunto: Consulta desde Healthy Habit\nHola, ${p.nombre}. Solicito información sobre una consulta.'
            : accion == 'Contactos'
                ? 'Ficha de contacto ficticia para la demostración.'
                : 'Vista previa de llamada telefónica.';
    final icono = accion == 'Correo' ? Icons.email_outlined
        : accion == 'WhatsApp' ? Icons.chat_outlined
        : accion == 'Contactos' ? Icons.contacts_outlined : Icons.call_outlined;
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      backgroundColor: HealthyAdaptive.surface,
      builder: (sheet) => SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icono, color: HealthyAdaptive.accent),
            const SizedBox(width: 10), Expanded(child: Text('$accion · Simulación',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: HealthyAdaptive.text)))]),
          const SizedBox(height: 12),
          Text(p.nombre, style: TextStyle(color: HealthyAdaptive.text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SelectableText(destino, style: TextStyle(color: HealthyAdaptive.text)),
          const SizedBox(height: 12),
          Text(mensaje, style: TextStyle(color: HealthyAdaptive.muted, height: 1.4)),
          const SizedBox(height: 12),
          Text('Información ficticia. No se realizará ninguna comunicación real.',
            style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () async {
              final copia = accion == 'Contactos'
                  ? 'BEGIN:VCARD\nVERSION:3.0\nFN:${p.nombre}\nTEL:${p.telefono}\nEMAIL:${p.correo}\nEND:VCARD'
                  : '$destino\n\n$mensaje';
              await Clipboard.setData(ClipboardData(text: copia));
              if (sheet.mounted) Navigator.pop(sheet);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos ficticios copiados.')));
            },
            icon: const Icon(Icons.copy_outlined),
            label: Text(accion == 'Contactos' ? 'Copiar ficha de contacto' : 'Copiar datos de prueba'),
          )),
        ]),
      )),
    );
  }
  Future<void> _llamar(BuildContext c, _Profesional p) => _simular(c, p, 'Llamada');
  Future<void> _whatsapp(BuildContext c, _Profesional p) => _simular(c, p, 'WhatsApp');
  Future<void> _correo(BuildContext c, _Profesional p) => _simular(c, p, 'Correo');
  Future<void> _contactos(BuildContext c, _Profesional p) => _simular(c, p, 'Contactos');

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
                  Text(profesional.descripcion),
                  const SizedBox(height: 10),
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
                        onPressed: () => _contactos(context, profesional),
                        icon: const Icon(Icons.contacts_outlined),
                        label: const Text('Contactos'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _llamar(context, profesional),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Llamar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _whatsapp(context, profesional),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('WhatsApp'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _correo(context, profesional),
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Correo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Los perfiles y contactos son ficticios. Se sustituirán por información autorizada en la versión beta.',
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
              'Demostración de orientación profesional. Los perfiles y contactos son ficticios.',
              style: TextStyle(
                fontSize: 13,
                color: HealthyAdaptive.muted,
                height: 1.3,
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
                    'Mr. Healthy ofrece información general y no sustituye a un profesional de salud. Estos contactos son ejemplos y no ofrecen atención real.',
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
            onTap: () => _llamar(context, profesional),
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
                    onPressed: () => _whatsapp(context, profesional),
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
                    onPressed: () => _correo(context, profesional),
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
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => _contactos(context, profesional),
            icon: const Icon(Icons.contacts_outlined),
            label: const Text('Contactos'),
          )),
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
  final String descripcion;

  const _Profesional({
    required this.nombre,
    required this.especialidad,
    required this.telefono,
    required this.correo,
    required this.horario,
    required this.descripcion,
  });
}
