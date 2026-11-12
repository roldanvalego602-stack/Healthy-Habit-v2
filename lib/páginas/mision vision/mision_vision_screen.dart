import 'package:flutter/material.dart';

class MisionVisionScreen extends StatelessWidget {
  const MisionVisionScreen({super.key});

  static const List<_Principio> _principios = [
    _Principio(
      icon: Icons.touch_app_outlined,
      titulo: 'Sencillez',
      texto:
          'Una interfaz clara, con botones y opciones comprensibles, para '
          'que las tareas principales se hagan sin pasos innecesarios.',
    ),
    _Principio(
      icon: Icons.emoji_events_outlined,
      titulo: 'Motivación',
      texto:
          'Niveles, experiencia, logros y desafíos que hacen divertido '
          'mantener la constancia y evitan el abandono de los hábitos.',
    ),
    _Principio(
      icon: Icons.verified_outlined,
      titulo: 'Confiabilidad',
      texto:
          'Registros respaldados por evidencia opcional, sin pérdida ni '
          'duplicación de tu progreso.',
    ),
    _Principio(
      icon: Icons.lock_outline_rounded,
      titulo: 'Privacidad',
      texto:
          'Protegemos tus credenciales y datos personales, y te informamos '
          'qué se recopila y cómo puedes controlarlo.',
    ),
    _Principio(
      icon: Icons.health_and_safety_outlined,
      titulo: 'Responsabilidad',
      texto:
          'Somos una herramienta de apoyo: no sustituimos la orientación '
          'de profesionales de la salud.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0E1A30)),
        title: const Text(
          'Misión y visión',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0E1A30),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const _HeaderBanner(),
          const SizedBox(height: 20),
          const _InfoCard(
            icon: Icons.flag_outlined,
            etiqueta: 'MISIÓN',
            titulo: 'Qué hacemos y para quién',
            texto:
                'Facilitar la formación y el seguimiento de hábitos '
                'saludables, en especial los alimenticios, mediante '
                'personalización, gamificación, retroalimentación y registro '
                'respaldado por evidencia, para favorecer tu constancia y '
                'que puedas visualizar tu progreso de una forma sencilla y '
                'divertida.',
          ),
          const SizedBox(height: 16),
          const _InfoCard(
            icon: Icons.visibility_outlined,
            etiqueta: 'VISIÓN',
            titulo: 'Hacia dónde vamos',
            texto:
                'Ser una herramienta accesible y confiable que acompañe a '
                'las personas en la construcción de un estilo de vida más '
                'saludable, que crezca con nuevas categorías de hábitos y '
                'que ayude a cada usuario a reconocer sus avances y mantener '
                'la constancia en el tiempo.',
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Nuestros principios',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0E1A30),
              ),
            ),
          ),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                for (var i = 0; i < _principios.length; i++) ...[
                  _PrincipioTile(principio: _principios[i]),
                  if (i < _principios.length - 1) const _Divisor(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Principio {
  final IconData icon;
  final String titulo;
  final String texto;

  const _Principio({
    required this.icon,
    required this.titulo,
    required this.texto,
  });
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.025),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2D38), Color(0xFF1E424D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_outlined, color: Colors.amber, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'HEALTHY HABIT',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nuestra misión y visión',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lo que nos mueve y hacia dónde queremos llegar.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge('Constancia', const Color(0xFF00C88C)),
              _badge('Progreso', Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String etiqueta;
  final String titulo;
  final String texto;

  const _InfoCard({
    required this.icon,
    required this.etiqueta,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2B7FD1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              etiqueta,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6FC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E1A30),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      texto,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF7A869A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrincipioTile extends StatelessWidget {
  final _Principio principio;

  const _PrincipioTile({required this.principio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              principio.icon,
              size: 20,
              color: const Color(0xFF2B7FD1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  principio.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0E1A30),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  principio.texto,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF7A869A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 68, color: Colors.grey.shade200);
  }
}
