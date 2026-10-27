import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthy_habit/p%C3%A1ginas/habitos/registrar_habito_screen.dart';
import 'package:healthy_habit/p%C3%A1ginas/notifications_screen.dart';
import '../páginas/habitos/habits_screen.dart';
import '../páginas/desafios/desafios_screen.dart';
import '../páginas/tienda/store_screen.dart';
import '../páginas/perfil/profile_screen.dart';
import '../páginas/chatbot/nutrichat.dart';

void main() => runApp(const HabitTrackerApp());

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthy Habit',
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF7F9F8),
        useMaterial3: true,
      ),
      home: const HomeScreen2(),
    );
  }
}

// ---------- Paleta de Colores Explícita desde Figma ----------
class AppColors {
  static const primaryGreen = Color(0xFF00C88C);
  static const darkGreenCard = Color(0xFF143834);
  static const textDark = Color(0xFF0E1A30);
  static const textGrey = Color(0xFF7A869A);
  static const yellowCard = Color(0xFFFDE89D);
  static const blueWaterCard = Color(0xFFE8F6FC);
  static const purpleCard = Color(0xFFF0EBFC);
  static const mintCard = Color(0xFFE2F7ED);
}

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});

  @override
  State<HomeScreen2> createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
  int _selectedIndex = 0;

  List<Widget> get _tabs => [
    _buildHomeBody(),
    const HabitsScreen(),
    const StoreScreen(),
    const DesafiosScreen(),
    const ProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildHomeBody() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("No se encontró sesión de usuario."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        final Map<String, dynamic> userData =
            (userSnapshot.data?.data() as Map<String, dynamic>?) ?? {};

        final String name = userData['name'] ?? 'Usuario';
        final String? photoUrl = userData['photoUrl'] ?? currentUser.photoURL;
        final int level = userData['level'] ?? 1;
        final String levelTitle = userData['title'] ?? 'Cultivador Constante';
        final int currentXp = userData['currentXp'] ?? 0;
        final int nextLevelXp = userData['nextLevelXp'] ?? 1000;
        final int streakDays = userData['streakDays'] ?? 0;
        final String nextAchievement =
            userData['nextAchievementTitle'] ?? 'Insignia Ritmo firme';
        final String nextAchievementSub =
            userData['nextAchievementSubtitle'] ?? 'A 2 misiones';

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('user_habits')
                  .snapshots(),
          builder: (context, habitsSnapshot) {
            int totalHabits = 0;
            int completedHabits = 0;
            Map<String, dynamic>? activeMission;

            if (habitsSnapshot.hasData &&
                habitsSnapshot.data!.docs.isNotEmpty) {
              final docs = habitsSnapshot.data!.docs;
              totalHabits = docs.length;
              completedHabits =
                  docs
                      .where(
                        (doc) =>
                            (doc.data()
                                as Map<String, dynamic>)['completedToday'] ==
                            true,
                      )
                      .length;

              // Seleccionar el primer hábito para la tarjeta de misión principal
              activeMission = docs.first.data() as Map<String, dynamic>;
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(photoUrl: photoUrl),
                  const SizedBox(height: 16),
                  Text(
                    '¡Hola, $name!',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Continúa con tus hábitos de hoy.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _LevelCard(
                    level: level,
                    title: levelTitle,
                    currentXp: currentXp,
                    nextLevelXp: nextLevelXp,
                  ),
                  const SizedBox(height: 16),
                  _StatsRow(
                    streakDays: streakDays,
                    completedHabits: completedHabits,
                    totalHabits: totalHabits,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(onTapViewHabits: () => _onNavTap(1)),
                  const SizedBox(height: 14),
                  _MissionCard(missionData: activeMission),
                  const SizedBox(height: 16),
                  _NextAchievementCard(
                    title: nextAchievement,
                    subtitle: nextAchievementSub,
                  ),
                  const SizedBox(height: 16),
                  const _MrHealthyBannerCard(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_selectedIndex]),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ---------- Top Bar ----------
class _TopBar extends StatelessWidget {
  final String? photoUrl;
  const _TopBar({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage('assets/logo/logo.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Healthy Habit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const Spacer(),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.mintCard,
            border: Border.all(color: Colors.white, width: 2),
            image:
                photoUrl != null
                    ? DecorationImage(
                      image: NetworkImage(photoUrl!),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child:
              photoUrl == null
                  ? const Icon(Icons.person, color: AppColors.primaryGreen)
                  : null,
        ),
      ],
    );
  }
}

// ---------- Tarjeta Nivel XP Dinámica ----------
class _LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final int currentXp;
  final int nextLevelXp;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.currentXp,
    required this.nextLevelXp,
  });

  @override
  Widget build(BuildContext context) {
    final double progress =
        nextLevelXp > 0 ? (currentXp / nextLevelXp).clamp(0.0, 1.0) : 0.0;
    final int percentage = (progress * 100).toInt();
    final int remainingXp = (nextLevelXp - currentXp).clamp(0, nextLevelXp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3832), Color(0xFF1E4D44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NIVEL $level',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentXp XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$remainingXp XP para nivel ${level + 1}',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ---------- Fila Racha y Progreso Diario Ajustada ----------
class _StatsRow extends StatelessWidget {
  final int streakDays;
  final int completedHabits;
  final int totalHabits;

  const _StatsRow({
    required this.streakDays,
    required this.completedHabits,
    required this.totalHabits,
  });

  @override
  Widget build(BuildContext context) {
    final double habitProgress =
        totalHabits > 0 ? (completedHabits / totalHabits) : 0.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.yellowCard,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$streakDays días',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Racha actual',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: habitProgress,
                    strokeWidth: 4,
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completedHabits / $totalHabits',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Text(
                        'Completados',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final VoidCallback onTapViewHabits;
  const _SectionHeader({required this.onTapViewHabits});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Tu misión de hoy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        GestureDetector(
          onTap: onTapViewHabits,
          child: const Text(
            'Ver hábitos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Tarjeta Misión Adaptable ----------
class _MissionCard extends StatelessWidget {
  final Map<String, dynamic>? missionData;

  const _MissionCard({this.missionData});

  @override
  Widget build(BuildContext context) {
    final String category =
        (missionData?['category'] ?? 'HIDRATACIÓN').toString().toUpperCase();
    final String title = missionData?['title'] ?? 'Toma 6 vasos de agua';
    final int xpBonus = missionData?['xpBonus'] ?? 10;
    final int currentVal = missionData?['currentValue'] ?? 4;
    final int targetVal = missionData?['targetValue'] ?? 6;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blueWaterCard,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFF2B7FD1),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2B7FD1),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.yellowCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$xpBonus XP',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Vasos Responsivos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(targetVal, (index) {
              final isFilled = index < currentVal;
              return Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isFilled
                              ? const Color(0xFF2B7FD1)
                              : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_drink_rounded,
                      size: 20,
                      color:
                          isFilled
                              ? const Color(0xFF2B7FD1)
                              : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentVal de $targetVal',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Solo faltan ${(targetVal - currentVal).clamp(0, targetVal)} vasos',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistrarHabitoScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Registrar vaso',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Banner Próximo Logro ----------
class _NextAchievementCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NextAchievementCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purpleCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.yellowCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRÓXIMO LOGRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.purple,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
        ],
      ),
    );
  }
}

// ---------- Banner Mr. Healthy ----------
class _MrHealthyBannerCard extends StatelessWidget {
  const _MrHealthyBannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.mintCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MR. HEALTHY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Un vaso con tu almuerzo mantiene tu racha fácil.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NutriChatPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Chatear',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            height: 72,
            child: Image.asset(
              'assets/mascot/healthy.png',
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primaryGreen,
                    size: 50,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Bottom Nav Bar ----------
class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              isSelected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.track_changes_rounded,
              label: 'Hábitos',
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              icon: Icons.storefront_rounded,
              label: 'Tienda',
              isSelected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.emoji_events_rounded,
              label: 'Desafíos',
              isSelected: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              isSelected: selectedIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryGreen : AppColors.textGrey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
