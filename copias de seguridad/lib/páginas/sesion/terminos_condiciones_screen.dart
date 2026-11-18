import 'package:flutter/material.dart';

class TerminosCondicionesScreen extends StatelessWidget {
  const TerminosCondicionesScreen({super.key});

  // ====== EDITA AQUÍ ======
  static const String _correo = 'correo@ejemplo.com';
  static const String _vigencia = '4 de noviembre de 2026';
  static const String _version = '1.0';
  // ========================

  static const List<_Seccion> _secciones = [
    _Seccion(
      icon: Icons.handshake_outlined,
      titulo: 'Aceptación de los términos',
      texto:
          'Al crear una cuenta o usar Healthy Habit, aceptas estos Términos y '
          'Condiciones. Si no estás de acuerdo con ellos, te pedimos que no '
          'uses la aplicación.',
    ),
    _Seccion(
      icon: Icons.groups_outlined,
      titulo: 'Quiénes somos',
      texto:
          'Healthy Habit fue creada por estudiantes universitarios con el fin '
          'de ayudar a las personas a mejorar su estilo de vida de una forma '
          'divertida, mediante el seguimiento de hábitos saludables.',
    ),
    _Seccion(
      icon: Icons.verified_user_outlined,
      titulo: 'Requisitos de uso',
      texto:
          'La aplicación está dirigida a personas de 18 a 40 años. La edad '
          'mínima para usarla es de 18 años. Al registrarte, declaras que '
          'cumples con este requisito.',
    ),
    _Seccion(
      icon: Icons.person_outline_rounded,
      titulo: 'Cuenta y perfil',
      texto:
          'Puedes registrarte, iniciar sesión y crear o editar un perfil con '
          'tus objetivos y preferencias. Eres responsable de mantener la '
          'confidencialidad de tu cuenta y de que la información que '
          'proporcionas sea veraz.',
    ),
    _Seccion(
      icon: Icons.checklist_rounded,
      titulo: 'Uso de la aplicación',
      texto:
          'Puedes agregar, modificar y eliminar tus hábitos, y consultar tus '
          'rachas, XP, niveles, logros y desafíos. Estas funciones están '
          'pensadas para apoyar tu constancia y mostrarte tu progreso.',
    ),
    _Seccion(
      icon: Icons.monetization_on_outlined,
      titulo: 'HabitCoins',
      texto:
          'Las HabitCoins son monedas propias de la aplicación. No son dinero '
          'real, no tienen valor monetario y no pueden canjearse por dinero '
          'ni transferirse fuera de la app.',
    ),
    _Seccion(
      icon: Icons.attach_file_rounded,
      titulo: 'Evidencias',
      texto:
          'Puedes adjuntar evidencias de forma opcional en ciertos registros. '
          'Solo tú puedes verlas y nadie más puede usarlas. La aplicación '
          'rechaza cualquier evidencia que no esté relacionada con tus '
          'hábitos.',
    ),
    _Seccion(
      icon: Icons.smart_toy_outlined,
      titulo: 'Asistente de IA',
      texto:
          'El asistente es propio de la aplicación y te ayuda con dudas '
          'frecuentes, orientación contextual y consulta de tu perfil. Las '
          'conversaciones no se guardan. El asistente filtra groserías e '
          'insultos, y sus respuestas son solo orientativas.',
    ),
    _Seccion(
      icon: Icons.health_and_safety_outlined,
      titulo: 'Recomendaciones y salud',
      texto:
          'La aplicación ofrece recomendaciones según tus objetivos y '
          'progreso. Estas no sustituyen la orientación de un profesional de '
          'la salud. Ante cualquier condición médica o duda sobre tu '
          'alimentación, consulta a un especialista.',
    ),
    _Seccion(
      icon: Icons.lock_outline_rounded,
      titulo: 'Datos personales',
      texto:
          'Tus datos se utilizan únicamente para el funcionamiento de la '
          'aplicación y no se comparten con terceros. Se conservan mientras '
          'tu cuenta esté activa. Para más detalle, consulta el Aviso de '
          'Privacidad.',
    ),
    _Seccion(
      icon: Icons.rule_rounded,
      titulo: 'Conducta del usuario',
      texto:
          'Te comprometes a usar la aplicación de forma respetuosa y lícita, '
          'sin usar lenguaje ofensivo ni subir contenido ajeno a tus hábitos '
          'o contrario a la ley.',
    ),
    _Seccion(
      icon: Icons.delete_outline_rounded,
      titulo: 'Eliminación de cuenta',
      texto:
          'Puedes eliminar tu cuenta en cualquier momento desde la ventana de '
          'usuario, donde encontrarás las opciones disponibles para tu '
          'cuenta. Al eliminarla, tu información se borra de la base de '
          'datos.',
    ),
    _Seccion(
      icon: Icons.gavel_rounded,
      titulo: 'Limitación de responsabilidad',
      texto:
          'Healthy Habit es una herramienta de apoyo y seguimiento personal. '
          'No garantizamos resultados específicos de salud, y no nos '
          'hacemos responsables por decisiones tomadas con base en la '
          'información o recomendaciones de la aplicación.',
    ),
    _Seccion(
      icon: Icons.edit_note_rounded,
      titulo: 'Cambios a estos términos',
      texto:
          'Si estos términos se actualizan, se informará dentro de la '
          'aplicación. El uso continuado después del aviso implica la '
          'aceptación de los cambios.',
    ),
    _Seccion(
      icon: Icons.balance_rounded,
      titulo: 'Ley aplicable',
      texto:
          'Estos términos se rigen por las leyes de México. Cualquier '
          'controversia se resolverá conforme a la legislación mexicana '
          'aplicable.',
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
          'Términos y condiciones',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0E1A30),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const _HeaderBanner(vigencia: _vigencia, version: _version),
          const SizedBox(height: 20),
          for (var i = 0; i < _secciones.length; i++) ...[
            _SeccionCard(numero: i + 1, seccion: _secciones[i]),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    size: 20,
                    color: Color(0xFF2B7FD1),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Tienes dudas sobre estos términos?',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7A869A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _correo,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0E1A30),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Seccion {
  final IconData icon;
  final String titulo;
  final String texto;

  const _Seccion({
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
  final String vigencia;
  final String version;

  const _HeaderBanner({required this.vigencia, required this.version});

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
              Icon(Icons.description_outlined, color: Colors.amber, size: 16),
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
            'Términos y condiciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lee las reglas básicas para usar la aplicación.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge('Vigente: $vigencia', const Color(0xFF00C88C)),
              _badge('Versión $version', Colors.amber),
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

class _SeccionCard extends StatelessWidget {
  final int numero;
  final _Seccion seccion;

  const _SeccionCard({required this.numero, required this.seccion});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2B7FD1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(seccion.icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'SECCIÓN $numero',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  seccion.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0E1A30),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  seccion.texto,
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
    );
  }
}