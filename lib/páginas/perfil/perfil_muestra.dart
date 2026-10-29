import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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
  static const Color navy = Color(0xFF173544);
  static const Color background = Color(0xFFF4F8F5);
  static const Color gold = Color(0xFFD5A33E);
  bool _isLoading = false;

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _friendRef {
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

  Future<void> _toggleFriendship(bool isFriend) async {
    final currentUser = _currentUser;
    final friendRef = _friendRef;

    if (currentUser == null || friendRef == null) {
      _showMessage('Inicia sesión para agregar amigos.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isFriend) {
        await friendRef.delete();
      } else {
        await friendRef.set({
          'uid': widget.userId,
          'name': widget.name,
          'username': widget.username,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      _showMessage(
        isFriend
            ? 'Has eliminado a ${widget.name} de tus amigos.'
            : '¡Agregaste a ${widget.name} a tus amigos!',
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.code == 'permission-denied'
            ? 'Firestore no permite esta operación. Revisa las reglas.'
            : 'No se pudo actualizar tu lista de amigos.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Ocurrió un error al actualizar tus amigos.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      stream: _db.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};

        final name = _readString(data, 'name', widget.name);
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
        final completed = _readInt(
          data,
          'completedHabits',
          widget.completedHabits,
        );

        final currentUser = _currentUser;
        final isOwnProfile = currentUser?.uid == widget.userId;
        final friendRef = _friendRef;

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navy),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              username,
              style: const TextStyle(
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
                            username: username,
                            bio: bio,
                            title: title,
                            isOwnProfile: isOwnProfile,
                            friendRef: friendRef,
                          ),
                          const SizedBox(height: 22),
                          _levelCard(level),
                          const SizedBox(height: 14),
                          _statistics(streak, completed),
                          const SizedBox(height: 28),
                          _sectionTitle('Logros destacados'),
                          const SizedBox(height: 14),
                          _achievementsCard(),
                          const SizedBox(height: 28),
                          _mascotSupportCard(name),
                        ],
                      ),
                    ),
          ),
        );
      },
    );
  }

  String _formatUsername(String username) {
    return username.startsWith('@') ? username : '@$username';
  }

  Widget _publicProfileCard({
    required String name,
    required String username,
    required String bio,
    required String title,
    required bool isOwnProfile,
    required DocumentReference<Map<String, dynamic>>? friendRef,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 18),
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
            height: 130,
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
            child: const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'PERFIL PÚBLICO',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: mint, width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFE6F1EC),
                    child: Icon(Icons.person_rounded, size: 50, color: green),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: const TextStyle(
                    color: Color(0xFF8496A0),
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
                      color: const Color(0xFFFFF2D2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '✦ $title',
                      style: const TextStyle(
                        color: gold,
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
                    child:
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: friendRef.snapshots(),
                          builder: (context, snapshot) {
                            final isFriend = snapshot.data?.exists ?? false;

                            return SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isLoading || snapshot.hasError
                                        ? null
                                        : () => _toggleFriendship(isFriend),
                                icon:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : Icon(
                                          isFriend
                                              ? Icons.check_circle_rounded
                                              : Icons.person_add_rounded,
                                          size: 18,
                                        ),
                                label: Text(
                                  isFriend ? 'Amigos' : 'Agregar amigo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFriend ? navy : green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
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

  Widget _statistics(int streak, int completed) {
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
        const SizedBox(width: 10),
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
        color: Colors.white,
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
            style: const TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8496A0), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: navy,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _achievementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _achievement(
            Icons.water_drop_outlined,
            'Gota constante',
            const Color(0xFF62B7DD),
          ),
          _achievement(Icons.local_fire_department_outlined, 'En llamas', gold),
          _achievement(
            Icons.spa_outlined,
            'Primer brote',
            const Color(0xFF369B7B),
          ),
        ],
      ),
    );
  }

  Widget _achievement(IconData icon, String name, Color color) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            border: Border.all(color: color, width: 1.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: navy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _mascotSupportCard(String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F3E7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: green, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '¡Acompaña a $name a mantener sus hábitos saludables!',
              style: const TextStyle(
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
