import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_coin.dart';
import '../../tema/healthy_visual_mode.dart';
import '../../tema/healthy_motion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'levels_system.dart';
import 'xp_journey_path.dart';
import 'healthy_level_reward_line.dart';

class CaminoNivelesScreen extends StatelessWidget {
  final int xp;

  const CaminoNivelesScreen({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    // RECOMPENSAS_NIVELES_V2
    final usuario = FirebaseAuth.instance.currentUser;
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );

    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(
        title: const Text(
          'Mi camino',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: HealthyAdaptive.background,
      ),
      body:
          usuario == null
              ? const Center(child: Text('Inicia sesión para ver tus niveles.'))
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: db.collection('users').doc(usuario.uid).snapshots(),
                builder: (context, snapshot) {
                  final datos = snapshot.data?.data() ?? <String, dynamic>{};

                  int leerNumero(dynamic valor, int defecto) {
                    if (valor is num) return valor.toInt();
                    return int.tryParse(valor?.toString() ?? '') ?? defecto;
                  }

                  final xpActual = leerNumero(
                    datos['xp'] ?? datos['currentXp'],
                    xp,
                  );
                  final current = LevelSystem.fromXp(xpActual);
                  final next = LevelSystem.nextLevel(xpActual);
                  final monedas = leerNumero(datos['habitCoins'], 0);

                  final reclamados = <int>{
                    for (final valor
                        in (datos['claimedLevelRewards'] is List
                            ? datos['claimedLevelRewards'] as List
                            : <dynamic>[]))
                      if (leerNumero(valor, 0) >= 2) leerNumero(valor, 0),
                  };

                  return ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      _summary(context, current, next, xpActual),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: HealthyAdaptive.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const HealthyCoinIcon(size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tu saldo de Habit Coins',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: HealthyAdaptive.muted,
                                    ),
                                  ),
                                  Text(
                                    '$monedas monedas',
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                      color: HealthyAdaptive.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tu camino de crecimiento',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: HealthyAdaptive.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Descubre tus próximos niveles y recompensas.',
                        style: TextStyle(color: HealthyAdaptive.muted),
                      ),
                      const SizedBox(height: 20),
                      XpJourneyPath(
                        currentLevel: current.number,
                        claimedRewards: reclamados,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Las recompensas se entregan automáticamente al '
                        'subir de nivel mediante registros de hábitos. '
                        'Los niveles alcanzados anteriormente pueden '
                        'mostrar recompensas pendientes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF71879A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _summary(BuildContext context, HealthyLevel current, HealthyLevel? next, int xpActual) {
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
                    HealthyCountUp(
                      value: xpActual,
                      suffix: ' XP acumulados',
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
            child: TweenAnimationBuilder<double>(
              key: ValueKey('xp-progress-$xpActual'),
              tween: Tween(begin: HealthyVisualEffects.enabled(context) ? 0.0
                  : LevelSystem.progress(xpActual),
                end: LevelSystem.progress(xpActual)),
              duration: HealthyVisualEffects.duration(
                context, const Duration(milliseconds: 850)),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF08B889)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            next == null
                ? '¡Has alcanzado el último nivel disponible!'
                : 'Faltan ${LevelSystem.remainingXp(xpActual)} XP '
                    'para ${next.name}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 8),
            HealthyLevelRewardLine(coins: next.rewardCoins),
          ],
        ],
      ),
    );
  }

}
