import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Estadísticas basadas en registros reales de cada intento (attempts/logs).
/// Un registro equivale a una actividad; completar un intento es distinto.
class ProgresoScreen extends StatefulWidget {
  const ProgresoScreen({super.key});
  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _Log {
  final DateTime date;
  final String title;
  final int xp;
  final bool completed;
  const _Log(this.date, this.title, this.xp, this.completed);
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  static const mint = Color(0xFF08B889);
  static const ink = Color(0xFF193344);
  static const bg = Color(0xFFF5F8F6);
  late final FirebaseFirestore db = FirebaseFirestore.instanceFor(
    app: Firebase.app(), databaseId: 'default');
  bool loading = true;
  String? error;
  Map<String, dynamic> profile = {};
  List<_Log> logs = [];
  int completedAttempts = 0;
  int attemptsCount = 0;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() { super.initState(); _load(); }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
  int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() { loading = false; error = 'Inicia sesión para ver tu progreso.'; }); return; }
    setState(() { loading = true; error = null; });
    try {
      final userRef = db.collection('users').doc(user.uid);
      final results = await Future.wait([userRef.get(), userRef.collection('user_habits').get()]);
      final userData = (results[0] as DocumentSnapshot<Map<String, dynamic>>).data() ?? {};
      final habits = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final allAttempts = await Future.wait(habits.docs.map((h) => h.reference.collection('attempts').get()));
      final attemptDocs = allAttempts.expand((a) => a.docs).toList();
      final logSets = await Future.wait(attemptDocs.map((a) => a.reference.collection('logs').get()));
      final entries = <_Log>[];
      for (var i = 0; i < attemptDocs.length; i++) {
        for (final doc in logSets[i].docs) {
          final data = doc.data();
          final date = _date(data['createdAt']);
          if (date == null) continue;
          entries.add(_Log(date, (data['habitTitle'] ?? 'Hábito').toString(),
            _int(data['xpEarned']), data['completed'] == true));
        }
      }
      entries.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        profile = userData;
        logs = entries;
        attemptsCount = attemptDocs.length;
        completedAttempts = attemptDocs.where((a) => a.data()['status'] == 'completed').length;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = 'No se pudieron consultar las estadísticas. Comprueba la conexión y los permisos de Firestore.\n$e'; });
    }
  }

  Widget _tile(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color), const SizedBox(height: 9),
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ink)),
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF71879A))),
    ]),
  );

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(top: 23, bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ink)));

  Widget _panel(Widget child) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: child);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey = _key(today);
    final daily = <String, int>{};
    final byHabit = <String, int>{};
    for (final log in logs) {
      daily.update(_key(log.date), (v) => v + 1, ifAbsent: () => 1);
      byHabit.update(log.title, (v) => v + 1, ifAbsent: () => 1);
    }
    final last7 = List.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6-i)));
    final weekly = last7.fold<int>(0, (sum, day) => sum + (daily[_key(day)] ?? 0));
    final activeDays = last7.where((d) => (daily[_key(d)] ?? 0) > 0).length;
    final maxDaily = last7.fold<int>(1, (m, d) { final n = daily[_key(d)] ?? 0; return n > m ? n : m; });
    final sortedHabits = byHabit.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = DateTime(month.year, month.month, 1).weekday - 1;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('Mi progreso', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: bg, foregroundColor: ink,
        actions: [IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh_rounded), tooltip: 'Actualizar')]),
      body: loading ? const Center(child: CircularProgressIndicator(color: mint))
        : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12), ElevatedButton(onPressed: _load, child: const Text('Reintentar'))])))
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 30), children: [
          const Text('Cada registro cuenta. Sigue construyendo tu constancia.', style: TextStyle(color: Color(0xFF71879A))),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _tile('Experiencia total', '${_int(profile['xp'])} XP', Icons.stars_rounded, mint)),
            const SizedBox(width: 10),
            Expanded(child: _tile('Nivel', '${_int(profile['level']) == 0 ? 1 : _int(profile['level'])}', Icons.emoji_events_outlined, const Color(0xFFE6A83D))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _tile('Racha actual', '${_int(profile['currentStreak'] ?? profile['streakDays'])} días', Icons.local_fire_department_rounded, const Color(0xFFE6A83D))),
            const SizedBox(width: 10),
            Expanded(child: _tile('Mejor racha', '${_int(profile['longestStreak'])} días', Icons.military_tech_outlined, mint)),
          ]),
          _section('Actividad de los últimos 7 días'),
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$weekly registros · $activeDays de 7 días con actividad', style: const TextStyle(fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 18),
            SizedBox(height: 145, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final day in last7) Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${daily[_key(day)] ?? 0}', style: const TextStyle(fontSize: 11, color: ink)),
                const SizedBox(height: 5),
                Container(height: 8 + 82 * (daily[_key(day)] ?? 0) / maxDaily,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(color: (daily[_key(day)] ?? 0) == 0 ? const Color(0xFFE6ECE9) : mint,
                    borderRadius: BorderRadius.circular(7))),
                const SizedBox(height: 6),
                Text(['L','M','X','J','V','S','D'][day.weekday-1], style: const TextStyle(fontSize: 12, color: ink)),
              ])),
            ])),
            const SizedBox(height: 8),
            const Text('Las barras representan registros guardados, no porcentajes de cumplimiento.',
              style: TextStyle(fontSize: 11, color: Color(0xFF71879A))),
          ])),
          _section('Calendario de constancia'),
          _panel(Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
              Text('${['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'][month.month-1]} ${month.year}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
              IconButton(onPressed: DateTime(month.year, month.month).isBefore(DateTime(today.year, today.month))
                ? () => setState(() => month = DateTime(month.year, month.month + 1)) : null,
                icon: const Icon(Icons.chevron_right)),
            ]),
            Row(children: [for (final day in ['L','M','X','J','V','S','D']) Expanded(child: Center(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: ink))))]),
            const SizedBox(height: 8),
            GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 5, crossAxisSpacing: 5),
              itemCount: offset + daysInMonth, itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();
                final day = index - offset + 1;
                final count = daily[_key(DateTime(month.year, month.month, day))] ?? 0;
                return Container(alignment: Alignment.center,
                  decoration: BoxDecoration(color: count > 0 ? mint : bg, borderRadius: BorderRadius.circular(10)),
                  child: Text('$day', style: TextStyle(color: count > 0 ? Colors.white : ink, fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal)));
              }),
            const SizedBox(height: 9),
            const Text('Verde = al menos un registro ese día.', style: TextStyle(fontSize: 11, color: Color(0xFF71879A))),
          ])),
          _section('Tus hábitos en números'),
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${logs.length} registros en total · $completedAttempts de $attemptsCount intentos completados',
              style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (sortedHabits.isEmpty) const Text('Aún no hay registros. Completa una actividad para comenzar.'),
            for (final entry in sortedHabits.take(8)) Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
              Expanded(child: Text(entry.key, maxLines: 2, overflow: TextOverflow.ellipsis)),
              Text('${entry.value} registros', style: const TextStyle(fontWeight: FontWeight.bold, color: mint)),
            ])),
          ])),
          const SizedBox(height: 15),
          const Text('Las estadísticas se calculan a partir de los registros disponibles en Firestore. No se estiman días sin historial.',
            style: TextStyle(fontSize: 11, color: Color(0xFF71879A))),
        ])),
    );
  }
}
