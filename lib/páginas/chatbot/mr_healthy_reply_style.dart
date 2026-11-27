import 'package:flutter/material.dart';

/// Estilos para conversaciones ordinarias, sin modificar intenciones,
/// mensajes de seguridad, datos personales o respuestas especializadas.
enum MrHealthyReplyStyle { natural, direct, guided }

extension MrHealthyReplyStyleInfo on MrHealthyReplyStyle {
  String get label => switch (this) {
    MrHealthyReplyStyle.natural => 'Natural',
    MrHealthyReplyStyle.direct => 'Directo',
    MrHealthyReplyStyle.guided => 'Paso a paso',
  };

  String get description => switch (this) {
    MrHealthyReplyStyle.natural => 'Conversación cercana',
    MrHealthyReplyStyle.direct => 'Respuestas sin rodeos',
    MrHealthyReplyStyle.guided => 'Ideas organizadas',
  };

  IconData get icon => switch (this) {
    MrHealthyReplyStyle.natural => Icons.sentiment_satisfied_alt_rounded,
    MrHealthyReplyStyle.direct => Icons.short_text_rounded,
    MrHealthyReplyStyle.guided => Icons.format_list_numbered_rounded,
  };
}

class MrHealthyReplyStyler {
  const MrHealthyReplyStyler._();

  static const preferenceKey = 'mr_healthy_reply_style_v1';

  static MrHealthyReplyStyle parse(String? raw) =>
      MrHealthyReplyStyle.values.firstWhere(
        (style) => style.name == raw,
        orElse: () => MrHealthyReplyStyle.natural,
      );

  /// Únicamente transforma respuestas de charla editorial general.
  /// No inventa consejos ni modifica mensajes generados por el motor
  /// de acciones, fichas, moderación o seguridad.
  static String format(String original, MrHealthyReplyStyle style) {
    if (style == MrHealthyReplyStyle.natural || original.trim().isEmpty) {
      return original;
    }
    if (style == MrHealthyReplyStyle.direct) {
      // Eliminar adornos, manteniendo todas las afirmaciones y advertencias.
      return original
          .replaceAll(RegExp(r'[🌱🌿🍃💪🫡😄👑]'), '')
          .replaceAll(RegExp(r' {2,}'), ' ')
          .trim();
    }

    // Mejora legibilidad sin añadir contenido ni alterar información.
    final text = original.trim();
    final fragments = text.split(RegExp(r'(?<=[.!?])\s+(?=[A-ZÁÉÍÓÚÑ¿¡])'));
    if (fragments.length < 3 || text.contains('\n')) return text;
    return fragments.asMap().entries.map((entry) =>
        '${entry.key + 1}. ${entry.value.trim()}').join('\n');
  }
}
