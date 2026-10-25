import 'package:flutter/material.dart';
import 'package:healthy_habit/p%C3%A1ginas/desafios/achievement_screen.dart';

class DesafiosScreen extends StatefulWidget {
  const DesafiosScreen({super.key});

  @override
  State<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends State<DesafiosScreen> {
  String _selectedFilter = 'Todos';

  final List<String> _filters = [
    'Todos',
    'Diarios',
    'Semanales',
    'Especiales',
    'Temporada',
  ];

  @override
  Widget build(BuildContext context) {
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
          // Monedas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      (context, error, stackTrace) => const Icon(
                        Icons.monetization_on,
                        size: 18,
                        color: Colors.amber,
                      ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '120',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0E1A30),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0E1A30),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0E1A30)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Temporada Equilibrio
            const _SeasonBanner(),

            const SizedBox(height: 20),

            // Filtros de categoría
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  return ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF7A869A),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    selectedColor: const Color(0xFF0E1A30),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            isSelected
                                ? Colors.transparent
                                : Colors.grey.shade200,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 1. Desafío En Curso (Hidratación constante)
            const _ChallengeCard(
              statusTag: 'EN CURSO',
              categoryTag: 'Diario',
              timeLeft: 'Quedan 2 días',
              title: 'Hidratación constante',
              description:
                  'Completa tu hábito de agua durante 7 días seguidos.',
              currentProgress: 5,
              totalProgress: 7,
              progressPercentage: 0.71,
              xpReward: 80,
              hcReward: 25,
              difficulty: 'Baja',
              difficultyStars: 1,
              iconData: Icons.water_drop_outlined,
              iconBgColor: Color(0xFFE8F6FC),
              iconColor: Color(0xFF2B7FD1),
            ),

            const SizedBox(height: 16),

            // 2. Desafío En Curso (Frutas en la comida)
            const _ChallengeCard(
              statusTag: 'EN CURSO',
              categoryTag: 'Especial',
              timeLeft: 'Quedan 4 días',
              title: 'Incluye frutas en la comida',
              description:
                  'Añade fruta a tus meriendas durante la semana de equilibrio.',
              currentProgress: 2,
              totalProgress: 4,
              progressPercentage: 0.50,
              xpReward: 50,
              hcReward: 20,
              difficulty: 'Fácil',
              difficultyStars: 1,
              iconData: Icons.local_fire_department_outlined,
              iconBgColor: Color(0xFFFDE89D),
              iconColor: Colors.orange,
            ),

            const SizedBox(height: 16),

            // 3. Desafío Completado - Reclamar recompensa
            const _CompletedRewardCard(),

            const SizedBox(height: 16),

            // 4. Desafío Bloqueado por Nivel
            const _LockedChallengeCard(),

            const SizedBox(height: 16),

            // 5. Desafío Disponible para Aceptar
            const _AvailableChallengeCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------- Banner de Temporada ----------
class _SeasonBanner extends StatelessWidget {
  const _SeasonBanner();

  @override
  Widget build(BuildContext context) {
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
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'TEMPORADA EQUILIBRIO',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: const [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white60,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '5 días restantes',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'SEMANA 4',
            style: TextStyle(
              color: Color(0xFF00C88C),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const Text(
            '3 desafíos disponibles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mantén el ritmo y desbloquea recompensas de temporada.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Chips de Recompensas Acumuladas
          Row(
            children: [
              _buildBadgeChip(
                '+240 XP',
                const Color(0xFF00C88C).withOpacity(0.2),
                const Color(0xFF00C88C),
              ),
              const SizedBox(width: 8),
              _buildBadgeChip(
                '+125 HC',
                Colors.amber.withOpacity(0.2),
                Colors.amber,
              ),
              const SizedBox(width: 8),
              _buildBadgeChip(
                '3 Insignias',
                Colors.purple.withOpacity(0.2),
                Colors.purpleAccent,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Progreso de temporada',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '320 / 500 pts',
                style: TextStyle(
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
            child: const LinearProgressIndicator(
              value: 320 / 500,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ---------- Tarjeta de Desafío En Curso ----------
class _ChallengeCard extends StatelessWidget {
  final String statusTag;
  final String categoryTag;
  final String timeLeft;
  final String title;
  final String description;
  final int currentProgress;
  final int totalProgress;
  final double progressPercentage;
  final int xpReward;
  final int hcReward;
  final String difficulty;
  final int difficultyStars;
  final IconData iconData;
  final Color iconBgColor;
  final Color iconColor;

  const _ChallengeCard({
    required this.statusTag,
    required this.categoryTag,
    required this.timeLeft,
    required this.title,
    required this.description,
    required this.currentProgress,
    required this.totalProgress,
    required this.progressPercentage,
    required this.xpReward,
    required this.hcReward,
    required this.difficulty,
    required this.difficultyStars,
    required this.iconData,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags superirores
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusTag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B7FD1),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE89D).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  categoryTag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeLeft,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ícono y Título
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E1A30),
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

          // Progreso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentProgress / $totalProgress días',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                '${(progressPercentage * 100).toInt()}%',
                style: const TextStyle(color: Color(0xFF7A869A), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDEFF3),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2B7FD1)),
            ),
          ),
          const SizedBox(height: 14),

          // Recompensas y Dificultad
          Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Recompensa: ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
                  ),
                  _buildMiniReward(
                    '+ $xpReward XP',
                    const Color(0xFFE2F7ED),
                    const Color(0xFF00C88C),
                  ),
                  const SizedBox(width: 6),
                  _buildMiniReward(
                    '+ $hcReward HC',
                    const Color(0xFFFDE89D),
                    Colors.orange,
                  ),
                ],
              ),
              Text(
                'Dificultad: $difficulty',
                style: const TextStyle(fontSize: 11, color: Color(0xFF7A869A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMiniReward(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ---------- Tarjeta Recompensa Lista ----------
class _CompletedRewardCard extends StatelessWidget {
  const _CompletedRewardCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00C88C).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C88C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'COMPLETADO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/mascot/healthy.png',
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.emoji_events,
                        color: Color(0xFF00C88C),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '¡Racha de 7 días completada!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E1A30),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mr. Healthy anda feliz. Reclama tu recompensa.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AchievementScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C88C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Reclamar recompensa',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '+80 XP +25 HC',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
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

// ---------- Tarjeta Bloqueada ----------
class _LockedChallengeCard extends StatelessWidget {
  const _LockedChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'BLOQUEADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.purple,
                  ),
                ),
              ),
              const Text(
                'Se abre al nivel 7',
                style: TextStyle(fontSize: 11, color: Color(0xFF7A869A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Misión especial: Semana en equilibrio',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A869A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Un reto de 7 días para demostrar tu dominio del equilibrio.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ), // Corregido EdgeInsets
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Quitamos el 'const' que estaba antes de los corchetes
                const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: Color(0xFF7A869A),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Disponible en nivel 7',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A869A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Tarjeta Disponible para Aceptar ----------
class _AvailableChallengeCard extends StatelessWidget {
  const _AvailableChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'DISPONIBLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B7FD1),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(
                    'Quedan 3 días',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: Color(0xFF2B7FD1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Añade una fruta al desayuno',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E1A30),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Completa este hábito durante 5 días para desbloquear recompensas.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Ora Joto2"),
                      content: Text("data"),
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E1A30),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Aceptar desafío',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
