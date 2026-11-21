import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../tema/healthy_theme.dart';
import '../servicios/healthy_reminders_service.dart';
import 'perfil/configuracion_screen.dart';

/// Centro de recordatorios de la cuenta actual.
/// No fabrica notificaciones sociales ni recompensas de demostración.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _probando = false;
  bool _sincronizando = false;

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default')
        .collection('users').doc(user.uid);
  }

  void _mensaje(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _probar() async {
    if (_probando) return;
    setState(() => _probando = true);
    try {
      final ok = await HealthyRemindersService.instance.sendTest();
      _mensaje(ok
        ? 'Se envió la notificación de prueba a Android.'
        : 'No se pudo enviar. Usa Android y permite notificaciones '
          'en los ajustes del sistema.');
    } catch (error) {
      _mensaje('Falló la notificación de prueba: $error');
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  Future<void> _reprogramar(Map<String, dynamic> settings) async {
    if (_sincronizando) return;
    setState(() => _sincronizando = true);
    try {
      final ok = await HealthyRemindersService.instance.synchronize(
        settings, askPermission: true);
      _mensaje(ok
        ? 'Programación actualizada. Los avisos pueden demorarse por '
          'las restricciones de batería de Android.'
        : 'Android no concedió permisos, no admite esta función o '
          'los avisos están bloqueados.');
    } catch (error) {
      _mensaje('No se pudieron programar los avisos: $error');
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ref = _userRef;
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: HealthyAdaptive.background,
      ),
      body: ref == null
          ? const Center(child: Text('Inicia sesión para ver tus recordatorios.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: ref.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No se pudieron consultar las preferencias. '
                      'Comprueba tu conexión y permisos de Firestore.'),
                  ));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final raw = snapshot.data?.data()?['settings'];
                final settings = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : <String, dynamic>{};
                final enabled = settings['permitirRecordatorios'] == true;
                final horario =
                    (settings['horarioRecordatorio'] ?? '09:00').toString();
                final android = HealthyRemindersService.instance.supported;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(enabled
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                              color: theme.colorScheme.primary, size: 38),
                            const SizedBox(height: 12),
                            Text(enabled
                              ? 'Recordatorios activados en tu cuenta'
                              : 'Recordatorios desactivados',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('Horario base: $horario',
                              style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 6),
                            Text(android
                              ? 'Los avisos se programan localmente en '
                                'este teléfono. Requieren permiso de Android.'
                              : 'Los recordatorios locales están disponibles '
                                'en la aplicación Android, no en web.',
                              style: theme.textTheme.bodySmall),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsScreen())),
                              icon: const Icon(Icons.tune_rounded),
                              label: const Text('Configurar recordatorios'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comprobación en el dispositivo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800)),
                          const SizedBox(height: 9),
                          Text('1. Activa recordatorios en Ajustes.\n'
                            '2. Permite las notificaciones de Healthy Habit '
                            'en Android.\n'
                            '3. Envía un aviso de prueba.\n'
                            '4. Si funciona, vuelve a programar la agenda.',
                            style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 14),
                          FilledButton.tonalIcon(
                            onPressed: android && !_probando ? _probar : null,
                            icon: const Icon(Icons.notifications_outlined),
                            label: Text(_probando
                              ? 'Enviando...' : 'Enviar aviso de prueba'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: android && enabled && !_sincronizando
                                ? () => _reprogramar(settings) : null,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(_sincronizando
                                ? 'Programando...' : 'Reprogramar avisos'),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 14),
                    Card(child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            'Esta pantalla muestra recordatorios y su '
                            'configuración reales. La bandeja de eventos '
                            'sociales, solicitudes y recompensas todavía '
                            'no está conectada; no se muestran mensajes '
                            'ficticios como si hubieran ocurrido.',
                            style: theme.textTheme.bodySmall)),
                        ],
                      ),
                    )),
                  ],
                );
              },
            ),
    );
  }
}
