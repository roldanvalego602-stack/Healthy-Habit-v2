import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String username;
  final String? photoUrl;
  final int level;
  final int currentXp;
  final int nextLevelXp;
  final int streakDays;
  final int coins;
  final String? activeChallengeTitle;
  final String nextAchievementTitle;
  final double nextAchievementProgress; // Valor de 0.0 a 1.0

  UserModel({
    required this.uid,
    required this.name,
    required this.username,
    this.photoUrl,
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    required this.streakDays,
    required this.coins,
    this.activeChallengeTitle,
    required this.nextAchievementTitle,
    required this.nextAchievementProgress,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? 'Usuario',
      username: data['username'] ?? '@usuario',
      photoUrl: data['photoUrl'],
      level: data['level'] ?? 1,
      currentXp: data['currentXp'] ?? 0,
      nextLevelXp: data['nextLevelXp'] ?? 100,
      streakDays: data['streakDays'] ?? 0,
      coins: data['coins'] ?? 0,
      activeChallengeTitle: data['activeChallengeTitle'],
      nextAchievementTitle: data['nextAchievementTitle'] ?? 'Primer Brote',
      nextAchievementProgress: (data['nextAchievementProgress'] ?? 0.0).toDouble(),
    );
  }
}