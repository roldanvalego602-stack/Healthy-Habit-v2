import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_coin.dart';

import 'amigos_servicio.dart';
import 'amigos_screen.dart';
import '../logros/logros_screen.dart';
import '../logros/logros_service.dart';
import '../estadisticas/progreso_screen.dart';
import 'buscar_amigos_screen.dart';
import 'configuracion_screen.dart';
import 'profesionales_screen.dart';
import 'feed_amigos_screen.dart';
import 'editar_perfil_screen.dart';
import 'healthy_framed_avatar.dart';
import '../../tema/healthy_cosmetics.dart';
import 'profile_banner.dart';
import 'profile_photo_viewer.dart';
import 'profile_titles.dart';
import '../../servicios/daily_streak_display.dart';
import 'profile_monthly_summary.dart';
import 'profile_habit_insights.dart';
import '../tienda/wardrobe_screen.dart';
import '../tienda/healthy_mascot_live.dart';
import '../tienda/healthy_achievement_display.dart';
import '../splash_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color green = Color(0xFF198568);
  static const Color mint = Color(0xFF8DE0C0);
  Color get navy => HealthyAdaptive.text;
  Color get background => HealthyAdaptive.background;
  static const Color gold = Color(0xFFD5A33E);
  Color get muted => HealthyAdaptive.muted;

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
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
                    Text(
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
          return Scaffold(
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
        // Firebase Auth es la referencia del correo actual verificado.
        final email = _string(user.email, fallback: _string(data['email']));
        final level = _integer(data['level'], fallback: 1);
        final xp = _integer(data['xp']);
        final coins = _integer(data['habitCoins']);
        final streak = DailyStreakDisplay.current(data);
        final rawSettings = data['settings'];
        final prefs = rawSettings is Map ? rawSettings : const <String, dynamic>{};
        bool visible(String key) =>
            prefs[key] != false && prefs['modoDiscreto'] != true;
        final showXp = visible('mostrarXp');
        final showCoins = visible('mostrarPuntos');
        final showLevel = visible('mostrarNivelPerfil');
        final showStreak = visible('mostrarRachasDiarias');
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
                    showCoins: showCoins,
                    data: data,
                  ),
                  const SizedBox(height: 16),
                  _friendsCard(context, user.uid),
                  const SizedBox(height: 22),
                  if (showLevel || showXp) ...[
                    _levelCard(level: level, xp: xp,
                      showLevel: showLevel, showXp: showXp),
                    const SizedBox(height: 14),
                  ],
                  _statistics(streak: streak, coins: coins,
                    uid: user.uid, showStreak: showStreak, showCoins: showCoins),
                  if (prefs['modoDiscreto'] != true) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('Mis hábitos destacados', null, null),
                    const SizedBox(height: 12),
                    ProfileHabitInsightsCard(userRef: userRef),
                  ],
                  const SizedBox(height: 28),
                  _sectionTitle(
                    'Mis logros',
                    'Ver todos',
                    () => _open(context, const LogrosScreen()),
                  ),
                  const SizedBox(height: 14),
                  _achievementsCard(userRef, context, data),
                  const SizedBox(height: 12),
                  _sectionTitle('Tu mes, paso a paso', null, null),
                  const SizedBox(height: 14),
                  ProfileMonthlySummary(
                     userRef: userRef,
                     onViewProgress: () => _open(context, const ProgresoScreen()),
                   ),
                  const SizedBox(height: 28),
                  _sectionTitle(
                    'Personalización',
                    'Abrir armario',
                    () => _open(context, const WardrobeScreen()),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const ValueKey('profile-wardrobe-only'),
                      onPressed: () => _open(context, const WardrobeScreen()),
                      icon: const Icon(Icons.checkroom_rounded),
                      label: const Text(
                        'Cambiar banner, marco, avatar y estante en Armario'),
                    ),
                  ),
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
                          color: Colors.redAccent.withValues(alpha: 0.3),
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
      Expanded(
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
        color: HealthyAdaptive.surface,
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
    required bool showCoins,
    required Map<String, dynamic> data,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 14),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileBanner(
            bannerStyle: HealthyCosmetics.equippedId(data, 'perfil_banner') ??
                _string(data['profileBanner'], fallback: 'Amanecer'),
            label: HealthyCosmetics.equippedId(data, 'perfil_banner') != null
                ? 'MI PERFIL'
                : _string(data['profileBanner'], fallback: 'Amanecer')
                    .toUpperCase(),
            fallbackColors: _bannerColors(
              _string(data['profileBanner'], fallback: 'Amanecer'),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -45),
            child: Column(
              children: [
                Semantics(
                  button: true,
                  label: 'Opciones de foto de perfil',
                  child: InkWell(
                    key: const Key('profile-edit-photo'),
                    customBorder: const CircleBorder(),
                    onTap: () => showProfilePhotoActions(
                      context,
                      photoUrl: data.containsKey('photoUrl')
                          ? data['photoUrl']?.toString() ?? ''
                          : FirebaseAuth.instance.currentUser?.photoURL,
                      preset: HealthyCosmetics.equippedId(
                            data, 'perfil_avatar') ??
                          _string(data['profileAvatarStyle'], fallback: 'foto'),
                      onEdit: () => _open(context, const EditarPerfilScreen()),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        HealthyFramedAvatar(
                          size: 94,
                          photoUrl: data.containsKey('photoUrl')
                              ? data['photoUrl']?.toString() ?? ''
                              : FirebaseAuth.instance.currentUser?.photoURL,
                          preset: HealthyCosmetics.equippedId(
                                data, 'perfil_avatar') ??
                              _string(data['profileAvatarStyle'],
                                  fallback: 'foto'),
                          frameAsset: HealthyCosmetics.equippedAsset(
                              data, 'perfil_marco'),
                          backgroundColor: HealthyAdaptive.surface,
                          borderColor: _frameColor(
                            _string(data['profileFrame'],
                                fallback: 'Brote dorado'),
                          ),
                          borderWidth: 3,
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: HealthyAdaptive.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: HealthyAdaptive.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username.isNotEmpty ? '@$username' : email,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: HealthyAdaptive.isDark
                      ? const Color(0xFF443825)
                      : const Color(0xFFFFF2D2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✦ ${HealthyProfileTitles.visibleTitle(_string(data['profileTitle']), _integer(data['level'], fallback: 1), const <String>{})}',
                    style: TextStyle(
                      color: HealthyAdaptive.isDark
                          ? const Color(0xFFFFD477)
                          : const Color(0xFF977020),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    _string(data['bio'],
                      fallback: 'Pequeños pasos, raíces fuertes.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
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
                              foregroundColor: const Color(0xFF10392F),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (showCoins) ...[
                      const SizedBox(width: 10),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: HealthyAdaptive.yellow,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const HealthyCoinIcon(size: 20),
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
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.05),
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
                  color: HealthyAdaptive.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: green, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
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
                child: _friendStat(context, uid, 'friends', 'Amigos', 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _friendStat(
                  context, uid, 'solicitudes', 'Solicitudes', 1,
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
                      style: TextStyle(
                        color: navy,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
              ),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _openFriends(BuildContext context, int tab) {
    _open(context, AmigosScreen(initialTab: tab));
  }

  Widget _levelCard({required int level, required int xp, required bool showLevel, required bool showXp}) {
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
          if (showLevel) Row(
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
          if (showXp) ...[
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
    return counts.fold<int>(0, (total, amount) => total + amount);
  }

  Widget _statistics({
    required int streak,
    required int coins,
    required String uid,
    required bool showStreak,
    required bool showCoins,
  }) => Row(
    children: [
      if (showStreak) Expanded(
        child: _statCard(
          icon: Icons.local_fire_department_outlined,
          value: '$streak',
          label: 'Días de racha',
          color: const Color(0xFFFFF0CF),
          iconColor: gold,
        ),
      ),
      if (showStreak) const SizedBox(width: 9),
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
                color: HealthyAdaptive.water,
                iconColor: const Color(0xFF459FCB),
              ),
        ),
      ),
      if (showCoins) const SizedBox(width: 9),
      if (showCoins) Expanded(
        child: _statCard(
          customIcon: const HealthyCoinIcon(size: 22),
          value: '$coins',
          label: 'Habit Coins',
          color: HealthyAdaptive.lavender,
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
      color: HealthyAdaptive.surface,
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
          style: TextStyle(
            color: navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 10),
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
              style: TextStyle(
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

  /// Los mismos cálculos que LogrosScreen, sin otorgar recompensas.
  Widget _achievementsCard(
    DocumentReference<Map<String, dynamic>> userRef,
    BuildContext context,
    Map<String, dynamic> profile,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: userRef.collection('user_habits').snapshots(),
    builder: (context, habitsSnapshot) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: userRef.collection('achievements').snapshots(),
        builder: (context, badgesSnapshot) {
          if (habitsSnapshot.hasError || badgesSnapshot.hasError) {
            return ListTile(
              title: const Text('No se pudieron consultar tus logros'),
              onTap: () => _open(context, const LogrosScreen()),
            );
          }
          if (!habitsSnapshot.hasData || !badgesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final habits = habitsSnapshot.data!.docs;
          final completed = habits.where(
            (doc) => doc.data()['latestStatus'] == 'completed',
          ).length;
          final ids = badgesSnapshot.data!.docs.map((doc) => doc.id).toSet();
          final obtained = LogrosService.catalogo.where((def) =>
            LogrosService.obtenido(def,
              LogrosService.progreso(def, profile, habits.length, completed, ids),
            ),
          ).length;
          final next = LogrosService.siguiente(
            profile, habits.length, completed, ids,
          );
          final total = LogrosService.catalogo.length;
          final fraction = total == 0 ? 0.0 : obtained / total;
          final equipment = profile['shopEquipped'];
          final hasDisplay = equipment is Map &&
              equipment['perfil_expositor'] == 'achievement_display';
          return Material(
            color: HealthyAdaptive.surface,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _open(context, const LogrosScreen()),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(
                        hasDisplay
                            ? 'EXPOSITOR DE LOGROS · ${_string(profile['profileShelf'], fallback: 'Mis favoritos').toUpperCase()}'
                            : 'ESTANTE · ${_string(profile['profileShelf'], fallback: 'Mis favoritos').toUpperCase()}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted,
                          fontWeight: FontWeight.w800, fontSize: 11))),
                      Text('$obtained de $total',
                        style: TextStyle(color: HealthyAdaptive.accent,
                          fontWeight: FontWeight.w900)),
                    ]),
                    if (hasDisplay) ...[
                      const SizedBox(height: 12),
                      Center(child: HealthyAchievementDisplay(
                        width: 260, height: 148, earned: obtained)),
                    ],
                    const SizedBox(height: 16),
                    Row(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: HealthyAdaptive.mint,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(next?.icono ?? Icons.workspace_premium_rounded,
                          color: HealthyAdaptive.accent, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(next?.nombre ?? '¡Colección completa!',
                            style: TextStyle(color: navy,
                              fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(next?.descripcion ??
                              'Has alcanzado todos los objetivos disponibles.',
                            style: TextStyle(color: muted, fontSize: 12)),
                        ],
                      )),
                      Icon(Icons.chevron_right_rounded, color: muted),
                    ]),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: fraction, minHeight: 7,
                        backgroundColor: HealthyAdaptive.border,
                        color: HealthyAdaptive.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Toca para ver los detalles de tus insignias',
                      style: TextStyle(color: muted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
  );

  Widget _mascotCard({required int streak}) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: HealthyAdaptive.mint,
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
            child: const HealthyMascotLive(size: 92),
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
                style: TextStyle(
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
      color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: navy.withValues(alpha: 0.04),
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
            color: HealthyAdaptive.water,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: Color(0xFF3880A3),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
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
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: navy,
            size: 18,
          ),
        ),
      ],
    ),
  );

  Widget _settingsCard(BuildContext context) => Material(
    color: HealthyAdaptive.surface,
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
                color: HealthyAdaptive.mint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: green,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
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
            Icon(Icons.chevron_right_rounded, color: navy),
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

}
