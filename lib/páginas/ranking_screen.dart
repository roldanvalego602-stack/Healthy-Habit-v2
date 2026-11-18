import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'niveles/levels_system.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  static const green = Color(0xFF08B889);
  static const ink = Color(0xFF193344);
  static const background = Color(0xFFF5F8F6);
  static const muted = Color(0xFF71879A);

  int _int(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  int _xp(Map<String, dynamic> data) {
    final value = _int(data['xp'] ?? data['currentXp']);
    return value < 0 ? 0 : value;
  }

  String _name(Map<String, dynamic> data) {
    final name = (data['name'] ?? 'Usuario').toString().trim();
    return name.isEmpty ? 'Usuario' : name;
  }

  String _photo(Map<String, dynamic> data) {
    return (data['photoUrl'] ?? '').toString().trim();
  }

  Widget _levelBadge(int xp, {double size = 35}) {
    final level = LevelSystem.fromXp(xp);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: level.accentColor.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: level.accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Icon(level.icon, color: level.accentColor, size: size * 0.55),
    );
  }

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
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Ranking de Healthy Habit',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: background,
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
            return const Center(child: CircularProgressIndicator(color: green));
          }

          final users = snapshot.data!.docs;
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
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 18),

              _myPosition(users, myIndex),

              const SizedBox(height: 22),

              if (users.isNotEmpty) ...[
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
                      Expanded(child: _podium(users[1], 2, 118))
                    else
                      const Expanded(child: SizedBox()),
                    const SizedBox(width: 8),
                    Expanded(child: _podium(users[0], 1, 140)),
                    const SizedBox(width: 8),
                    if (users.length > 2)
                      Expanded(child: _podium(users[2], 3, 105))
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 22),
              ],

              const Text(
                'Clasificación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 10),

              if (users.isEmpty)
                _emptyRanking()
              else
                ...List.generate(users.length, (index) {
                  return _rankingTile(
                    users[index],
                    index + 1,
                    users[index].id == uid,
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _myPosition(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    int myIndex,
  ) {
    final inRanking = myIndex >= 0;
    final data = inRanking ? users[myIndex].data() : <String, dynamic>{};

    final xp = _xp(data);
    final level = LevelSystem.fromXp(xp);

    return Container(
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
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  inRanking ? '#${myIndex + 1}' : 'Fuera del top 100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (inRanking) _levelBadge(xp, size: 47),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            inRanking
                ? '$xp XP acumulados'
                : 'Sigue ganando XP para entrar en la clasificación.',
            style: const TextStyle(color: Colors.white70),
          ),
          if (inRanking) ...[
            const SizedBox(height: 5),
            Text(
              'Nivel ${level.number} · ${level.name}',
              style: const TextStyle(
                color: Color(0xFFBCEBDC),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _podium(
    QueryDocumentSnapshot<Map<String, dynamic>> user,
    int rank,
    double height,
  ) {
    final data = user.data();
    final xp = _xp(data);
    final level = LevelSystem.fromXp(xp);
    final name = _name(data);

    final isFirst = rank == 1;
    final podiumColor = isFirst ? const Color(0xFFFDE89D) : Colors.white;

    return Container(
      height: height + 115,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
      decoration: BoxDecoration(
        color: podiumColor,
        borderRadius: BorderRadius.circular(18),
        border:
            isFirst
                ? Border.all(color: const Color(0xFFE5C55D), width: 1.5)
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFirst ? Icons.emoji_events_rounded : Icons.military_tech_rounded,
            color: isFirst ? const Color(0xFFB88500) : green,
            size: 29,
          ),
          const SizedBox(height: 5),
          Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          _levelBadge(xp, size: 43),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: ink,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Nivel ${level.number}',
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            level.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 10),
          ),
          const SizedBox(height: 7),
          Text(
            '$xp XP',
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingTile(
    QueryDocumentSnapshot<Map<String, dynamic>> user,
    int position,
    bool isMe,
  ) {
    final data = user.data();
    final xp = _xp(data);
    final level = LevelSystem.fromXp(xp);
    final name = _name(data);
    final photo = _photo(data);

    final hasPhoto =
        photo.startsWith('https://') || photo.startsWith('http://');

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFE2F7ED) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isMe
                ? Border.all(color: green, width: 1.5)
                : Border.all(color: const Color(0xFFE6EFEB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '#$position',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: ink,
                  fontSize: 13,
                ),
              ),
            ),
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFE2F7ED),
              backgroundImage: hasPhoto ? NetworkImage(photo) : null,
              child:
                  hasPhoto
                      ? null
                      : const Icon(
                        Icons.person_rounded,
                        color: green,
                        size: 21,
                      ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name${isMe ? ' (Tú)' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nivel ${level.number} · ${level.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _levelBadge(xp, size: 32),
                const SizedBox(height: 5),
                Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyRanking() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 45, color: green),
          SizedBox(height: 12),
          Text(
            'Todavía no hay participantes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
