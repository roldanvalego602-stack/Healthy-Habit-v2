import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Amistades recíprocas y solicitudes de amistad.
///
/// Estructura en Firestore:
///   users/{uid}/friends/{otherUid}                -> amistad recíproca
///   users/{uid}/solicitudes/{senderUid}            -> solicitudes recibidas
///   users/{uid}/solicitudes_enviadas/{recipientUid} -> solicitudes enviadas
///
/// Aceptar una solicitud crea ambos vínculos `friends`. La versión anterior
/// utilizaba relaciones unilaterales; no deben usarse para este módulo.
class AmigosServicio {
  AmigosServicio._();

  static FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  static String? get uidActual => FirebaseAuth.instance.currentUser?.uid;

  /// Relación recíproca aceptada. Ya no existe el concepto de seguir.
  static Stream<QuerySnapshot<Map<String, dynamic>>> amigos(String uid) =>
      _db.collection('users').doc(uid).collection('friends')
          .orderBy('createdAt', descending: true).snapshots();

  /// Eliminación simétrica: ambos dejan de estar en la lista de amigos.
  static Future<void> eliminarAmigo(String otroUid) async {
    final yo = uidActual;
    if (yo == null || otroUid.isEmpty || yo == otroUid) {
      throw StateError('Se requiere una amistad y una sesión válida.');
    }
    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(yo)
        .collection('friends').doc(otroUid));
    batch.delete(_db.collection('users').doc(otroUid)
        .collection('friends').doc(yo));
    await batch.commit();
  }

  /// Cantidad en vivo de 'friends' o 'solicitudes'.
  static Stream<int> contar(String uid, String coleccion) {
    return _db
        .collection('users')
        .doc(uid)
        .collection(coleccion)
        .snapshots()
        .map((s) => s.size);
  }

  // ---------- Solicitudes de amistad ----------

  /// Solicitudes que ME han enviado y aún no respondo.
  static Stream<QuerySnapshot<Map<String, dynamic>>> solicitudesRecibidas(
    String uid,
  ) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('solicitudes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Solicitudes que YO envié y aún están pendientes de respuesta.
  static Stream<QuerySnapshot<Map<String, dynamic>>> solicitudesEnviadas(
    String uid,
  ) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('solicitudes_enviadas')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Envía una solicitud solo si todavía no son amigos y no hay otra
  /// pendiente. Evita duplicados y autoinvitaciones con una transacción.
  static Future<void> enviarSolicitud(String otroUid) async {
    final yo = uidActual;
    if (yo == null || otroUid.isEmpty || yo == otroUid) {
      throw StateError('Selecciona un usuario diferente de tu cuenta.');
    }
    final friendRef = _db.collection('users').doc(yo)
        .collection('friends').doc(otroUid);
    final sentRef = _db.collection('users').doc(yo)
        .collection('solicitudes_enviadas').doc(otroUid);
    final receivedRef = _db.collection('users').doc(yo)
        .collection('solicitudes').doc(otroUid);
    final destinationRef = _db.collection('users').doc(otroUid)
        .collection('solicitudes').doc(yo);
    await _db.runTransaction((tx) async {
      final friend = await tx.get(friendRef);
      final sent = await tx.get(sentRef);
      final received = await tx.get(receivedRef);
      if (friend.exists) {
        throw StateError('Esta persona ya es tu amiga.');
      }
      if (sent.exists) {
        throw StateError('Ya enviaste una solicitud a esta persona.');
      }
      if (received.exists) {
        throw StateError('Esta persona ya te invitó. '
            'Acepta su solicitud desde Amigos.');
      }
      tx.set(destinationRef, {
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(sentRef, {
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Cancela una solicitud que YO envié y sigue pendiente.
  static Future<void> cancelarSolicitud(String otroUid) async {
    final yo = uidActual;
    if (yo == null) return;

    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(otroUid).collection('solicitudes').doc(yo),
    );
    batch.delete(
      _db
          .collection('users')
          .doc(yo)
          .collection('solicitudes_enviadas')
          .doc(otroUid),
    );
    await batch.commit();
  }

  /// La aceptación genera amistad mutua, nunca un seguimiento unilateral.
  /// Primero se comprueba que la solicitud esté pendiente.
  static Future<void> aceptarSolicitud(String deUid) async {
    final yo = uidActual;
    if (yo == null || deUid.isEmpty || yo == deUid) {
      throw StateError('Solicitud de amistad inválida.');
    }
    final recibido = _db.collection('users').doc(yo)
        .collection('solicitudes').doc(deUid);
    final enviado = _db.collection('users').doc(deUid)
        .collection('solicitudes_enviadas').doc(yo);
    final miAmigo = _db.collection('users').doc(yo)
        .collection('friends').doc(deUid);
    final suAmigo = _db.collection('users').doc(deUid)
        .collection('friends').doc(yo);
    await _db.runTransaction((transaction) async {
      final pending = await transaction.get(recibido);
      if (!pending.exists) {
        throw StateError('La solicitud ya fue procesada o cancelada.');
      }
      transaction.set(miAmigo, {
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(suAmigo, {
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.delete(recibido);
      transaction.delete(enviado);
    });
  }

  /// Rechazo la solicitud que me envió [deUid]: solo se borra, sin crear
  /// ninguna relación de seguimiento.
  static Future<void> rechazarSolicitud(String deUid) async {
    final yo = uidActual;
    if (yo == null) return;

    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(yo).collection('solicitudes').doc(deUid),
    );
    batch.delete(
      _db
          .collection('users')
          .doc(deUid)
          .collection('solicitudes_enviadas')
          .doc(yo),
    );
    await batch.commit();
  }

  /// Trae los datos de varios usuarios (uid -> datos) en bloques de 30.
  static Future<Map<String, Map<String, dynamic>>> perfiles(
    List<String> ids,
  ) async {
    final salida = <String, Map<String, dynamic>>{};
    if (ids.isEmpty) return salida;

    for (var i = 0; i < ids.length; i += 30) {
      final bloque = ids.sublist(i, math.min(i + 30, ids.length));
      final snap =
          await _db
              .collection('public_profiles')
              .where(FieldPath.documentId, whereIn: bloque)
              .get();
      for (final doc in snap.docs) {
        salida[doc.id] = doc.data();
      }
    }
    return salida;
  }
}
