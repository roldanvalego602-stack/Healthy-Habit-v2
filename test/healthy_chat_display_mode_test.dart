import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_chat_display_mode.dart';

void main() {
  test('modo de visualización inválido vuelve a equilibrado', () {
    expect(HealthyChatDisplayModeCodec.parse(null), HealthyChatDisplayMode.balanced);
    expect(HealthyChatDisplayModeCodec.parse('unknown'), HealthyChatDisplayMode.balanced);
  });

  test('los tres modos tienen nombres persistibles y tamaños distintos', () {
    for (final mode in HealthyChatDisplayMode.values) {
      expect(HealthyChatDisplayModeCodec.parse(mode.name), mode);
      expect(mode.label, isNotEmpty);
      expect(mode.description, isNotEmpty);
    }
    expect(HealthyChatDisplayMode.compact.messageFontSize,
        lessThan(HealthyChatDisplayMode.balanced.messageFontSize));
    expect(HealthyChatDisplayMode.balanced.messageFontSize,
        lessThan(HealthyChatDisplayMode.reading.messageFontSize));
    expect(HealthyChatDisplayMode.compact.messageGap,
        lessThan(HealthyChatDisplayMode.reading.messageGap));
  });
}
