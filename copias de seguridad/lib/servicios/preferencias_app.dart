import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Escucha las preferencias guardadas por SettingsScreen en users/{uid}.settings.
class PreferenciasApp extends StatelessWidget {
  const PreferenciasApp({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    ThemeMode themeMode,
    double textScale,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return builder(context, ThemeMode.system, 1.0);
        }
        final db = FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'default',
        );
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: db.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final raw = data?['settings'];
            final settings = raw is Map ? raw : const <String, dynamic>{};
            final theme = switch (settings['tema']) {
              'Claro' => ThemeMode.light,
              'Oscuro' => ThemeMode.dark,
              _ => ThemeMode.system,
            };
            final scale = switch (settings['tamanoTexto']) {
              'Pequeño' => 0.90,
              'Grande' => 1.15,
              _ => 1.0,
            };
            return builder(context, theme, scale);
          },
        );
      },
    );
  }
}
