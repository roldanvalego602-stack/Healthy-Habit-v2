import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Seguir / dejar de seguir y listas de amigos.
///
/// Estructura en Firestore:
///   users/{miUid}/following/{otroUid}   -> a quién sigo yo
///   users/{otroUid}/followers/{miUid}   -> quién me sigue a mí
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
