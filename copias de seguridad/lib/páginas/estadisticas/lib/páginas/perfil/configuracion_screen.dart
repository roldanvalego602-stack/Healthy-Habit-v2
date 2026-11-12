import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'editar_perfil_screen.dart';
import 'informacion_app_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const green = Color(0xFF198568);
  static const navy = Color(0xFF172B36);
  static const muted = Color(0xFF7A869A);
  static const bg = Color(0xFFF7F9F8);
  static const categories = [
    'Alimentación',
    'Hidratación',
    'Energía',
    'Bienestar',
  ];
  static const defaults = <String, dynamic>{
    'analizarHistorialIA': false,
    'sonidosApp': true,
    'vibracionHaptica': true,
    'animacionesDivertidas': true,
    'mostrarRachaAmigos': true,
    'permitirReacciones': true,
    'permitirRecordatorios': false,
    'recordatorioHabito': true,
    'recordatorioRacha': true,
    'recordatorioDesafios': false,
    'descansoSemanal': true,
    'mostrarXp': true,
    'mostrarPuntos': true,
    'mostrarNivelPerfil': true,
    'mostrarRachasDiarias': true,
    'efectosRecompensa': true,
    'modoDiscreto': false,
    'objetivoPrincipal': 'Mejorar mi bienestar',
    'categoriasInteres': <String>[
      'Alimentación',
      'Hidratación',
      'Energía',
      'Bienestar',
    ],
    'dificultad': 'Moderado',
    'frecuencia': 'Diaria',
    'tema': 'Sistema',
    'tamanoTexto': 'Normal',
    'idioma': 'Español',
    'visibilidadLogros': 'Solo amigos',
    'desafiosDe': 'Todos',
    'horarioRecordatorio': '09:00',
  };

  late final FirebaseFirestore db;
  final auth = FirebaseAuth.instance;
  Map<String, dynamic> settings = Map.of(defaults);
  bool loading = true;
  bool saving = false;

  DocumentReference<Map<String, dynamic>>? get userRef {
    final user = auth.currentUser;
    return user == null ? null : db.collection('users').doc(user.uid);
  }

  @override
  void initState() {
    super.initState();
    db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final ref = userRef;
      if (ref == null) throw StateError('Debes iniciar sesión.');
      final snap = await ref.get();
      final stored = snap.data()?['settings'];
      if (!mounted) return;
      setState(() {
        settings = {
          ...defaults,
          if (stored is Map) ...Map<String, dynamic>.from(stored),
        };
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _message('No se pudieron cargar tus preferencias: $e');
    }
  }

  Future<void> _save(String key, dynamic value) async {
    final before = settings[key];
    setState(() {
      settings[key] = value;
      saving = true;
    });
    try {
      final ref = userRef;
      if (ref == null) throw StateError('Sesión cerrada');
      await ref.set({
        'settings': {key: value},
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        setState(() => settings[key] = before);
        _message('No se guardó el cambio: $e');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  bool _bool(String key) => settings[key] == true;
  String _str(String key) => (settings[key] ?? defaults[key] ?? '').toString();
  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _page(String tipo) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => InformacionAppScreen(tipo: tipo)),
  );

  Future<void> _choose(String key, String title, List<String> options) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...options.map(
                    (o) => RadioListTile<String>(
                      title: Text(o),
                      value: o,
                      groupValue: _str(key),
                      onChanged: (v) => Navigator.pop(ctx, v),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
    if (chosen != null && chosen != _str(key)) await _save(key, chosen);
  }

  Future<void> _categories() async {
    final selected = Set<String>.from(
      (settings['categoriasInteres'] as List?)?.map((e) => e.toString()) ??
          categories,
    );
    final result = await showDialog<List<String>>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, update) => AlertDialog(
                  title: const Text('Categorías de interés'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        categories
                            .map(
                              (c) => CheckboxListTile(
                                title: Text(c),
                                value: selected.contains(c),
                                onChanged:
                                    (v) => update(() {
                                      if (v == true) {
                                        selected.add(c);
                                      } else {
                                        selected.remove(c);
                                      }
                                    }),
                              ),
                            )
                            .toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed:
                          selected.isEmpty
                              ? null
                              : () => Navigator.pop(ctx, selected.toList()),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
          ),
    );
    if (result != null) await _save('categoriasInteres', result);
  }

  Future<void> _editEmail() async {
    final user = auth.currentUser;
    if (user == null) return;
    final ctrl = TextEditingController(text: user.email ?? '');
    final email = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cambiar correo'),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Nuevo correo electrónico',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('Continuar'),
              ),
            ],
          ),
    );
    ctrl.dispose();
    if (email == null || email.isEmpty || !email.contains('@')) return;
    try {
      await user.verifyBeforeUpdateEmail(email);
      _message(
        'Revisa el correo de verificación. Puede requerirse iniciar sesión de nuevo.',
      );
    } on FirebaseAuthException catch (e) {
      _message(
        e.code == 'requires-recent-login'
            ? 'Por seguridad, cierra sesión, vuelve a entrar y repite el cambio.'
            : 'No se pudo cambiar el correo: ${e.message ?? e.code}',
      );
    }
  }

  Future<void> _resetPassword() async {
    final email = auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      _message('Esta cuenta no tiene correo asociado.');
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Restablecer contraseña'),
            content: Text(
              '¿Enviar un enlace para cambiar tu contraseña a $email?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enviar'),
              ),
            ],
          ),
    );
    if (yes != true) return;
    try {
      await auth.sendPasswordResetEmail(email: email);
      _message('Enlace enviado a $email');
    } on FirebaseAuthException catch (e) {
      _message('No se pudo enviar: ${e.message ?? e.code}');
    }
  }

  Future<void> _showEvidence() async {
    final ref = userRef;
    if (ref == null) return;
    try {
      final snap = await ref.collection('temporary_habit_evidence').get();
      if (!mounted) return;
      final now = DateTime.now();
      final active =
          snap.docs.where((doc) {
            final expires = doc.data()['expiresAt'];
            return expires is! Timestamp || expires.toDate().isAfter(now);
          }).length;
      await showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Evidencias temporales'),
              content: Text(
                'Documentos encontrados: ${snap.size}\nEvidencias aún vigentes: $active\n\nLas fotos se almacenan temporalmente y su limpieza depende del servicio de evidencias de la aplicación.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
      );
    } catch (e) {
      _message('No se pudieron consultar las evidencias: $e');
    }
  }

  Future<void> _deleteAccount() async {
    final user = auth.currentUser;
    if (user == null) return;
    // No se ofrece borrado parcial: eliminar solo Auth dejaría datos personales huérfanos.
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar cuenta'),
            content: const Text(
              'Esta acción requiere un proceso seguro de eliminación integral de Authentication, Firestore y evidencias. Todavía no existe un servicio de backend verificado para hacerlo sin dejar datos huérfanos. No se ha eliminado nada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: green),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: green,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5EEE9)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: Color(0xFFF2F5F3)),
                    children[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _action(
    String title,
    VoidCallback onTap, {
    String? value,
    String? subtitle,
  }) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(
      title,
      style: const TextStyle(
        color: navy,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ),
        const Icon(Icons.chevron_right, color: muted, size: 19),
      ],
    ),
    onTap: onTap,
  );

  Widget _toggle(String key, String title, {String? subtitle}) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle:
            subtitle == null
                ? null
                : Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
        value: _bool(key),
        activeTrackColor: green,
        onChanged: saving ? null : (v) => _save(key, v),
      );

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para configurar tu cuenta.')),
      );
    }
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final selected = (settings['categoriasInteres'] as List?)?.join(', ') ?? '';
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text(
          'Configuración',
          style: TextStyle(color: navy, fontWeight: FontWeight.w900),
        ),
        actions: [
          if (saving)
            const Padding(
              padding: EdgeInsets.all(15),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          _section('CUENTA', Icons.person_outline, [
            _action(
              'Editar perfil',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
              ),
            ),
            _action(
              'Cambiar correo electrónico',
              _editEmail,
              value: user.email ?? 'Sin correo',
            ),
            _action('Cambiar contraseña', _resetPassword),
            _action(
              'Foto o avatar',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
              ),
              subtitle: 'Gestionar desde Editar perfil',
            ),
            _action(
              'Nombre de usuario',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
              ),
              value: 'Editar',
            ),
          ]),
          _section('PREFERENCIAS DE HÁBITOS', Icons.tune, [
            _action(
              'Objetivo principal',
              () => _choose('objetivoPrincipal', 'Objetivo principal', [
                'Mejorar mi bienestar',
                'Beber más agua',
                'Alimentarme mejor',
                'Tener más energía',
                'Mantener constancia',
              ]),
              value: _str('objetivoPrincipal'),
            ),
            _action('Categorías de interés', _categories, value: selected),
            _action(
              'Nivel de dificultad',
              () => _choose('dificultad', 'Dificultad', [
                'Fácil',
                'Moderado',
                'Difícil',
              ]),
              value: _str('dificultad'),
            ),
            _action(
              'Frecuencia de hábitos',
              () => _choose('frecuencia', 'Frecuencia', ['Diaria', 'Semanal']),
              value: _str('frecuencia'),
            ),
            _action(
              'Máximo de hábitos activos',
              () => _message(
                'Los espacios activos dependen de los desbloqueos del sistema de Hábitos; no se pueden aumentar desde Configuración.',
              ),
              value: 'Según desbloqueos',
            ),
            _action(
              'Recalcular mis recomendaciones',
              () => _message(
                'Tus preferencias se guardaron. La generación automática de recomendaciones requiere integrar el motor de sugerencias.',
              ),
              subtitle:
                  'Guarda tus intereses; el motor de recomendaciones está pendiente',
            ),
          ]),
          _section('ASISTENTE IA', Icons.auto_awesome_outlined, [
            _toggle(
              'analizarHistorialIA',
              'Permitir análisis del historial',
              subtitle:
                  'Consentimiento guardado; Mr.Healthy debe consultar este ajuste antes de analizar datos.',
            ),
          ]),
          _section('PRIVACIDAD Y DATOS', Icons.shield_outlined, [
            _action('Ver información de privacidad', () => _page('privacidad')),
            _action('Evidencias temporales guardadas', _showEvidence),
            _action(
              'Eliminar mi cuenta definitivamente',
              _deleteAccount,
              subtitle: 'Requiere eliminación segura desde backend',
            ),
          ]),
          _section('EXPERIENCIA VISUAL', Icons.visibility_outlined, [
            _action(
              'Tema',
              () => _choose('tema', 'Tema', ['Sistema', 'Claro', 'Oscuro']),
              value: _str('tema'),
            ),
            _toggle('sonidosApp', 'Sonidos de la app'),
            _toggle('vibracionHaptica', 'Vibración háptica'),
            _toggle('animacionesDivertidas', 'Animaciones divertidas'),
            _action(
              'Tamaño de texto',
              () => _choose('tamanoTexto', 'Tamaño de texto', [
                'Pequeño',
                'Normal',
                'Grande',
              ]),
              value: _str('tamanoTexto'),
            ),
            _action(
              'Idioma',
              () => _choose('idioma', 'Idioma', ['Español']),
              value: _str('idioma'),
            ),
          ]),
          _section('CONFIGURACIÓN SOCIAL', Icons.people_outline, [
            _action(
              'Quién puede ver mis logros',
              () => _choose('visibilidadLogros', 'Visibilidad de logros', [
                'Todos',
                'Solo amigos',
                'Solo yo',
              ]),
              value: _str('visibilidadLogros'),
            ),
            _action(
              'Quién puede enviarme desafíos',
              () => _choose('desafiosDe', 'Invitaciones a desafíos', [
                'Todos',
                'Solo amigos',
                'Nadie',
              ]),
              value: _str('desafiosDe'),
            ),
            _toggle('mostrarRachaAmigos', 'Mostrar racha a mis amigos'),
            _toggle('permitirReacciones', 'Permitir reacciones'),
            _action(
              'Administrar usuarios bloqueados',
              () => _message(
                'La lista de bloqueos necesita integración con AmigosServicio. No se han aplicado bloqueos.',
              ),
            ),
          ]),
          _section('RECORDATORIOS', Icons.notifications_none, [
            _toggle(
              'permitirRecordatorios',
              'Permitir recordatorios',
              subtitle:
                  'Preferencia guardada. No programa notificaciones del dispositivo.',
            ),
            _action('Horario preferido', () async {
              final parts = _str('horarioRecordatorio').split(':');
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.tryParse(parts.first) ?? 9,
                  minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
                ),
              );
              if (time != null) {
                await _save(
                  'horarioRecordatorio',
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                );
              }
            }, value: _str('horarioRecordatorio')),
            _toggle('recordatorioHabito', 'Recordatorios por hábito'),
            _toggle('recordatorioRacha', 'Recordatorio de racha'),
            _toggle('recordatorioDesafios', 'Recordatorios de desafíos'),
            _toggle('descansoSemanal', 'Descanso semanal'),
          ]),
          _section('GAMIFICACIÓN', Icons.emoji_events_outlined, [
            _toggle('mostrarXp', 'Mostrar XP lograda'),
            _toggle('mostrarPuntos', 'Mostrar Habit Coins'),
            _toggle('mostrarNivelPerfil', 'Mostrar nivel en perfil'),
            _toggle('mostrarRachasDiarias', 'Mostrar rachas diarias'),
            _toggle('efectosRecompensa', 'Efectos visuales de recompensa'),
            _toggle('modoDiscreto', 'Modo discreto'),
          ]),
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              'Los ajustes de visualización, funciones sociales, IA y avisos se guardan en tu cuenta. Para aplicarlos en todas las pantallas, cada módulo debe leer estas preferencias.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
          _section('INFORMACIÓN Y SOPORTE', Icons.info_outline, [
            _action('Acerca de Healthy Habit', () => _page('acerca')),
            _action('Términos de uso', () => _page('terminos')),
            _action('Aviso de privacidad', () => _page('privacidad')),
            _action(
              'Versión de la aplicación',
              () => _message(
                'Versión: consultar pubspec.yaml / compilación instalada.',
              ),
              value: 'Ver detalle',
            ),
            _action('Ayuda y soporte técnico', () => _page('ayuda')),
          ]),
        ],
      ),
    );
  }
}
