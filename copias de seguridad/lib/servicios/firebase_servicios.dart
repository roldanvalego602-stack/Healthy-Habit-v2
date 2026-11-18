import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String username,
    required String email,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final existingUser = await userRef.get();

    if (!existingUser.exists) {
      await userRef.set({
        'uid': uid,
        'name': name,
        'username': username,
        'email': email,
        'level': 1,
        'xp': 0,
        'habitCoins': 100,
        'currentStreak': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userRef.set({
        'uid': uid,
        'name': name,
        'username': username,
        'email': email,
      }, SetOptions(merge: true));
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getHabitsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('user_habits')
        .snapshots();
  }

  Future<void> addHabit(
    String userId,
    String title,
    String category,
    int targetCount,
  ) async {
    await _db.collection('users').doc(userId).collection('user_habits').add({
      'title': title,
      'category': category,
      'targetCount': targetCount,
      'currentCount': 0,
      'status': 'in_progress',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHabitProgress(
    String userId,
    String habitId,
    int newCount,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('user_habits')
        .doc(habitId)
        .update({'currentCount': newCount});
  }
}
