import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Limpieza oportunista: solo se ejecuta mientras la aplicación está abierta.
class TemporaryEvidenceService {
  static const int maxImageBytes = 250 * 1024;

  static FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  static Future<int> cleanExpiredForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final collection = _db
        .collection('users')
        .doc(uid)
        .collection('temporary_habit_evidence');
    var deleted = 0;
    // Un máximo por invocación evita lecturas/escrituras descontroladas en Spark.
    // Se usa consulta sin orderBy para evitar un índice compuesto adicional.
    for (var page = 0; page < 3; page++) {
      final expired = await collection
          .where('expiresAt', isLessThanOrEqualTo: Timestamp.now())
          .limit(30)
          .get();
      if (expired.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in expired.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deleted += expired.docs.length;
      if (expired.docs.length < 30) break;
    }
    return deleted;
  }
}
