import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../servicios/healthy_retro_sound_service.dart';
import '../../tema/healthy_magic_guide.dart';
import '../../tema/healthy_theme.dart';
import 'amigos_servicio.dart';
import 'buscar_amigos_screen.dart';
import 'perfil_muestra.dart';
import 'profile_avatar.dart';
import 'reaction_picker_dialog.dart';

/// Una amistad requiere solicitud y aceptación; no hay seguidores.
class AmigosScreen extends StatefulWidget {
  const AmigosScreen({super.key, this.initialTab = 0});
  /// Compatibilidad con accesos anteriores (0=amigos, 1/2=solicitudes).
  final int initialTab;

  @override
  State<AmigosScreen> createState() => _AmigosScreenState();
}

class _AmigosScreenState extends State<AmigosScreen> {
  late int _tab = widget.initialTab == 0 ? 0 : 1;
  final Set<String> _busy = {};
  String? get _uid => AmigosServicio.uidActual;

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmRemove(String name) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar amigo'),
          content: Text('¿Eliminar a $name de tu lista de amigos? '
              'Ambos dejarán de ver su progreso como amigos.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar amigo')),
          ],
        ),
      ) ?? false;

  Future<void> _action(String uid, String action, String name) async {
    if (_busy.contains(uid)) return;
    if (action == 'delete' && !await _confirmRemove(name)) return;
    if (!mounted) return;
    setState(() => _busy.add(uid));
    try {
      switch (action) {
        case 'delete':
          await AmigosServicio.eliminarAmigo(uid);
          _notify('Eliminaste a $name de tus amigos.');
          break;
        case 'accept':
          await AmigosServicio.aceptarSolicitud(uid);
          HealthyRetroSoundService.play('friend');
          _notify('Ahora $name es tu amigo.');
          break;
        case 'reject':
          await AmigosServicio.rechazarSolicitud(uid);
          _notify('Solicitud rechazada.');
          break;
        case 'cancel':
          await AmigosServicio.cancelarSolicitud(uid);
          _notify('Solicitud cancelada.');
          break;
      }
    } catch (e) {
      _notify('No se pudo completar la acción: $e');
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }

  Widget _error(String text) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text(text, textAlign: TextAlign.center),
  ));

  Widget _person(
      String uid, Map<String, dynamic> data, String state) {
    final name = (data['name'] ?? 'Usuario').toString();
    final username = (data['username'] ?? '').toString();
    final busy = _busy.contains(uid);
    final level = (data['level'] as num?)?.toInt() ?? 1;
    return Card(
      key: ValueKey('friend-$state-$uid'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: HealthyProfileAvatar(
              photoUrl: data['photoUrl']?.toString(),
              preset: data['profileAvatarStyle']?.toString() ?? 'foto',
              size: 45,
            ),
            title: Text(name, maxLines: 1,
              overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${username.startsWith('@') ? username : '@$username'}'
              ' · Nivel $level',
              maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PublicProfileScreen(
                userId: uid,
                name: name,
                username: username,
                level: level,
                streakDays: (data['currentStreak'] as num?)?.toInt() ?? 0,
                completedHabits:
                    (data['completedHabits'] as num?)?.toInt() ?? 0,
              ),
            )),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (state == 'friends') ...[
              TextButton.icon(
                onPressed: busy ? null : () {
                  final from = _uid;
                  if (from == null) return;
                  showDialog<void>(context: context,
                    builder: (_) => ReactionPickerDialog(
                      fromUid: from, toUid: uid, friendName: name));
                },
                icon: const Icon(Icons.add_reaction_outlined),
                label: const Text('Animar')),
              const SizedBox(width: 6),
              TextButton(
                onPressed: busy ? null : () => _action(uid, 'delete', name),
                child: const Text('Eliminar')),
            ] else if (state == 'incoming') ...[
              OutlinedButton(
                onPressed: busy ? null : () => _action(uid, 'reject', name),
                child: const Text('Rechazar')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: busy ? null : () => _action(uid, 'accept', name),
                child: const Text('Aceptar')),
            ] else
              OutlinedButton(
                onPressed: busy ? null : () => _action(uid, 'cancel', name),
                child: const Text('Cancelar solicitud')),
          ]),
        ]),
      ),
    );
  }

  Widget _list(List<String> ids, String state) {
    if (ids.isEmpty) {
      return _error(state == 'friends'
        ? 'Aún no tienes amigos. Busca personas y envía una solicitud.'
        : state == 'incoming'
          ? 'No hay solicitudes de amistad recibidas.'
          : 'No tienes solicitudes enviadas pendientes.');
    }
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: AmigosServicio.perfiles(ids),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _error('No se pudieron cargar los perfiles públicos.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: ids.length,
          itemBuilder: (context, index) {
            final uid = ids[index];
            final profile = snapshot.data![uid];
            if (profile == null) {
              return ListTile(title: const Text('Usuario no disponible'),
                subtitle: const Text('El perfil público no está accesible.'));
            }
            return _person(uid, profile, state);
          },
        );
      },
    );
  }

  Widget _requests(String uid) => StreamBuilder<
      QuerySnapshot<Map<String, dynamic>>>(
    stream: AmigosServicio.solicitudesRecibidas(uid),
    builder: (context, incoming) {
      if (incoming.hasError) {
        return _error('No se pudieron consultar las solicitudes recibidas.');
      }
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AmigosServicio.solicitudesEnviadas(uid),
        builder: (context, outgoing) {
          if (outgoing.hasError) {
            return _error('No se pudieron consultar las solicitudes enviadas.');
          }
          if (!incoming.hasData || !outgoing.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final a = incoming.data!.docs.map((d) => d.id).toList();
          final b = outgoing.data!.docs.map((d) => d.id).toList();
          if (a.isEmpty && b.isEmpty) {
            return _error('No tienes solicitudes pendientes.');
          }
          final all = <String>{...a, ...b}.toList();
          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: AmigosServicio.perfiles(all),
            builder: (context, profiles) {
              if (profiles.hasError) {
                return _error('No se pudieron consultar los perfiles de las solicitudes.');
              }
              if (!profiles.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = profiles.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: [
                  if (a.isNotEmpty) ...[
                    ListTile(title: Text('Recibidas (${a.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800))),
                    for (final id in a)
                      if (data.containsKey(id))
                        _person(id, data[id]!, 'incoming'),
                  ],
                  if (b.isNotEmpty) ...[
                    ListTile(title: Text('Enviadas (${b.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800))),
                    for (final id in b)
                      if (data.containsKey(id))
                        _person(id, data[id]!, 'outgoing'),
                  ],
                ],
              );
            },
          );
        },
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      floatingActionButton: const HealthyMagicGuideButton(section: 'amigos'),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(title: const Text('Amigos')),
      body: uid == null ? _error('Inicia sesión para agregar amigos.')
        : Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Expanded(child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Mis amigos'),
                      icon: Icon(Icons.people_outline)),
                    ButtonSegment(value: 1, label: Text('Solicitudes'),
                      icon: Icon(Icons.mark_email_unread_outlined)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (selected) =>
                      setState(() => _tab = selected.first),
                )),
                IconButton(
                  tooltip: 'Buscar amigos',
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>
                      const BuscarAmigosScreen())),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                ),
              ]),
            ),
            Expanded(child: _tab == 1
              ? _requests(uid)
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: AmigosServicio.amigos(uid),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return _error('No se pudo cargar tu lista de amigos. '
                        'Comprueba las reglas de Firestore.');
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _list(snap.data!.docs.map((d) => d.id).toList(),
                      'friends');
                  },
                )),
          ]),
    );
  }
}
