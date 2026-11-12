import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'amigos_servicio.dart';
import 'buscar_amigos_screen.dart';
import 'perfil_muestra.dart';

class _C {
  static const green = Color(0xFF198568);
  static const mint = Color(0xFF8DE0C0);
  static const navy = Color(0xFF173544);
  static const background = Color(0xFFF4F8F5);
  static const grey = Color(0xFF8496A0);
  static const border = Color(0xFFE3ECE7);
  static const mintSoft = Color(0xFFE2F4EB);
  static const gold = Color(0xFFD5A33E);

  static const avatars = [
    Color(0xFF198568),
    Color(0xFFD5A33E),
    Color(0xFF459FCB),
    Color(0xFF8C72C6),
    Color(0xFFE8736C),
  ];
}

/// Feed con el progreso en vivo de las personas que sigues: nivel, racha,
/// avance de XP hacia el siguiente nivel y su próximo logro.
class FeedAmigosScreen extends StatefulWidget {
  const FeedAmigosScreen({super.key});

  @override
  State<FeedAmigosScreen> createState() => _FeedAmigosScreenState();
}

class _FeedAmigosScreenState extends State<FeedAmigosScreen> {
  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  String? get _uid => AmigosServicio.uidActual;

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 18),
              Expanded(
                child:
                    uid == null
                        ? const Center(
                          child: Text('Inicia sesión para ver el feed.'),
                        )
                        : _cuerpo(uid),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: _C.navy),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Feed de progreso',
            style: TextStyle(
              color: _C.navy,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cuerpo(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AmigosServicio.siguiendo(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return _mensaje(
            icono: Icons.cloud_off_outlined,
            titulo: 'No se pudo cargar el feed',
            detalle: 'Comprueba tu conexión e inténtalo de nuevo.',
          );
        }

        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _C.green),
          );
        }

        final ids = snap.data!.docs.map((d) => d.id).toList();

        if (ids.isEmpty) {
          return _mensaje(
            icono: Icons.dynamic_feed_outlined,
            titulo: 'Aún no sigues a nadie',
            detalle: 'Sigue a tus amigos para ver aquí su progreso.',
            accion: 'Buscar amigos',
            onAccion: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BuscarAmigosScreen()),
              );
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: ids.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _TarjetaProgresoAmigo(uid: ids[i]),
        );
      },
    );
  }

  Widget _mensaje({
    required IconData icono,
    required String titulo,
    required String detalle,
    String? accion,
    VoidCallback? onAccion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: _C.mintSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: _C.green, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _C.navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.grey, fontSize: 13, height: 1.4),
            ),
            if (accion != null && onAccion != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onAccion,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(
                    accion,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.mint,
                    foregroundColor: _C.navy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con el progreso de un amigo. Escucha su documento en vivo, así
/// que se actualiza sola cuando esa persona avanza.
class _TarjetaProgresoAmigo extends StatelessWidget {
  final String uid;
  const _TarjetaProgresoAmigo({required this.uid});

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  String _texto(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final t = v.toString().trim();
    return t.isEmpty ? fallback : t;
  }

  int _num(dynamic v, [int fallback = 0]) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  double _doble(dynamic v, [double fallback = 0]) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? fallback;
  }

  /// Lee el primer campo presente entre varios nombres posibles, para
  /// aceptar tanto 'currentStreak'/'streakDays' como otras variantes que ya
  /// usan distintas pantallas de la app.
  dynamic _primero(Map<String, dynamic> d, List<String> claves) {
    for (final k in claves) {
      if (d[k] != null) return d[k];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        final d = snap.data!.data() ?? {};

        final nombre = _texto(d['name'], 'Usuario');
        final username = _texto(d['username']);
        final nivel = _num(_primero(d, ['level']), 1);
        final racha = _num(_primero(d, ['currentStreak', 'streakDays']), 0);
        final xpActual = _num(_primero(d, ['currentXp']), 0);
        final xpSiguiente = _num(_primero(d, ['nextLevelXp']), 1000);
        final progresoXp =
            xpSiguiente > 0
                ? (xpActual / xpSiguiente).clamp(0.0, 1.0).toDouble()
                : 0.0;
        final logro = _texto(d['nextAchievementTitle']);
        final progresoLogro =
            _doble(_primero(d, ['nextAchievementProgress']), -1);

        final color =
            _C.avatars[uid.codeUnits.fold<int>(0, (a, b) => a + b) %
                _C.avatars.length];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => PublicProfileScreen(
                        userId: uid,
                        name: nombre,
                        username:
                            username.isEmpty
                                ? '@usuario'
                                : (username.startsWith('@')
                                    ? username
                                    : '@$username'),
                        level: nivel,
                        streakDays: racha,
                        completedHabits: _num(d['completedHabits']),
                      ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _C.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: color,
                        child: Text(
                          nombre.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _C.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _C.mintSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Nivel $nivel',
                                    style: const TextStyle(
                                      color: _C.green,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$racha días 🔥',
                                  style: const TextStyle(
                                    color: _C.navy,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progreso de nivel',
                        style: TextStyle(
                          color: _C.grey,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$xpActual / $xpSiguiente XP',
                        style: const TextStyle(
                          color: _C.navy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progresoXp,
                      minHeight: 8,
                      backgroundColor: _C.mintSoft,
                      valueColor: const AlwaysStoppedAnimation(_C.green),
                    ),
                  ),
                  if (logro.isNotEmpty && progresoLogro >= 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '🏅 $logro',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _C.navy,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${(progresoLogro.clamp(0.0, 1.0) * 100).round()}%',
                          style: const TextStyle(
                            color: _C.gold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progresoLogro.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: _C.mintSoft,
                        valueColor: const AlwaysStoppedAnimation(_C.gold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
