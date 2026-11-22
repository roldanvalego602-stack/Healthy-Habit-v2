import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';

/// Resumen mensual basado en los registros reales, sin modificar estadísticas
/// ni recompensas. El Future se conserva mientras el widget esté montado.
class ProfileMonthlySummary extends StatefulWidget {
  const ProfileMonthlySummary({
    super.key,
    required this.userRef,
    required this.onViewProgress,
  });

  final DocumentReference<Map<String, dynamic>> userRef;
  final VoidCallback onViewProgress;

  @override
  State<ProfileMonthlySummary> createState() => _ProfileMonthlySummaryState();
}

class _MonthStats {
  const _MonthStats(this.registros, this.xp, this.diasActivos);
  final int registros;
  final int xp;
  final int diasActivos;
}

class _ProfileMonthlySummaryState extends State<ProfileMonthlySummary> {
  late Future<_MonthStats> _loading;

  @override
  void initState() {
    super.initState();
    _loading = _readMonth();
  }

  @override
  void didUpdateWidget(covariant ProfileMonthlySummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userRef.path != widget.userRef.path) {
      _loading = _readMonth();
    }
  }

  DateTime? _date(dynamic raw) {
    if (raw is Timestamp) return raw.toDate().toLocal();
    if (raw is DateTime) return raw.toLocal();
    return null;
  }

  Future<_MonthStats> _readMonth() async {
    final now = DateTime.now();
    final habits = await widget.userRef.collection('user_habits').get();
    final attempts = await Future.wait(
      habits.docs.map((habit) => habit.reference.collection('attempts').get()),
    );
    final allAttempts = attempts.expand((collection) => collection.docs).toList();
    final logs = await Future.wait(
      allAttempts.map((attempt) => attempt.reference.collection('logs').get()),
    );
    var count = 0;
    var xp = 0;
    final days = <String>{};
    for (final collection in logs) {
      for (final document in collection.docs) {
        final data = document.data();
        final date = _date(data['createdAt']);
        if (date == null || date.year != now.year || date.month != now.month) {
          continue;
        }
        count++;
        final value = data['xpEarned'];
        xp += value is num ? value.toInt() : int.tryParse('$value') ?? 0;
        days.add('${date.year}-${date.month}-${date.day}');
      }
    }
    return _MonthStats(count, xp, days.length);
  }

  void _refresh() {
    setState(() => _loading = _readMonth());
  }

  Widget _stat(String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value, style: TextStyle(
        fontSize: 21, fontWeight: FontWeight.w900,
        color: HealthyAdaptive.text,
      )),
      Text(label, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: HealthyAdaptive.muted)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.calendar_month_outlined,
            color: HealthyAdaptive.accent, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text('${months[today.month - 1]} ${today.year}',
            style: TextStyle(color: HealthyAdaptive.text,
              fontWeight: FontWeight.w900, fontSize: 16))),
          IconButton(
            tooltip: 'Actualizar resumen mensual',
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded, color: HealthyAdaptive.accent),
          ),
        ]),
        const SizedBox(height: 10),
        FutureBuilder<_MonthStats>(
          future: _loading,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'No se pudo cargar el resumen. Pulsa actualizar para reintentar.',
                style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final result = snapshot.data!;
            return Row(children: [
              Expanded(child: _stat('Registros', '${result.registros}')),
              Expanded(child: _stat('XP ganado', '${result.xp}')),
              Expanded(child: _stat('Días activos', '${result.diasActivos}')),
            ]);
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onViewProgress,
            icon: const Icon(Icons.insights_rounded),
            label: const Text('Ver calendario y estadísticas'),
          ),
        ),
      ]),
    );
  }
}
