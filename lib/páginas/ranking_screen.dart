import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  static const green = Color(0xFF08B889);
  static const ink = Color(0xFF193344);

  int _int(dynamic value, [int fallback = 0]) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver el ranking.')),
      );
    }

    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text(
          'Ranking de Healthy Habit',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF5F8F6),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            db
                .collection('users')
                .orderBy('xp', descending: true)
                .limit(100)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No se pudo consultar el ranking. '
                  'Comprueba los permisos de lectura de Firestore.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('Todavía no hay participantes.'));
          }

          final myIndex = users.indexWhere((u) => u.id == uid);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const Text(
                'Cada hábito cuenta',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Clasificación global por experiencia acumulada. '
                'Se muestran hasta 100 usuarios.',
                style: TextStyle(color: Color(0xFF71879A)),
              ),
              const SizedBox(height: 18),

              // TU POSICIÓN
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF143834),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TU POSICIÓN',
                      style: TextStyle(
                        color: Color(0xFFBCEBDC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      myIndex < 0 ? 'Fuera del top 100' : '#${myIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      myIndex < 0
                          ? 'Sigue ganando XP para entrar '
                              'en la clasificación.'
                          : '${_int(users[myIndex].data()['xp'])} '
                              'XP acumulados',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // PODIO
              const Text(
                'Los primeros lugares',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (users.length > 1)
                    Expanded(child: _podium(users[1], 2, 104))
                  else
                    const Expanded(child: SizedBox()),

                  const SizedBox(width: 8),

                  Expanded(child: _podium(users[0], 1, 125)),

                  const SizedBox(width: 8),

                  if (users.length > 2)
                    Expanded(child: _podium(users[2], 3, 92))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),

              const SizedBox(height: 22),

              // CLASIFICACIÓN GENERAL
              const Text(
                'Clasificación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 10),

              ...List.generate(users.length, (i) {
                final doc = users[i];
                final data = doc.data();
                final isMe = doc.id == uid;

                final name = (data['name'] ?? 'Usuario').toString().trim();

                final photo = (data['photoUrl'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFE2F7ED) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: isMe ? Border.all(color: green, width: 1.5) : null,
                  ),
                  child: ListTile(
                    leading: SizedBox(
                      width: 62,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 27,
                            child: Text(
                              '#${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: const Color(0xFFE2F7ED),
                            backgroundImage:
                                photo.startsWith('https://')
                                    ? NetworkImage(photo)
                                    : null,
                            child:
                                photo.startsWith('https://')
                                    ? null
                                    : const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: green,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      '${name.isEmpty ? 'Usuario' : name}'
                      '${isMe ? ' (Tú)' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('Nivel ${_int(data['level'], 1)}'),
                    trailing: Text(
                      '${_int(data['xp'])} XP',
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  // TARJETA DEL PODIO
  Widget _podium(
    QueryDocumentSnapshot<Map<String, dynamic>> user,
    int rank,
    double height,
  ) {
    final data = user.data();
    final name = (data['name'] ?? 'Usuario').toString();

    return Container(
      height: height + 72,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
      decoration: BoxDecoration(
        color: rank == 1 ? const Color(0xFFFDE89D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            rank == 1
                ? Icons.emoji_events_rounded
                : Icons.military_tech_rounded,
            color: rank == 1 ? const Color(0xFFB88500) : green,
            size: 29,
          ),
          const SizedBox(height: 6),
          Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name.trim().isEmpty ? 'Usuario' : name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
          ),
          const SizedBox(height: 5),
          Text('${_int(data['xp'])} XP', style: const TextStyle(color: ink)),
        ],
      ),
    );
  }
}
