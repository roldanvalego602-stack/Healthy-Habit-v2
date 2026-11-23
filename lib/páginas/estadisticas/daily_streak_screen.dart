import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Racha diaria y recompensas verificadas por el servidor.
/// Los registros heredados de Flutter se muestran, pero no otorgan monedas.
class DailyStreakScreen extends StatefulWidget {
  const DailyStreakScreen({super.key});

  @override
  State<DailyStreakScreen> createState() => _DailyStreakScreenState();
}

class _DailyStreakScreenState extends State<DailyStreakScreen> {
  String? _claiming;

  int _number(dynamic value) => value is num ? value.toInt() : 0;

  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int _daysAgo(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return 100000;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(DateTime(parsed.year, parsed.month, parsed.day))
        .inDays;
  }

  int _activeStreak(int stored, String lastDay) {
    final elapsed = _daysAgo(lastDay);
    return elapsed == 0 || elapsed == 1 ? stored : 0;
  }

  int _reward(int streak) {
    if (streak >= 7) return 5;
    if (streak >= 4) return 4;
    if (streak >= 2) return 3;
    return 2;
  }

  Future<void> _claim(String day) async {
    if (_claiming != null) return;
    setState(() => _claiming = day);
    try {
      final callable = FirebaseFunctions.instanceFor(
        app: Firebase.app(), region: 'us-central1',
      ).httpsCallable('claimDailyStreakReward');
      final result = await callable.call<Map<String, dynamic>>({'day': day});
      if (!mounted) return;
      final amount = _number(result.data['coinsAwarded']);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.data['alreadyClaimed'] == true
            ? 'Este premio ya había sido reclamado.'
            : '¡Premio recogido! +$amount Habit Coins'),
      ));
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.code == 'not-found'
            ? 'Las recompensas diarias aún no están desplegadas.'
            : 'No se pudo reclamar el premio: ${error.message ?? error.code}'),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo reclamar el premio. Revisa tu conexión.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _claiming = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver tu racha.')),
      );
    }
    final userRef = FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    ).collection('users').doc(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi racha diaria 🔥')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userRef.snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return const Center(child: Text('No se pudo cargar la racha.'));
          }
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = userSnapshot.data!.data() ?? <String, dynamic>{};
          final server = profile['serverLastStreakDay'] is String;
          final latest = (profile[server
              ? 'serverLastStreakDay' : 'lastStreakDate'] ?? '').toString();
          final rawStreak = _number(profile[server
              ? 'serverStreakDays' : 'currentStreak']);
          final streak = _activeStreak(rawStreak, latest);
          final best = _number(profile[server
              ? 'serverLongestStreak' : 'longestStreak']);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: Color(0xFFED9230), size: 52),
                      const SizedBox(height: 8),
                      Text('$streak días',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      Text(streak == 0
                          ? 'Registra una actividad válida para iniciar.'
                          : _daysAgo(latest) == 0
                              ? '¡Ya registraste actividad hoy!'
                              : 'Registra una actividad hoy para mantenerla.'),
                      const SizedBox(height: 12),
                      Text('Mejor racha: $best días'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Recompensas por constancia',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Un día cuenta al registrar una actividad válida. '
                'Las monedas solo se otorgan mediante registros '
                'verificados por el servidor.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    return Container(
                      width: 94,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: day <= streak
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Día $day', style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('🪙 +${_reward(day)}'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text('Premios por recoger',
                  style: Theme.of(context).textTheme.titleMedium),
              if (!server)
                const Card(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Tu racha histórica se conserva. Para desbloquear los '
                    'premios diarios debemos conectar el registro habitual '
                    'al motor oficial seguro de Cloud Functions.',
                  ),
                ))
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: userRef.collection('daily_streak_days')
                      .orderBy('day', descending: true).limit(14).snapshots(),
                  builder: (context, daysSnapshot) {
                    if (daysSnapshot.hasError) {
                      return const Card(child: ListTile(
                        title: Text('No se pudo consultar el historial de premios.'),
                      ));
                    }
                    if (!daysSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final days = daysSnapshot.data!.docs;
                    if (days.isEmpty) {
                      return const Card(child: ListTile(
                        title: Text('Aún no tienes premios verificados.'),
                      ));
                    }
                    return Column(children: [
                      for (final doc in days)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.card_giftcard_rounded),
                            title: Text('Día ${doc.id} · '
                                '${_reward(_number(doc.data()['streak']))} monedas'),
                            subtitle: Text(doc.data()['claimed'] == true
                                ? 'Recogido' : 'Listo para recoger'),
                            trailing: doc.data()['claimed'] == true
                                ? const Icon(Icons.check_circle_outline)
                                : FilledButton(
                                    onPressed: _claiming == null
                                        ? () => _claim(doc.id) : null,
                                    child: Text(_claiming == doc.id
                                        ? 'Reclamando…' : 'Recoger'),
                                  ),
                          ),
                        ),
                    ]);
                  },
                ),
              const SizedBox(height: 18),
              Text(
                'La racha se calcula por día calendario. Si pasa más de '
                'un día sin actividad válida, vuelve a empezar en cero. '
                'No se entregan monedas por registros históricos sin verificar.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
