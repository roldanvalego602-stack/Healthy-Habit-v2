import 'package:flutter/material.dart';
import 'levels_system.dart';

class CaminoNivelesScreen extends StatelessWidget {
  final int xp;

  const CaminoNivelesScreen({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    final current = LevelSystem.fromXp(xp);
    final next = LevelSystem.nextLevel(xp);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text(
          'Mi camino',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFFF5F8F6),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _summary(current, next),
          const SizedBox(height: 24),
          const Text(
            'Tu camino de crecimiento',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF193344),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Descubre tus próximos niveles y recompensas.',
            style: TextStyle(color: Color(0xFF71879A)),
          ),
          const SizedBox(height: 20),
          ...LevelSystem.levels.map((level) {
            final completed = xp >= level.requiredXp;
            final isCurrent = level.number == current.number;

            return _levelNode(
              level,
              completed: completed,
              isCurrent: isCurrent,
              isLast: level.number == LevelSystem.levels.length,
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Las recompensas se muestran como vista previa. '
            'Su entrega automática se activará en una próxima etapa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF71879A), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _summary(HealthyLevel current, HealthyLevel? next) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF143834), Color(0xFF246451)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TU NIVEL ACTUAL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '${current.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
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
                      current.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$xp XP acumulados',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: LevelSystem.progress(xp),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF08B889)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            next == null
                ? '¡Has alcanzado el último nivel disponible!'
                : 'Faltan ${LevelSystem.remainingXp(xp)} XP '
                    'para ${next.name}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 8),
            Text(
              'Próxima recompensa: '
              '${next.rewardCoins} Habit Coins',
              style: const TextStyle(
                color: Color(0xFFFFE49A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _levelNode(
    HealthyLevel level, {
    required bool completed,
    required bool isCurrent,
    required bool isLast,
  }) {
    final foreground = level.dark ? Colors.white : const Color(0xFF193344);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 65,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      completed ? level.accentColor : const Color(0xFFE5EEE9),
                  border: Border.all(
                    color:
                        isCurrent
                            ? const Color(0xFF08B889)
                            : const Color(0xFFC7DAD0),
                    width: isCurrent ? 3 : 1,
                  ),
                ),
                child: Center(
                  child:
                      completed
                          ? Text(
                            '${level.number}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF173D34),
                            ),
                          )
                          : const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF78968A),
                          ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 32,
                  color:
                      completed
                          ? const Color(0xFF08B889)
                          : const Color(0xFFD0DED6),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [level.startColor, level.endColor],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent ? const Color(0xFF08B889) : Colors.transparent,
                width: 2,
              ),
              boxShadow:
                  isCurrent
                      ? [
                        BoxShadow(
                          color: const Color(0xFF08B889).withOpacity(0.15),
                          blurRadius: 12,
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                Icon(level.icon, size: 30, color: level.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NIVEL ${level.number}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: foreground.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.name,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${level.requiredXp} XP requeridos',
                        style: TextStyle(
                          color: foreground.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                      if (level.rewardCoins > 0) ...[
                        const SizedBox(height: 5),
                        Text(
                          '🪙 ${level.rewardCoins} Habit Coins',
                          style: TextStyle(
                            color:
                                level.dark
                                    ? const Color(0xFFFFE49A)
                                    : const Color(0xFF8B6B19),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      if (isCurrent) ...[
                        const SizedBox(height: 7),
                        const Text(
                          '● TU NIVEL ACTUAL',
                          style: TextStyle(
                            color: Color(0xFF08B889),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ] else if (completed) ...[
                        const SizedBox(height: 7),
                        Text(
                          '✓ DESBLOQUEADO',
                          style: TextStyle(
                            color: level.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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
