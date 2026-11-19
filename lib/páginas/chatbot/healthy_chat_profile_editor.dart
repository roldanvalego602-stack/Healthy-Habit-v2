import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../tema/healthy_theme.dart';
import '../../tema/healthy_visual_mode.dart';

/// Vista previa verificada; los cambios los valida EditarPerfilScreen.
class HealthyChatProfileEditor extends StatelessWidget {
  const HealthyChatProfileEditor({
    super.key, required this.onEdit,
  });
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text('Inicia sesión para modificar tu perfil.'));
    }
    final doc = FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    ).collection('users').doc(uid);
    return AnimatedSize(
      duration: HealthyVisualEffects.duration(
        context, const Duration(milliseconds: 220)),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HealthyAdaptive.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HealthyAdaptive.border),
        ),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: doc.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('No pude consultar tus datos del perfil.');
            }
            if (!snapshot.hasData) {
              return const Center(child: LinearProgressIndicator());
            }
            final profile = snapshot.data!.data() ?? <String, dynamic>{};
            final name = (profile['name'] ?? 'Sin nombre').toString();
            final username = (profile['username'] ?? '').toString();
            final bio = (profile['bio'] ?? '').toString();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(Icons.manage_accounts_rounded,
                      color: HealthyAdaptive.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Editar tu perfil',
                    style: TextStyle(color: HealthyAdaptive.text,
                      fontWeight: FontWeight.w900))),
                ]),
                const SizedBox(height: 9),
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: HealthyAdaptive.text,
                    fontWeight: FontWeight.w800)),
                if (username.isNotEmpty)
                  Text('@$username', maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: HealthyAdaptive.muted,
                      fontSize: 11)),
                if (bio.isNotEmpty)
                  Text(bio, maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: HealthyAdaptive.muted,
                      fontSize: 11)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('chat-edit-profile-action'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Revisar y editar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
