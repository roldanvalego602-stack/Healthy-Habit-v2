import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import 'social_action_button.dart';
import 'profile_avatar.dart';
import 'healthy_framed_avatar.dart';
import 'profile_photo_viewer.dart';
import '../../tema/healthy_cosmetics.dart';
import 'profile_banner.dart';
import 'amigos_servicio.dart';
import '../logros/logros_service.dart';
import '../tienda/healthy_mascot_outfit.dart';
import '../tienda/shop_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String username;
  final String? bio;
  final String? title;
  final int level;
  final int streakDays;
  final int completedHabits;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    this.bio = 'Pequeños pasos, raíces fuertes.',
    this.title = 'Cultivador de constancia',
    this.level = 1,
    this.streakDays = 0,
    this.completedHabits = 0,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  static const Color green = Color(0xFF198568);
  static const Color mint = Color(0xFF8DE0C0);
  Color get navy => HealthyAdaptive.text;
  Color get background => HealthyAdaptive.background;
  static const Color gold = Color(0xFFD5A33E);
  bool _isLoading = false;

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _followingRef {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.uid == widget.userId) {
      return null;
    }

    return _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('friends')
        .doc(widget.userId);
  }

  DocumentReference<Map<String, dynamic>>? get _pendingRef {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.uid == widget.userId) {
      return null;
    }
    return _db.collection('users').doc(currentUser.uid)
        .collection('solicitudes_enviadas').doc(widget.userId);
  }

  Future<void> _toggleFriendship(bool isFollowing, bool isPending) async {
    if (_currentUser == null || _currentUser!.uid == widget.userId ||
        _isLoading) {
      return;
    }
    if (isFollowing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar amigo'),
          content: Text('¿Quieres eliminar a ${widget.name} de tus amigos?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    setState(() => _isLoading = true);
    try {
      if (isFollowing) {
        await AmigosServicio.eliminarAmigo(widget.userId);
      } else if (isPending) {
        await AmigosServicio.cancelarSolicitud(widget.userId);
      } else {
        await AmigosServicio.enviarSolicitud(widget.userId);
      }
      if (!mounted) return;
      _showMessage(isFollowing
          ? 'Eliminaste a ${widget.name} de tus amigos.'
          : isPending
              ? 'Solicitud cancelada.'
              : 'Solicitud enviada a ${widget.name}.');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(e.code == 'permission-denied'
          ? 'Esta acción no está permitida por Firestore.'
          : 'No se pudo completar la solicitud. Inténtalo de nuevo.');
    } catch (_) {
      if (mounted) _showMessage('No se pudo completar la acción.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: green));
  }

  String _readString(Map<String, dynamic> data, String key, String fallback) {
    final value = data[key];
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString().trim();
  }

  int _readInt(Map<String, dynamic> data, String key, int fallback) {
    final value = data[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection(isOwnAccount(widget.userId) ? 'users' : 'public_profiles').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};

        final name = _readString(data, 'name', widget.name);
        final photoUrl = data.containsKey('photoUrl')
            ? data['photoUrl']?.toString() ?? ''
            : isOwnAccount(widget.userId)
                ? _currentUser?.photoURL ?? ''
                : '';
        final username = _formatUsername(
          _readString(data, 'username', widget.username),
        );
        final bio = _readString(
          data,
          'bio',
          widget.bio ?? 'Pequeños pasos, raíces fuertes.',
        );
        final title = _readString(
          data,
          'title',
          widget.title ?? 'Cultivador de constancia',
        );
        final level = _readInt(data, 'level', widget.level);
        final streak = _readInt(data, 'currentStreak', widget.streakDays);
        final rawSettings = data['settings'];
        final publicStreak = rawSettings is! Map ||
            rawSettings['mostrarRachaAmigos'] != false;
        final achievementsVisibility = rawSettings is Map
            ? (rawSettings['visibilidadLogros'] ?? 'Solo amigos').toString()
            : 'Solo amigos';
        final completed = _readInt(
          data,
          'completedHabits',
          widget.completedHabits,
        );

        final currentUser = _currentUser;
        final isOwnProfile = currentUser?.uid == widget.userId;
        final friendRef = _followingRef;

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: navy),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              username,
              style: TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child:
                snapshot.hasError
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No se pudo cargar el perfil. '
                          'Revisa las reglas de Firestore.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData
                    ? const Center(
                      child: CircularProgressIndicator(color: green),
                    )
                    : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _publicProfileCard(
                            name: name,
                            photoUrl: photoUrl,
                            avatarStyle: HealthyCosmetics.equippedId(
                                  data, 'perfil_avatar', publicProfile: true) ??
                                _readString(data, 'profileAvatarStyle', 'foto'),
                            bannerStyle: HealthyCosmetics.equippedId(
                                  data, 'perfil_banner', publicProfile: true) ??
                                _readString(data, 'profileBanner', 'Amanecer'),
                            frameAsset: HealthyCosmetics.equippedAsset(
                                data, 'perfil_marco', publicProfile: true),
                            username: username,
                            bio: bio,
                            title: title,
                            isOwnProfile: isOwnProfile,
                            friendRef: friendRef,
                          ),
                          const SizedBox(height: 22),
                          _levelCard(level),
                          const SizedBox(height: 14),
                          _statistics(streak, completed,
                            showStreak: isOwnProfile || publicStreak),
                          const SizedBox(height: 28),
                          _visibleAchievements(
                            own: isOwnProfile,
                            visibility: achievementsVisibility,
                            data: data,
                          ),
                          const SizedBox(height: 24),
                          _myHealthyCard(data),
                          const SizedBox(height: 20),
                          _mascotSupportCard(name),
                        ],
                      ),
                    ),
          ),
        );
      },
    );
  }

  bool isOwnAccount(String uid) => _currentUser?.uid == uid;

  String _formatUsername(String username) {
    return username.startsWith('@') ? username : '@$username';
  }

  Widget _publicProfileCard({
    required String name,
    required String photoUrl,
    required String avatarStyle,
    required String bannerStyle,
    required String? frameAsset,
    required String username,
    required String bio,
    required String title,
    required bool isOwnProfile,
    required DocumentReference<Map<String, dynamic>>? friendRef,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 18),
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
            bannerStyle: bannerStyle,
            label: 'PERFIL PÚBLICO',
            fallbackColors: const [
              Color(0xFF174D4B),
              Color(0xFF498A75),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                Semantics(
                  button: true,
                  label: 'Ampliar fotografía de perfil',
                  child: InkWell(
                    key: const Key('public-profile-open-avatar'),
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProfilePhotoFullScreen(
                          photoUrl: photoUrl,
                          preset: avatarStyle,
                        ),
                      ),
                    ),
                    child: HealthyFramedAvatar(
                      size: 88,
                      photoUrl: photoUrl,
                      preset: avatarStyle,
                      frameAsset: frameAsset,
                      backgroundColor: HealthyAdaptive.surfaceAlt,
                      borderColor: mint,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: TextStyle(
                    color: HealthyAdaptive.muted,
                    fontSize: 13,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: HealthyAdaptive.isDark
                          ? const Color(0xFF473A26)
                          : const Color(0xFFFFF2D2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '✦ $title',
                      style: TextStyle(
                        color: HealthyAdaptive.isDark
                            ? const Color(0xFFF7D58D) : gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8797A0),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (!isOwnProfile && friendRef != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: friendRef.snapshots(),
                      builder: (context, followingSnapshot) {
                        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: _pendingRef!.snapshots(),
                          builder: (context, pendingSnapshot) {
                            final isFollowing = followingSnapshot.data?.exists ?? false;
                            final isPending = pendingSnapshot.data?.exists ?? false;
                            final ready = followingSnapshot.hasData &&
                                pendingSnapshot.hasData &&
                                !followingSnapshot.hasError &&
                                !pendingSnapshot.hasError;
                            return SizedBox(
                              width: double.infinity,
                              child: SocialActionButton(
                                label: isFollowing ? 'Amigos'
                                    : isPending ? 'Pendiente' : 'Agregar amigo',
                                icon: isFollowing ? Icons.check_circle_rounded
                                    : isPending ? Icons.schedule_rounded
                                    : Icons.person_add_rounded,
                                outlined: isFollowing || isPending,
                                busy: _isLoading || !ready,
                                onPressed: !ready || _isLoading
                                    ? null
                                    : () => _toggleFriendship(isFollowing, isPending),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelCard(int level) {
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
      child: Row(
        children: [
          Container(
            width: 54,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: mint, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '$level',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NIVEL DE HÁBITOS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cultivador Nivel $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

  Widget _statistics(int streak, int completed, {required bool showStreak}) {
    return Row(
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
        if (showStreak) const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.check_circle_outline_rounded,
            value: '$completed',
            label: 'Hábitos logrados',
            color: const Color(0xFFE0F3FB),
            iconColor: const Color(0xFF459FCB),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: HealthyAdaptive.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: navy,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _visibleAchievements({
    required bool own,
    required String visibility,
    required Map<String, dynamic> data,
  }) {
    Widget content() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Logros destacados'),
        const SizedBox(height: 14),
        _achievementsCard(data),
      ],
    );

    Widget privateMessage() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Los logros de este usuario son privados.',
        style: TextStyle(color: HealthyAdaptive.muted),
      ),
    );

    if (own || visibility == 'Todos') return content();
    if (visibility == 'Solo yo') return privateMessage();
    final viewer = _currentUser?.uid;
    if (viewer == null) return privateMessage();

    // La aceptación de una amistad crea un documento recíproco.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(widget.userId)
          .collection('friends').doc(viewer).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return privateMessage();
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return snapshot.data!.exists ? content() : privateMessage();
      },
    );
  }

  /// Solo se muestran insignias deducibles de los datos publicados
  /// (nivel, XP y racha compartida); nunca medallas ficticias.
  Widget _achievementsCard(Map<String, dynamic> data) {
    const visibleTypes = {'nivel', 'xp', 'racha'};
    final visible = LogrosService.catalogo.where((definition) {
      if (!visibleTypes.contains(definition.tipo)) return false;
      return LogrosService.obtenido(
        definition,
        LogrosService.progreso(definition, data, 0, 0, const <String>{}),
      );
    }).take(3).toList();

    final rawEquipment = data['healthyEquipped'];
    final exhibitor = rawEquipment is Map &&
        rawEquipment['perfil_expositor'] == 'achievement_display';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        border: exhibitor
            ? Border.all(color: gold, width: 2)
            : null,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exhibitor) ...[
            Row(children: [
              const Icon(Icons.workspace_premium_rounded,
                color: gold, size: 19),
              const SizedBox(width: 8),
              Text('EXPOSITOR DE LOGROS', style: TextStyle(
                color: navy, fontWeight: FontWeight.w900, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
          ],
          visible.isEmpty
          ? Text(
              'Todavía no hay insignias compartidas de nivel, XP o racha.',
              style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12),
            )
          : Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final logro in visible)
                  _achievement(
                    logro.icono,
                    logro.nombre,
                    HealthyAdaptive.accent,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _achievement(IconData icon, String name, Color color) {
    return SizedBox(
      width: 95,
      child: Column(children: [
        Container(
          width: 58,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            border: Border.all(color: color, width: 1.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: navy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ]),
    );
  }

  Widget _myHealthyCard(Map<String, dynamic> data) {
    final raw = data['healthyEquipped'];
    final equipped = <String, String>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.key is! String || entry.value is! String) continue;
        final item = shopItemById(entry.value as String);
        if (item != null && item.slot == entry.key &&
            !entry.key.toString().startsWith('perfil_')) {
          equipped[entry.key as String] = item.id;
        }
      }
    }
    final names = equipped.values
        .map((id) => shopItemById(id)?.name)
        .whereType<String>()
        .toList();
    return Container(
      key: const ValueKey('public-profile-my-healthy'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        border: Border.all(color: HealthyAdaptive.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome_rounded, color: HealthyAdaptive.accent),
            const SizedBox(width: 9),
            Text('Mi Healthy', style: TextStyle(
              color: navy, fontSize: 18, fontWeight: FontWeight.w800,
            )),
          ]),
          const SizedBox(height: 5),
          Text('Así luce Mr. Healthy con sus accesorios equipados.',
            style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 275,
            child: FittedBox(
              fit: BoxFit.contain,
              child: HealthyMascotOutfit(equipped: equipped),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              names.isEmpty ? 'Mr. Healthy sin accesorios' : names.join(' · '),
              textAlign: TextAlign.center,
              style: TextStyle(color: navy, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mascotSupportCard(String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthyAdaptive.mint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: green, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '¡Acompaña a $name a mantener sus hábitos saludables!',
              style: TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
