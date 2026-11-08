import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Seguir / dejar de seguir, solicitudes de amistad y listas de amigos.
///
/// Estructura en Firestore:
///   users/{miUid}/following/{otroUid}          -> a quién sigo yo
///   users/{otroUid}/followers/{miUid}          -> quién me sigue a mí
///   users/{miUid}/solicitudes/{otroUid}        -> solicitudes que ME envían (recibidas)
///   users/{otroUid}/solicitudes_enviadas/{miUid} -> solicitudes que YO envié (reflejo)
///
/// Para seguir a alguien ya no se escribe "following" directamente: primero
/// se crea una solicitud, y solo cuando el destinatario la acepta se crea la
/// relación de following/followers.
/// Cada documento guarda solo { createdAt }.
class AmigosServicio {
  AmigosServicio._();

  static FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  static String? get uidActual => FirebaseAuth.instance.currentUser?.uid;

  static Stream<QuerySnapshot<Map<String, dynamic>>> siguiendo(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> seguidores(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Cantidad en vivo. [coleccion] = 'following' o 'followers'.
  static Stream<int> contar(String uid, String coleccion) {
    return _db
        .collection('users')
        .doc(uid)
        .collection(coleccion)
        .snapshots()
        .map((s) => s.size);
  }

  static Future<void> seguir(String otroUid) async {
    final yo = uidActual;
    if (yo == null || yo == otroUid) return;

    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(yo).collection('following').doc(otroUid),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db.collection('users').doc(otroUid).collection('followers').doc(yo),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
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

  /// Envía una solicitud de amistad a [otroUid]. No sigue de inmediato: el
  /// destinatario debe aceptarla desde su pantalla de Solicitudes.
  static Future<void> enviarSolicitud(String otroUid) async {
    final yo = uidActual;
    if (yo == null || yo == otroUid) return;

    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(otroUid).collection('solicitudes').doc(yo),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db
          .collection('users')
          .doc(yo)
          .collection('solicitudes_enviadas')
          .doc(otroUid),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
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

  /// Acepto la solicitud que me envió [deUid]: se crea la relación de
  /// following/followers (deUid pasa a seguirme) y se borra la solicitud.
  static Future<void> aceptarSolicitud(String deUid) async {
    final yo = uidActual;
    if (yo == null) return;

    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(deUid).collection('following').doc(yo),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db.collection('users').doc(yo).collection('followers').doc(deUid),
      {'createdAt': FieldValue.serverTimestamp()},
    );
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

  static Future<void> dejarDeSeguir(String otroUid) async {
    final yo = uidActual;
    if (yo == null) return;

    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(yo).collection('following').doc(otroUid),
    );
    batch.delete(
      _db.collection('users').doc(otroUid).collection('followers').doc(yo),
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
              .collection('users')
              .where(FieldPath.documentId, whereIn: bloque)
              .get();
      for (final doc in snap.docs) {
        salida[doc.id] = doc.data();
      }
    }
    return salida;
  }
}
