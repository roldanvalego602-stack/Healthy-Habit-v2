import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  // Conectarse explícitamente a la base de datos con ID "default".
  // Es diferente de FirebaseFirestore.instance, que utiliza "(default)".
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  // 1. Guardar o actualizar los datos del usuario.
  Future<void> saveUserData({
    required String uid,
    required String name,
    required String username,
    required String email,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'username': username,
        'email': email,
        'level': 1,
        'xp': 0,
        'habitCoins': 100,
        'currentStreak': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error al guardar usuario: $e');
      rethrow;
    }
  }

  // 2. Obtener los hábitos de un usuario.
  Stream<QuerySnapshot<Map<String, dynamic>>> getHabitsStream(String userId) {
    return _db.collection('users').doc(userId).collection('habits').snapshots();
  }

  // 3. Agregar un nuevo hábito.
  Future<void> addHabit(
    String userId,
    String title,
    String category,
    int targetCount,
  ) async {
    try {
      await _db.collection('users').doc(userId).collection('habits').add({
        'title': title,
        'category': category,
        'targetCount': targetCount,
        'currentCount': 0,
        'status': 'in_progress',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al agregar hábito: $e');
      rethrow;
    }
  }

  // 4. Actualizar el progreso de un hábito.
  Future<void> updateHabitProgress(
    String userId,
    String habitId,
    int newCount,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .update({'currentCount': newCount});
    } catch (e) {
      print('Error al actualizar hábito: $e');
      rethrow;
    }
  }
}
