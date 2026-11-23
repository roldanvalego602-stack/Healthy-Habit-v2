import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../tema/healthy_theme.dart';
import '../tema/healthy_motion.dart';
import '../tema/healthy_visual_mode.dart';
import '../tema/healthy_profile_presentation.dart';
import 'perfil/profile_avatar.dart';
import 'perfil/profile_screen.dart';
import 'perfil/perfil_muestra.dart';

import 'niveles/levels_system.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  Color get green => HealthyAdaptive.accent;
  Color get ink => HealthyAdaptive.text;
  Color get background => HealthyAdaptive.background;
  Color get muted => HealthyAdaptive.muted;

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

  void _openUserProfile(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (uid.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => currentUid == uid
          ? const ProfileScreen()
          : PublicProfileScreen(
              userId: uid,
              name: _name(data),
              username: (data['username'] ?? '').toString(),
            ),
    ));
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
        title: Text(
          'Ranking',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        backgroundColor: background,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            db
                .collection('public_profiles')
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
            return Center(child: CircularProgressIndicator(color: green));
          }

          final users = snapshot.data!.docs;
          final myIndex = users.indexWhere((u) => u.id == uid);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                'Cada hábito cuenta',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Clasificación global por experiencia acumulada. '
                'Se muestran hasta 100 usuarios.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 18),

              _myPosition(users, myIndex),

              const SizedBox(height: 22),

              if (users.isNotEmpty) ...[
                Text(
                  'Los primeros lugares',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // En móviles estrechos, una lista evita la compresión
                    // de nombres largos y los RenderFlex overflow.
                    if (constraints.maxWidth < 540) {
                      return Column(
                        children: [
                          _podium(users[0], 1, compact: true),
                          if (users.length > 1) ...[
                            const SizedBox(height: 9),
                            _podium(users[1], 2, compact: true),
                          ],
                          if (users.length > 2) ...[
                            const SizedBox(height: 9),
                            _podium(users[2], 3, compact: true),
                          ],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (users.length > 1)
                          Expanded(child: _podium(users[1], 2))
                        else
                          const Expanded(child: SizedBox()),
                        const SizedBox(width: 10),
                        Expanded(child: _podium(users[0], 1)),
                        const SizedBox(width: 10),
                        if (users.length > 2)
                          Expanded(child: _podium(users[2], 3))
                        else
                          const Expanded(child: SizedBox()),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
              ],

              Text(
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
                    context,
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
                  style: TextStyle(
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
          if (inRanking)
            HealthyCountUp(
              value: xp,
              suffix: ' XP acumulados',
              style: const TextStyle(color: Colors.white70),
            )
          else
            const Text(
              'Sigue ganando XP para entrar en la clasificación.',
              style: TextStyle(color: Colors.white70),
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
    int rank, {
    bool compact = false,
  }) {
    final data = user.data();
    return RankingPodiumCard(
      key: ValueKey('ranking-top-$rank'),
      rank: rank,
      name: _name(data),
      xp: _xp(data),
      compact: compact,
      photoUrl: HealthyProfilePresentation.photoUrl(
          data, publicProfile: true),
      avatarPreset: HealthyProfilePresentation.avatarPreset(
          data, publicProfile: true),
      onTap: (context) => _openUserProfile(context, user.id, data),
    );
  }

  Widget _rankingTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> user,
    int position,
    bool isMe,
  ) {
    final data = user.data();
    final xp = _xp(data);
    final level = LevelSystem.fromXp(xp);
    final name = _name(data);
    final photo = HealthyProfilePresentation.photoUrl(
        data, publicProfile: true);
    final avatarPreset = HealthyProfilePresentation.avatarPreset(
        data, publicProfile: true);

    return HealthyMotionCard(
      enableEntrance: isMe,
      enablePress: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('ranking-abrir-perfil-${user.id}'),
          onTap: () => _openUserProfile(context, user.id, data),
          borderRadius: BorderRadius.circular(16),
          child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: isMe ? HealthyAdaptive.mint : HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            isMe
                ? Border.all(color: green, width: 1.5)
                : Border.all(color: HealthyAdaptive.border),
        boxShadow: isMe && HealthyVisualEffects.allowDecorativeShadows
            ? [BoxShadow(color: green.withValues(alpha: 0.12),
                blurRadius: 13, offset: const Offset(0, 4))]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '#$position',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: ink,
                  fontSize: 13,
                ),
              ),
            ),
            HealthyProfileAvatar(
              photoUrl: photo,
              preset: avatarPreset,
              size: 38,
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
                    style: TextStyle(
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
                    style: TextStyle(color: muted, fontSize: 11),
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
                  style: TextStyle(
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
        ),
      ),
      ),
    );
  }

  Widget _emptyRanking() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
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

@visibleForTesting
class RankingPodiumCard extends StatelessWidget {
  const RankingPodiumCard({
    super.key,
    required this.rank,
    required this.name,
    required this.xp,
    this.compact = false,
    this.photoUrl,
    this.avatarPreset = 'foto',
    this.onTap,
  });

  final int rank;
  final String name;
  final int xp;
  final bool compact;
  final String? photoUrl;
  final String avatarPreset;
  final void Function(BuildContext context)? onTap;

  @override
  Widget build(BuildContext context) {
    final level = LevelSystem.fromXp(xp);
    final first = rank == 1;
    final dark = HealthyAdaptive.isDark;
    // Cada tarjeta define su propio par fondo/texto: nunca texto blanco
    // sobre dorado claro o plata clara.
    final bg = first
        ? (dark ? const Color(0xFF4B3B24) : const Color(0xFFFFF0BD))
        : rank == 2
            ? (dark ? const Color(0xFF253746) : const Color(0xFFEAF0F4))
            : (dark ? const Color(0xFF36312D) : const Color(0xFFF4E8DF));
    final fg = dark ? const Color(0xFFF1F5F6) : const Color(0xFF24303A);
    final secondary = dark
        ? const Color(0xFFB8C6CF)
        : const Color(0xFF52626F);
    final accent = first
        ? (dark ? const Color(0xFFFFD477) : const Color(0xFF956413))
        : rank == 2
            ? (dark ? const Color(0xFFB9DAEC) : const Color(0xFF53758C))
            : (dark ? const Color(0xFFE5B89B) : const Color(0xFF956E57));

    final badge = Container(
      width: compact ? 46 : 54,
      height: compact ? 46 : 54,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: HealthyProfileAvatar(
        photoUrl: photoUrl,
        preset: avatarPreset,
        size: compact ? 42 : 50,
      ),
    );

    final mainInfo = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          name,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          textAlign: compact ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 15 : 14,
            height: 1.22,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Nivel ${level.number} · ${level.name}',
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          textAlign: compact ? TextAlign.start : TextAlign.center,
          style: TextStyle(color: secondary, fontSize: 12, height: 1.3),
        ),
        const SizedBox(height: 6),
        Text(
          '$xp XP',
          style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );

    return HealthyMotionCard(
      enablePress: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('ranking-podio-abrir-perfil-$rank'),
          borderRadius: BorderRadius.circular(18),
          onTap: onTap == null ? null : () => onTap!(context),
          child: Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.3),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 10,
        vertical: compact ? 12 : 18,
      ),
      child: compact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  first ? Icons.emoji_events_rounded : Icons.military_tech_rounded,
                  color: accent,
                  size: 26,
                ),
                const SizedBox(width: 9),
                SizedBox(
                  width: 32,
                  child: Text(
                    '#$rank',
                    style: TextStyle(color: fg, fontSize: 19,
                      fontWeight: FontWeight.w900),
                  ),
                ),
                badge,
                const SizedBox(width: 12),
                Expanded(child: mainInfo),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  first ? Icons.emoji_events_rounded : Icons.military_tech_rounded,
                  color: accent,
                  size: 29,
                ),
                const SizedBox(height: 6),
                Text('#$rank', style: TextStyle(
                  color: fg, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                badge,
                const SizedBox(height: 12),
                mainInfo,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
