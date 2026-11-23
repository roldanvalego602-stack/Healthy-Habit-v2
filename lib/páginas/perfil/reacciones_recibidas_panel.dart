import 'package:flutter/material.dart';
import 'amigos_servicio.dart';
import 'profile_avatar.dart';
import 'perfil_muestra.dart';
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
                if (visibles.isNotEmpty)
                  FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: AmigosServicio.perfiles(
                      visibles.map((e) => e.fromUid).toSet().toList(),
                    ),
                    builder: (context, profiles) {
                      final publicProfiles = profiles.data ??
                          <String, Map<String, dynamic>>{};
                      return Column(
                        children: [
                          for (final item in visibles)
                            Builder(builder: (context) {
                              final friend = publicProfiles[item.fromUid];
                              final name = friend?['name']?.toString() ??
                                  'Amigo de Healthy Habit';
                              final username =
                                  friend?['username']?.toString() ?? '';
                              return ListTile(
                                key: ValueKey('reaction-${item.id}'),
                                contentPadding: EdgeInsets.zero,
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    HealthyProfileAvatar(
                                      photoUrl: friend?['photoUrl']?.toString(),
                                      preset: friend?['profileAvatarStyle']
                                              ?.toString() ?? 'foto',
                                      size: 44,
                                    ),
                                    Positioned(
                                      right: -5,
                                      bottom: -5,
                                      child: Text(
                                        item.emoji.isEmpty ? '👏' : item.emoji,
                                        style: const TextStyle(fontSize: 19),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  item.leido ? name : '$name te animó',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: item.leido
                                        ? FontWeight.w500
                                        : FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.emoji} · '
                                  '${item.createdAt.day}/'
                                  '${item.createdAt.month}/'
                                  '${item.createdAt.year}',
                                ),
                                onTap: friend == null ? null : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => PublicProfileScreen(
                                        userId: item.fromUid,
                                        name: name,
                                        username: username,
                                      ),
                                    ),
                                  );
                                },
                                trailing: item.leido
                                    ? const Icon(Icons.done_all_rounded)
                                    : TextButton(
                                        onPressed:
                                            _ocupadas.contains(item.id)
                                                ? null
                                                : () => _marcarLeida(item),
                                        child: const Text('Marcar leída'),
                                      ),
                              );
                            }),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
