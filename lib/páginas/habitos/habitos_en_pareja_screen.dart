import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import '../perfil/amigos_servicio.dart';
import 'catalogo.dart';
import 'habitos_pareja_servicio.dart';

/// Invitaciones y participación voluntaria en hábitos con un amigo.
/// El avance se registra en la cuenta de cada persona, no se comparte XP.
class HabitosEnParejaScreen extends StatefulWidget {
  const HabitosEnParejaScreen({super.key, this.initialHabitId});
  final String? initialHabitId;
  @override
  State<HabitosEnParejaScreen> createState() => _HabitosEnParejaScreenState();
}

class _HabitosEnParejaScreenState extends State<HabitosEnParejaScreen> {
  final _service = const HabitosParejaServicio();
  String? _sending;
  String? _busy;
  String? get _uid => AmigosServicio.uidActual;

  void _message(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _invite() async {
    final me = _uid;
    if (me == null || _sending != null) return;
    final friends = await AmigosServicio.amigos(me).first;
    if (!mounted) return;
    if (friends.docs.isEmpty) {
      _message('Primero agrega un amigo y acepta su solicitud.');
      return;
    }
    final ids = friends.docs.map((e) => e.id).toList();
    final profiles = await AmigosServicio.perfiles(ids);
    if (!mounted) return;
    final pairs = ids.where(profiles.containsKey).toList();
    if (pairs.isEmpty) {
      _message('Los perfiles públicos de tus amigos no están disponibles.');
      return;
    }
    String recipient = pairs.first;
    String habitId = habitCatalog.any((e) =>
        e['id'] == widget.initialHabitId)
        ? widget.initialHabitId!
        : habitCatalog.first['id'] as String;

    final confirmed = await showDialog<bool>(context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Invitar a realizar un hábito'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                key: const ValueKey('pair-recipient'),
                value: recipient,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Amigo'),
                items: [
                  for (final id in pairs)
                    DropdownMenuItem(value: id, child: Text(
                      (profiles[id]?['name'] ?? 'Usuario').toString(),
                      overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (value) {
                  if (value != null) update(() => recipient = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: const ValueKey('pair-habit'),
                value: habitId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Hábito oficial'),
                items: [
                  for (final item in habitCatalog)
                    DropdownMenuItem(
                      value: item['id'] as String,
                      child: Text(item['title'] as String,
                        overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (value) {
                  if (value != null) update(() => habitId = value);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu amigo podrá aceptar o rechazar. Cada uno '
                'debe activar y registrar su hábito por separado. '
                'Compartir no concede recompensas adicionales.',
                style: TextStyle(fontSize: 12)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar invitación')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sending = recipient);
    try {
      await _service.invitar(recipient, habitId);
      _message('Invitación enviada. Tu amigo debe aceptarla.');
    } catch (error) {
      _message('No se pudo enviar: $error');
    } finally {
      if (mounted) setState(() => _sending = null);
    }
  }

  Future<void> _act(
      String id, String habitId, String action) async {
    if (_busy != null) return;
    setState(() => _busy = id);
    try {
      if (action == 'accept') {
        await _service.responder(id, aceptar: true);
      } else if (action == 'reject') {
        await _service.responder(id, aceptar: false);
      } else if (action == 'cancel') {
        await _service.cancelar(id);
      } else if (action == 'finish') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Terminar hábito en pareja'),
            content: const Text(
              'Dejarán de realizar este hábito juntos. '
              'Los hábitos y registros personales se conservan.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Terminar')),
            ],
          ),
        );
        if (confirmed != true) return;
        await _service.terminar(id);
      } else if (action == 'activate') {
        final ok = await showDialog<bool>(context: context,
          builder: (context) => AlertDialog(
            title: const Text('Activar hábito personal'),
            content: const Text(
              'Se aplicarán los cupos, desbloqueos y costos normales '
              'del catálogo. No recibirás XP por activarlo. '
              '¿Quieres continuar?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Activar')),
            ],
          ),
        );
        if (ok != true) return;
        await _service.activarHabito(habitId);
      }
      _message(action == 'activate'
          ? 'Hábito activado en tu cuenta. Ya puedes registrar sesiones.'
          : 'Solicitud actualizada.');
    } catch (error) {
      _message('No se pudo completar: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _invitations(
      QuerySnapshot<Map<String, dynamic>> snapshot, String side) {
    final items = snapshot.docs.where((doc) =>
      doc.data()['status'] == 'pendiente' ||
      doc.data()['status'] == 'aceptada').toList()
      ..sort((a, b) {
        final ta = a.data()['createdAt'];
        final tb = b.data()['createdAt'];
        if (ta is Timestamp && tb is Timestamp) {
          return tb.compareTo(ta);
        }
        return 0;
      });
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(side == 'received'
          ? 'No hay invitaciones recibidas.'
          : 'No hay invitaciones enviadas.'),
      );
    }
    return Column(children: [
      for (final item in items)
        Card(
          key: ValueKey('pair-invitation-${item.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((item.data()['habitTitle'] ?? 'Hábito').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(item.data()['status'] == 'aceptada'
                  ? 'Invitación aceptada. Ambos pueden activar el hábito.'
                  : side == 'received'
                    ? 'Un amigo quiere realizar este hábito contigo.'
                    : 'Esperando la respuesta de tu amigo.'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  if (side == 'received' &&
                      item.data()['status'] == 'pendiente') ...[
                    OutlinedButton(
                      onPressed: _busy == null ? () => _act(item.id,
                        '', 'reject') : null,
                      child: const Text('Rechazar')),
                    FilledButton(
                      onPressed: _busy == null ? () => _act(item.id,
                        '', 'accept') : null,
                      child: const Text('Aceptar')),
                  ],
                  if (side == 'sent' &&
                      item.data()['status'] == 'pendiente')
                    OutlinedButton(
                      onPressed: _busy == null ? () => _act(item.id,
                        '', 'cancel') : null,
                      child: const Text('Cancelar invitación')),
                  if (item.data()['status'] == 'aceptada')
                    FilledButton.tonalIcon(
                      onPressed: _busy == null ? () => _act(
                        item.id,
                        (item.data()['habitId'] ?? '').toString(),
                        'activate',
                      ) : null,
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text('Activar mi hábito'),
                    ),
                  if (item.data()['status'] == 'aceptada')
                    TextButton(
                      onPressed: _busy == null ? () =>
                        _act(item.id, '', 'finish') : null,
                      child: const Text('Terminar pareja'),
                    ),
                ]),
              ]),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver hábitos en pareja.')),
      );
    }
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(title: const Text('Hábitos en pareja')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sending == null ? () {
          _invite().catchError((Object error) {
            _message('No se pudieron consultar tus amigos: $error');
          });
        } : null,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(_sending == null ? 'Invitar amigo' : 'Enviando...'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text('Realicen un mismo hábito, cada uno a su ritmo.',
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Las invitaciones son voluntarias. Los registros, '
            'las fotografías, las notas y el XP permanecen separados.',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Text('Recibidas', style: Theme.of(context).textTheme.titleLarge),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.recibidas(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Text(
                  'No se pudieron consultar las invitaciones. '
                  'Verifica las reglas de Firestore.');
              }
              if (!snap.hasData) {
                return const LinearProgressIndicator();
              }
              return _invitations(snap.data!, 'received');
            },
          ),
          const SizedBox(height: 14),
          Text('Enviadas', style: Theme.of(context).textTheme.titleLarge),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.enviadas(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Text(
                  'No se pudieron consultar las invitaciones enviadas.');
              }
              if (!snap.hasData) {
                return const LinearProgressIndicator();
              }
              return _invitations(snap.data!, 'sent');
            },
          ),
        ],
      ),
    );
  }
}
