import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Indicador en vivo; sólo cuenta documentos destinados a la sesión actual.
/// No requiere índices compuestos ni colecciones nuevas.
class SocialNotificationBell extends StatelessWidget {
  const SocialNotificationBell({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return IconButton.filledTonal(
        tooltip: 'Notificaciones',
        onPressed: onPressed,
        icon: const Icon(Icons.notifications_none_rounded),
      );
    }

    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('interactions')
          .where('toUid', isEqualTo: uid).snapshots(),
      builder: (context, reactions) {
        final unread = reactions.data?.docs.where((doc) {
          final data = doc.data();
          return data['tipo'] == 'reaccion' && data['leido'] == false;
        }).length ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('users').doc(uid)
              .collection('solicitudes').snapshots(),
          builder: (context, requests) {
            final friendCount = requests.data?.docs.length ?? 0;
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('shared_habit_invites')
                  .where('recipientUid', isEqualTo: uid).snapshots(),
              builder: (context, invitations) {
                final inviteCount = invitations.data?.docs
                    .where((doc) => doc.data()['status'] == 'pendiente')
                    .length ?? 0;
                final count = unread + friendCount + inviteCount;
                return IconButton.filledTonal(
                  tooltip: count > 0
                      ? 'Notificaciones: $count pendientes'
                      : 'Notificaciones',
                  onPressed: onPressed,
                  icon: count == 0
                      ? const Icon(Icons.notifications_none_rounded)
                      : Badge.count(
                          count: count,
                          child: const Icon(Icons.notifications_active_rounded),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }
}
