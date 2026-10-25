import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Guardar o actualizar los datos del usuario en la colección 'users'
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
      }, SetOptions(merge: true)); // Merge evita sobrescribir si ya existe
    } catch (e) {
      print('Error al guardar usuario: $e');
    }
  }

  // 2. Obtener los hábitos de un usuario desde su subcolección
  Stream<QuerySnapshot> getHabitsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('habits')
        .snapshots();
  }

  // 3. Agregar un nuevo hábito a la subcolección del usuario
  Future<void> addHabit(String userId, String title, String category, int targetCount) async {
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
    }
  }

  // 4. Actualizar el progreso de un hábito diario
  Future<void> updateHabitProgress(String userId, String habitId, int newCount) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .update({
        'currentCount': newCount,
      });
    } catch (e) {
      print('Error al actualizar hábito: $e');
    }
  }
}