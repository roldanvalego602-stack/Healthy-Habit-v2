import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_reply_style.dart';

void main() {
  test('persistencia y recuperación de los tres estilos', () {
    expect(MrHealthyReplyStyler.parse(null), MrHealthyReplyStyle.natural);
    expect(MrHealthyReplyStyler.parse('desconocido'), MrHealthyReplyStyle.natural);
    for (final style in MrHealthyReplyStyle.values) {
      expect(MrHealthyReplyStyler.parse(style.name), style);
      expect(style.label, isNotEmpty);
    }
  });

  test('el modo natural conserva exactamente la respuesta', () {
    const source = 'Soy Mr. Healthy 🌱. ¿Qué quieres consultar?';
    expect(MrHealthyReplyStyler.format(source, MrHealthyReplyStyle.natural), source);
  });

  test('el modo directo elimina adornos sin borrar información', () {
    const source = '🌱 Puedo explicar un concepto. No soy médico.';
    final output = MrHealthyReplyStyler.format(source, MrHealthyReplyStyle.direct);
    expect(output, contains('Puedo explicar un concepto.'));
    expect(output, contains('No soy médico.'));
    expect(output, isNot(contains('🌱')));
  });

  test('el modo guiado conserva las frases y las organiza', () {
    const source = 'Primero revisa la idea. Después elige una acción. Finalmente comprueba el resultado.';
    final output = MrHealthyReplyStyler.format(source, MrHealthyReplyStyle.guided);
    expect(output, contains('1. Primero revisa la idea.'));
    expect(output, contains('2. Después elige una acción.'));
    expect(output, contains('3. Finalmente comprueba el resultado.'));
  });
}
