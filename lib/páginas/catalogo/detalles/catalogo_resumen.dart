import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/catalogo_item.dart';

/// Extracto estrictamente basado en la ficha, sin generación externa.
class ResumenFichaCatalogo extends StatefulWidget {
  const ResumenFichaCatalogo({super.key, required this.item});
  final CatalogoItem item;

  @override
  State<ResumenFichaCatalogo> createState() => _ResumenFichaCatalogoState();
}

class _ResumenFichaCatalogoState extends State<ResumenFichaCatalogo> {
  int _tema = 0;
  static const _temas = <String>[
    'En pocas palabras', 'Beneficios', 'Cómo usarlo', 'Precauciones', 'Datos',
  ];

  String _contenido() {
    final item = widget.item;
    switch (_tema) {
      case 0:
        return '${item.titulo}: ${item.descripcion}\n\n'
            'Categoría: ${item.categoria}. '
            'Etiquetas: ${item.etiquetas.join(', ')}.';
      case 1:
        return item.beneficios.isEmpty
            ? 'Sin beneficios documentados.'
            : item.beneficios.map((e) => '• $e').join('\n');
      case 2:
        return item.pasos.isEmpty
            ? 'Sin indicaciones documentadas.'
            : item.pasos.asMap().entries
                .map((e) => '${e.key + 1}. ${e.value}').join('\n');
      case 3:
        return item.precauciones.isEmpty
            ? 'No se han registrado precauciones.'
            : item.precauciones.map((e) => '• $e').join('\n');
      default:
        return item.detalles.isEmpty
            ? 'No hay datos complementarios documentados.'
            : item.detalles.entries
                .map((e) => '${e.key}: ${e.value}').join('\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contenido = _contenido();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Consultar rápidamente',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Selecciona exactamente la información que necesitas de '
            'esta ficha, sin respuestas inventadas.',
            style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(spacing: 7, runSpacing: 5, children: [
            for (var i = 0; i < _temas.length; i++)
              ChoiceChip(
                label: Text(_temas[i]),
                selected: _tema == i,
                onSelected: (_) => setState(() => _tema = i),
              ),
          ]),
          const SizedBox(height: 16),
          Flexible(child: SingleChildScrollView(
            child: SelectableText(contenido,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          )),
          const SizedBox(height: 12),
          Text('Fuente: ${widget.item.fuente}',
            style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: contenido));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resumen copiado')));
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar respuesta'),
            ),
          ),
        ]),
      ),
    );
  }
}
