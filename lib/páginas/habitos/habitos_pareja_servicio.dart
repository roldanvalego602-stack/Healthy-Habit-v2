import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'habit_action_service.dart';

/// Invitaciones explícitas para realizar hábitos oficiales entre amigos.
///
/// Importante: Firestore debe autorizar a los dos participantes mediante
/// reglas del servidor. Estas comprobaciones del cliente no las reemplazan.
class HabitosParejaServicio {
  const HabitosParejaServicio();

  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default');

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Inicia sesión para compartir hábitos.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _invitations =>
      _db.collection('shared_habit_invites');

  Stream<QuerySnapshot<Map<String, dynamic>>> recibidas() =>
      _invitations.where('recipientUid', isEqualTo: _uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> enviadas() =>
      _invitations.where('senderUid', isEqualTo: _uid).snapshots();

  /// Identificador fijo para impedir varias invitaciones simultáneas
  /// entre los mismos dos usuarios y el mismo hábito.
  static String idPara(String senderUid, String recipientUid, String habitId) =>
      '${senderUid.length}_$senderUid'
      '_${recipientUid.length}_$recipientUid'
      '_$habitId';

  Future<void> invitar(String recipientUid, String habitId) async {
    final me = _uid;
    if (recipientUid.isEmpty || recipientUid == me) {
      throw ArgumentError('Selecciona un amigo válido.');
    }
    final habit = HabitActionService.findCatalogHabit(habitId);
    if (habit == null) {
      throw ArgumentError('Solo se pueden compartir hábitos del catálogo.');
    }
    final friendship = await _db.collection('users').doc(me)
        .collection('friends').doc(recipientUid).get();
    if (!friendship.exists) {
      throw StateError('Solo puedes invitar a amigos que te hayan aceptado.');
    }

    final ref = _invitations.doc(idPara(me, recipientUid, habitId));
    await _db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists &&
          (existing.data()?['status'] == 'pendiente' ||
           existing.data()?['status'] == 'aceptada')) {
        throw StateError('Ya existe una invitación o actividad compartida '
            'con este amigo para ese hábito.');
      }
      tx.set(ref, {
        'habitId': habit.id,
        'habitTitle': habit.title,
        'senderUid': me,
        'recipientUid': recipientUid,
        'status': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
      });
    });
  }

  Future<void> responder(String invitationId, {required bool aceptar}) async {
    final me = _uid;
    final ref = _invitations.doc(invitationId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final data = doc.data();
      if (data == null || data['recipientUid'] != me ||
          data['status'] != 'pendiente') {
        throw StateError('La invitación no está pendiente para tu cuenta.');
      }
      final sender = data['senderUid']?.toString() ?? '';
      final friendship = await tx.get(_db.collection('users').doc(me)
          .collection('friends').doc(sender));
      if (!friendship.exists) {
        throw StateError('Solo puedes aceptar invitaciones de tus amigos.');
      }
      tx.update(ref, {
        'status': aceptar ? 'aceptada' : 'rechazada',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cancelar(String invitationId) async {
    final me = _uid;
    final ref = _invitations.doc(invitationId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final data = doc.data();
      if (data == null || data['senderUid'] != me ||
          data['status'] != 'pendiente') {
        throw StateError('No puedes cancelar esta invitación.');
      }
      tx.update(ref, {
        'status': 'cancelada',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Activa el hábito únicamente para el usuario actual, conservando
  /// cupos, costo y reglas oficiales. No hay XP por aceptar la invitación.
  Future<void> activarHabito(String habitId) async {
    final service = const HabitActionService();
    final preview = await service.preview(habitId, remove: false);
    await service.execute(preview);
  }
}
