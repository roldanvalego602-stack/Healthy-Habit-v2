import 'package:flutter/material.dart';
import 'interaction_service.dart';
import '../tienda/shop_service.dart';
import '../../servicios/healthy_retro_sound_service.dart';
import '../../tema/healthy_cosmetics.dart';

class ReactionPickerDialog extends StatefulWidget {
  final String fromUid;
  final String toUid;
  final String friendName;
  final String? eventId;

  const ReactionPickerDialog({
    super.key,
    required this.fromUid,
    required this.toUid,
    required this.friendName,
    this.eventId,
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
  String? _stickerSeleccionado;

  Future<void> _enviarReaccion(String emoji, {String? stickerId}) async {
    if (_enviando || _enviado) return; // evita doble envío

    debugPrint('👉 Enviando reacción: $emoji | De: ${widget.fromUid} | Para: ${widget.toUid}');

    setState(() {
      _enviando = true;
      _emojiSeleccionado = emoji;
      _stickerSeleccionado = stickerId;
    });

    try {
      await InteractionService().enviarReaccion(
        fromUid: widget.fromUid,
        toUid: widget.toUid,
        emoji: emoji,
        challengeId: stickerId != null ? 'sticker:$stickerId' :
            widget.eventId == null ? '' : 'event:${widget.eventId}',
        estado: 'enviado',
      );

      // Reproducir solo tras confirmar la escritura en Firestore.
      await HealthyRetroSoundService.play('friend');
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
        _stickerSeleccionado = null;
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
              widget.eventId == null ? 'Animar a ${widget.friendName}' :
                  'Reaccionar a esta actividad',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
            ),
      content: SingleChildScrollView(
        child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _enviado ? _buildConfirmacion() : _buildSelectorEmojis(),
        ),
      ),
    );
  }

  Widget _buildSelectorEmojis() {
    return Column(
      key: const ValueKey('selector'),
      mainAxisSize: MainAxisSize.min,
      children: [
      Wrap(
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
    ),
    const SizedBox(height: 14),
    const Text('Stickers de tu colección',
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
    const SizedBox(height: 8),
    StreamBuilder<ShopState>(
      stream: ShopService.instance.watch(),
      builder: (context, snapshot) {
        final state = snapshot.data;
        final stickers = shopCatalog
            .where((item) => item.category == 'Reacciones' &&
                state != null && state.owns(item.id)).toList();
        if (stickers.isEmpty) {
          return const Text('Compra reacciones en la tienda para enviarlas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54));
        }
        return Wrap(
          spacing: 9, runSpacing: 9,
          alignment: WrapAlignment.center,
          children: [
            for (final item in stickers)
              InkWell(
                key: ValueKey('sticker-${item.id}'),
                onTap: _enviando ? null : () => _enviarReaccion(
                    HealthyCosmetics.reactionEmoji[item.id] ?? '👏',
                    stickerId: item.id),
                child: Tooltip(
                  message: item.name,
                  child: Image.asset(
                    HealthyCosmetics.artwork[item.id]!,
                    width: 68, height: 68, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Text(item.emoji, style: const TextStyle(fontSize: 30)),
                  ),
                ),
              ),
          ],
        );
      },
    ),
      ],
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
            child: _stickerSeleccionado != null &&
                    HealthyCosmetics.artwork.containsKey(_stickerSeleccionado)
                ? Image.asset(
                    HealthyCosmetics.artwork[_stickerSeleccionado]!,
                    width: 65, height: 65, fit: BoxFit.contain,
                  )
                : Text(_emojiSeleccionado ?? '✅',
                    style: const TextStyle(fontSize: 34)),
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