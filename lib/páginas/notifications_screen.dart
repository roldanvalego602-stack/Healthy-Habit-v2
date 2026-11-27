import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../tema/healthy_magic_guide.dart';

import '../tema/healthy_theme.dart';
import '../servicios/healthy_reminders_service.dart';
import 'perfil/configuracion_screen.dart';
import 'perfil/reacciones_recibidas_panel.dart';
import 'perfil/solicitudes_amigos_panel.dart';
import 'habitos/habitos_pareja_notificaciones.dart';

/// Centro de recordatorios de la cuenta actual.
/// No fabrica notificaciones sociales ni recompensas de demostración.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _filter = 0; // 0 Todas, 1 Actividad, 2 Social.
  bool _probando = false;
  bool _sincronizando = false;
  bool _probandoProgramacion = false;
  late Future<int?> _pendientes;
  late Future<bool?> _permiso;
  late Future<bool?> _pruebaPendiente;

  @override
  void initState() {
    super.initState();
    _actualizarDiagnostico();
  }

  void _actualizarDiagnostico() {
    _pendientes = HealthyRemindersService.instance.pendingCount();
    _permiso = HealthyRemindersService.instance.notificationsEnabled();
    _pruebaPendiente =
        HealthyRemindersService.instance.diagnosticPending();
  }

  Future<void> _refrescar() async {
    if (!mounted) return;
    setState(_actualizarDiagnostico);
  }

  Future<void> _probarProgramacion() async {
    if (_probandoProgramacion) return;
    setState(() => _probandoProgramacion = true);
    try {
      final scheduled =
          await HealthyRemindersService.instance.scheduleDiagnosticTest();
      _mensaje(scheduled
          ? 'Prueba programada para dentro de aproximadamente 2 minutos. '
            'Android puede retrasarla. Cierra la aplicación y comprueba '
            'las notificaciones del sistema.'
          : 'No se pudo programar: comprueba el permiso de notificaciones.');
    } catch (error) {
      _mensaje('Error de programación en Android: $error');
    } finally {
      if (mounted) {
        setState(() {
          _probandoProgramacion = false;
          _actualizarDiagnostico();
        });
      }
    }
  }

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
        ? 'Android aceptó la notificación inmediata. Revisa la bandeja.'
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
      if (mounted) {
        setState(() {
          _sincronizando = false;
          _actualizarDiagnostico();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ref = _userRef;
    return Scaffold(
      floatingActionButton: const HealthyMagicGuideButton(section: 'notificaciones'),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
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
                    SegmentedButton<int>(
                      key: const ValueKey('notifications-filters'),
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Todas')),
                        ButtonSegment(value: 1, label: Text('Actividad')),
                        ButtonSegment(value: 2, label: Text('Social')),
                      ],
                      selected: {_filter},
                      showSelectedIcon: false,
                      onSelectionChanged: (values) =>
                          setState(() => _filter = values.first),
                    ),
                    const SizedBox(height: 14),
                    if (_filter != 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Avisos de actividad',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800)),
                      ),
                    if (_filter != 2) Card(
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
                                'este teléfono. Los de racha se actualizan '
                                'al registrar actividades o volver a la app; '
                                'requieren permiso de Android.'
                              : 'Los recordatorios locales están disponibles '
                                'en la aplicación Android, no en web.',
                              style: theme.textTheme.bodySmall),
                            const SizedBox(height: 9),
                            FutureBuilder<int?>(
                              future: _pendientes,
                              builder: (context, pending) {
                                if (pending.hasError) {
                                  return Text('No fue posible consultar la '
                                    'agenda local. Revisa permisos de Android.',
                                    style: theme.textTheme.bodySmall);
                                }
                                if (!pending.hasData) {
                                  return Text(android
                                    ? 'Consultando agenda local...'
                                    : 'No disponible en esta plataforma.',
                                    style: theme.textTheme.bodySmall);
                                }
                                return Text(
                                  '${pending.data} avisos programados en '
                                  'este dispositivo',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<bool?>(
                              future: _permiso,
                              builder: (context, permission) {
                                if (permission.hasError) {
                                  return Text('No se pudo comprobar el permiso.',
                                    style: theme.textTheme.bodySmall);
                                }
                                if (!permission.hasData) {
                                  return Text('Verificando permiso de Android...',
                                    style: theme.textTheme.bodySmall);
                                }
                                return Text(
                                  permission.data == true
                                    ? 'Permiso del sistema: concedido'
                                    : 'Permiso del sistema: desactivado',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _refrescar,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Actualizar diagnóstico'),
                            ),
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
                    if (_filter != 2) const SizedBox(height: 14),
                    if (_filter != 2) Card(child: Padding(
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
                            key: const ValueKey('reminders-test-scheduled'),
                            onPressed: android && !_probandoProgramacion
                                ? _probarProgramacion : null,
                            icon: const Icon(Icons.schedule_rounded),
                            label: Text(_probandoProgramacion
                              ? 'Programando prueba...'
                              : 'Probar aviso programado (+2 min)'),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<bool?>(
                            future: _pruebaPendiente,
                            builder: (context, pending) {
                              if (pending.hasError) {
                                return Text('No se pudo consultar la prueba '
                                  'programada.',
                                  style: theme.textTheme.bodySmall);
                              }
                              if (!pending.hasData) {
                                return Text('Consultando prueba programada...',
                                  style: theme.textTheme.bodySmall);
                              }
                              return Text(
                                pending.data == true
                                  ? 'Prueba programada: pendiente en Android.'
                                  : 'No hay prueba programada pendiente.',
                                style: theme.textTheme.bodySmall,
                              );
                            },
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
                    if (_filter != 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Actividad social',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800)),
                      ),
                    if (_filter != 1) const SolicitudesAmigosPanel(),
                    if (_filter != 1) const SizedBox(height: 14),
                    if (_filter != 1) const HabitosParejaNotificaciones(),
                    if (_filter != 1) const SizedBox(height: 14),
                    if (_filter != 1) const ReaccionesRecibidasPanel(),
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
                            'Los recordatorios de actividad muestran la agenda '
                            'local de Android, no un historial de entregas. '
                            'En Social aparecen solicitudes, invitaciones y '
                            'reacciones reales de tu cuenta. Las solicitudes '
                            'se resuelven aceptándolas o rechazándolas.',
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
