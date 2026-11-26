import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../tema/healthy_theme.dart';

/// Perfiles de muestra y recursos verificables para futuras consultas.
/// No se realizan llamadas ni envíos a contactos ficticios.
class ProfesionalesScreen extends StatelessWidget {
  const ProfesionalesScreen({super.key});

  static const demoProfiles = <({
    String name, String area, String phone, String email, String hours,
    String description
  })>[
    (
      name: 'Nicol Ramírez',
      area: 'Alimentación e hidratación · Ejemplo',
      phone: '+52 000 000 0001',
      email: 'nicol.ramirez@example.com',
      hours: 'Lun–vie · 9:00–14:00 (simulado)',
      description: 'Perfil de ejemplo para orientación sobre organización de comidas, hidratación y metas alimentarias. No se han verificado credenciales ni disponibilidad.',
    ),
    (
      name: 'Fernando López',
      area: 'Hábitos y bienestar · Ejemplo',
      phone: '+52 000 000 0002',
      email: 'fernando.lopez@example.com',
      hours: 'Lun–vie · 15:00–19:00 (simulado)',
      description: 'Perfil de ejemplo para constancia y organización de rutinas saludables. No se han verificado credenciales ni disponibilidad.',
    ),
  ];

  Future<void> _demoAction(
    BuildContext context,
    ({String name, String area, String phone, String email,
      String hours, String description}) profile,
    String action,
  ) async {
    final destination = action == 'Correo' ? profile.email : profile.phone;
    final detail = action == 'WhatsApp'
        ? 'Hola, ${profile.name}. Quiero información desde Healthy Habit.'
        : action == 'Correo'
            ? 'Asunto: Consulta desde Healthy Habit\nHola, ${profile.name}. Quisiera información sobre sus servicios.'
            : action == 'Contactos'
                ? 'Ficha de contacto de ejemplo, lista para copiar.'
                : 'Vista previa de la llamada.';
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: HealthyAdaptive.surface,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$action · Demostración',
              style: TextStyle(color: HealthyAdaptive.text,
                fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 12),
            Text(profile.name, style: TextStyle(
              color: HealthyAdaptive.text, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SelectableText(destination, style: TextStyle(
              color: HealthyAdaptive.text)),
            const SizedBox(height: 10),
            Text(detail, style: TextStyle(color: HealthyAdaptive.muted)),
            const SizedBox(height: 12),
            Text('Datos ficticios. No se enviará ningún mensaje, llamada o correo.',
              style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () async {
                final content = action == 'Contactos'
                    ? 'BEGIN:VCARD\nVERSION:3.0\nFN:${profile.name}\nTEL:${profile.phone}\nEMAIL:${profile.email}\nEND:VCARD'
                    : '$destination\n\n$detail';
                await Clipboard.setData(ClipboardData(text: content));
                if (sheet.mounted) Navigator.pop(sheet);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Datos de muestra copiados.')));
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar datos de muestra'),
            )),
          ],
        ),
      )),
    );
  }

  Widget _demoProfileCard(
    BuildContext context,
    ({String name, String area, String phone, String email,
      String hours, String description}) profile,
  ) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: HealthyAdaptive.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: HealthyAdaptive.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.person_pin_circle_outlined,
            color: HealthyAdaptive.accent, size: 30),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: TextStyle(
                color: HealthyAdaptive.text, fontWeight: FontWeight.w900,
                fontSize: 17)),
              Text(profile.area, style: TextStyle(
                color: HealthyAdaptive.muted, fontSize: 12)),
            ],
          )),
        ]),
        const SizedBox(height: 12),
        Text(profile.description, style: TextStyle(
          color: HealthyAdaptive.muted, fontSize: 13)),
        const SizedBox(height: 8),
        Text(profile.hours, style: TextStyle(
          color: HealthyAdaptive.text, fontSize: 12)),
        const SizedBox(height: 6),
        Text(profile.phone, style: TextStyle(
          color: HealthyAdaptive.accent)),
        Text(profile.email, style: TextStyle(
          color: HealthyAdaptive.muted, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 6, children: [
          OutlinedButton.icon(
            onPressed: () => _demoAction(context, profile, 'WhatsApp'),
            icon: const Icon(Icons.chat_outlined, size: 17),
            label: const Text('WhatsApp')),
          OutlinedButton.icon(
            onPressed: () => _demoAction(context, profile, 'Llamada'),
            icon: const Icon(Icons.call_outlined, size: 17),
            label: const Text('Llamar')),
          OutlinedButton.icon(
            onPressed: () => _demoAction(context, profile, 'Correo'),
            icon: const Icon(Icons.email_outlined, size: 17),
            label: const Text('Correo')),
          OutlinedButton.icon(
            onPressed: () => _demoAction(context, profile, 'Contactos'),
            icon: const Icon(Icons.contacts_outlined, size: 17),
            label: const Text('Contactos')),
        ]),
      ],
    ),
  );


  static final Uri _directorio = Uri.parse(
    'https://cmnutriologos.com/directorio/',
  );
  static final Uri _cedulas = Uri.parse(
    'https://www.gob.mx/cedulaprofesional/es',
  );

  Future<void> _abrir(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(
        uri, mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el sitio. '
              'Comprueba tu conexión o el navegador del dispositivo.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace externo.')),
        );
      }
    }
  }

  Widget _resource(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String button,
    required Uri url,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: HealthyAdaptive.surface,
      border: Border.all(color: HealthyAdaptive.border),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HealthyAdaptive.mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 25, color: HealthyAdaptive.accent),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(
            color: HealthyAdaptive.text,
            fontSize: 16, fontWeight: FontWeight.w900,
          ))),
        ]),
        const SizedBox(height: 10),
        Text(subtitle, style: TextStyle(
          color: HealthyAdaptive.muted,
          fontSize: 13, height: 1.45,
        )),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _abrir(context, url),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(button),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(
        title: const Text('Orientación profesional',
          style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: HealthyAdaptive.background,
        foregroundColor: HealthyAdaptive.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Profesionales · Demostración',
            style: TextStyle(fontWeight: FontWeight.w900,
              color: HealthyAdaptive.text, fontSize: 21)),
          const SizedBox(height: 6),
          Text('Nicol y Fernando son perfiles simulados. Los cuatro botones '
              'permiten mostrar y copiar datos de prueba sin contactar a nadie.',
            style: TextStyle(color: HealthyAdaptive.muted, fontSize: 13)),
          const SizedBox(height: 16),
          for (final profile in demoProfiles) ...[
            _demoProfileCard(context, profile),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 14),
          Text('Recursos externos para localizar profesionales reales',
            style: TextStyle(fontWeight: FontWeight.w900,
              color: HealthyAdaptive.text, fontSize: 17)),
          const SizedBox(height: 10),
          Text('Encuentra orientación especializada',
            style: TextStyle(color: HealthyAdaptive.text,
              fontWeight: FontWeight.w900, fontSize: 21)),
          const SizedBox(height: 9),
          Text(
            'Healthy Habit no ofrece citas, consultas ni profesionales '
            'afiliados actualmente. Estos recursos externos permiten '
            'buscar profesionales y consultar sus credenciales.',
            style: TextStyle(color: HealthyAdaptive.muted,
              fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          _resource(
            context,
            icon: Icons.health_and_safety_outlined,
            title: 'Directorio de nutriólogos',
            subtitle: 'Consulta el directorio público del Colegio Mexicano '
              'de Nutriólogos. La disponibilidad y contratación se realizan '
              'fuera de Healthy Habit.',
            button: 'Abrir directorio',
            url: _directorio,
          ),
          const SizedBox(height: 14),
          _resource(
            context,
            icon: Icons.verified_user_outlined,
            title: 'Verificar cédula profesional',
            subtitle: 'Consulta los servicios de la Secretaría de Educación '
              'Pública de México para verificar datos de cédulas profesionales '
              'antes de contratar una consulta.',
            button: 'Consultar cédulas (SEP)',
            url: _cedulas,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HealthyAdaptive.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Mr. Healthy proporciona información general de hábitos, '
              'no diagnósticos ni tratamientos. Para indicaciones '
              'individuales, consulta directamente a un profesional '
              'de la salud acreditado.',
              style: TextStyle(color: HealthyAdaptive.text,
                fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
