import 'package:flutter/material.dart';

class SelectorBienestarCatalogo extends StatelessWidget {
  const SelectorBienestarCatalogo({
    super.key,
    required this.seleccionado,
    required this.onSeleccionar,
  });

  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  static const opciones = <(String, IconData, String)>[
    ('Sueño y recuperación', Icons.bedtime_rounded,
      'Descanso, sueño y recuperación después de la actividad'),
    ('Prevención y seguridad', Icons.shield_outlined,
      'Consejos para prevenir accidentes y reducir riesgos'),
    ('Bienestar cotidiano', Icons.self_improvement_rounded,
      'Movimiento, postura y pequeñas pausas'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Elige qué quieres mejorar',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final (group, icon, description) in opciones)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: seleccionado == group
                  ? colors.primaryContainer : colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                key: ValueKey('wellness-$group'),
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSeleccionar(
                    seleccionado == group ? null : group),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                      child: Icon(icon, color: colors.primary, size: 25),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group, style: const TextStyle(
                          fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(description, style:
                          Theme.of(context).textTheme.bodySmall),
                      ],
                    )),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 17),
                  ]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class JarraBuenBeberCatalogo extends StatelessWidget {
  const JarraBuenBeberCatalogo({
    super.key,
    required this.seleccionado,
    required this.onSeleccionar,
  });
  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  static const niveles = <(String, Color, IconData)>[
    ('Agua simple', Color(0xFF5CB6D7), Icons.water_drop_outlined),
    ('Opciones sin azúcar', Color(0xFF5FC29D), Icons.local_cafe_outlined),
    ('Bebidas nutritivas', Color(0xFFE9BC69), Icons.local_drink_outlined),
    ('Bebidas con azúcares', Color(0xFFE8918D), Icons.warning_amber_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Jarra del Buen Beber: explora las bebidas',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Selecciona un grupo. Los colores indican tipos de bebidas, '
          'no cantidades recomendadas ni equivalencias nutricionales.',
          style: theme.textTheme.bodySmall),
        const SizedBox(height: 14),
        for (var i = 0; i < niveles.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: i * 9.0, vertical: 3,
            ),
            child: Material(
              color: niveles[i].$2.withValues(
                alpha: seleccionado == null ||
                    seleccionado == niveles[i].$1 ? 0.92 : 0.3),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: ValueKey('jarra-${niveles[i].$1}'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSeleccionar(
                  seleccionado == niveles[i].$1
                      ? null : niveles[i].$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 18),
                  child: Row(
                    children: [
                      Icon(niveles[i].$3, color: Colors.black87),
                      const SizedBox(width: 12),
                      Expanded(child: Text(niveles[i].$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87))),
                      const Icon(Icons.chevron_right, color: Colors.black87),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 9),
        Text('Herramienta educativa. Para necesidades individuales de '
          'hidratación consulta a un profesional de salud.',
          style: theme.textTheme.bodySmall),
      ],
    );
  }
}
