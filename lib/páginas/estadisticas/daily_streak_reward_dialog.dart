import 'package:flutter/material.dart';
import '../../tema/healthy_coin.dart';

/// Selección del usuario al registrar su primera sesión válida del día.
enum StreakRewardAction { claimed, alreadyClaimed, later, showHistory }

/// El widget sólo presenta datos confirmados y llama al backend inyectado.
/// No escribe monedas ni rachas desde Flutter.
class DailyStreakRewardDialog extends StatefulWidget {
  const DailyStreakRewardDialog({
    super.key,
    required this.streak,
    required this.coins,
    required this.xp,
    required this.onClaim,
  });

  final int streak;
  final int coins;
  final int xp;
  final Future<Map<String, dynamic>> Function() onClaim;

  @override
  State<DailyStreakRewardDialog> createState() =>
      _DailyStreakRewardDialogState();
}

class _DailyStreakRewardDialogState extends State<DailyStreakRewardDialog> {
  bool _claiming = false;
  String? _error;

  Future<void> _collect() async {
    if (_claiming) return;
    setState(() {
      _claiming = true;
      _error = null;
    });
    try {
      final result = await widget.onClaim();
      if (!mounted) return;
      if (result['alreadyClaimed'] == true) {
        Navigator.of(context).pop(StreakRewardAction.alreadyClaimed);
        return;
      }
      if (result['coinsAwarded'] == widget.coins) {
        Navigator.of(context).pop(StreakRewardAction.claimed);
        return;
      }
      setState(() {
        _error = 'El servidor devolvió un premio inesperado. '
            'Consulta el historial antes de volver a intentarlo.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo confirmar el reclamo. '
            'Revisa tu racha para comprobar si el premio se acreditó.';
      });
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Color(0xFFE38B24), size: 30),
          const SizedBox(width: 8),
          Expanded(child: Text('¡Día ${widget.streak} de racha!')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 58, color: Color(0xFFE38B24)),
          const SizedBox(height: 12),
          Text('¡${widget.streak} días de constancia!',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          HealthyCoinAmount(
            amount: '+${widget.coins}',
            size: 35,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
            suffix: ' Habit Coins',
          ),
          const SizedBox(height: 8),
          Text(
            '¡Primera sesión del día registrada! '
            '+${widget.xp} XP por tu actividad. '
            'Recoge tu premio diario o consérvalo para más tarde.',
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _claiming ? null :
              () => Navigator.pop(context, StreakRewardAction.later),
          child: const Text('Más tarde'),
        ),
        TextButton(
          onPressed: _claiming ? null :
              () => Navigator.pop(context, StreakRewardAction.showHistory),
          child: const Text('Ver racha'),
        ),
        FilledButton.icon(
          key: const ValueKey('streak-collect-now'),
          onPressed: _claiming ? null : _collect,
          icon: _claiming
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.redeem_rounded),
          label: Text(_claiming ? 'Reclamando…' : 'Recoger'),
        ),
      ],
    );
  }
}
