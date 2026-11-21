import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/politica_habitos_pareja.dart';

void main() {
  final accepted = <String, dynamic>{
    'senderUid': 'user-a',
    'recipientUid': 'user-b',
    'habitId': 'habit-agua',
    'status': 'aceptada',
  };

  test('cada participante puede activar únicamente el hábito invitado', () {
    expect(PoliticaHabitosPareja.puedeActivar(
      invitacion: accepted, uid: 'user-a', habitId: 'habit-agua'), isTrue);
    expect(PoliticaHabitosPareja.puedeActivar(
      invitacion: accepted, uid: 'user-b', habitId: 'habit-agua'), isTrue);
    expect(PoliticaHabitosPareja.puedeActivar(
      invitacion: accepted, uid: 'user-c', habitId: 'habit-agua'), isFalse);
    expect(PoliticaHabitosPareja.puedeActivar(
      invitacion: accepted, uid: 'user-a', habitId: 'otro-habito'), isFalse);
  });

  test('pendientes, rechazadas y finalizadas no activan hábitos', () {
    for (final status in [
      'pendiente', 'rechazada', 'cancelada', 'finalizada',
    ]) {
      expect(PoliticaHabitosPareja.puedeActivar(
        invitacion: {...accepted, 'status': status},
        uid: 'user-a', habitId: 'habit-agua'), isFalse,
        reason: 'Estado $status');
    }
  });

  test('sólo participantes pueden terminar una asociación aceptada', () {
    expect(PoliticaHabitosPareja.puedeTerminar(
      invitacion: accepted, uid: 'user-a'), isTrue);
    expect(PoliticaHabitosPareja.puedeTerminar(
      invitacion: accepted, uid: 'user-c'), isFalse);
    expect(PoliticaHabitosPareja.puedeTerminar(
      invitacion: {...accepted, 'status': 'finalizada'},
      uid: 'user-a'), isFalse);
  });

  test('identifica al otro participante sin permitir autorrelaciones', () {
    expect(PoliticaHabitosPareja.otroParticipante(
      invitacion: accepted, uid: 'user-a'), 'user-b');
    expect(PoliticaHabitosPareja.otroParticipante(
      invitacion: accepted, uid: 'user-b'), 'user-a');
    expect(PoliticaHabitosPareja.otroParticipante(
      invitacion: accepted, uid: 'user-c'), isNull);
    expect(PoliticaHabitosPareja.otroParticipante(
      invitacion: {...accepted, 'recipientUid': 'user-a'},
      uid: 'user-a'), isNull);
  });
}
