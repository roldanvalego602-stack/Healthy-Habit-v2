import 'package:flutter/material.dart';
import 'interaction_service.dart';

class ReactionPickerDialog extends StatefulWidget {
  final String fromUid;
  final String toUid;
  final String friendName;

  const ReactionPickerDialog({
    super.key,
    required this.fromUid,
    required this.toUid,
    required this.friendName,
  });

  @override
  State<ReactionPickerDialog> createState() => _ReactionPickerDialogState();
}

class _ReactionPickerDialogState extends State<ReactionPickerDialog> {
  static const _navy = Color(0xFF173544);
  static const _green = Color(0xFF198568);

  final List<String> _reactions = ['🔥', '❤️', '👏', '💪', '🎉', '⭐'];

  bool _enviando = false;
  bool _enviado = false;
  String? _emojiSeleccionado;

  Future<void> _enviarReaccion(String emoji) async {
    if (_enviando || _enviado) return; // evita doble envío

    debugPrint('👉 Enviando reacción: $emoji | De: ${widget.fromUid} | Para: ${widget.toUid}');

    setState(() {
      _enviando = true;
      _emojiSeleccionado = emoji;
    });

    try {
      await InteractionService().enviarReaccion(
        fromUid: widget.fromUid,
        toUid: widget.toUid,
        emoji: emoji,
        estado: 'enviado',
      );

      debugPrint('✅ Reacción enviada correctamente');

      if (!mounted) return;

      setState(() {
        _enviando = false;
        _enviado = true;
      });

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ ERROR al enviar reacción: $e');
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _emojiSeleccionado = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: _enviado
          ? null
          : Text(
              'Animar a ${widget.friendName}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
            ),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _enviado ? _buildConfirmacion() : _buildSelectorEmojis(),
      ),
    );
  }

  Widget _buildSelectorEmojis() {
    return Wrap(
      key: const ValueKey('selector'),
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: _reactions.map((emoji) {
        final estaEnviandoEste = _enviando && _emojiSeleccionado == emoji;
        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _enviando ? null : () => _enviarReaccion(emoji),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: estaEnviandoEste
                ? const SizedBox(
                    width: 38,
                    height: 38,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _green,
                    ),
                  )
                : Opacity(
                    opacity: _enviando ? 0.4 : 1,
                    child: Text(emoji, style: const TextStyle(fontSize: 38)),
                  ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmacion() {
    return Column(
      key: const ValueKey('confirmacion'),
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE2F4EB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _emojiSeleccionado ?? '✅',
              style: const TextStyle(fontSize: 34),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '¡Se ha enviado!',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'a ${widget.friendName}',
          style: const TextStyle(color: Color(0xFF8496A0), fontSize: 13),
        ),
      ],
    );
  }
}