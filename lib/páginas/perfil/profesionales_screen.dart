import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../tema/healthy_theme.dart';

/// Recursos externos reales. No se muestran profesionales ficticios
/// ni se ofrecen citas o afiliaciones que Healthy Habit no gestiona.
class ProfesionalesScreen extends StatelessWidget {
  const ProfesionalesScreen({super.key});

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
