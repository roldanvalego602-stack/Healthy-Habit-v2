import 'package:flutter/material.dart';

/// Pantalla de celebración de un logro para Healthy Habit.
///
/// Es una pantalla de presentación: no añade XP ni Habit Coins por sí sola,
/// para evitar entregar recompensas duplicadas al abrirla.
class AchievementScreen extends StatelessWidget {
  const AchievementScreen({
    super.key,
    this.achievementName = 'Gota constante',
    this.milestoneLabel = '7 DÍAS · UN GRAN PASO',
    this.description = 'Completaste tu hábito de hidratación durante 7 días.',
    this.streakDays = 7,
    this.xpReward = 100,
    this.coinReward = 30,
    this.badgeIcon = Icons.water_drop_outlined,
    this.onViewAchievement,
    this.onContinue,
    this.onBack,
  });

  final String achievementName;
  final String milestoneLabel;
  final String description;
  final int streakDays;
  final int xpReward;
  final int coinReward;
  final IconData badgeIcon;
  final VoidCallback? onViewAchievement;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  static const Color _background = Color(0xFFF6F8F5);
  static const Color _navy = Color(0xFF193344);
  static const Color _muted = Color(0xFF84929A);
  static const Color _mint = Color(0xFF8FE2C4);
  static const Color _mintStrong = Color(0xFF1D8069);
  static const Color _blue = Color(0xFF438EAE);
  static const Color _bluePale = Color(0xFFE1F3FC);
  static const Color _yellow = Color(0xFFFFE9A8);

  void _showAchievementDetails(BuildContext context) {
    if (onViewAchievement != null) {
      onViewAchievement!();
      return;
    }

    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: Icon(badgeIcon, color: _blue, size: 42),
            title: Text(
              achievementName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
            ),
            content: Text(
              '$description\n\nRecompensa obtenida: +$xpReward XP y +$coinReward Habit Coins.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.5),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _mint,
                  foregroundColor: _navy,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _continue(BuildContext context) {
    if (onContinue != null) {
      onContinue!();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Logro celebrado! Conecta este botón con Inicio.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Volver',
                    onPressed:
                        onBack ??
                        () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _navy,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Tu momento',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F6EC),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  milestoneLabel.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _mintStrong,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '¡Nuevo logro!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _navy,
                  fontSize: 38,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 330,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 238,
                      height: 238,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDCE8E4),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 178,
                      height: 178,
                      decoration: const BoxDecoration(
                        color: _bluePale,
                        shape: BoxShape.circle,
                      ),
                    ),
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: _HexagonBorderPainter(color: _blue),
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(
                          child: Icon(badgeIcon, size: 78, color: _blue),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 48,
                      top: 45,
                      child: _ConfettiDot(color: Color(0xFFF28D83)),
                    ),
                    const Positioned(
                      right: 42,
                      top: 150,
                      child: _ConfettiDot(color: Color(0xFFE9BC4C)),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 2,
                      child: Image.asset(
                        'assets/mascot/healthy.png',
                        width: 126,
                        height: 142,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const SizedBox(
                              width: 126,
                              height: 142,
                              child: Center(
                                child: Text(
                                  '😊',
                                  style: TextStyle(fontSize: 78),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                achievementName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _RewardTile(
                            background: const Color(0xFF64E9B5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '+$xpReward XP',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Cada paso suma',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF267B68),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RewardTile(
                            background: _yellow,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/monedas/h coin.png',
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.monetization_on_rounded,
                                            color: Color(0xFFB58A26),
                                            size: 30,
                                          ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '+$coinReward Habit Coins',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                const Text(
                                  'Para tu colección',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF947B48),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_outlined, color: _blue, size: 25),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Insignia desbloqueada',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 66,
                child: FilledButton.icon(
                  onPressed: () => _showAchievementDetails(context),
                  icon: const Icon(Icons.workspace_premium_outlined, size: 25),
                  label: const Text(
                    'Ver logro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _mint,
                    foregroundColor: _navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton(
                  onPressed: () => _continue(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _navy,
                    side: const BorderSide(color: Color(0xFFE1E8E4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Un pequeño hábito. Una historia que sigue creciendo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  const _ConfettiDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HexagonBorderPainter extends CustomPainter {
  const _HexagonBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final points = <Offset>[
      Offset(size.width / 2, 4),
      Offset(size.width - 8, size.height * 0.25),
      Offset(size.width - 8, size.height * 0.75),
      Offset(size.width / 2, size.height - 4),
      Offset(8, size.height * 0.75),
      Offset(8, size.height * 0.25),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
