import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'amigos_servicio.dart';
import 'amigos_screen.dart';
import '../logros/logros_screen.dart';
import 'buscar_amigos_screen.dart';
import 'configuracion_screen.dart';
import 'profesionales_screen.dart';
import 'feed_amigos_screen.dart';
import 'editar_perfil_screen.dart';
import '../splash_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color green = Color(0xFF198568);
  static const Color mint = Color(0xFF8DE0C0);
  static const Color navy = Color(0xFF173544);
  static const Color background = Color(0xFFF4F8F5);
  static const Color gold = Color(0xFFD5A33E);
  static const Color muted = Color(0xFF8496A0);

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: Text('Inicia sesión para ver tu perfil.')),
      );
    }
    final userRef = _db.collection('users').doc(user.uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: green,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudo cargar tu perfil.',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comprueba tu conexión e inténtalo de nuevo.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: background,
            body: Center(child: CircularProgressIndicator(color: green)),
          );
        }
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final name = _string(
          data['name'],
          fallback: user.displayName ?? 'Usuario',
        );
        final username = _string(
          data['username'],
        ).replaceFirst(RegExp(r'^@+'), '');
        final email = _string(data['email'], fallback: user.email ?? '');
        final level = _integer(data['level'], fallback: 1);
        final xp = _integer(data['xp']);
        final coins = _integer(data['habitCoins']);
        final streak = _integer(data['currentStreak']);
        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context),
                  const SizedBox(height: 18),
                  _profileCard(
                    context,
                    name: name,
                    username: username,
                    email: email,
                    coins: coins,
                    data: data,
                  ),
                  const SizedBox(height: 16),
                  _friendsCard(context, user.uid),
                  const SizedBox(height: 22),
                  _levelCard(level: level, xp: xp),
                  const SizedBox(height: 14),
                  _statistics(streak: streak, coins: coins, uid: user.uid),
                  const SizedBox(height: 28),
                  _sectionTitle(
                    'Mis logros',
                    'Ver todos',
                    () => _open(context, const LogrosScreen()),
                  ),
                  const SizedBox(height: 14),
                  _achievementsCard(userRef, context),
                  const SizedBox(height: 12),
                  _specialAchievements(),
                  const SizedBox(height: 28),
                  _sectionTitle('Tu mes, paso a paso', null, null),
                  const SizedBox(height: 14),
                  _monthlyProgress(),
                  const SizedBox(height: 28),
                  _sectionTitle(
                    'Hecho a tu manera',
                    'Personalizar',
                    () => _showCustomization(context, userRef, data),
                  ),
                  const SizedBox(height: 14),
                  _customizationCard(data),
                  const SizedBox(height: 20),
                  _mascotCard(streak: streak),
                  const SizedBox(height: 20),
                  _professionalsCard(context),
                  const SizedBox(height: 20),
                  _settingsCard(context),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Capturar el Navigator raíz ANTES del signOut: los
                        // StreamBuilder pueden desmontar este contexto al cambiar auth.
                        final navigator = Navigator.of(
                          context,
                          rootNavigator: true,
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await FirebaseAuth.instance.signOut();
                          if (!navigator.mounted) return;
                          // No depende de una ruta '/login' inexistente.
                          // SplashScreen decide entre HomeScreen2 y LoginScreen.
                          navigator.pushAndRemoveUntil<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const SplashScreen(),
                            ),
                            (route) => false,
                          );
                        } catch (e) {
                          if (messenger.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No se pudo cerrar la sesión: $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.redAccent.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _string(dynamic value, {String fallback = ''}) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;
  static int _integer(dynamic value, {int fallback = 0}) =>
      value is num ? value.toInt() : fallback;

  Widget _header(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Text(
          'Perfil',
          style: TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      _headerButton(
        'Configuración',
        Icons.settings_outlined,
        () => _open(context, const SettingsScreen()),
      ),
      const SizedBox(width: 8),
      _headerButton(
        'Profesionales',
        Icons.medical_services_outlined,
        () => _open(context, const ProfesionalesScreen()),
      ),
      const SizedBox(width: 8),
      _headerButton(
        'Buscar amigos',
        Icons.person_add_alt_1_rounded,
        () => _open(context, const BuscarAmigosScreen()),
      ),
    ],
  );

  Widget _headerButton(String tooltip, IconData icon, VoidCallback onPressed) =>
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: navy),
        ),
      );

  Widget _profileCard(
    BuildContext context, {
    required String name,
    required String username,
    required String email,
    required int coins,
    required Map<String, dynamic> data,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: _bannerColors(
                  _string(data['profileBanner'], fallback: 'Amanecer'),
                ),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    _string(
                      data['profileBanner'],
                      fallback: 'Amanecer',
                    ).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6D989),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -45),
            child: Column(
              children: [
                Container(
                  width: 94,
                  height: 94,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _frameColor(
                        _string(data['profileFrame'], fallback: 'Brote dorado'),
                      ),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFE6F1EC),
                    backgroundImage:
                        _string(data['photoUrl']).isNotEmpty
                            ? NetworkImage(_string(data['photoUrl']))
                            : null,
                    child:
                        _string(data['photoUrl']).isEmpty
                            ? const Icon(
                              Icons.person_rounded,
                              size: 54,
                              color: green,
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username.isNotEmpty ? '@$username' : email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2D2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✦ ${_string(data['profileTitle'], fallback: 'Cultivador de constancia')}',
                    style: TextStyle(
                      color: gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Pequeños pasos, raíces fuertes.',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => _editProfile(context, data),
                            icon: const Icon(Icons.edit_rounded, size: 17),
                            label: const Text(
                              'Editar perfil',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mint,
                              foregroundColor: navy,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3D7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/monedas/h coin.png',
                              width: 20,
                              height: 20,
                              errorBuilder:
                                  (_, __, ___) =>
                                      const SizedBox(width: 20, height: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$coins',
                              style: const TextStyle(
                                color: gold,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _friendsCard(BuildContext context, String uid) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F4EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: green, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Amigos',
                  style: TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openFriends(context, 0),
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    color: green,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _friendStat(context, uid, 'following', 'Siguiendo', 0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _friendStat(context, uid, 'followers', 'Seguidores', 1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _friendStat(
                  context,
                  uid,
                  'solicitudes',
                  'Solicitudes',
                  2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FeedAmigosScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.dynamic_feed_rounded, size: 19),
              label: const Text(
                'Ver progreso de amigos',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _open(context, const BuscarAmigosScreen()),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
              label: const Text(
                'Agregar amigos',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                side: const BorderSide(color: mint, width: 1.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _friendStat(
    BuildContext context,
    String uid,
    String collection,
    String label,
    int tab,
  ) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openFriends(context, tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              StreamBuilder<int>(
                stream: AmigosServicio.contar(uid, collection),
                builder:
                    (context, snap) => Text(
                      snap.hasError ? '—' : '${snap.data ?? 0}',
                      style: const TextStyle(
                        color: navy,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
              ),
              const SizedBox(height: 3),
              Text(label, style: const TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _openFriends(BuildContext context, int tab) {
    _open(context, AmigosScreen(initialTab: tab));
  }

  Widget _levelCard({required int level, required int xp}) {
    const xpForNextLevel = 1000;
    final xpInLevel = xp % xpForNextLevel;
    final progress = xpInLevel / xpForNextLevel;
    final remaining = xpForNextLevel - xpInLevel;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF112F3C), Color(0xFF285566)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: mint, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TU NIVEL ACTUAL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Raíces fuertes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Rango Brote · sigue creciendo',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$xpInLevel / $xpForNextLevel XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                '${(progress * 100).round()} %',
                style: const TextStyle(
                  color: mint,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFF42616B),
              valueColor: const AlwaysStoppedAnimation<Color>(mint),
            ),
          ),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Te faltan $remaining XP para el siguiente nivel.',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _completedCount(String uid) async {
    final habits =
        await _db.collection('users').doc(uid).collection('user_habits').get();
    final counts = await Future.wait(
      habits.docs.map((habit) async {
        final attempts =
            await habit.reference
                .collection('attempts')
                .where('status', isEqualTo: 'completed')
                .get();
        return attempts.docs.length;
      }),
    );
    return counts.fold<int>(0, (sum, count) => sum + count);
  }

  Widget _statistics({
    required int streak,
    required int coins,
    required String uid,
  }) => Row(
    children: [
      Expanded(
        child: _statCard(
          icon: Icons.local_fire_department_outlined,
          value: '$streak',
          label: 'Días de racha',
          color: const Color(0xFFFFF0CF),
          iconColor: gold,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: FutureBuilder<int>(
          future: _completedCount(uid),
          builder:
              (_, snap) => _statCard(
                icon: Icons.check_circle_outline_rounded,
                value:
                    snap.hasError
                        ? '—'
                        : snap.hasData
                        ? '${snap.data}'
                        : '…',
                label: 'Hábitos completados',
                color: const Color(0xFFE0F3FB),
                iconColor: const Color(0xFF459FCB),
              ),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _statCard(
          customIcon: Image.asset(
            'assets/monedas/h coin.png',
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) => const SizedBox(width: 22, height: 22),
          ),
          value: '$coins',
          label: 'Habit Coins',
          color: const Color(0xFFEDE5FB),
          iconColor: const Color(0xFF8C72C6),
        ),
      ),
    ],
  );

  Widget _statCard({
    IconData? icon,
    Widget? customIcon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 128),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: customIcon ?? Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 10),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, String? action, VoidCallback? onTap) =>
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: navy,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onTap,
              child: Text(
                action,
                style: const TextStyle(
                  color: green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );

  Widget _achievementsCard(
    DocumentReference<Map<String, dynamic>> userRef,
    BuildContext context,
  ) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userRef.collection('achievements').doc('primer_paso').snapshots(),
      builder: (context, snapshot) {
        final unlocked = snapshot.data?.exists ?? false;
        return InkWell(
          onTap: () => _open(context, const LogrosScreen()),
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ESTANTE · MIS LOGROS',
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      snapshot.hasError
                          ? 'Sin conexión'
                          : unlocked
                          ? '1 desbloqueado'
                          : '0 desbloqueados',
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 62,
                      height: 70,
                      decoration: BoxDecoration(
                        color:
                            unlocked
                                ? const Color(0xFFE3F7EC)
                                : const Color(0xFFF0F2F2),
                        border: Border.all(
                          color: unlocked ? green : muted,
                          width: 1.8,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        unlocked
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_outline,
                        color: unlocked ? green : muted,
                        size: 35,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Primer paso',
                            style: TextStyle(
                              color: navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            unlocked
                                ? '¡Logro desbloqueado!'
                                : 'Registra tu primer hábito',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            '+25 XP · +10 Habit Coins',
                            style: TextStyle(
                              color: green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: muted),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: unlocked ? 1 : 0,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE5EEE9),
                    valueColor: const AlwaysStoppedAnimation<Color>(green),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Toca para ver todos los logros y desafíos.',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _specialAchievements() => Row(
    children: [
      Expanded(
        child: _specialCard(
          Icons.nightlight_round,
          'Ritmo lunar',
          'PRÓXIMAMENTE',
          'Los logros de sueño llegarán después.',
          const Color(0xFFF0E9FB),
          const Color(0xFF8D77C3),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _specialCard(
          Icons.lock_outline_rounded,
          'Un mes floreciendo',
          'PRÓXIMAMENTE',
          'Los logros de racha llegarán después.',
          const Color(0xFFEAF1ED),
          const Color(0xFF80958F),
        ),
      ),
    ],
  );

  Widget _specialCard(
    IconData icon,
    String title,
    String rarity,
    String description,
    Color color,
    Color iconColor,
  ) => Container(
    constraints: const BoxConstraints(minHeight: 155),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const Spacer(),
            Flexible(
              child: Text(
                rarity,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: const TextStyle(color: muted, fontSize: 10, height: 1.4),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: const LinearProgressIndicator(
            value: 0,
            minHeight: 5,
            backgroundColor: Colors.white70,
          ),
        ),
      ],
    ),
  );

  Widget _monthlyProgress() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _monthLabel(DateTime.now()),
                style: const TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.calendar_month_rounded, color: muted),
          ],
        ),
        const SizedBox(height: 20),
        const Icon(Icons.insights_outlined, color: green, size: 42),
        const SizedBox(height: 12),
        const Text(
          'Resumen mensual pendiente de integración',
          textAlign: TextAlign.center,
          style: TextStyle(color: navy, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Aquí se mostrarán tus registros reales cuando conectemos las estadísticas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
    ),
  );

  static String _monthLabel(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _customizationCard(Map<String, dynamic> data) => Column(
    children: [
      const Row(
        children: [
          Icon(Icons.palette_outlined, color: green, size: 16),
          SizedBox(width: 7),
          Text(
            'Vista previa de personalización',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _customItem(
              Icons.landscape_rounded,
              'Banner',
              _string(data['profileBanner'], fallback: 'Amanecer'),
              const Color(0xFFE2F4EB),
              green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _customItem(
              Icons.circle_outlined,
              'Marco',
              _string(data['profileFrame'], fallback: 'Brote dorado'),
              const Color(0xFFFFF1D1),
              gold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _customItem(
              Icons.workspace_premium_outlined,
              'Estante',
              _string(data['profileShelf'], fallback: 'Mis favoritos'),
              const Color(0xFFE1F1FB),
              const Color(0xFF459FCB),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _customItem(
              Icons.badge_outlined,
              'Título',
              _string(
                data['profileTitle'],
                fallback: 'Cultivador de constancia',
              ),
              const Color(0xFFF0E5FB),
              const Color(0xFF9877C7),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _customItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    Color iconColor,
  ) => Container(
    constraints: const BoxConstraints(minHeight: 85),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: muted, fontSize: 9)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _mascotCard({required int streak}) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xFFE2F3E7),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Row(
      children: [
        Container(
          width: 88,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFD1EAD7),
            borderRadius: BorderRadius.circular(45),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(45),
            child: Image.asset(
              'assets/mascot/healthy.png',
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) =>
                      const Icon(Icons.eco_rounded, color: green, size: 55),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MR. HEALTHY · EL MERO MERO A TU LADO',
                style: TextStyle(
                  color: green,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '¡$streak días cultivando tu mejor versión!',
                style: const TextStyle(
                  color: navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Hoy no hace falta hacerlo todo. Un pequeño paso también cuenta.',
                style: TextStyle(
                  color: Color(0xFF6F8C7B),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mi compañero →',
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _professionalsCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: navy.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE2F0FB),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: Color(0xFF3880A3),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ORIENTACIÓN PROFESIONAL',
                style: TextStyle(
                  color: Color(0xFF3880A3),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Consulta con especialistas',
                style: TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Accede a nutriólogos y psicólogos capacitados.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _open(context, const ProfesionalesScreen()),
          icon: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: navy,
            size: 18,
          ),
        ),
      ],
    ),
  );

  Widget _settingsCard(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _open(context, const SettingsScreen()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F4EB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: green,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración',
                    style: TextStyle(
                      color: navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Preferencias y ajustes de tu cuenta',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: navy),
          ],
        ),
      ),
    ),
  );

  static List<Color> _bannerColors(String banner) {
    switch (banner) {
      case 'Bosque':
        return [const Color(0xFF123F32), const Color(0xFF3D8961)];
      case 'Océano':
        return [const Color(0xFF17466D), const Color(0xFF63B8C8)];
      case 'Atardecer':
        return [const Color(0xFF78465B), const Color(0xFFE6A66E)];
      default:
        return [const Color(0xFF174D4B), const Color(0xFF498A75)];
    }
  }

  static Color _frameColor(String frame) {
    switch (frame) {
      case 'Menta':
        return mint;
      case 'Océano':
        return const Color(0xFF62B7DD);
      case 'Lavanda':
        return const Color(0xFF9877C7);
      default:
        return gold;
    }
  }

  // Una única pantalla es responsable de los controladores de edición.
  void _editProfile(BuildContext context, Map<String, dynamic> data) {
    _open(context, const EditarPerfilScreen());
  }

  void _showCustomization(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> userRef,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personaliza tu perfil',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona un estilo. Los cambios se guardan en tu cuenta.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    _customSelector(
                      sheetContext,
                      userRef,
                      'Banner',
                      'profileBanner',
                      _string(data['profileBanner'], fallback: 'Amanecer'),
                      ['Amanecer', 'Bosque', 'Océano', 'Atardecer'],
                    ),
                    _customSelector(
                      sheetContext,
                      userRef,
                      'Marco',
                      'profileFrame',
                      _string(data['profileFrame'], fallback: 'Brote dorado'),
                      ['Brote dorado', 'Menta', 'Océano', 'Lavanda'],
                    ),
                    _customSelector(
                      sheetContext,
                      userRef,
                      'Estante',
                      'profileShelf',
                      _string(data['profileShelf'], fallback: 'Mis favoritos'),
                      ['Mis favoritos', 'Primeros pasos', 'Colección natural'],
                    ),
                    _customSelector(
                      sheetContext,
                      userRef,
                      'Título',
                      'profileTitle',
                      _string(
                        data['profileTitle'],
                        fallback: 'Cultivador de constancia',
                      ),
                      [
                        'Cultivador de constancia',
                        'Semilla saludable',
                        'Explorador del bienestar',
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _customSelector(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> userRef,
    String label,
    String field,
    String current,
    List<String> options,
  ) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(current),
      trailing: const Icon(Icons.expand_more),
      onTap: () async {
        final choice = await showDialog<String>(
          context: context,
          builder:
              (dialogContext) => SimpleDialog(
                title: Text('Elegir $label'),
                children:
                    options
                        .map(
                          (option) => SimpleDialogOption(
                            onPressed:
                                () => Navigator.pop(dialogContext, option),
                            child: Row(
                              children: [
                                if (option == current)
                                  const Icon(Icons.check, color: green),
                                const SizedBox(width: 8),
                                Expanded(child: Text(option)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
        );
        if (choice == null) return;
        try {
          await userRef.set({
            field: choice,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No se pudo personalizar: $e')),
            );
        }
      },
    );
  }
}
