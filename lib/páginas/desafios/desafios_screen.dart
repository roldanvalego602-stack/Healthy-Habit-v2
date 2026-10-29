import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:healthy_habit/p%C3%A1ginas/desafios/achievement_screen.dart';

class DesafiosScreen extends StatefulWidget {
  const DesafiosScreen({super.key});

  @override
  State<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends State<DesafiosScreen> {
  late final FirebaseFirestore _db;

  String _selectedFilter = 'Todos';
  bool _inicializando = false;
  bool _procesando = false;

  final List<String> _filters = const [
    'Todos',
    'Diarios',
    'Semanales',
    'Especiales',
    'Temporada',
  ];

  DocumentReference<Map<String, dynamic>> get _userRef {
    final user = FirebaseAuth.instance.currentUser!;
    return _db.collection('users').doc(user.uid);
  }

  CollectionReference<Map<String, dynamic>> get _challengesRef =>
      _userRef.collection('challenges');

  @override
  void initState() {
    super.initState();
    _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    _inicializarDesafios();
  }

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _inicializarDesafios() async {
    if (_inicializando || FirebaseAuth.instance.currentUser == null) return;

    _inicializando = true;

    try {
      final snapshot = await _challengesRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final defaults = [
        {
          'title': 'Hidratación constante',
          'description': 'Completa tu hábito de agua durante 7 días seguidos.',
          'category': 'Diarios',
          'status': 'inProgress',
          'currentProgress': 5,
          'totalProgress': 7,
          'xpReward': 80,
          'hcReward': 25,
          'difficulty': 'Baja',
          'difficultyStars': 1,
          'timeLeft': 'Quedan 2 días',
          'icon': 'water',
          'season': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Incluye frutas en la comida',
          'description':
              'Añade fruta a tus meriendas durante la semana de equilibrio.',
          'category': 'Especiales',
          'status': 'inProgress',
          'currentProgress': 2,
          'totalProgress': 4,
          'xpReward': 50,
          'hcReward': 20,
          'difficulty': 'Fácil',
          'difficultyStars': 1,
          'timeLeft': 'Quedan 4 días',
          'icon': 'fruit',
          'season': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Racha de 7 días',
          'description': 'Mantén tus hábitos durante siete días.',
          'category': 'Semanales',
          'status': 'completed',
          'currentProgress': 7,
          'totalProgress': 7,
          'xpReward': 80,
          'hcReward': 25,
          'difficulty': 'Media',
          'difficultyStars': 2,
          'timeLeft': 'Completado',
          'icon': 'trophy',
          'season': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Semana en equilibrio',
          'description': 'Completa una misión especial de siete días.',
          'category': 'Especiales',
          'status': 'locked',
          'currentProgress': 0,
          'totalProgress': 7,
          'xpReward': 150,
          'hcReward': 50,
          'difficulty': 'Alta',
          'difficultyStars': 3,
          'timeLeft': 'Requiere nivel 7',
          'requiredLevel': 7,
          'icon': 'lock',
          'season': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Añade una fruta al desayuno',
          'description': 'Completa este hábito durante cinco días.',
          'category': 'Diarios',
          'status': 'available',
          'currentProgress': 0,
          'totalProgress': 5,
          'xpReward': 40,
          'hcReward': 10,
          'difficulty': 'Fácil',
          'difficultyStars': 1,
          'timeLeft': 'Disponible',
          'icon': 'fruit',
          'season': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _db.batch();

      for (final challenge in defaults) {
        final ref = _challengesRef.doc();
        batch.set(ref, challenge);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error inicializando desafíos: $e');
    } finally {
      _inicializando = false;
    }
  }

  Future<void> _aceptarDesafio(String id, Map<String, dynamic> data) async {
    if (_procesando) return;

    setState(() => _procesando = true);

    try {
      final ref = _challengesRef.doc(id);
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        throw Exception('El desafío ya no existe.');
      }

      final challenge = snapshot.data()!;
      if (challenge['status'] != 'available') {
        throw Exception('Este desafío ya no está disponible.');
      }

      await ref.update({
        'status': 'inProgress',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      _mensaje('Desafío aceptado: ${data['title']}');
    } catch (e) {
      _mensaje('No se pudo aceptar el desafío: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _reclamarRecompensa(String id, Map<String, dynamic> data) async {
    if (_procesando) return;

    setState(() => _procesando = true);

    try {
      final challengeRef = _challengesRef.doc(id);
      final userRef = _userRef;

      await _db.runTransaction((transaction) async {
        final challengeSnapshot = await transaction.get(challengeRef);
        final userSnapshot = await transaction.get(userRef);

        if (!challengeSnapshot.exists) {
          throw Exception('El desafío no existe.');
        }

        final challenge = challengeSnapshot.data()!;
        final status = challenge['status']?.toString() ?? '';

        if (status != 'completed') {
          throw Exception('Debes completar el desafío antes de reclamar.');
        }

        final current = _toInt(challenge['currentProgress']);
        final total = _toInt(challenge['totalProgress'], 1);

        if (current < total) {
          throw Exception('El progreso del desafío aún no está completo.');
        }

        final userData = userSnapshot.data() ?? <String, dynamic>{};
        final xp = _toInt(userData['xp']);
        final coins = _toInt(userData['habitCoins']);

        final xpReward = _toInt(challenge['xpReward']);
        final hcReward = _toInt(challenge['hcReward']);

        transaction.set(userRef, {
          'xp': xp + xpReward,
          'habitCoins': coins + hcReward,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.update(challengeRef, {
          'status': 'claimed',
          'claimedAt': FieldValue.serverTimestamp(),
        });
      });

      _mensaje('¡Recompensa reclamada!');
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AchievementScreen()),
      );
    } catch (e) {
      _mensaje('No se pudo reclamar la recompensa: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  bool _coincideFiltro(Map<String, dynamic> data) {
    if (_selectedFilter == 'Todos') return true;

    final category = data['category']?.toString() ?? '';
    final season = data['season'] == true;

    if (_selectedFilter == 'Temporada') return season;

    return category.toLowerCase() == _selectedFilter.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver tus desafíos.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Desafíos',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0E1A30),
          ),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _userRef.snapshots(),
            builder: (context, snapshot) {
              final coins = _toInt(snapshot.data?.data()?['habitCoins']);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE89D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/monedas/h coin.png',
                      width: 20,
                      height: 20,
                      errorBuilder:
                          (_, __, ___) => const Icon(
                            Icons.monetization_on,
                            size: 18,
                            color: Colors.amber,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF0E1A30),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0E1A30),
            ),
            onPressed: () => _mensaje('No tienes notificaciones nuevas.'),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0E1A30)),
            onPressed: () => _mostrarFiltros(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _challengesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los desafíos.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final challenges =
              docs.where((doc) => _coincideFiltro(doc.data())).toList();

          final totalSeasonXP = docs
              .where((doc) => doc.data()['season'] == true)
              .fold<int>(0, (sum, doc) => sum + _toInt(doc.data()['xpReward']));

          final seasonCompleted =
              docs
                  .where(
                    (doc) =>
                        doc.data()['season'] == true &&
                        (doc.data()['status'] == 'completed' ||
                            doc.data()['status'] == 'claimed'),
                  )
                  .length;

          return RefreshIndicator(
            onRefresh: _inicializarDesafios,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                _SeasonBanner(
                  totalXP: totalSeasonXP,
                  completed: seasonCompleted,
                  total:
                      docs.where((doc) => doc.data()['season'] == true).length,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = filter == _selectedFilter;

                      return ChoiceChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            color:
                                selected
                                    ? Colors.white
                                    : const Color(0xFF7A869A),
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        selected: selected,
                        onSelected: (value) {
                          if (value) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                        selectedColor: const Color(0xFF0E1A30),
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (challenges.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No hay desafíos en esta categoría.'),
                    ),
                  ),
                for (final doc in challenges) ...[
                  _ChallengeCard(
                    data: doc.data(),
                    processing: _procesando,
                    onAccept: () => _aceptarDesafio(doc.id, doc.data()),
                    onClaim: () => _reclamarRecompensa(doc.id, doc.data()),
                    onDetails: () => _mostrarDetalles(doc.data()),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarDetalles(Map<String, dynamic> data) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(data['title']?.toString() ?? 'Desafío'),
            content: Text(
              '${data['description'] ?? ''}\n\n'
              'Recompensa: ${data['xpReward'] ?? 0} XP y '
              '${data['hcReward'] ?? 0} HC.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet<void>(
      context: context,
      builder:
          (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(title: Text('Filtrar desafíos')),
                for (final filter in _filters)
                  RadioListTile<String>(
                    title: Text(filter),
                    value: filter,
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFilter = value);
                        Navigator.pop(context);
                      }
                    },
                  ),
              ],
            ),
          ),
    );
  }
}

class _SeasonBanner extends StatelessWidget {
  final int totalXP;
  final int completed;
  final int total;

  const _SeasonBanner({
    required this.totalXP,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2D38), Color(0xFF1E424D)],
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
              const Icon(
                Icons.star_outline_rounded,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'TEMPORADA EQUILIBRIO',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '$completed / $total completados',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Desafíos de temporada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Completa desafíos para conseguir recompensas.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _badge('Hasta $totalXP XP', const Color(0xFF00C88C)),
              _badge('$completed completados', Colors.amber),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso de temporada',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onClaim;
  final VoidCallback onDetails;

  const _ChallengeCard({
    required this.data,
    required this.processing,
    required this.onAccept,
    required this.onClaim,
    required this.onDetails,
  });

  int _intValue(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Desafío';
    final description = data['description']?.toString() ?? '';
    final category = data['category']?.toString() ?? 'Diarios';
    final status = data['status']?.toString() ?? 'available';
    final current = _intValue(data['currentProgress']);
    final total = _intValue(data['totalProgress'], 1).clamp(1, 999999);
    final xp = _intValue(data['xpReward']);
    final hc = _intValue(data['hcReward']);
    final progress = (current / total).clamp(0.0, 1.0).toDouble();

    final isLocked = status == 'locked';
    final isCompleted = status == 'completed';
    final isClaimed = status == 'claimed';
    final isAvailable = status == 'available';

    final icon = switch (data['icon']?.toString()) {
      'water' => Icons.water_drop_outlined,
      'fruit' => Icons.local_fire_department_outlined,
      'trophy' => Icons.emoji_events_outlined,
      'lock' => Icons.lock_outline_rounded,
      _ => Icons.flag_outlined,
    };

    final statusText = switch (status) {
      'inProgress' => 'EN CURSO',
      'completed' => 'COMPLETADO',
      'claimed' => 'RECOMPENSA RECLAMADA',
      'locked' => 'BLOQUEADO',
      _ => 'DISPONIBLE',
    };

    final statusColor = switch (status) {
      'completed' || 'claimed' => const Color(0xFF00A875),
      'locked' => Colors.purple,
      'available' => const Color(0xFF2B7FD1),
      _ => const Color(0xFF2B7FD1),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFFCFCFC) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isCompleted
                  ? const Color(0xFF00C88C).withOpacity(0.35)
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE89D).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.schedule_rounded, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  data['timeLeft']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isLocked
                          ? Colors.purple.shade50
                          : const Color(0xFFE8F6FC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isLocked ? Colors.purple : const Color(0xFF2B7FD1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color:
                            isLocked
                                ? const Color(0xFF7A869A)
                                : const Color(0xFF0E1A30),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A869A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current / $total',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(color: Color(0xFF7A869A), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDEFF3),
              valueColor: AlwaysStoppedAnimation(
                isCompleted || isClaimed
                    ? const Color(0xFF00C88C)
                    : const Color(0xFF2B7FD1),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              const Text(
                'Recompensa:',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
              ),
              _reward(
                '+$xp XP',
                const Color(0xFFE2F7ED),
                const Color(0xFF00A875),
              ),
              _reward('+$hc HC', const Color(0xFFFDE89D), Colors.orange),
              Text(
                'Dificultad: ${data['difficulty'] ?? 'Normal'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF7A869A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isAvailable)
            _actionButton(
              label: 'Aceptar desafío',
              icon: Icons.play_arrow_rounded,
              onPressed: processing ? null : onAccept,
              background: const Color(0xFF0E1A30),
            )
          else if (isCompleted)
            _actionButton(
              label: 'Reclamar recompensa',
              icon: Icons.card_giftcard_rounded,
              onPressed: processing ? null : onClaim,
              background: const Color(0xFF00A875),
            )
          else if (isClaimed)
            const Center(
              child: Text(
                'Recompensa obtenida',
                style: TextStyle(
                  color: Color(0xFF00A875),
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else if (isLocked)
            _actionButton(
              label: 'Ver detalles',
              icon: Icons.info_outline,
              onPressed: onDetails,
              background: const Color(0xFF7A869A),
            )
          else
            _actionButton(
              label: 'Ver detalles',
              icon: Icons.info_outline,
              onPressed: onDetails,
              background: const Color(0xFF0E1A30),
            ),
        ],
      ),
    );
  }

  Widget _reward(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color background,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          disabledBackgroundColor: background.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
