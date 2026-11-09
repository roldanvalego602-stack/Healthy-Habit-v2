import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'logros_service.dart';

class LogrosScreen extends StatelessWidget {
  const LogrosScreen({super.key});
  static const _green = Color(0xFF08B889);
  static const _navy = Color(0xFF193344);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para consultar tus logros.')),
      );
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    final ref = db.collection('users').doc(user.uid);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text(
          'Mis logros',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF5F8F6),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: _green,
              indicatorColor: _green,
              tabs: [Tab(text: 'Logros'), Tab(text: 'Desafíos')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: ref.snapshots(),
                    builder: (context, profile) {
                      if (profile.hasError)
                        return const Center(
                          child: Text('No se pudo consultar tu perfil.'),
                        );
                      if (!profile.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final data = profile.data!.data() ?? <String, dynamic>{};
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: ref.collection('user_habits').snapshots(),
                        builder: (context, habits) {
                          if (habits.hasError)
                            return const Center(
                              child: Text(
                                'No se pudieron consultar los hábitos.',
                              ),
                            );
                          if (!habits.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          final docs = habits.data!.docs;
                          final completados =
                              docs
                                  .where(
                                    (d) =>
                                        d.data()['latestStatus'] == 'completed',
                                  )
                                  .length;
                          return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>
                          >(
                            stream: ref.collection('achievements').snapshots(),
                            builder: (context, achievements) {
                              if (achievements.hasError)
                                return const Center(
                                  child: Text(
                                    'No se pudieron consultar las medallas.',
                                  ),
                                );
                              if (!achievements.hasData)
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              final ids =
                                  achievements.data!.docs
                                      .map((d) => d.id)
                                      .toSet();
                              final obtenidos =
                                  LogrosService.catalogo
                                      .where(
                                        (l) => LogrosService.obtenido(
                                          l,
                                          LogrosService.progreso(
                                            l,
                                            data,
                                            docs.length,
                                            completados,
                                            ids,
                                          ),
                                        ),
                                      )
                                      .length;
                              return ListView(
                                padding: const EdgeInsets.all(18),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tu colección de medallas',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                            color: _navy,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$obtenidos de ${LogrosService.catalogo.length} logros conseguidos',
                                        ),
                                        const SizedBox(height: 10),
                                        LinearProgressIndicator(
                                          value:
                                              obtenidos /
                                              LogrosService.catalogo.length,
                                          minHeight: 8,
                                          color: _green,
                                          backgroundColor: const Color(
                                            0xFFE6EEE9,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Las medallas nuevas se calculan con tu progreso actual. No otorgan recompensas adicionales.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ...LogrosService.catalogo.map((logro) {
                                    final progreso = LogrosService.progreso(
                                      logro,
                                      data,
                                      docs.length,
                                      completados,
                                      ids,
                                    );
                                    final obtenido = LogrosService.obtenido(
                                      logro,
                                      progreso,
                                    );
                                    return Card(
                                      color: Colors.white,
                                      elevation: 0,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor:
                                                  obtenido
                                                      ? const Color(0xFFDDF8EC)
                                                      : const Color(0xFFF0F2F3),
                                              child: Icon(
                                                obtenido
                                                    ? logro.icono
                                                    : Icons
                                                        .lock_outline_rounded,
                                                color:
                                                    obtenido
                                                        ? _green
                                                        : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    logro.nombre,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: _navy,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    obtenido
                                                        ? '¡Conseguido! ${logro.descripcion}'
                                                        : logro.descripcion,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  LinearProgressIndicator(
                                                    value: (progreso /
                                                            logro.meta)
                                                        .clamp(0.0, 1.0),
                                                    minHeight: 5,
                                                    color: _green,
                                                    backgroundColor:
                                                        const Color(0xFFE8EEEE),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    obtenido
                                                        ? (logro.id ==
                                                                LogrosService
                                                                    .primerPasoId
                                                            ? '+25 XP · +10 Habit Coins (recompensa existente)'
                                                            : 'Medalla desbloqueada')
                                                        : '${progreso.clamp(0, logro.meta)} / ${logro.meta}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          obtenido
                                                              ? _green
                                                              : Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Los desafíos se incorporarán más adelante.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
