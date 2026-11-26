import 'package:flutter/material.dart';

import '../../tema/healthy_coin.dart';
import '../../tema/healthy_theme.dart';

/// Vitrina 100 % ficticia para la exposición académica.
/// No conecta un procesador de pagos, no altera Firestore, inventario ni XP.
/// Las cifras en MXN son únicamente ejemplos para presentar un concepto.
class SeasonPassPreviewScreen extends StatefulWidget {
  const SeasonPassPreviewScreen({super.key});

  @override
  State<SeasonPassPreviewScreen> createState() => _SeasonPassPreviewScreenState();
}

class _SeasonPassPreviewScreenState extends State<SeasonPassPreviewScreen> {
  bool _premiumPreview = false;
  int _selectedLevel = 1;

  void _explain(String product) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$product: vista de demostración. '
            'No se realiza ningún cargo ni se entregan recompensas.'),
      ));
  }

  Widget _reward({
    required int level,
    required IconData icon,
    required String title,
    required String detail,
    required bool premium,
  }) {
    final selected = _selectedLevel == level;
    return InkWell(
      key: ValueKey('season-reward-$level-${premium ? 'premium' : 'free'}'),
      onTap: () => setState(() => _selectedLevel = level),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: premium
              ? const Color(0xFF273C36)
              : HealthyAdaptive.surface,
          border: Border.all(
            color: selected ? const Color(0xFFF6C962) :
              premium ? const Color(0xFF796741) : HealthyAdaptive.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NIVEL $level',
              style: TextStyle(
                color: premium ? const Color(0xFFFFDB87)
                    : HealthyAdaptive.muted,
                fontSize: 10, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: premium ? const Color(0xFF475D50)
                    : HealthyAdaptive.mint,
              ),
              child: title.contains('Habit Coins')
                  ? const Center(child: HealthyCoinIcon(size: 38))
                  : Icon(icon, size: 30,
                      color: premium ? const Color(0xFFF6D58E)
                          : HealthyAdaptive.accent),
            ),
            const SizedBox(height: 9),
            Text(title, maxLines: 2, textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12,
                color: premium ? Colors.white : HealthyAdaptive.text)),
            const SizedBox(height: 4),
            Text(detail, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10,
                color: premium ? Colors.white70 : HealthyAdaptive.muted)),
            if (premium) ...[
              const SizedBox(height: 5),
              const Icon(Icons.lock_outline_rounded,
                color: Color(0xFFFFDB87), size: 17),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = HealthyAdaptive.accent;
    final rewards = [
      (1, Icons.monetization_on_outlined, '50 Habit Coins',
        'Ruta gratuita', Icons.auto_awesome_rounded,
        'Aura exclusiva', 'Ruta premium'),
      (2, Icons.emoji_events_outlined, 'Emblema inicial',
        'Ruta gratuita', Icons.checkroom_rounded,
        'Sombrero estelar', 'Ruta premium'),
      (3, Icons.local_fire_department_rounded, 'Impulso visual',
        'Ruta gratuita', Icons.panorama_rounded,
        'Banner galaxia', 'Ruta premium'),
      (4, Icons.card_giftcard_outlined, 'Caja de temporada',
        'Ruta gratuita', Icons.workspace_premium_rounded,
        'Marco legendario', 'Ruta premium'),
      (5, Icons.stars_rounded, 'Medalla de constancia',
        'Ruta gratuita', Icons.auto_fix_high_rounded,
        'Aspecto especial', 'Ruta premium'),
    ];

    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(title: const Text('Temporada Healthy')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF113E35), Color(0xFF347B60)]),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TEMPORADA 01 · CONCEPTO',
                  style: TextStyle(color: Color(0xFFFFDB87),
                    letterSpacing: 1.3, fontWeight: FontWeight.w800,
                    fontSize: 11)),
                const SizedBox(height: 10),
                const Text('Cultiva tu leyenda',
                  style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 27)),
                const SizedBox(height: 7),
                const Text('Una ruta gratuita y otra premium con '
                  'recompensas cosméticas exclusivas para Mr. Healthy.',
                  style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 14),
                const LinearProgressIndicator(value: .28,
                  backgroundColor: Color(0xFF638E78),
                  color: Color(0xFFFFD77B), minHeight: 8),
                const SizedBox(height: 6),
                const Text('Progreso ilustrativo · no vinculado a tu cuenta',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Ruta gratuita'),
                icon: Icon(Icons.eco_outlined)),
              ButtonSegment(value: true, label: Text('Ruta premium'),
                icon: Icon(Icons.workspace_premium_outlined)),
            ],
            selected: {_premiumPreview},
            onSelectionChanged: (value) =>
              setState(() => _premiumPreview = value.first),
          ),
          const SizedBox(height: 15),
          Text('Recompensas por nivel',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900,
              color: HealthyAdaptive.text)),
          const SizedBox(height: 9),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rewards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (_, i) {
                final item = rewards[i];
                return _reward(level: item.$1,
                  icon: _premiumPreview ? item.$5 : item.$2,
                  title: _premiumPreview ? item.$6 : item.$3,
                  detail: _premiumPreview ? item.$7 : item.$4,
                  premium: _premiumPreview);
              },
            ),
          ),
          const SizedBox(height: 13),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: HealthyAdaptive.surface,
            ),
            padding: const EdgeInsets.all(15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pase premium · \$99 MXN (precio ficticio)',
                  style: TextStyle(fontWeight: FontWeight.w900,
                    color: HealthyAdaptive.text)),
                const SizedBox(height: 6),
                Text('Desbloquearía la ruta premium de esta temporada. '
                  'No se puede comprar ni reclamar en esta versión.',
                  style: TextStyle(color: HealthyAdaptive.muted)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const ValueKey('season-demo-premium'),
                  onPressed: () => _explain('Pase premium'),
                  icon: const Icon(Icons.lock_rounded),
                  label: const Text('Ver cómo se compraría'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          Text('Paquetes de Habit Coins',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900,
              color: HealthyAdaptive.text)),
          const SizedBox(height: 5),
          Text('Productos ficticios de monetización: '
            'ninguna opción procesa pagos ni modifica tu saldo.',
            style: TextStyle(color: HealthyAdaptive.muted)),
          const SizedBox(height: 10),
          for (final pack in [
            (100, 19), (550, 79), (1200, 149),
          ])
            Card(
              child: ListTile(
                leading: const HealthyCoinIcon(size: 39),
                title: Text('${pack.$1} Habit Coins',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Simulación académica'),
                trailing: OutlinedButton(
                  onPressed: () => _explain('${pack.$1} Habit Coins'),
                  child: Text('${pack.$2} MXN'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.info_outline_rounded, color: accent, size: 18),
            const SizedBox(width: 7),
            const Expanded(child: Text(
              'Demostración visual: sin compras integradas, '
              'sin cargo bancario y sin premios reales.',
              style: TextStyle(fontSize: 11))),
          ]),
        ],
      ),
    );
  }
}
