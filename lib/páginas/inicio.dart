import 'perfil/profile_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../tema/healthy_theme.dart';
import '../tema/healthy_coin.dart';
import '../tema/healthy_motion.dart';
import '../tema/healthy_float.dart';
import 'package:healthy_habit/páginas/ranking_screen.dart';

import 'habitos/habits_screen.dart';
import 'habitos/registrar_habito_screen.dart';
import 'tienda/store_screen.dart';
import 'niveles/camino_niveles_screen.dart';
import 'niveles/levels_system.dart';
import 'perfil/profile_screen.dart';
import 'catalogo/catalogo_screen.dart';
import 'chatbot/nutrichat.dart';
import 'notifications_screen.dart';
import 'logros/logros_screen.dart';
import 'logros/logros_service.dart';
import 'estadisticas/progreso_screen.dart';
import 'estadisticas/daily_streak_screen.dart';
import '../servicios/daily_streak_display.dart';

// Firebase se inicializa realmente en lib/main.dart.
void main() => runApp(const HabitTrackerApp());

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthy Habit',
      theme: HealthyThemes.light(),
      darkTheme: HealthyThemes.dark(),
      themeMode: HealthyThemeController.instance.mode,
      home: const HomeScreen2(),
    );
  }
}

class AppColors {
  static Color get primaryGreen => HealthyAdaptive.accent;
  static Color get darkGreenCard => HealthyAdaptive.isDark ? const Color(0xFF19453A) : const Color(0xFF143834);
  static Color get textDark => HealthyAdaptive.text;
  static Color get textGrey => HealthyAdaptive.muted;
  static Color get yellowCard => HealthyAdaptive.yellow;
  static Color get blueWaterCard => HealthyAdaptive.water;
  static Color get purpleCard => HealthyAdaptive.lavender;
  static Color get mintCard => HealthyAdaptive.mint;
  static Color get page => HealthyAdaptive.background;
}

int _number(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});

  @override
  State<HomeScreen2> createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
  int _selectedIndex = 0;

  late final FirebaseFirestore _db;

  @override
  void initState() {
    super.initState();

    _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
  }

  // NAVEGACIÓN PRINCIPAL
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      _home(),
      const HabitsScreen(),
      const StoreScreen(),
      const CatalogoScreen(),
      const ProfileScreen(),
    ];

    const labels = ['Inicio', 'Hábitos', 'Tienda', 'Catálogo', 'Perfil'];

    const icons = [
      Icons.home_rounded,
      Icons.track_changes_rounded,
      Icons.storefront_rounded,
      Icons.menu_book_rounded,
      Icons.person_outline_rounded,
    ];

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(child: HealthyPageSwitch(index: _selectedIndex, child: screens[_selectedIndex])),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: HealthyAdaptive.surface,
            border: Border(top: BorderSide(color: HealthyAdaptive.border)),
          ),
          child: Row(
            children: List.generate(
              5,
              (i) => Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = i;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[i],
                          color:
                              i == _selectedIndex
                                  ? AppColors.primaryGreen
                                  : AppColors.textGrey,
                          size: 23,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                i == _selectedIndex
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                            color:
                                i == _selectedIndex
                                    ? AppColors.primaryGreen
                                    : AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // DATOS DE INICIO
  // --------------------------------------------------

  Widget _home() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No se encontró sesión de usuario.'));
    }

    final userRef = _db.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userRef.snapshots(),
      builder: (context, profile) {
        if (profile.hasError) {
          return const Center(child: Text('No se pudo cargar tu perfil.'));
        }

        if (!profile.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = profile.data?.data() ?? <String, dynamic>{};

        final name = (data['name'] ?? user.displayName ?? 'Usuario').toString();

        final photo = (data['photoUrl'] ?? user.photoURL)?.toString();

        final xp =
            _number(
              data['xp'] ?? data['currentXp'],
            ).clamp(0, 1000000000).toInt();

        // CAMBIO IMPORTANTE:
        // El nivel visible depende solamente de XP.
        final level = LevelSystem.fromXp(xp).number;

        final streak = DailyStreakDisplay.current(data);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: userRef.collection('user_habits').snapshots(),
          builder: (context, habits) {
            if (habits.hasError) {
              return const Center(
                child: Text('No se pudieron cargar tus hábitos.'),
              );
            }

            if (!habits.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return _HomeContent(
              key: ValueKey(user.uid),
              name: name,
              photoUrl: photo,
              xp: xp,
              level: level,
              streak: streak,
              habits: habits.data!.docs,
              userRef: userRef,
              coins: _number(data['habitCoins']),
              onHabits: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              onProfile: () {
                setState(() {
                  _selectedIndex = 4;
                });
              },
              onStore: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            );
          },
        );
      },
    );
  }
}

// ====================================================
// CONTENIDO DE LA PÁGINA DE INICIO
// ====================================================

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.xp,
    required this.level,
    required this.streak,
    required this.habits,
    required this.onHabits,
    required this.userRef,
    required this.coins,
    required this.onProfile,
    required this.onStore,
  });

  final String name;
  final String? photoUrl;

  final int xp;
  final int level;
  final int streak;
  final int coins;

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> habits;

  final VoidCallback onHabits;
  final VoidCallback onProfile;
  final VoidCallback onStore;

  final DocumentReference<Map<String, dynamic>> userRef;

  @override
  Widget build(BuildContext context) {
    final active =
        habits.where((h) => h.data()['latestStatus'] == 'inProgress').toList();

    final completed =
        habits.where((h) => h.data()['latestStatus'] == 'completed').length;

    final mission = active.isEmpty ? null : active.first;

    final total =
        habits.where((h) {
          final status = h.data()['latestStatus'];

          return status == 'inProgress' || status == 'completed';
        }).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO
          Row(
            children: [
              Image.asset(
                'assets/logo/logo.png',
                width: 38,
                height: 38,
                errorBuilder:
                    (_, __, ___) =>
                        Icon(Icons.eco, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Healthy Habit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: 7),
              Tooltip(
                message: 'Abrir mi perfil',
                child: InkWell(
                  onTap: onProfile,
                  borderRadius: BorderRadius.circular(30),
                  child: HealthyProfileAvatar(
                    photoUrl: photoUrl,
                    size: 44,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            '¡Hola, $name!',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),

          Text(
            'Continúa con tus hábitos de hoy.',
            style: TextStyle(color: AppColors.textGrey),
          ),

          const SizedBox(height: 14),

          // HABIT COINS
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const HealthyCoinIcon(size: 23),
              label: Text('$coins Habit Coins · Ir a tienda'),
              onPressed: onStore,
            ),
          ),

          const SizedBox(height: 14),

          // NIVEL CALCULADO DESDE XP
          _levelCard(),

          const SizedBox(height: 12),

          // CAMINO DE NIVELES
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaminoNivelesScreen(xp: xp),
                  ),
                );
              },
              icon: const Icon(Icons.route_rounded),
              label: const Text('Ver mi camino de niveles'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.darkGreenCard,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ESTADÍSTICAS RÁPIDAS
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const ValueKey('open-daily-streak'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const DailyStreakScreen(),
                    ),
                  ),
                  child: _stat(
                    Icons.local_fire_department,
                    '$streak días',
                    'Racha actual',
                    AppColors.yellowCard,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat(
                  Icons.check_circle_outline,
                  '$completed / $total',
                  'Hábitos completados',
                  HealthyAdaptive.surfaceAlt,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ESTADÍSTICAS Y PROGRESO
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgresoScreen()),
                );
              },
              icon: const Icon(Icons.insights_rounded),
              label: const Text('Ver mis estadísticas y progreso'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // RANKING GLOBAL
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RankingScreen()),
                );
              },
              icon: const Icon(Icons.emoji_events_rounded),
              label: const Text('Ver ranking de usuarios'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.darkGreenCard,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Accesos rápidos a los tres pasos centrales del recorrido.
          _demoJourney(context),

          const SizedBox(height: 24),

          // MISIÓN DEL DÍA
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tu misión de hoy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              TextButton(onPressed: onHabits, child: const Text('Ver hábitos')),
            ],
          ),

          const SizedBox(height: 10),

          _mission(context, mission),

          const SizedBox(height: 16),

          _achievement(context),

          const SizedBox(height: 16),

          _mascot(context),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // TARJETA DE NIVEL Y XP
  // --------------------------------------------------

  Widget _levelCard() {
    final current = LevelSystem.fromXp(xp);
    final next = LevelSystem.nextLevel(xp);

    final progress = LevelSystem.progress(xp);
    final remaining = LevelSystem.remainingXp(xp);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3832), Color(0xFF1E4D44)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(current.icon, color: current.accentColor, size: 22),
                    Text(
                      '${current.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TU NIVEL ACTUAL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      current.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Text(
            '$xp XP acumulados',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          ),

          const SizedBox(height: 9),

          Text(
            next == null
                ? '¡Alcanzaste el último nivel disponible!'
                : 'Faltan $remaining XP para '
                    'nivel ${next.number}: ${next.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),

          if (next != null) ...[
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: [
                const Text('Próxima recompensa prevista:',
                  style: TextStyle(color: Color(0xFFFFE49A),
                    fontSize: 12, fontWeight: FontWeight.w700)),
                HealthyCoinAmount(amount: '${next.rewardCoins}',
                  size: 18, suffix: ' Habit Coins',
                  style: const TextStyle(color: Color(0xFFFFE49A),
                    fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------
  // HERRAMIENTAS DE DESARROLLO
  // --------------------------------------------------

  // --------------------------------------------------
  // TARJETAS DE ESTADÍSTICAS
  // --------------------------------------------------

  Widget _stat(IconData icon, String value, String caption, Color bg) {
    return HealthyMotionCard(
      enablePress: false,
      child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon == Icons.local_fire_department
              ? HealthyGlowIcon(icon: icon, color: const Color(0xFFE5A34B))
              : Icon(icon, color: AppColors.primaryGreen),
          const SizedBox(height: 6),
          caption == 'Racha actual'
              ? HealthyStreakNumber(
                  days: int.tryParse(value.split(' ').first) ?? 0,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
          Text(
            caption,
            style: TextStyle(color: AppColors.textGrey, fontSize: 11),
          ),
        ],
      ),
      ),
    );
  }

  // --------------------------------------------------
  // RECORRIDO PRINCIPAL
  // --------------------------------------------------

  Widget _demoJourney(BuildContext context) {
    return Container(
      key: const Key('inicio-recorrido'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        border: Border.all(color: HealthyAdaptive.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu recorrido saludable',
            style: TextStyle(color: AppColors.textDark,
              fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 5),
          Text('Registra una actividad y observa tus avances.',
            style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _journeyAction(
                  context,
                  icon: Icons.add_task_rounded,
                  title: 'Registrar',
                  subtitle: 'Hábitos',
                  onTap: onHabits,
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: HealthyAdaptive.muted),
              const SizedBox(width: 7),
              Expanded(
                child: _journeyAction(
                  context,
                  icon: Icons.insights_rounded,
                  title: 'Progreso',
                  subtitle: 'Estadísticas',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProgresoScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: HealthyAdaptive.muted),
              const SizedBox(width: 7),
              Expanded(
                child: _journeyAction(
                  context,
                  icon: Icons.emoji_events_rounded,
                  title: 'Logros',
                  subtitle: 'Insignias',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogrosScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _journeyAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: HealthyAdaptive.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 23, color: HealthyAdaptive.accent),
              const SizedBox(height: 6),
              Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textDark,
                  fontSize: 12, fontWeight: FontWeight.w800)),
              Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: HealthyAdaptive.muted, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MISIÓN DEL DÍA
  // --------------------------------------------------

  Widget _mission(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>>? habit,
  ) {
    if (habit == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: HealthyAdaptive.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(
              Icons.flag_outlined,
              color: AppColors.primaryGreen,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Todavía no tienes hábitos activos.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onHabits,
              child: const Text('Explorar hábitos'),
            ),
          ],
        ),
      );
    }

    final data = habit.data();

    final title = (data['title'] ?? data['name'] ?? 'Hábito').toString();

    final category = (data['category'] ?? 'Bienestar').toString();

    // Los intentos anteriores a la sincronización de campos «latest»
    // solamente tienen lastAttemptId. Mantener ambos evita perder el botón.
    final attemptId =
        (data['latestAttemptId'] ?? data['lastAttemptId'] ?? '').toString();

    final progress = _number(data['latestProgress']);

    final target = _number(data['latestTarget'] ?? data['target'], 1)
        .clamp(1, 100000).toInt();

    final fraction = (progress / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.blueWaterCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.toUpperCase(),
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 21,
            ),
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          ),

          const SizedBox(height: 9),

          Text(
            '$progress de $target sesiones',
            style: TextStyle(color: AppColors.textGrey),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  attemptId.isEmpty
                      ? onHabits
                      : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RegistrarHabitoScreen(
                                  habitId: habit.id,
                                  attemptId: attemptId,
                                  habitTitle: title,
                                  category: category,
                                  currentProgress: progress,
                                  goal: target,
                                ),
                          ),
                        );
                      },
              icon: const Icon(Icons.add_rounded),
              label: Text(
                attemptId.isEmpty ? 'Ver hábitos' : 'Registrar sesión',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // LOGROS
  // --------------------------------------------------

  Widget _achievement(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: userRef.collection('achievements').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No se pudieron consultar los logros.'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final ids = snapshot.data!.docs.map((d) => d.id).toSet();

        final perfil = <String, dynamic>{
          'xp': xp,
          'level': level,
          'currentStreak': streak,
        };

        final completados =
            habits.where((h) => h.data()['latestStatus'] == 'completed').length;

        final siguiente = LogrosService.siguiente(
          perfil,
          habits.length,
          completados,
          ids,
        );

        final progreso =
            siguiente == null
                ? 0
                : LogrosService.progreso(
                  siguiente,
                  perfil,
                  habits.length,
                  completados,
                  ids,
                );

        return Material(
          color: AppColors.purpleCard,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LogrosScreen()));
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.yellowCard,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      siguiente == null
                          ? Icons.emoji_events_rounded
                          : siguiente.icono,
                      color: Colors.deepOrange,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          siguiente == null
                              ? 'COLECCIÓN COMPLETA'
                              : 'PRÓXIMO LOGRO',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          siguiente?.nombre ?? '¡Todos los logros conseguidos!',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          siguiente == null
                              ? 'Consulta tu colección de medallas.'
                              : '${siguiente.descripcion} · '
                                  '${progreso.clamp(0, siguiente.meta)} '
                                  '/ ${siguiente.meta}',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Ver todos los logros',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textGrey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // MASCOTA Y NUTRICHAT
  // --------------------------------------------------

  Widget _mascot(BuildContext context) {
    return Container(
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
                Text(
                  'MR. HEALTHY',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Cada pequeño paso cuenta.',
                  style: TextStyle(color: AppColors.textDark),
                ),

                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NutriChatPage()),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Chatear'),
                ),
              ],
            ),
          ),

          Image.asset(
            'assets/mascot/healthy.png',
            width: 72,
            height: 72,
            errorBuilder: (_, __, ___) => const Icon(Icons.eco, size: 50),
          ),
        ],
      ),
    );
  }
}
