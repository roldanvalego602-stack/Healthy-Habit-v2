import 'package:flutter/material.dart';

import 'catalogo_explorador.dart';
import 'catalogo_media.dart';
import 'modelos/catalogo_item.dart';

/// Comparación de fichas educativas: sin decisiones clínicas ni cambios de XP.
class CatalogoComparacion extends StatelessWidget {
  const CatalogoComparacion({
    super.key,
    required this.items,
    required this.onAbrir,
    required this.onQuitar,
    required this.onLimpiar,
  });

  final List<CatalogoItem> items;
  final ValueChanged<CatalogoItem> onAbrir;
  final ValueChanged<CatalogoItem> onQuitar;
  final VoidCallback onLimpiar;

  static const _nutrientes = [
    'Proteína', 'Grasas', 'Carbohidratos', 'Fibra',
  ];

  List<String> get _campos {
    if (items.isEmpty) return const [];
    if (items.first.categoria == 'Alimentos') {
      return [..._nutrientes, 'Referencia', 'Grupo del plato'];
    }
    if (items.first.categoria == 'Bebidas') {
      return ['Grupo de bebida'];
    }
    if (items.first.categoria == 'Ejercicios') {
      return ['Grupo muscular', 'Equipo', 'Impacto', 'Modalidad'];
    }
    return ['Objetivo', 'Frecuencia', 'Lugar', 'Costo'];
  }

  String _valor(CatalogoItem item, String campo) {
    if (_nutrientes.contains(campo)) {
      final numero = CatalogoExplorador.nutriente(item, campo);
      return numero == null ? 'Sin dato' : '${numero.toStringAsFixed(1)} g';
    }
    return item.detalles[campo] ?? 'Sin dato';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comparar elementos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900)),
                    Text('${items.length} seleccionados · desliza para verlos',
                      style: theme.textTheme.bodySmall),
                  ],
                )),
                TextButton(
                  onPressed: onLimpiar,
                  child: const Text('Limpiar'),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 210,
                        child: Card(
                          elevation: 0,
                          color: color.surfaceContainerLowest,
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 12, 12, 4),
                                  children: [
                                    CatalogoMedia(item: item, altura: 110),
                                    const SizedBox(height: 10),
                                    Text(item.titulo,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 5),
                                    Text(item.descripcion,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall),
                                    const SizedBox(height: 12),
                                    for (final campo in _campos) ...[
                                      Text(campo, style: theme.textTheme.labelSmall
                                        ?.copyWith(color: color.onSurfaceVariant)),
                                      const SizedBox(height: 3),
                                      Text(_valor(item, campo),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 9),
                                    ],
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 6, 12, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    FilledButton.tonalIcon(
                                      onPressed: () => onAbrir(item),
                                      icon: const Icon(Icons.open_in_new,
                                          size: 17),
                                      label: const Text('Ver ficha'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => onQuitar(item),
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 16),
                                      label: const Text('Quitar'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Text(
                items.first.categoria == 'Alimentos'
                  ? 'Datos orientativos de las fichas. No equipara crudo con '
                      'cocido ni convierte porciones o cantidades faltantes.'
                  : 'Comparación educativa de características registradas; '
                      'no constituye una indicación personalizada.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
