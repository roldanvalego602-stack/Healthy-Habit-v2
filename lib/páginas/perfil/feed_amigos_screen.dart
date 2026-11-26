import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import 'amigos_servicio.dart';
import 'buscar_amigos_screen.dart';
import 'perfil_muestra.dart';
import 'reaction_picker_dialog.dart';

/// Cronología de eventos confirmados por el servidor, nunca estados de perfil
/// presentados como noticias. Solo lectura; no concede premios ni XP.
class FeedAmigosScreen extends StatefulWidget {
  const FeedAmigosScreen({super.key});

  @override
  State<FeedAmigosScreen> createState() => _FeedAmigosScreenState();
}

class _FeedAmigosScreenState extends State<FeedAmigosScreen> {
  Future<List<_FriendEvent>>? _loading;
  String? _loadedFor;
  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
    app: Firebase.app(), databaseId: 'default');

  Future<List<_FriendEvent>> _read(String uid) async {
    final friends = await AmigosServicio.amigos(uid).first;
    final ids = friends.docs.map((d) => d.id).take(30).toList();
    if (ids.isEmpty) return const [];
    // Las reglas del servidor son la autoridad sobre visibilidad y amistad;
    // ninguna fecha, XP o logro se infiere del perfil editable.
    final profiles = await AmigosServicio.perfiles(ids);
    final requests = await Future.wait(ids.map((id) =>
        _db.collection('public_profiles').doc(id)
          .collection('activity_events')
          .orderBy('createdAt', descending: true).limit(15).get()));
    final events = <_FriendEvent>[];
    for (var i = 0; i < ids.length; i++) {
      final id = ids[i];
      final profile = profiles[id] ?? const <String, dynamic>{};
      for (final event in requests[i].docs) {
        final data = event.data();
        if (data['actorUid'] != id ||
            !const {'level_up', 'habit_completed', 'achievement_unlocked'}
                .contains(data['kind']) ||
            data['createdAt'] is! Timestamp) continue;
        final level = data['level'];
        if (data['kind'] == 'level_up' &&
            (level is! int || level < 2 || level > 1000)) continue;
        final habitId = data['habitId']?.toString() ?? '';
        if (data['kind'] == 'habit_completed' && habitId.isEmpty) continue;
        if (data['kind'] == 'achievement_unlocked' &&
            !const {'primera_meta', 'triple_victoria', 'cinco_logros',
              'nivel_3', 'nivel_5', 'racha_3', 'racha_7', 'racha_30'}
                .contains(data['achievementId'])) continue;
        events.add(_FriendEvent(
          eventId: event.id, uid: id, data: data,
          name: (profile['name'] ?? 'Tu amigo').toString(),
          photo: (profile['photoUrl'] ?? '').toString(),
          date: (data['createdAt'] as Timestamp).toDate(),
        ));
      }
    }
    events.sort((a, b) => b.date.compareTo(a.date));
    return events.take(70).toList();
  }

  void _refresh(String uid) => setState(() {
    _loadedFor = uid;
    _loading = _read(uid);
  });

  @override
  Widget build(BuildContext context) {
    final uid = AmigosServicio.uidActual;
    if (uid != null && (_loading == null || _loadedFor != uid)) {
      _loadedFor = uid;
      _loading = _read(uid);
    }
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(
        title: const Text('Actividad de amigos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar actividad',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: uid == null ? null : () => _refresh(uid),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Inicia sesión para ver a tus amigos.'))
          : FutureBuilder<List<_FriendEvent>>(
              future: _loading,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _message(
                    'No se pudo leer la actividad',
                    'La cronología necesita permisos del servidor para '
                    'eventos reales. No mostramos logros inventados.',
                    action: () => _refresh(uid),
                    label: 'Reintentar',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final events = snapshot.data!;
                if (events.isEmpty) {
                  return _message(
                    'Todavía no hay actividad para mostrar',
                    'Aquí aparecerán los niveles y hábitos completados '
                    'que el servidor confirme de tus amigos.',
                    action: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BuscarAmigosScreen())),
                    label: 'Buscar amigos',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(uid),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _eventTile(uid, events[index]),
                  ),
                );
              },
            ),
    );
  }

  static const _achievementTitles = <String, String>{
    'primera_meta': 'Meta cumplida',
    'triple_victoria': 'Triple victoria',
    'cinco_logros': 'Cinco objetivos',
    'nivel_3': 'En crecimiento',
    'nivel_5': 'Cultivador experto',
    'racha_3': 'Tres días de constancia',
    'racha_7': 'Semana imparable',
    'racha_30': 'Constancia legendaria',
  };

  Widget _eventTile(String me, _FriendEvent event) {
    final level = event.data['kind'] == 'level_up';
    final achievement = event.data['kind'] == 'achievement_unlocked';
    final title = level
        ? '${event.name} alcanzó el nivel ${event.data['level']}'
        : achievement
            ? '${event.name} consiguió el logro '
              '${_achievementTitles[event.data['achievementId']] ?? 'nuevo'}'
            : '${event.name} compartió un hábito completado';
    final when = event.date.toLocal();
    final localDate = '${when.day.toString().padLeft(2, '0')}/'
        '${when.month.toString().padLeft(2, '0')}/${when.year} '
        '${when.hour.toString().padLeft(2, '0')}:'
        '${when.minute.toString().padLeft(2, '0')}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: event.photo.startsWith('https://')
                  ? NetworkImage(event.photo) : null,
              child: event.photo.startsWith('https://')
                  ? null : const Icon(Icons.person_outline_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: HealthyAdaptive.text)),
                Text(localDate, style: TextStyle(
                    fontSize: 11, color: HealthyAdaptive.muted)),
              ],
            )),
            Icon(level ? Icons.trending_up_rounded :
                  achievement ? Icons.emoji_events_rounded :
                  Icons.verified_rounded,
              color: HealthyAdaptive.accent),
          ]),
          if (!level && !achievement) ...[
            const SizedBox(height: 9),
            const Text('Actividad finalizada y confirmada por el servidor.',
                style: TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 9),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.add_reaction_outlined, size: 16),
              label: const Text('Reaccionar'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ReactionPickerDialog(
                  fromUid: me,
                  toUid: event.uid,
                  friendName: event.name,
                  eventId: event.eventId,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context,
                MaterialPageRoute<void>(
                  builder: (_) => PublicProfileScreen(
                    userId: event.uid,
                    name: event.name,
                    username: '',
                  ))),
              child: const Text('Ver perfil'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _message(String title, String description,
      {required VoidCallback action, required String label}) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.dynamic_feed_outlined, size: 48),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(description, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        FilledButton(onPressed: action, child: Text(label)),
      ]),
    ));
  }
}

class _FriendEvent {
  const _FriendEvent({
    required this.eventId, required this.uid, required this.data,
    required this.name, required this.photo, required this.date,
  });
  final String eventId, uid, name, photo;
  final Map<String, dynamic> data;
  final DateTime date;
}
