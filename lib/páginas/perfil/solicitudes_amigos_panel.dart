import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'amigos_servicio.dart';
import 'amigos_screen.dart';

/// Solicitudes reales para el centro de notificaciones.
class SolicitudesAmigosPanel extends StatelessWidget {
  const SolicitudesAmigosPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = AmigosServicio.uidActual;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AmigosServicio.solicitudesRecibidas(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Card(child: ListTile(
            title: Text('No se pudieron consultar las solicitudes'),
            subtitle: Text('Comprueba las reglas de Firestore.'),
          ));
        }
        if (!snap.hasData) {
          return const Card(child: ListTile(
            title: Text('Consultando solicitudes de amistad...'),
          ));
        }
        final requests = snap.data!.docs;
        final ids = requests.map((e) => e.id).toList();
        final created = {
          for (final doc in requests)
            doc.id: doc.data()['createdAt'] is Timestamp
                ? (doc.data()['createdAt'] as Timestamp).toDate()
                : null,
        };
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.person_add_alt_1_rounded),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    ids.isEmpty ? 'Sin solicitudes nuevas'
                      : 'Solicitudes de amistad (${ids.length})',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  )),
                ]),
                const SizedBox(height: 5),
                if (ids.isEmpty)
                  const Text('Cuando alguien quiera agregarte aparecerá aquí.'),
                if (ids.isNotEmpty)
                  FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: AmigosServicio.perfiles(ids.take(5).toList()),
                    builder: (context, perfiles) {
                      if (!perfiles.hasData) {
                        return const Text('Cargando usuarios...');
                      }
                      return Column(children: [
                        for (final id in ids.take(5))
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.account_circle_outlined),
                            title: Text(
                              (perfiles.data![id]?['name'] ?? 'Usuario').toString()),
                            subtitle: Text(created[id] == null
                                ? 'Quiere agregarte como amigo'
                                : 'Solicitud recibida el '
                                    '${created[id]!.day}/'
                                    '${created[id]!.month}/'
                                    '${created[id]!.year}'),
                            trailing: const Icon(
                              Icons.mark_email_unread_outlined,
                              size: 20,
                            ),
                          ),
                      ]);
                    },
                  ),
                if (ids.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const ValueKey('notifications-friend-requests'),
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: const Text('Aceptar o rechazar solicitudes'),
                      onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                          const AmigosScreen(initialTab: 1))),
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
