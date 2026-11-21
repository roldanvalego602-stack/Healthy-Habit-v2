import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../perfil/amigos_servicio.dart';
import 'habitos_en_pareja_screen.dart';
import 'habitos_pareja_servicio.dart';

class HabitosParejaNotificaciones extends StatelessWidget {
  const HabitosParejaNotificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    if (AmigosServicio.uidActual == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: const HabitosParejaServicio().recibidas(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(child: ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Invitaciones en pareja no disponibles'),
            subtitle: Text('Comprueba los permisos de Firestore.'),
          ));
        }
        if (!snapshot.hasData) {
          return const Card(child: ListTile(
            title: Text('Consultando invitaciones a hábitos...'),
          ));
        }
        final invites = snapshot.data!.docs.where(
          (doc) => doc.data()['status'] == 'pendiente').toList();
        return Card(
          child: ListTile(
            key: const ValueKey('notifications-shared-habits'),
            leading: const Icon(Icons.people_alt_outlined),
            title: Text(invites.isEmpty
              ? 'Hábitos en pareja'
              : '${invites.length} invitaciones a hábitos'),
            subtitle: Text(invites.isEmpty
              ? 'No hay invitaciones pendientes.'
              : 'Tus amigos quieren realizar un hábito contigo.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
                const HabitosEnParejaScreen())),
          ),
        );
      },
    );
  }
}
