import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../catalogo_explorador.dart';
import '../modelos/catalogo_item.dart';

/// Gráfica de gramos informativos, no porcentajes de dieta ni de calorías.
/// Cada ficha conserva su referencia de alimento crudo/cocido.
class ResumenNutricionalCatalogo extends StatelessWidget {
  const ResumenNutricionalCatalogo({super.key, required this.item});
  final CatalogoItem item;

  static const campos = <String>[
    'Proteína', 'Grasas', 'Carbohidratos', 'Fibra',
  ];

  static const tonos = <Color>[
    Color(0xFF399C7C), Color(0xFFDCA45F),
    Color(0xFF578BC9), Color(0xFF9468B8),
  ];

  @override
  Widget build(BuildContext context) {
    final valores = <(String, double, Color)>[
      for (var i = 0; i < campos.length; i++)
        if (CatalogoExplorador.nutriente(item, campos[i]) case final double value)
          (campos[i], value, tonos[i]),
    ];
    final referencia = item.detalles['Referencia'];
    final tema = Theme.of(context);
    if (valores.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(
              'Esta ficha aún no tiene valores nutricionales cuantificados '
              'y verificados. No se muestran estimaciones inventadas.',
              style: tema.textTheme.bodySmall,
            )),
          ]),
        ),
      );
    }
    final maximo = valores.map((e) => e.$2).reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Macronutrientes registrados',
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(referencia ?? 'Referencia de la ficha',
            style: tema.textTheme.bodySmall),
        const SizedBox(height: 16),
        for (final (nombre, valor, color) in valores) ...[
          Row(children: [
            Expanded(child: Text(nombre)),
            Text('${valor.toStringAsFixed(1)} g',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: maximo == 0 ? 0 : valor / maximo,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          'Las barras comparan gramos dentro de esta ficha. La fibra '
          'se presenta como dato informativo y también forma parte de '
          'los carbohidratos; no se suman barras ni se calculan calorías. '
          'Los alimentos crudos y cocidos no son directamente equivalentes.',
          style: tema.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class GuiaPasosCatalogo extends StatefulWidget {
  const GuiaPasosCatalogo({super.key, required this.item});
  final CatalogoItem item;

  @override
  State<GuiaPasosCatalogo> createState() => _GuiaPasosCatalogoState();
}

class _GuiaPasosCatalogoState extends State<GuiaPasosCatalogo> {
  int _paso = 0;

  @override
  void didUpdateWidget(covariant GuiaPasosCatalogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) _paso = 0;
  }

  @override
  Widget build(BuildContext context) {
    final pasos = widget.item.pasos;
    if (pasos.isEmpty) {
      return const Text('No se han documentado instrucciones.');
    }
    final total = pasos.length;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paso ${_paso + 1} de $total',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: scheme.primary)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
            value: (_paso + 1) / total, minHeight: 6),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Container(
            key: ValueKey('${widget.item.id}-$_paso'),
            constraints: const BoxConstraints(minHeight: 96),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(pasos[_paso],
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          TextButton.icon(
            onPressed: _paso == 0 ? null :
                () => setState(() => _paso--),
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Anterior'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => setState(() {
              _paso = _paso == total - 1 ? 0 : _paso + 1;
            }),
            icon: Icon(_paso == total - 1
                ? Icons.replay_rounded : Icons.chevron_right_rounded),
            label: Text(_paso == total - 1 ? 'Repetir' : 'Siguiente'),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          'Guía educativa. Avanzar por los pasos no registra actividad, '
          'no verifica ejercicios y no concede XP.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
