import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../tema/healthy_visual_mode.dart';
import 'levels_system.dart';

/// La línea se revela desde el primer nivel hasta el nivel realmente alcanzado.
/// No modifica XP, recompensas ni documentos de Firebase.
class XpJourneyPath extends StatefulWidget {
  const XpJourneyPath({
    super.key,
    required this.currentLevel,
    required this.claimedRewards,
  });

  final int currentLevel;
  final Set<int> claimedRewards;

  @override
  State<XpJourneyPath> createState() => _XpJourneyPathState();
}

class _XpJourneyPathState extends State<XpJourneyPath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  bool _started = false;

  int get _lastReached => widget.currentLevel.clamp(
        1, LevelSystem.levels.length);

  Duration get _travelDuration => Duration(
        milliseconds: math.min(4600, 640 + (LevelSystem.levels.length - 1) * 170),
      );

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: _travelDuration,
      value: 1,
    );
    HealthyVisualController.instance.addListener(_onModeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _synchronizeAnimation();
  }

  @override
  void didUpdateWidget(covariant XpJourneyPath oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLevel != widget.currentLevel) {
      _reveal.duration = _travelDuration;
      _started = false;
      _synchronizeAnimation();
    }
  }

  void _onModeChanged() {
    if (!mounted) return;
    _synchronizeAnimation();
    setState(() {});
  }

  void _synchronizeAnimation() {
    final animate = HealthyVisualEffects.enabled(context) &&
        TickerMode.of(context);
    if (!animate) {
      _reveal.stop();
      _reveal.value = 1;
      return;
    }
    if (!_started) {
      _started = true;
      _reveal.forward(from: 0);
    }
  }

  @override
  void dispose() {
    HealthyVisualController.instance.removeListener(_onModeChanged);
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        // El trazo recorre todas las paradas: enciende las alcanzadas y
        // oscurece progresivamente las que todavía están bloqueadas.
        final position = (LevelSystem.levels.length - 1) * _reveal.value;
        final motion = HealthyVisualEffects.enabled(context);
        return Column(
          key: const Key('xp-journey-path'),
          children: [
            for (var i = 0; i < LevelSystem.levels.length; i++)
              _XpJourneyStop(
                key: ValueKey('xp-journey-node-${i + 1}'),
                level: LevelSystem.levels[i],
                index: i,
                position: position,
                unlocked: i < _lastReached,
                current: i == _lastReached - 1,
                first: i == 0,
                last: i == LevelSystem.levels.length - 1,
                rewardClaimed: widget.claimedRewards.contains(i + 1),
                motion: motion,
              ),
          ],
        );
      },
    );
  }
}

/// División superior/inferior de cada conexión para que el trazo se dibuje
/// de arriba hacia abajo y llegue a cada parada antes de iluminarla.
@visibleForTesting
class XpJourneyTrackPainter extends CustomPainter {
  const XpJourneyTrackPainter({
    required this.upper,
    required this.lower,
    required this.upperAsh,
    required this.lowerAsh,
    required this.first,
    required this.last,
    required this.litColor,
    required this.unlitColor,
  });

  final double upper;
  final double lower;
  final double upperAsh;
  final double lowerAsh;
  final bool first;
  final bool last;
  final Color litColor;
  final Color unlitColor;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    const centerY = 28.0;
    final base = Paint()
      ..color = unlitColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final bright = Paint()
      ..color = litColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final ash = Paint()
      ..color = const Color(0xFF24353E)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    if (!first) {
      canvas.drawLine(Offset(x, 0), Offset(x, centerY), base);
      if (upper > 0 || upperAsh > 0) {
        final amount = math.max(upper, upperAsh);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, centerY * amount.clamp(0.0, 1.0)),
          upperAsh > 0 ? ash : bright,
        );
      }
    }
    if (!last && size.height > centerY) {
      canvas.drawLine(
        Offset(x, centerY), Offset(x, size.height), base,
      );
      if (lower > 0 || lowerAsh > 0) {
        final amount = math.max(lower, lowerAsh);
        canvas.drawLine(
          Offset(x, centerY),
          Offset(x, centerY + (size.height - centerY) *
              amount.clamp(0.0, 1.0)),
          lowerAsh > 0 ? ash : bright,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant XpJourneyTrackPainter oldDelegate) =>
      upper != oldDelegate.upper ||
      lower != oldDelegate.lower ||
      upperAsh != oldDelegate.upperAsh ||
      lowerAsh != oldDelegate.lowerAsh ||
      first != oldDelegate.first ||
      last != oldDelegate.last ||
      litColor != oldDelegate.litColor ||
      unlitColor != oldDelegate.unlitColor;
}

class _XpJourneyStop extends StatelessWidget {
  const _XpJourneyStop({
    super.key,
    required this.level,
    required this.index,
    required this.position,
    required this.unlocked,
    required this.current,
    required this.first,
    required this.last,
    required this.rewardClaimed,
    required this.motion,
  });

  final HealthyLevel level;
  final int index;
  final double position;
  final bool unlocked;
  final bool current;
  final bool first;
  final bool last;
  final bool rewardClaimed;
  final bool motion;

  @override
  Widget build(BuildContext context) {
    // El nivel 1 está iluminado desde el inicio; los siguientes se activan
    // cuando la línea los alcanza, no al cargar los datos del usuario.
    final reveal = unlocked
        ? ((position - index + 0.16) / 0.16).clamp(0.0, 1.0)
        : 0.0;
    // Las etapas futuras se oscurecen cuando la línea llega a ellas.
    final fused = unlocked
        ? 0.0
        : ((position - index + 0.16) / 0.27).clamp(0.0, 1.0);
    final activated = unlocked && reveal >= 0.999;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const unlitStart = Color(0xFF26343E);
    const unlitEnd = Color(0xFF192630);
    const unlitInk = Color(0xFFB3BEC6);
    const waitingStart = Color(0xFF425966);
    const waitingEnd = Color(0xFF344954);
    const lineBright = Color(0xFF30D8A2);
    final reachedColor = level.accentColor;

    final liveStart = dark && !level.dark
        ? const Color(0xFF24483D)
        : level.startColor;
    final liveEnd = dark && !level.dark
        ? const Color(0xFF18372F)
        : level.endColor;
    final fgLive = dark || level.dark
        ? const Color(0xFFF2F7F6)
        : const Color(0xFF17392F);
    final fg = unlocked
        ? Color.lerp(unlitInk, fgLive, reveal)!
        : Color.lerp(const Color(0xFFE5EDF1), unlitInk, fused)!;
    final muted = unlocked
        ? Color.lerp(
            const Color(0xFF91A0A9),
            fgLive.withValues(alpha: 0.78),
            reveal,
          )!
        : Color.lerp(
            const Color(0xFFCEDAE0),
            const Color(0xFF91A0A9),
            fused,
          )!;
    final accent = Color.lerp(
      const Color(0xFF71838E), reachedColor, reveal,
    )!;

    final upperFraction = first
        ? 0.0
        : ((position - (index - 1)) * 2).clamp(0.0, 1.0);
    final lowerFraction = last
        ? 0.0
        : ((position - index) * 2).clamp(0.0, 1.0);
    // Los segmentos antes y hasta el nivel actual son luminosos;
    // después de él, la misma onda deja una estela oscura.
    final upperFill = unlocked ? upperFraction : 0.0;
    final lowerFill = unlocked && !current ? lowerFraction : 0.0;
    final upperAsh = unlocked ? 0.0 : upperFraction;
    final lowerAsh = unlocked && !current ? 0.0 : lowerFraction;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 64,
            child: CustomPaint(
              painter: XpJourneyTrackPainter(
                upper: upperFill,
                lower: lowerFill,
                upperAsh: upperAsh,
                lowerAsh: lowerAsh,
                first: first,
                last: last,
                litColor: lineBright,
                unlitColor: dark
                    ? const Color(0xFF41515D)
                    : const Color(0xFF8D9BA4),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      unlocked
                          ? const Color(0xFF293943)
                          : Color.lerp(waitingStart, unlitStart, fused)!,
                      current ? const Color(0xFF20AD80) : reachedColor,
                      reveal,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: current && activated ? 3 : 2,
                      color: current && activated
                          ? const Color(0xFFA8FFE2)
                          : Color.lerp(
                              const Color(0xFF667683),
                              const Color(0xFFB0F4D9),
                              reveal,
                            )!,
                    ),
                    boxShadow: current && activated && motion
                        ? [BoxShadow(
                            color: lineBright.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          )]
                        : null,
                  ),
                  child: Center(
                    child: activated
                        ? Text('${level.number}',
                            style: const TextStyle(
                              color: Color(0xFF102F2A),
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ))
                        : Icon(Icons.lock_outline_rounded,
                            color: activated
                                ? Colors.white
                                : const Color(0xFFC3CED3),
                            size: 22),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RepaintBoundary(
                child: Container(
                  key: ValueKey('xp-path-card-${level.number}'),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      unlocked
                          ? Color.lerp(unlitStart, liveStart, reveal)!
                          : Color.lerp(waitingStart, unlitStart, fused)!,
                      unlocked
                          ? Color.lerp(unlitEnd, liveEnd, reveal)!
                          : Color.lerp(waitingEnd, unlitEnd, fused)!,
                    ]),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: current && activated
                          ? const Color(0xFF5EE5B5)
                          : Color.lerp(
                              const Color(0xFF52616B),
                              reachedColor.withValues(alpha: 0.65),
                              reveal,
                            )!,
                      width: current && activated ? 2 : 1,
                    ),
                    boxShadow: current && activated && motion
                        ? [BoxShadow(
                            color: lineBright.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 3),
                          )]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(level.icon, size: 29, color: accent),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('NIVEL ${level.number}',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                )),
                            const SizedBox(height: 4),
                            Text(level.name,
                                style: TextStyle(
                                  color: fg,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                )),
                            const SizedBox(height: 6),
                            Text('${level.requiredXp} XP requeridos',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                )),
                            if (level.rewardCoins > 0) ...[
                              const SizedBox(height: 5),
                              Text('🪙 ${level.rewardCoins} Habit Coins',
                                  style: TextStyle(
                                    color: activated
                                        ? (dark || level.dark
                                            ? const Color(0xFFFFE19A)
                                            : const Color(0xFF806019))
                                        : const Color(0xFFA0AEB6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  )),
                              const SizedBox(height: 5),
                              Text(
                                rewardClaimed
                                    ? '✓ RECOMPENSA ENTREGADA'
                                    : unlocked
                                        ? '◷ RECOMPENSA PENDIENTE'
                                        : 'RECOMPENSA BLOQUEADA',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            if (current) ...[
                              const SizedBox(height: 5),
                              Text('● TU NIVEL ACTUAL',
                                  style: TextStyle(
                                    color: activated
                                        ? const Color(0xFF31DDAC)
                                        : muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  )),
                            ] else if (unlocked) ...[
                              const SizedBox(height: 5),
                              Text('✓ DESBLOQUEADO',
                                  style: TextStyle(
                                    color: activated ? accent : muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
