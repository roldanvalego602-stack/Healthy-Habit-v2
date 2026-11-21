import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/habito_compartido_modelo.dart';

void main() {
  final invite = InvitacionHabitoCompartido(
    id: 'inv-1',
    habitId: 'agua',
    habitTitle: 'Tomar agua',
    senderUid: 'user-a',
    recipientUid: 'user-b',
    estado: EstadoInvitacionHabito.pendiente,
    createdAt: DateTime.utc(2026, 11, 21, 14),
  );

  test('solo el destinatario puede aceptar una invitación pendiente', () {
    expect(invite.puedeAceptar('user-b'), isTrue);
    expect(invite.puedeAceptar('user-a'), isFalse);
    expect(invite.puedeCancelar('user-a'), isTrue);
    expect(invite.puedeCancelar('user-b'), isFalse);
  });

  test('la aceptación ya procesada no se puede duplicar', () {
    final done = InvitacionHabitoCompartido.fromJson({
      ...invite.toJson(), 'status': 'aceptada',
    });
    expect(done.pendiente, isFalse);
    expect(done.puedeAceptar('user-b'), isFalse);
    expect(done.puedeCancelar('user-a'), isFalse);
  });

  test('rechaza autoinvitación y datos incompletos', () {
    expect(() => InvitacionHabitoCompartido.validar(
      habitId: 'agua', habitTitle: 'Agua',
      senderUid: 'a', recipientUid: 'a'), throwsArgumentError);
    expect(() => InvitacionHabitoCompartido.validar(
      habitId: '', habitTitle: 'Agua',
      senderUid: 'a', recipientUid: 'b'), throwsArgumentError);
  });

  test('serializa invitaciones sin añadir XP ni información privada', () {
    final data = invite.toJson();
    expect(data['senderUid'], 'user-a');
    expect(data['recipientUid'], 'user-b');
    expect(data.containsKey('xp'), isFalse);
    expect(data.containsKey('notes'), isFalse);
    expect(data.containsKey('photoUrl'), isFalse);
    final restored = InvitacionHabitoCompartido.fromJson(data);
    expect(restored.habitTitle, 'Tomar agua');
    expect(restored.estado, EstadoInvitacionHabito.pendiente);
    expect(restored.createdAt, invite.createdAt);
  });

  test('el progreso es independiente y acotado', () {
    const first = ProgresoHabitoCompartido(
      participantUid: 'a', completedSessions: 3, targetSessions: 6);
    const second = ProgresoHabitoCompartido(
      participantUid: 'b', completedSessions: 1, targetSessions: 6);
    expect(first.fraction, 0.5);
    expect(second.fraction, closeTo(1 / 6, 0.0001));
    expect(const ProgresoHabitoCompartido(
      participantUid: 'a', completedSessions: 99,
      targetSessions: 6).fraction, 1);
  });
}
