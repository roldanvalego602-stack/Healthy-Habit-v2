import 'package:flutter/material.dart';
import 'amigos_servicio.dart';
import 'interaction_model.dart';
import 'interaction_service.dart';

/// Reacciones verdaderas del usuario autenticado, sin eventos inventados.
class ReaccionesRecibidasPanel extends StatefulWidget {
  const ReaccionesRecibidasPanel({super.key});

  @override
  State<ReaccionesRecibidasPanel> createState() =>
      _ReaccionesRecibidasPanelState();
}

class _ReaccionesRecibidasPanelState
    extends State<ReaccionesRecibidasPanel> {
  final Set<String> _ocupadas = <String>{};

  Future<void> _marcarLeida(InteractionModel item) async {
    if (item.id == null || item.leido || !_ocupadas.add(item.id!)) return;
    setState(() {});
    try {
      await InteractionService().marcarComoLeida(item.id!);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo marcar la reacción como leída: $error'),
      ));
    } finally {
      if (mounted) {
        setState(() => _ocupadas.remove(item.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AmigosServicio.uidActual;
    if (uid == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<List<InteractionModel>>(
      stream: InteractionService().escucharReaccionesRecibidas(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No fue posible cargar las reacciones. '
              'Comprueba las reglas de Firestore y tu conexión.'),
          ));
        }
        if (!snapshot.hasData) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ));
        }
        final items = snapshot.data!
            .where((item) => item.toUid == uid &&
                item.tipo == 'reaccion' &&
                item.fromUid.isNotEmpty && item.fromUid != uid)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final visibles = items.take(15).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.favorite_outline),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Ánimos recibidos',
                    style: TextStyle(fontWeight: FontWeight.w800,
                      fontSize: 16))),
                  Text('${items.where((e) => !e.leido).length} nuevos'),
                ]),
                const SizedBox(height: 9),
                if (visibles.isEmpty)
                  const Text('Aún no has recibido reacciones de otros usuarios.'),
                for (final item in visibles)
                  ListTile(
                    key: ValueKey('reaction-${item.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Text(item.emoji.isEmpty ? '👏' : item.emoji,
                      style: const TextStyle(fontSize: 24)),
                    title: Text(item.leido
                        ? 'Reacción recibida'
                        : 'Nueva reacción recibida'),
                    subtitle: Text('De un usuario de Healthy Habit · '
                      '${item.createdAt.day}/${item.createdAt.month}'),
                    trailing: item.leido
                      ? const Icon(Icons.done_all_rounded)
                      : TextButton(
                          onPressed: _ocupadas.contains(item.id)
                              ? null : () => _marcarLeida(item),
                          child: const Text('Marcar leída'),
                        ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
