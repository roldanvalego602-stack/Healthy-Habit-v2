import 'package:flutter/material.dart';

/// Presentation-only settings: no impact on message processing or actions.
enum HealthyChatDisplayMode { compact, balanced, reading }

extension HealthyChatDisplayModePresentation on HealthyChatDisplayMode {
  String get label => switch (this) {
    HealthyChatDisplayMode.compact => 'Compacto',
    HealthyChatDisplayMode.balanced => 'Equilibrado',
    HealthyChatDisplayMode.reading => 'Lectura',
  };

  String get description => switch (this) {
    HealthyChatDisplayMode.compact => 'Más mensajes a la vista',
    HealthyChatDisplayMode.balanced => 'Espacio y claridad',
    HealthyChatDisplayMode.reading => 'Texto más grande',
  };

  IconData get icon => switch (this) {
    HealthyChatDisplayMode.compact => Icons.view_agenda_outlined,
    HealthyChatDisplayMode.balanced => Icons.chat_bubble_outline_rounded,
    HealthyChatDisplayMode.reading => Icons.text_fields_rounded,
  };

  double get messageFontSize => switch (this) {
    HealthyChatDisplayMode.compact => 12.5,
    HealthyChatDisplayMode.balanced => 13.5,
    HealthyChatDisplayMode.reading => 16.0,
  };

  double get messageLineHeight => switch (this) {
    HealthyChatDisplayMode.compact => 1.28,
    HealthyChatDisplayMode.balanced => 1.36,
    HealthyChatDisplayMode.reading => 1.52,
  };

  double get messageGap => switch (this) {
    HealthyChatDisplayMode.compact => 5,
    HealthyChatDisplayMode.balanced => 8,
    HealthyChatDisplayMode.reading => 14,
  };

  double get messageWidth => switch (this) {
    HealthyChatDisplayMode.compact => .91,
    HealthyChatDisplayMode.balanced => .85,
    HealthyChatDisplayMode.reading => .89,
  };

  double get messageHorizontalPadding => switch (this) {
    HealthyChatDisplayMode.compact => 10,
    HealthyChatDisplayMode.balanced => 12,
    HealthyChatDisplayMode.reading => 16,
  };

  double get messageVerticalPadding => switch (this) {
    HealthyChatDisplayMode.compact => 6,
    HealthyChatDisplayMode.balanced => 9,
    HealthyChatDisplayMode.reading => 14,
  };
}

class HealthyChatDisplayModeCodec {
  const HealthyChatDisplayModeCodec._();

  static const preferenceKey = 'healthy_chat_display_mode_v1';

  static HealthyChatDisplayMode parse(String? value) =>
      HealthyChatDisplayMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => HealthyChatDisplayMode.balanced,
      );
}
