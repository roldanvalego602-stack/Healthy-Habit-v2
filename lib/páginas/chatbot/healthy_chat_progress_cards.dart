import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../tema/healthy_theme.dart';
import '../../tema/healthy_visual_mode.dart';
import '../logros/logros_service.dart';

FirebaseFirestore get _healthyDb => FirebaseFirestore.instanceFor(
  app: Firebase.app(), databaseId: 'default');

/// Barra de progreso sin efectos continuos; Lite presenta el valor final.
class HealthyChatProgressTile extends StatelessWidget {
  const HealthyChatProgressTile({
    super.key,
    required this.title,
    required this.progress,
    required this.description,
    this.icon = Icons.flag_outlined,
  });

  final String title;
  final double progress;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final target = progress.clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: HealthyAdaptive.accent),
            const SizedBox(width: 7),
            Expanded(child: Text(title,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: HealthyAdaptive.text,
                fontSize: 12, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(
            color: HealthyAdaptive.muted, fontSize: 10.5)),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            key: ValueKey('chat-progress-$title-$target'),
            tween: Tween(begin: HealthyVisualEffects.enabled(context)
                ? 0.0 : target, end: target),
            duration: HealthyVisualEffects.duration(
                context, const Duration(milliseconds: 550)),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value, minHeight: 7,
                color: HealthyAdaptive.accent,
                backgroundColor: HealthyAdaptive.border,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HealthyChatChallengesCard extends StatelessWidget {
  const HealthyChatChallengesCard({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text('Inicia sesión para consultar desafíos.');
    return _moduleCard(
      context,
      icon: Icons.flag_rounded,
      heading: 'Tus desafíos',
      onOpen: onOpen,
      buttonLabel: 'Abrir Desafíos',
      content: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _healthyDb.collection('users').doc(uid)
            .collection('challenges').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text(
            'No pude consultar tus desafíos. Revisa la conexión y los permisos.');
          if (!snapshot.hasData) {
            return const Center(child: LinearProgressIndicator());
          }
          final all = snapshot.data!.docs;
          if (all.isEmpty) return Text(
            'Todavía no hay desafíos en tu cuenta. '
            'Abre Desafíos para cargar los disponibles.',
            style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12));
          final active = all.where((d) =>
              d.data()['status'] == 'inProgress').toList();
          final claimable = all.where((d) =>
              d.data()['status'] == 'completed').toList();
          final available = all.where((d) =>
              d.data()['status'] == 'available').toList();
          final chosen = <QueryDocumentSnapshot<Map<String, dynamic>>>[
            ...claimable, ...active, ...available,
          ].take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${active.length} activos · '
                  '${claimable.length} por reclamar · '
                  '${available.length} disponibles',
                  style: TextStyle(color: HealthyAdaptive.muted,
                    fontSize: 11)),
              const SizedBox(height: 5),
              Text(
                'Nota: los desafíos iniciales de Healthy Habit pueden '
                'incluir valores de demostración hasta integrar su seguimiento real.',
                style: TextStyle(color: HealthyAdaptive.muted,
                  fontSize: 10.5),
              ),
              for (final doc in chosen)
                HealthyChatProgressTile(
                  title: (doc.data()['title'] ?? 'Desafío').toString(),
                  progress: _fraction(doc.data()['currentProgress'],
                      doc.data()['totalProgress']),
                  description: _challengeStatus(doc.data()),
                  icon: Icons.flag_outlined,
                ),
              if (chosen.isEmpty) Text(
                'No hay desafíos pendientes; revisa el módulo para más detalles.',
                style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12)),
            ],
          );
        },
      ),
    );
  }

  static double _fraction(Object? rawCurrent, Object? rawGoal) {
    final current = LogrosService.entero(rawCurrent);
    final goal = LogrosService.entero(rawGoal, 1);
    return goal <= 0 ? 0 : (current / goal).clamp(0.0, 1.0).toDouble();
  }

  static String _challengeStatus(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? '';
    final n = LogrosService.entero(data['currentProgress']);
    final goal = LogrosService.entero(data['totalProgress'], 1);
    if (status == 'completed') return 'Completado · recompensa pendiente';
    if (status == 'available') return 'Disponible para aceptar';
    return '$n de $goal registros';
  }
}

class HealthyChatAchievementsCard extends StatelessWidget {
  const HealthyChatAchievementsCard({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text('Inicia sesión para consultar logros.');
    final user = _healthyDb.collection('users').doc(uid);
    return _moduleCard(
      context,
      heading: 'Logros e insignias',
      icon: Icons.workspace_premium_rounded,
      onOpen: onOpen,
      buttonLabel: 'Abrir Logros',
      content: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: user.snapshots(),
        builder: (context, profile) {
          if (profile.hasError) return const Text('No pude cargar tu perfil.');
          if (!profile.hasData) {
            return const Center(child: LinearProgressIndicator());
          }
          final data = profile.data!.data() ?? <String, dynamic>{};
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: user.collection('user_habits').snapshots(),
            builder: (context, habits) {
              if (habits.hasError) {
                return const Text('No pude consultar tus hábitos.');
              }
              if (!habits.hasData) {
                return const Center(child: LinearProgressIndicator());
              }
              final documents = habits.data!.docs;
              final completed = documents.where((d) =>
                  d.data()['latestStatus'] == 'completed').length;
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: user.collection('achievements').snapshots(),
                builder: (context, achievements) {
                  if (achievements.hasError) {
                    return const Text('No pude consultar tus insignias.');
                  }
                  if (!achievements.hasData) {
                    return const Center(child: LinearProgressIndicator());
                  }
                  final ids = achievements.data!.docs.map((d) => d.id).toSet();
                  final statuses = [
                    for (final def in LogrosService.catalogo)
                      (
                        definition: def,
                        current: LogrosService.progreso(
                          def, data, documents.length, completed, ids),
                      ),
                  ];
                  final unlocked = statuses.where((s) =>
                      LogrosService.obtenido(
                          s.definition, s.current)).length;
                  final pending = statuses.where((s) =>
                      !LogrosService.obtenido(
                          s.definition, s.current)).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$unlocked de ${statuses.length} logros alcanzados',
                          style: TextStyle(
                            color: HealthyAdaptive.muted, fontSize: 11)),
                      for (final goal in pending.take(2))
                        HealthyChatProgressTile(
                          title: goal.definition.nombre,
                          progress: goal.definition.meta == 0 ? 0 :
                              (goal.current / goal.definition.meta)
                                  .clamp(0.0, 1.0).toDouble(),
                          description: '${goal.current}/${goal.definition.meta} '
                              '· ${goal.definition.descripcion}',
                          icon: goal.definition.icono,
                        ),
                      if (pending.isEmpty) const Text(
                        '¡Has alcanzado todos los logros disponibles!',
                        style: TextStyle(fontSize: 12)),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Widget _moduleCard(
  BuildContext context, {
  required String heading,
  required IconData icon,
  required Widget content,
  required VoidCallback onOpen,
  required String buttonLabel,
}) {
  return Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: HealthyAdaptive.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: HealthyAdaptive.border),
    ),
    child: AnimatedSize(
      duration: HealthyVisualEffects.duration(
        context, const Duration(milliseconds: 240)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(icon, color: HealthyAdaptive.accent),
            const SizedBox(width: 8),
            Expanded(child: Text(heading,
              style: TextStyle(color: HealthyAdaptive.text,
                fontSize: 14, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 11),
          content,
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new_rounded, size: 17),
            label: Text(buttonLabel),
          ),
        ],
      ),
    ),
  );
}
