import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_motion.dart';

class SobreNosotrosScreen extends StatelessWidget {
  const SobreNosotrosScreen({super.key});

  // ====== EDITA AQUÍ TU INFORMACIÓN DE CONTACTO ======
  static const String _correo = ''; // Pendiente de proporcionar por el equipo.
  static const String _telefono = '';
  static const String _sitioWeb = '';
  static const String _redSocial = ''; // No se ha verificado una cuenta oficial.
  static const String _ubicacion = 'Durango, México';
  static const String _version = 'Healthy Habit · Proyecto académico';
  // ====================================================

  // Se emplea el logotipo ya registrado en pubspec.yaml.
  static const List<String> _imgLogo = ['assets/logo/logo.png'];
  static const List<String> _imgMarca = ['assets/logo/logo.png'];
  static const List<String> _imgColores = <String>[];
  static const List<String> _imgIconos = [
    'assets/logo/MrHealty.png',
    'assets/mascot/healthy.png',
  ];

  void _copiar(BuildContext context, String texto) {
    if (texto.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(
        backgroundColor: HealthyAdaptive.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: HealthyAdaptive.text),
        title: Text(
          'Sobre nosotros',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: HealthyAdaptive.text,
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
            icon: Icons.lightbulb_outline_rounded,
            etiqueta: 'NUESTRO ORIGEN',
            titulo: '¿Por qué nació Healthy Habit?',
            texto:
                'Surge de la necesidad de facilitar la organización y el '
                'seguimiento de hábitos saludables. Entre las '
                'responsabilidades escolares, laborales y personales, '
                'mantener un registro constante no es fácil. Por eso '
                'reunimos todo en un solo lugar, para que consultar tu '
                'cumplimiento sea sencillo.',
          ),
          const SizedBox(height: 16),
          const _InfoCard(
            icon: Icons.favorite_border_rounded,
            etiqueta: 'UTILIDAD',
            titulo: 'Una herramienta accesible',
            texto:
                'Te ayuda a organizar tus actividades y reconocer tus '
                'avances mediante una interfaz clara. Apoya tu seguimiento '
                'personal, sin sustituir la orientación de profesionales '
                'de la salud.',
          ),
          const SizedBox(height: 16),
          const _InfoCard(
            icon: Icons.flag_outlined,
            etiqueta: 'OBJETIVO',
            titulo: 'Constancia y progreso visible',
            texto:
                'Facilitar la formación y el seguimiento de hábitos '
                'alimenticios con personalización, gamificación, '
                'retroalimentación y registro respaldado por evidencia, '
                'para favorecer la constancia y que puedas visualizar tu '
                'progreso.',
          ),
          const SizedBox(height: 16),
          const _PilaresRow(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Nuestra identidad', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900,
              color: HealthyAdaptive.text,
            )),
          ),
          HealthyMotionCard(child: _ImagenCard(
            icon: Icons.draw_outlined,
            etiqueta: 'LOGO',
            titulo: 'Creación de nuestro logo',
            texto: 'Nuestro logotipo representa una fruta segmentada y la progresión de los hábitos. Las etapas del proceso de diseño pueden añadirse aquí.',
            imagenes: _imgLogo,
            altura: 180,
          )),
          const SizedBox(height: 16),
          HealthyMotionCard(child: _ImagenCard(
            icon: Icons.verified_outlined,
            etiqueta: 'MARCA',
            titulo: 'Nuestra marca',
            texto: 'La identidad visual de Healthy Habit.',
            imagenes: _imgMarca,
            altura: 180,
          )),
          const SizedBox(height: 16),
          HealthyMotionCard(child: _ImagenCard(
            icon: Icons.palette_outlined,
            etiqueta: 'COLORES',
            titulo: 'Nuestros colores',
            texto: 'Paleta de colores de la aplicación.',
            imagenes: _imgColores,
            altura: 140,
            extra: _PaletaColores(),
          )),
          const SizedBox(height: 16),
          HealthyMotionCard(child: _ImagenCard(
            icon: Icons.interests_outlined,
            etiqueta: 'ICONOS',
            titulo: 'Elaboración de iconos',
            texto: 'Logotipo y mascota utilizados en Healthy Habit.',
            imagenes: _imgIconos,
            altura: 100,
            minimoEspacios: 2,
          )),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Contacto',
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
                if (_correo.isEmpty && _telefono.isEmpty && _sitioWeb.isEmpty && _redSocial.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Los canales oficiales de contacto aún no están configurados.', style: TextStyle(color: HealthyAdaptive.muted)),
                  ),
                if (_correo.isNotEmpty)
                _ContactTile(
                  icon: Icons.mail_outline_rounded,
                  label: 'Correo electrónico',
                  value: _correo,
                  onTap: () => _copiar(context, _correo),
                ),
                const _Divisor(),
                if (_telefono.isNotEmpty)
                _ContactTile(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: _telefono,
                  onTap: () => _copiar(context, _telefono),
                ),
                const _Divisor(),
                if (_sitioWeb.isNotEmpty)
                _ContactTile(
                  icon: Icons.language_rounded,
                  label: 'Sitio web',
                  value: _sitioWeb,
                  onTap: () => _copiar(context, _sitioWeb),
                ),
                const _Divisor(),
                if (_redSocial.isNotEmpty)
                _ContactTile(
                  icon: Icons.alternate_email_rounded,
                  label: 'Redes sociales',
                  value: _redSocial,
                  onTap: () => _copiar(context, _redSocial),
                ),
                const _Divisor(),
                _ContactTile(
                  icon: Icons.location_on_outlined,
                  label: 'Ubicación',
                  value: _ubicacion,
                  onTap: () => _copiar(context, _ubicacion),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              _version,
              style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: HealthyAdaptive.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: HealthyAdaptive.border),
    boxShadow: [
      BoxShadow(
        color: HealthyAdaptive.isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.025),
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
          Row(
            children: [
              const Icon(Icons.eco_outlined, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              const Expanded(
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
            'Construye hábitos, paso a paso',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Organiza tu día, sigue tu progreso y celebra cada avance.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge('Seguimiento', const Color(0xFF00C88C)),
              _badge('Gamificación', Colors.amber),
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

class _PilaresRow extends StatelessWidget {
  const _PilaresRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pilar('Personalización', Color(0xFFE2F7ED), Color(0xFF00A875)),
        _Pilar('Gamificación', Color(0xFFFDE89D), Colors.orange),
        _Pilar('Retroalimentación', Color(0xFFE8F6FC), Color(0xFF2B7FD1)),
        _Pilar('Evidencia', Color(0xFFF3E8FF), Colors.purple),
      ],
    );
  }
}

class _Pilar extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Pilar(this.label, this.background, this.foreground);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF2B7FD1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A869A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E1A30),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.copy_rounded,
              size: 16,
              color: Color(0xFF7A869A),
            ),
          ],
        ),
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


/// Tarjetas con imágenes reales cuando están registradas en los assets.
/// Las imágenes no proporcionadas muestran una indicación explícita.
class _ImagenCard extends StatelessWidget {
  const _ImagenCard({
    required this.icon,
    required this.etiqueta,
    required this.titulo,
    required this.texto,
    required this.imagenes,
    this.altura = 160,
    this.minimoEspacios = 1,
    this.extra,
  });
  final IconData icon;
  final String etiqueta;
  final String titulo;
  final String texto;
  final List<String> imagenes;
  final double altura;
  final int minimoEspacios;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final count = imagenes.length > minimoEspacios ? imagenes.length : minimoEspacios;
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
              color: HealthyAdaptive.water,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(etiqueta, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: HealthyAdaptive.waterInk,
            )),
          ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: HealthyAdaptive.water,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: HealthyAdaptive.waterInk, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900,
                  color: HealthyAdaptive.text,
                )),
                const SizedBox(height: 4),
                Text(texto, style: TextStyle(
                  fontSize: 12.5, height: 1.45,
                  color: HealthyAdaptive.muted,
                )),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          if (count == 1)
            _EspacioImagen(ruta: imagenes.isEmpty ? null : imagenes.first, altura: altura)
          else LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 320 ? 2 : 3;
              final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10, runSpacing: 10,
                children: List.generate(count, (i) => SizedBox(
                  width: width,
                  child: _EspacioImagen(
                    ruta: i < imagenes.length ? imagenes[i] : null,
                    altura: altura,
                  ),
                )),
              );
            },
          ),
          if (extra != null) ...[const SizedBox(height: 14), extra!],
        ],
      ),
    );
  }
}

class _EspacioImagen extends StatelessWidget {
  const _EspacioImagen({required this.ruta, required this.altura});
  final String? ruta;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: double.infinity, height: altura,
      decoration: BoxDecoration(
        color: HealthyAdaptive.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HealthyAdaptive.border),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, size: 28, color: HealthyAdaptive.muted),
        const SizedBox(height: 6),
        Text('Imagen próximamente', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: HealthyAdaptive.muted)),
      ]),
    );
    if (ruta == null || ruta!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        ruta!, width: double.infinity, height: altura,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _PaletaColores extends StatelessWidget {
  const _PaletaColores();
  static const colores = <String, Color>{
    '#0F2D38': Color(0xFF0F2D38),
    '#2B7FD1': Color(0xFF2B7FD1),
    '#00C88C': Color(0xFF00C88C),
    '#FFC107': Color(0xFFFFC107),
    '#0E1A30': Color(0xFF0E1A30),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14, runSpacing: 10,
      children: colores.entries.map((entry) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(
            color: entry.value, shape: BoxShape.circle,
            border: Border.all(color: HealthyAdaptive.border),
          )),
          const SizedBox(height: 4),
          Text(entry.key, style: TextStyle(
            fontSize: 10, color: HealthyAdaptive.muted)),
        ],
      )).toList(),
    );
  }
}
