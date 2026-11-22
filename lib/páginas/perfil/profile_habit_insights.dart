import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../tema/healthy_theme.dart';

/// Resumen personal calculado exclusivamente con los hábitos del usuario.
class ProfileHabitInsights {
  const ProfileHabitInsights({
    required this.favoriteTitle,
    required this.topCategory,
    required this.registeredCount,
  });

  final String? favoriteTitle;
  final String? topCategory;
  final int registeredCount;

  static ProfileHabitInsights fromDocuments(
    Iterable<Map<String, dynamic>> documents,
  ) {
    final totals = <String, int>{};
    var bestCount = 0;
    String? bestTitle;
    var allRegistrations = 0;

    for (final data in documents) {
      final raw = data['latestProgress'];
      final progress = raw is num
          ? raw.toInt().clamp(0, 1000000).toInt()
          : 0;
      if (progress <= 0) continue;
      final title = (data['title'] ?? '').toString().trim();
      final category = (data['category'] ?? '').toString().trim();
      allRegistrations += progress;
      if (category.isNotEmpty) {
        totals.update(category, (value) => value + progress,
            ifAbsent: () => progress);
      }
      if (title.isNotEmpty &&
          (progress > bestCount ||
              (progress == bestCount &&
                  (bestTitle == null || title.compareTo(bestTitle) < 0)))) {
        bestCount = progress;
        bestTitle = title;
      }
    }
    String? category;
    for (final entry in totals.entries) {
      if (category == null ||
          entry.value > totals[category]! ||
          (entry.value == totals[category]! &&
              entry.key.compareTo(category) < 0)) {
        category = entry.key;
      }
    }
    return ProfileHabitInsights(
      favoriteTitle: bestTitle,
      topCategory: category,
      registeredCount: allRegistrations,
    );
  }
}

class ProfileHabitInsightsCard extends StatelessWidget {
  const ProfileHabitInsightsCard({super.key, required this.userRef});

  final DocumentReference<Map<String, dynamic>> userRef;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: userRef.collection('user_habits').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('No se pudo consultar tu actividad de hábitos.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final summary = ProfileHabitInsights.fromDocuments(
          snapshot.data!.docs.map((doc) => doc.data()),
        );
        return Card(
          color: HealthyAdaptive.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metric(Icons.favorite_border_rounded, 'Hábito más practicado',
                    summary.favoriteTitle ?? 'Todavía sin registros'),
                const Divider(height: 22),
                _metric(Icons.category_outlined, 'Categoría más practicada',
                    summary.topCategory ?? 'Todavía sin registros'),
                const SizedBox(height: 10),
                Text(
                  'Calculado a partir del progreso del intento más reciente '
                  'de cada hábito oficial. No incluye rutinas privadas.',
                  style: TextStyle(
                    color: HealthyAdaptive.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metric(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: HealthyAdaptive.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  color: HealthyAdaptive.muted, fontSize: 12,
                )),
                Text(value, style: TextStyle(
                  color: HealthyAdaptive.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                )),
              ],
            ),
          ),
        ],
      );
}
