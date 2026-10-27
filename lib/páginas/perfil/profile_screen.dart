import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:healthy_habit/p%C3%A1ginas/habitos/habits_screen.dart';
import '../../servicios/autenticacion_servicio.dart';
import 'buscar_amigos_screen.dart';
import 'editar_perfil_screen.dart';
import 'profesionales_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color green = Color(0xFF198568);
  static const Color mint = Color(0xFF8DE0C0);
  static const Color navy = Color(0xFF173544);
  static const Color background = Color(0xFFF4F8F5);
  static const Color gold = Color(0xFFD5A33E);

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: Text('Inicia sesión para ver tu perfil.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(user.uid).snapshots(),
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
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: background,
            body: Center(child: CircularProgressIndicator(color: green)),
          );
        }

        final data = snapshot.data?.data() ?? <String, dynamic>{};

        final name = _stringValue(
          data['name'],
          fallback: user.displayName ?? 'Usuario',
        );

        final username = _stringValue(data['username']);
        final email = _stringValue(data['email'], fallback: user.email ?? '');

        final level = _intValue(data['level'], fallback: 1);
        final xp = _intValue(data['xp']);
        final coins = _intValue(data['habitCoins']);
        final streak = _intValue(data['currentStreak']);

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
                  ),
                  const SizedBox(height: 22),
                  _levelCard(level: level, xp: xp),
                  const SizedBox(height: 14),
                  _statistics(streak: streak, coins: coins),
                  const SizedBox(height: 28),
                  _sectionTitle('Mis logros', 'Ver todos', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Aquí podrás consultar todos tus logros.',
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  _achievementsCard(),
                  const SizedBox(height: 12),
                  _specialAchievements(),
                  const SizedBox(height: 28),
                  _sectionTitle('Tu mes, paso a paso', null, null),
                  const SizedBox(height: 14),
                  _monthlyProgress(),
                  const SizedBox(height: 28),
                  _sectionTitle('Hecho a tu manera', 'Personalizar', () {
                    _showCustomization(context);
                  }),
                  const SizedBox(height: 14),
                  _customizationCard(),
                  const SizedBox(height: 20),
                  _mascotCard(streak: streak),
                  const SizedBox(height: 20),
                  _professionalsCard(context),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
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

  static String _stringValue(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static int _intValue(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return fallback;
  }

  Widget _header(BuildContext context) {
    return Row(
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
          tooltip: 'Profesionales',
          icon: Icons.medical_services_outlined,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfesionalesScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        _headerButton(
          tooltip: 'Buscar amigos',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HabitsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _headerButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: navy),
      ),
    );
  }

  Widget _profileCard(
    BuildContext context, {
    required String name,
    required String username,
    required String email,
    required int coins,
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
              gradient: const LinearGradient(
                colors: [Color(0xFF174D4B), Color(0xFF498A75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'AMANECER',
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
                    border: Border.all(color: mint, width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFE6F1EC),
                    child: Icon(Icons.person_rounded, size: 54, color: green),
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
                  style: const TextStyle(
                    color: Color(0xFF8496A0),
                    fontSize: 13,
                  ),
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
                  child: const Text(
                    '✦ Cultivador de constancia',
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
                  style: TextStyle(color: Color(0xFF8797A0), fontSize: 13),
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditarPerfilScreen(),
                                ),
                              );
                            },
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

  Widget _levelCard({required int level, required int xp}) {
    const xpForNextLevel = 1000;
    final xpInLevel = xp % xpForNextLevel;
    final progress = xpInLevel / xpForNextLevel;
    final remainingXp = xpForNextLevel - xpInLevel;

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
              'Te faltan $remainingXp XP para el siguiente nivel.',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statistics({required int streak, required int coins}) {
    return Row(
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
          child: _statCard(
            icon: Icons.check_circle_outline_rounded,
            value: '186',
            label: 'Hábitos completados',
            color: const Color(0xFFE0F3FB),
            iconColor: const Color(0xFF459FCB),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            customIcon: Image.asset(
              'assets/monedas/h coin.png',
              width: 22,
              height: 22,
            ),
            value: '$coins',
            label: 'Habit Coins',
            color: const Color(0xFFEDE5FB),
            iconColor: const Color(0xFF8C72C6),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    IconData? icon,
    Widget? customIcon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
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
            style: const TextStyle(color: Color(0xFF8496A0), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String? action, VoidCallback? onTap) {
    return Row(
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
  }

  Widget _achievementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTANTE · MIS FAVORITOS',
                style: TextStyle(
                  color: Color(0xFF8496A0),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
              Text(
                '18 desbloqueados',
                style: TextStyle(
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
              Expanded(
                child: _achievement(
                  Icons.water_drop_outlined,
                  'Gota constante',
                  'Poco común',
                  const Color(0xFF62B7DD),
                ),
              ),
              Expanded(
                child: _achievement(
                  Icons.local_fire_department_outlined,
                  'En llamas',
                  'Rara',
                  gold,
                ),
              ),
              Expanded(
                child: _achievement(
                  Icons.spa_outlined,
                  'Primer brote',
                  'Común',
                  const Color(0xFF369B7B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5EEE9),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '3 destacados · visibles en tu perfil',
            style: TextStyle(color: Color(0xFF8496A0), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _achievement(IconData icon, String name, String rarity, Color color) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 62,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                border: Border.all(color: color, width: 1.8),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: color, size: 35),
            ),
            Positioned(
              right: -4,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: navy,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          rarity,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _specialAchievements() {
    return Row(
      children: [
        Expanded(
          child: _specialCard(
            icon: Icons.nightlight_round,
            title: 'Ritmo lunar',
            rarity: 'ÉPICA',
            description: 'En progreso · 7 de 14 noches',
            color: const Color(0xFFF0E9FB),
            iconColor: const Color(0xFF8D77C3),
            progress: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _specialCard(
            icon: Icons.lock_outline_rounded,
            title: 'Un mes floreciendo',
            rarity: 'RARA',
            description: 'Bloqueado · alcanza una racha de 30 días',
            color: const Color(0xFFEAF1ED),
            iconColor: const Color(0xFF80958F),
            progress: 0,
          ),
        ),
      ],
    );
  }

  Widget _specialCard({
    required IconData icon,
    required String title,
    required String rarity,
    required String description,
    required Color color,
    required Color iconColor,
    required double progress,
  }) {
    return Container(
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
              Text(
                rarity,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
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
            style: const TextStyle(
              color: Color(0xFF7E9098),
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white70,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyProgress() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Octubre 2026',
                  style: TextStyle(
                    color: navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.calendar_month_rounded, color: Color(0xFF82959E)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 0.8,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFE8F0EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(mint),
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '80 %',
                          style: TextStyle(
                            color: navy,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'de tu objetivo',
                          style: TextStyle(
                            color: Color(0xFF8496A0),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '48 cumplidos',
                      style: TextStyle(
                        color: green,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'de 60 hábitos del mes',
                      style: TextStyle(color: Color(0xFF8496A0), fontSize: 11),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 12 por cumplir',
                      style: TextStyle(color: Color(0xFF8496A0), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE5EEE9)),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: green, size: 20),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  '+8 hábitos respecto a septiembre. ¡Vas bien!',
                  style: TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customizationCard() {
    return Column(
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle_outline, color: green, size: 16),
            SizedBox(width: 7),
            Text(
              'Tu personalización está equipada',
              style: TextStyle(color: Color(0xFF8496A0), fontSize: 11),
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
                'Amanecer',
                const Color(0xFFE2F4EB),
                green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _customItem(
                Icons.circle_outlined,
                'Marco · poco común',
                'Brote dorado',
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
                'Estante · 3 destacados',
                'Mis favoritos',
                const Color(0xFFE1F1FB),
                const Color(0xFF459FCB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _customItem(
                Icons.badge_outlined,
                'Título activo',
                'Cultivador de constancia',
                const Color(0xFFF0E5FB),
                const Color(0xFF9877C7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _customItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    Color iconColor,
  ) {
    return Container(
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
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF8496A0), fontSize: 9),
                ),
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
  }

  Widget _mascotCard({required int streak}) {
    return Container(
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
  }

  Widget _professionalsCard(BuildContext context) {
    return Container(
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
                  style: TextStyle(color: Color(0xFF8496A0), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfesionalesScreen()),
              );
            },
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: navy,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomization(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (_) => const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personaliza tu perfil',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                SizedBox(height: 18),
                ListTile(
                  leading: Icon(Icons.landscape_outlined),
                  title: Text('Cambiar banner'),
                  subtitle: Text('Elige el fondo de tu perfil'),
                ),
                ListTile(
                  leading: Icon(Icons.workspace_premium_outlined),
                  title: Text('Elegir logros destacados'),
                  subtitle: Text('Muestra tus logros favoritos'),
                ),
                ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('Cambiar título'),
                  subtitle: Text('Muestra tu título actual'),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}
