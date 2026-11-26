import 'package:flutter/material.dart';

/// Expositor visual real: piezas, peana y medallas, en vez de emoji genérico.
/// La cantidad de medallas visibles es informativa; no concede logros.
class HealthyAchievementDisplay extends StatelessWidget {
  const HealthyAchievementDisplay({
    super.key,
    this.width = 240,
    this.height = 142,
    this.earned = 3,
  });

  final double width, height;
  final int earned;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 240,
        height: 142,
        child: Stack(alignment: Alignment.center, children: [
          Positioned(
            left: 8, right: 8, top: 12, bottom: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF194639), Color(0xFF31755E),
                    Color(0xFF194639)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4BA60), width: 3),
                boxShadow: const [BoxShadow(
                  color: Color(0x33000000), blurRadius: 9,
                  offset: Offset(0, 5))],
              ),
            ),
          ),
          Positioned(
            top: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF0E392E),
                border: Border.all(color: const Color(0xFFBCA16A))),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: const Text('MIS LOGROS',
                style: TextStyle(color: Color(0xFFFFDA88),
                    fontWeight: FontWeight.w900, fontSize: 11,
                    letterSpacing: 2)),
            ),
          ),
          Positioned(
            left: 22, right: 22, top: 92,
            child: Container(height: 11, decoration: BoxDecoration(
              color: const Color(0xFFC69D54),
              borderRadius: BorderRadius.circular(7),
              boxShadow: const [BoxShadow(
                color: Color(0x55000000), blurRadius: 4,
                offset: Offset(0, 3))],
            )),
          ),
          Positioned(
            left: 28, right: 28, top: 48,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: i < earned
                        ? const RadialGradient(colors: [
                            Color(0xFFFFE8A4), Color(0xFFC99232)])
                        : const RadialGradient(colors: [
                            Color(0xFF789A8F), Color(0xFF45665B)]),
                      border: Border.all(color: const Color(0xFFFFE6B0),
                        width: i < earned ? 2 : 1),
                    ),
                    child: Icon(
                      [Icons.star_rounded, Icons.emoji_events_rounded,
                        Icons.eco_rounded][i],
                      color: i < earned ? const Color(0xFF73511F)
                        : const Color(0xFFC8D4CE), size: 28,
                    ),
                  ),
              ],
            ),
          ),
          const Positioned(
            bottom: 10,
            child: Text('✦ CONSTANCIA ✦',
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF8D994), letterSpacing: 1.5)),
          ),
        ]),
      ),
    ),
  );
}
