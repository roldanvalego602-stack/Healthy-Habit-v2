import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'tema/healthy_theme.dart';
import 'tema/cosmos_theme_sync.dart';
import 'tema/healthy_magic_guide.dart';
import 'servicios/healthy_retro_sound_service.dart';
import 'tema/healthy_profile_presentation.dart';
import 'páginas/perfil/profile_avatar.dart';
import 'páginas/tienda/healthy_mascot_live.dart';
import 'tema/healthy_visual_mode.dart';
import 'tema/healthy_motion.dart';
import 'tema/healthy_float.dart';
import 'servicios/preferencias_app.dart';
import 'servicios/healthy_reminders_service.dart';
import 'servicios/healthy_public_profile_service.dart';
import 'servicios/shop_demo_bootstrap.dart';
import 'servicios/beta_habit_gateway.dart';

// Importaciones de tus pantallas
import 'páginas/habitos/habits_screen.dart';
import 'páginas/tienda/store_screen.dart';
import 'páginas/perfil/profile_screen.dart';
import 'páginas/desafios/desafios_screen.dart';
import 'páginas/splash_screen.dart';
import 'páginas/notifications_screen.dart';
import 'páginas/habitos/registrar_habito_screen.dart';
import 'páginas/chatbot/nutrichat.dart';
import 'páginas/perfil/feed_amigos_screen.dart';

// Instancia compartida de Firestore.
late final FirebaseFirestore firestoreDb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HealthyThemeController.instance.load();
  await HealthyVisualController.instance.load();

  // Modo demo aislado: el arranque falla si los flags no coinciden.
  // Nunca se inicializa la app real cuando las compras demo están habilitadas.
  ShopDemoBootstrap.validateMode(
    ShopDemoBootstrap.enabled, ShopDemoBootstrap.purchaseEnabled);
  ShopDemoBootstrap.validateOfficialHabitsMode();
  // Nunca mezclar los diarios ni el proyecto Firebase de demo y beta.
  if (BetaHabitGateway.enabled && ShopDemoBootstrap.enabled) {
    throw StateError(
      'Los modos demo y beta de hábitos son mutuamente excluyentes.');
  }
  if (ShopDemoBootstrap.enabled) {
    ShopDemoBootstrap.validateHost(ShopDemoBootstrap.host);
    if (Firebase.apps.isNotEmpty) {
      // Android puede haber inicializado el proyecto de google-services.json.
      // No tomar una app de producción ni sustituirla silenciosamente.
      throw StateError(
        'Firebase ya está inicializado. Para el modo demo usa una '
        'configuración nativa aislada sin proyecto real.');
    }
  }
  await Firebase.initializeApp(
    options: ShopDemoBootstrap.enabled
        ? ShopDemoBootstrap.demoOptions
        : DefaultFirebaseOptions.currentPlatform,
  );

  // App Check solamente para el cliente de beta cerrado. En ejecuciones
  // normales y en demo no se cambia ningún proveedor ni proyecto.
  // El backend permanece cerrado hasta endurecer la base llamada 'default'.
  if (BetaHabitGateway.enabled) {
    if (ShopDemoBootstrap.enabled ||
        Firebase.app().options.projectId != BetaHabitGateway.projectId ||
        kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw StateError(
        'La beta de hábitos solo admite Android y el proyecto autorizado.');
    }
    const debugAttestation = bool.fromEnvironment(
      'HH_BETA_APP_CHECK_DEBUG', defaultValue: false);
    if (debugAttestation && !kDebugMode) {
      throw StateError(
        'App Check de depuración está prohibido en compilaciones release.');
    }
    await FirebaseAppCheck.instance.activate(
      androidProvider: debugAttestation
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  }

  final firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(), databaseId: 'default');

  if (ShopDemoBootstrap.enabled) {
    ShopDemoBootstrap.validateInitializedProject(
      Firebase.app().options.projectId);
    await FirebaseAuth.instance.useAuthEmulator(
      ShopDemoBootstrap.host, 9099);
    firestore.useFirestoreEmulator(ShopDemoBootstrap.host, 8080);
    if (ShopDemoBootstrap.officialHabitsEnabled) {
      FirebaseFunctions.instanceFor(
        app: Firebase.app(), region: 'us-central1',
      ).useFunctionsEmulator(ShopDemoBootstrap.host, 5001);
      debugPrint('Healthy Habit: hábitos oficiales conectados a Functions Emulator.');
    }
    debugPrint('Healthy Habit: proyecto DEMO aislado, sin datos de producción.');
  }

  debugPrint('Firestore databaseId: ${firestore.databaseId}');

  // No consultar toda la colección users: contiene perfiles privados.
  // La conexión se verificará mediante lecturas autorizadas en cada pantalla.

  firestoreDb = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  // Configura y reconstruye los avisos del usuario actual al iniciar sesión.
  // Si cambia o se cierra la cuenta, cancela la agenda del usuario anterior.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      try {
        if (user == null) {
          await HealthyRemindersService.instance.cancel();
          return;
        }
        final ref = firestoreDb.collection('users').doc(user.uid);
        final doc = await ref.get();
        if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
        final raw = doc.data()?['settings'];
        await HealthyRemindersService.instance.synchronize(
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
          profile: doc.data(),
        );
      } catch (error) {
        debugPrint('Recordatorios: no se pudo restaurar la agenda: $error');
      }
    });
  }

  HealthyPublicProfileService.instance.start();
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        HealthyThemeController.instance,
        HealthyVisualController.instance,
      ]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Healthy Habit',
        theme: HealthyThemes.light(),
        darkTheme: HealthyThemes.dark(),
        themeMode: HealthyThemeController.instance.mode,
        // La escala de Configuración se aplica a todas las rutas,
        // respetando también la escala de accesibilidad del dispositivo.
        builder: (context, child) => PreferenciasApp(
          builder: (context, _, textScale) {
            final baseScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(baseScale * textScale),
              ),
              child: CosmosThemeSync(
                child: CosmosAppScene(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// ---------- Paleta de Colores ----------
class AppColors {
  static Color get primaryGreen => HealthyAdaptive.accent;
  static Color get darkGreenCard => HealthyAdaptive.isDark ? const Color(0xFF19453A) : const Color(0xFF143834);
  static Color get textDark => HealthyAdaptive.text;
  static Color get textGrey => HealthyAdaptive.muted;
  static Color get yellowCard => HealthyAdaptive.yellow;
  static Color get blueWaterCard => HealthyAdaptive.water;
  static Color get purpleCard => HealthyAdaptive.lavender;
  static Color get mintCard => HealthyAdaptive.mint;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _tabs => [
    _buildHomeBody(),
    const HabitsScreen(),
    const StoreScreen(),
    const DesafiosScreen(),
    const ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (_selectedIndex == index) return;
    HealthyRetroSoundService.play('tap');
    setState(() => _selectedIndex = index);
  }

  Widget _buildHomeBody() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('No hay una sesión de usuario activa.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestoreDb.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (userSnapshot.hasError) {
          return const Center(
            child: Text('Error al cargar los datos del usuario.'),
          );
        }

        final userData = userSnapshot.data?.data() ?? {};

        final String name = userData['name'] as String? ?? 'Usuario';
        final avatarPreset = HealthyProfilePresentation.avatarPreset(userData);
        final String? photoUrl =
            HealthyProfilePresentation.photoUrl(userData) ??
            (avatarPreset == 'foto' ? currentUser.photoURL : null);
        final int level = (userData['level'] as num?)?.toInt() ?? 1;
        final String levelTitle =
            userData['title'] as String? ?? 'Cultivador Constante';
        final int currentXp = (userData['xp'] as num?)?.toInt() ??
            (userData['currentXp'] as num?)?.toInt() ??
            0;
        final int nextLevelXp =
            (userData['nextLevelXp'] as num?)?.toInt() ?? 1000;
        final int streakDays = (userData['currentStreak'] as num?)?.toInt() ??
            (userData['streakDays'] as num?)?.toInt() ??
            0;
        final String nextAchievement =
            userData['nextAchievementTitle'] as String? ??
            'Insignia Ritmo firme';
        final String nextAchievementSub =
            userData['nextAchievementSubtitle'] as String? ?? 'A 2 misiones';

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              firestoreDb
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('user_habits')
                  .snapshots(),
          builder: (context, habitsSnapshot) {
            if (habitsSnapshot.hasError) {
              return const Center(child: Text('Error al cargar los hábitos.'));
            }

            int totalHabits = 0;
            int completedHabits = 0;
            Map<String, dynamic>? activeMission;

            if (habitsSnapshot.hasData) {
              final docs = habitsSnapshot.data!.docs;

              totalHabits = docs.length;
              completedHabits =
                  docs.where((doc) {
                    return doc.data()['completedToday'] == true;
                  }).length;

              if (docs.isNotEmpty) {
                activeMission = docs.first.data();
              }
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(photoUrl: photoUrl, avatarPreset: avatarPreset),
                  const SizedBox(height: 16),
                  Text(
                    '¡Hola, $name!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
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
      floatingActionButton: HealthyMagicGuideButton(
        section: const ['inicio', 'habitos', 'tienda', 'habitos', 'perfil'][_selectedIndex]),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      body: SafeArea(child: HealthyPageSwitch(index: _selectedIndex, child: _tabs[_selectedIndex])),
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
  final String avatarPreset;

  const _TopBar({this.photoUrl, this.avatarPreset = 'foto'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HealthyMascotLive(size: 38),
        const SizedBox(width: 8),
        Text(
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
            ],
          ),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedAmigosScreen(),
                ),
              );
            },
            child: Icon(
              Icons.dynamic_feed_rounded,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
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
            child: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.mintCard,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: HealthyProfileAvatar(
            photoUrl: photoUrl,
            preset: avatarPreset,
            size: 38,
          ),
        ),
      ],
    );
  }
}

// ---------- Tarjeta Nivel XP ----------
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
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
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
                      style: TextStyle(
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
              valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
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

// ---------- Fila Racha y Progreso Diario ----------
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
        totalHabits > 0 ? completedHabits / totalHabits : 0.0;

    return HealthyMotionCard(
      enablePress: false,
      child: Row(
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
                    const HealthyFloat(
                      distance: 2,
                      child: Text('🔥', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: HealthyStreakNumber(
                        days: streakDays,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
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
              color: HealthyAdaptive.surfaceAlt,
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
                    backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Completados',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      ),
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
        Text(
          'Tu misión de hoy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        GestureDetector(
          onTap: onTapViewHabits,
          child: Text(
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

// ---------- Tarjeta Misión ----------
class _MissionCard extends StatelessWidget {
  final Map<String, dynamic>? missionData;

  const _MissionCard({this.missionData});

  @override
  Widget build(BuildContext context) {
    final String category =
        (missionData?['category'] ?? 'HIDRATACIÓN').toString().toUpperCase();
    final String title =
        missionData?['title'] as String? ?? 'Toma 6 vasos de agua';
    final int xpBonus = (missionData?['xpBonus'] as num?)?.toInt() ?? 10;
    final int currentVal = (missionData?['currentValue'] as num?)?.toInt() ?? 4;
    final int targetVal = (missionData?['targetValue'] as num?)?.toInt() ?? 6;

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
                  style: TextStyle(
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(targetVal.clamp(0, 20), (index) {
              final bool isFilled = index < currentVal;

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
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Solo faltan ${(targetVal - currentVal).clamp(0, targetVal)} vasos',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
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
            decoration: BoxDecoration(
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
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
                Text(
                  'MR. HEALTHY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
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
                  child: Padding(
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
            child: const HealthyMascotLive(size: 72),
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
