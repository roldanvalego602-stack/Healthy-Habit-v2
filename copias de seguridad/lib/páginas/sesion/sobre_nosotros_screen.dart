import 'package:flutter/material.dart';

class SobreNosotrosScreen extends StatelessWidget {
  const SobreNosotrosScreen({super.key});

  // ====== EDITA AQUÍ ======
  static const String _correo = 'correo@ejemplo.com';
  static const String _version = '1.0';
  // ========================

  static const List<_Funcion> _funciones = [
    _Funcion(
      icon: Icons.track_changes_rounded,
      titulo: 'Hábitos y rachas',
      texto: 'Crea tus hábitos, cúmplelos cada día y mantén tu racha.',
      color: Color(0xFF00C88C),
      fondo: Color(0xFFE2F7ED),
    ),
    _Funcion(
      icon: Icons.bolt_rounded,
      titulo: 'XP, niveles y logros',
      texto: 'Cada paso suma: sube de nivel y desbloquea logros.',
      color: Color(0xFFC98A00),
      fondo: Color(0xFFFDE89D),
    ),
    _Funcion(
      icon: Icons.emoji_events_rounded,
      titulo: 'Desafíos',
      texto: 'Acepta retos para mantenerte motivado y ganar recompensas.',
      color: Color(0xFF8B5CF6),
      fondo: Color(0xFFF0EBFC),
    ),
    _Funcion(
      icon: Icons.storefront_rounded,
      titulo: 'HabitCoins y tienda',
      texto: 'Canjea tus monedas por banners, marcos y títulos para tu perfil.',
      color: Color(0xFF2B7FD1),
      fondo: Color(0xFFE8F6FC),
    ),
    _Funcion(
      icon: Icons.groups_rounded,
      titulo: 'Amigos',
      texto: 'Sigue a otras personas y comparte tu progreso con quien tú elijas.',
      color: Color(0xFF00C88C),
      fondo: Color(0xFFE2F7ED),
    ),
    _Funcion(
      icon: Icons.smart_toy_outlined,
      titulo: 'Mr. Healthy',
      texto: 'Tu asistente te orienta con dudas frecuentes sobre la app.',
      color: Color(0xFF2B7FD1),
      fondo: Color(0xFFE8F6FC),
    ),
    _Funcion(
      icon: Icons.medical_services_outlined,
      titulo: 'Orientación profesional',
      texto: 'Consulta con nutriólogos y psicólogos capacitados.',
      color: Color(0xFF8B5CF6),
      fondo: Color(0xFFF0EBFC),
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
          'Sobre nosotros',
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
          const _HeaderBanner(version: _version),
          const SizedBox(height: 20),
          const _InfoCard(
            icon: Icons.groups_outlined,
            etiqueta: 'QUIÉNES SOMOS',
            titulo: 'Estudiantes universitarios con una idea',
            texto:
                'Healthy Habit fue creada por estudiantes universitarios con el '
                'fin de ayudar a las personas a mejorar su estilo de vida de '
                'una forma divertida, mediante el seguimiento de hábitos '
                'saludables.',
          ),
          const SizedBox(height: 14),
          const _InfoCard(
            icon: Icons.flag_outlined,
            etiqueta: 'NUESTRA MISIÓN',
            titulo: 'Pequeños pasos, raíces fuertes',
            texto:
                'Creemos que los grandes cambios se construyen con acciones '
                'pequeñas y constantes. Por eso convertimos tus hábitos en un '
                'camino con metas, rachas y recompensas que te motivan a '
                'seguir.',
          ),
          const SizedBox(height: 14),
          const _InfoCard(
            icon: Icons.cake_outlined,
            etiqueta: 'PARA QUIÉN ES',
            titulo: 'Personas de 18 a 40 años',
            texto:
                'La aplicación está dirigida a personas de 18 a 40 años que '
                'quieren cuidar su alimentación y construir mejores rutinas '
                'día a día.',
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Qué puedes hacer en la app',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0E1A30),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                for (var i = 0; i < _funciones.length; i++) ...[
                  _FuncionTile(funcion: _funciones[i]),
                  if (i < _funciones.length - 1)
                    const Divider(
                      height: 1,
                      indent: 18,
                      endIndent: 18,
                      color: Color(0xFFEEF2F0),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _AvisoSalud(),
          const SizedBox(height: 14),
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
                        '¿Quieres contactarnos?',
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
          const Center(
            child: Text(
              'Hecho con 💚 por el equipo de Healthy Habit',
              style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Funcion {
  final IconData icon;
  final String titulo;
  final String texto;
  final Color color;
  final Color fondo;

  const _Funcion({
    required this.icon,
    required this.titulo,
    required this.texto,
    required this.color,
    required this.fondo,
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
  final String version;

  const _HeaderBanner({required this.version});

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.eco_rounded, color: Colors.amber, size: 16),
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
                  'Sobre nosotros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Conoce la historia detrás de la app.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C88C).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Versión $version',
                    style: const TextStyle(
                      color: Color(0xFF00C88C),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            height: 84,
            child: Image.asset(
              'assets/logo/MrHealty.png',
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF00C88C),
                    size: 56,
                  ),
            ),
          ),
        ],
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
            child: Icon(icon, color: color, size: 24),
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
                    etiqueta,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
    );
  }
}

class _FuncionTile extends StatelessWidget {
  final _Funcion funcion;

  const _FuncionTile({required this.funcion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: funcion.fondo,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(funcion.icon, color: funcion.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  funcion.titulo,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0E1A30),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  funcion.texto,
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

class _AvisoSalud extends StatelessWidget {
  const _AvisoSalud();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F7ED),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            color: Color(0xFF00A877),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Healthy Habit es una herramienta de apoyo y seguimiento '
              'personal. Sus recomendaciones no sustituyen la orientación de '
              'un profesional de la salud.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF3F6B5B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
