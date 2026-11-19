import 'package:flutter/material.dart';
import '../../tema/healthy_visual_mode.dart';

/// Botón social con efecto de presión, transición entre estados y carga.
/// La etiqueta solo cambia cuando el flujo de Firebase actualiza su estado.
class SocialActionButton extends StatefulWidget {
  const SocialActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.outlined = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool outlined;
  final bool compact;

  @override
  State<SocialActionButton> createState() => _SocialActionButtonState();
}

class _SocialActionButtonState extends State<SocialActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = !HealthyVisualEffects.enabled(context);
    final enabled = widget.onPressed != null && !widget.busy;
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final foreground = widget.outlined
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onPrimary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AnimatedScale(
        scale: _pressed && enabled && !reduceMotion ? 0.96 : 1.0,
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Material(
          color: widget.outlined ? surface : primary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? widget.onPressed : null,
            onHighlightChanged: (value) {
              if (mounted) setState(() => _pressed = value);
            },
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
              constraints: BoxConstraints(minHeight: widget.compact ? 38 : 44),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 10 : 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.outlined ? primary : Colors.transparent,
                  width: 1.3,
                ),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: widget.busy
                      ? SizedBox(
                          key: const ValueKey('busy'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                          ),
                        )
                      : Row(
                          key: ValueKey(widget.label),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, size: 16, color: foreground),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: widget.compact ? 12 : 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
