import 'package:cloud_firestore/cloud_firestore.dart';

/// Estadísticas agregadas y públicas del catálogo oficial. No lee perfiles
/// privados ni crea contadores desde el cliente.
class HabitPopularity {
  const HabitPopularity({
    required this.habitId,
    required this.activeUsers,
  });

  final String habitId;
  final int activeUsers;

  static HabitPopularity? fromMap(String id, Map<String, dynamic> data) {
    final raw = data['activeUsers'];
    if (raw is! num || raw < 1 || raw != raw.toInt()) return null;
    if (data['verified'] != true) return null;
    final count = raw.toInt();
    if (count > 1000000000) return null;
    return HabitPopularity(habitId: id, activeUsers: count);
  }
}

class HabitPopularityService {
  const HabitPopularityService();

  Future<List<HabitPopularity>> fetchVerified() async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db
        .collection('public_habit_popularity')
        .limit(100)
        .get();
    final values = <HabitPopularity>[];
    for (final doc in snapshot.docs) {
      final value = HabitPopularity.fromMap(doc.id, doc.data());
      if (value != null) values.add(value);
    }
    values.sort((a, b) {
      final count = b.activeUsers.compareTo(a.activeUsers);
      return count != 0 ? count : a.habitId.compareTo(b.habitId);
    });
    return values;
  }
}
