import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_motion.dart';
import '../../tema/healthy_visual_mode.dart';

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
  final String note;
  final bool hasEvidence;
  final String? evidenceId;
  final DateTime? evidenceExpiresAt;
  const _Log(
    this.date,
    this.title,
    this.xp,
    this.completed, {
    required this.note,
    required this.hasEvidence,
    this.evidenceId,
    this.evidenceExpiresAt,
  });
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  static const mint = Color(0xFF08B889);
  Color get ink => HealthyAdaptive.text;
  Color get bg => HealthyAdaptive.background;
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
          entries.add(_Log(
            date,
            (data['habitTitle'] ?? 'Hábito').toString(),
            _int(data['xpEarned']),
            data['completed'] == true,
            note: (data['note'] ?? '').toString().trim(),
            hasEvidence: data['hasEvidence'] == true,
            evidenceId: data['evidenceId']?.toString(),
            evidenceExpiresAt: _date(data['evidenceExpiresAt']),
          ));
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

  bool _evidenceAvailable(_Log log) =>
      log.hasEvidence &&
      log.evidenceId != null &&
      log.evidenceId!.isNotEmpty &&
      log.evidenceExpiresAt != null &&
      DateTime.now().toUtc().isBefore(log.evidenceExpiresAt!.toUtc());

  Future<void> _viewEvidence(_Log log) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_evidenceAvailable(log)) {
      _showMessage('La fotografía ha expirado o no está disponible.');
      return;
    }
    try {
      final doc = await db.collection('users').doc(user.uid)
          .collection('temporary_habit_evidence').doc(log.evidenceId!).get();
      if (!mounted) return;
      final data = doc.data();
      final expiry = _date(data?['expiresAt']);
      if (data == null ||
          expiry == null ||
          !DateTime.now().toUtc().isBefore(expiry.toUtc())) {
        _showMessage('La evidencia ya no está disponible.');
        return;
      }
      final encoded = data['imageBase64'];
      if (encoded is! String || encoded.isEmpty) {
        _showMessage('No se encontró la imagen de este registro.');
        return;
      }
      final bytes = base64Decode(encoded);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(log.title),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.memory(bytes, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('No se pudo abrir la imagen.')),
              if (log.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Nota: ${log.note}'),
              ],
              const SizedBox(height: 10),
              const Text('La fotografía es temporal. El registro y su nota permanecen en el historial.',
                style: TextStyle(fontSize: 12)),
            ],
          )),
          actions: [TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          )],
        ),
      );
    } catch (_) {
      _showMessage('No se pudo cargar la evidencia. Revisa tu conexión.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _logCard(_Log log) {
    final available = _evidenceAvailable(log);
    final date = log.date;
    final dateLabel = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _panel(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(log.title, style: TextStyle(
              color: ink, fontWeight: FontWeight.w800, fontSize: 14,
            ))),
            Text('+${log.xp} XP', style: const TextStyle(
              color: mint, fontWeight: FontWeight.w800,
            )),
          ]),
          const SizedBox(height: 4),
          Text(dateLabel, style: TextStyle(
            fontSize: 11, color: HealthyAdaptive.muted,
          )),
          if (log.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.notes_rounded, size: 17, color: HealthyAdaptive.muted),
              const SizedBox(width: 7),
              Expanded(child: Text(log.note, style: TextStyle(
                color: ink, fontSize: 13, height: 1.4,
              ))),
            ]),
          ],
          if (log.hasEvidence) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(available ? Icons.image_outlined : Icons.hide_image_outlined,
                size: 18, color: HealthyAdaptive.muted),
              const SizedBox(width: 7),
              Expanded(child: Text(
                available ? 'Fotografía temporal disponible' : 'Fotografía expirada o no disponible',
                style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
              )),
              if (available) TextButton(
                onPressed: () => _viewEvidence(log),
                child: const Text('Ver'),
              ),
            ]),
          ],
        ],
      )),
    );
  }

  Widget _tile(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: HealthyAdaptive.surface, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color), const SizedBox(height: 9),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ink)),
      Text(label, maxLines: 2, style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted)),
    ]),
  );

  Widget _weeklyMetric(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: HealthyAdaptive.accent, size: 16),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
        fontWeight: FontWeight.w700, color: ink, fontSize: 13)),
    ],
  );

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(top: 23, bottom: 12),
    child: Text(text, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ink)));

  Widget _panel(Widget child) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: HealthyAdaptive.surface, borderRadius: BorderRadius.circular(20)), child: child);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daily = <String, int>{};
    final byHabit = <String, int>{};
    for (final log in logs) {
      daily.update(_key(log.date), (v) => v + 1, ifAbsent: () => 1);
      byHabit.update(log.title, (v) => v + 1, ifAbsent: () => 1);
    }
    final last7 = List.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6-i)));
    final weekly = last7.fold<int>(0, (sum, day) => sum + (daily[_key(day)] ?? 0));
    final activeDays = last7.where((d) => (daily[_key(d)] ?? 0) > 0).length;
    final last7Keys = last7.map(_key).toSet();
    final weeklyXp = logs.where((log) => last7Keys.contains(_key(log.date)))
        .fold<int>(0, (sum, log) => sum + log.xp);
    final maxDaily = last7.fold<int>(1, (m, d) { final n = daily[_key(d)] ?? 0; return n > m ? n : m; });
    final sortedHabits = byHabit.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final monthLogs = logs.where((log) =>
        log.date.year == month.year && log.date.month == month.month).toList();
    final monthDays = monthLogs.map((log) => _key(log.date)).toSet().length;
    final monthXp = monthLogs.fold<int>(0, (sum, log) => sum + log.xp);
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
          Text('Cada registro cuenta. Sigue construyendo tu constancia.',
            style: TextStyle(color: HealthyAdaptive.muted)),
          const SizedBox(height: 15),
          HealthyMotionCard(
            enablePress: false,
            child: _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.insights_rounded, color: HealthyAdaptive.accent, size: 22),
                const SizedBox(width: 9),
                Expanded(child: Text('Tu avance esta semana',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink))),
              ]),
              const SizedBox(height: 12),
              Text('$activeDays de 7 días con actividad',
                style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: activeDays / 7.0),
                  duration: HealthyVisualEffects.enabled(context)
                      ? const Duration(milliseconds: 650) : Duration.zero,
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: HealthyAdaptive.border,
                    color: HealthyAdaptive.accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 14, runSpacing: 6, children: [
                _weeklyMetric(Icons.check_circle_outline_rounded, '$weekly registros'),
                _weeklyMetric(Icons.auto_awesome_rounded, '+$weeklyXp XP'),
              ]),
              const SizedBox(height: 6),
              Text('Actividad calculada a partir de tus registros guardados.',
                style: TextStyle(color: HealthyAdaptive.muted, fontSize: 11)),
            ])),
          ),
          const SizedBox(height: 12),
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
            Text('$weekly registros · $activeDays de 7 días con actividad', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 18),
            SizedBox(height: 145, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final day in last7) Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${daily[_key(day)] ?? 0}', style: TextStyle(fontSize: 11, color: ink)),
                const SizedBox(height: 5),
                TweenAnimationBuilder<double>(
                  key: ValueKey('weekly-bar-${_key(day)}-${daily[_key(day)] ?? 0}'),
                  tween: Tween<double>(begin: 0.0, end: 8.0 + 82.0 * (daily[_key(day)] ?? 0) / maxDaily),
                  duration: HealthyVisualEffects.enabled(context)
                      ? const Duration(milliseconds: 520) : Duration.zero,
                  curve: Curves.easeOutCubic,
                  builder: (context, height, _) => Container(
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: (daily[_key(day)] ?? 0) == 0
                          ? HealthyAdaptive.border : HealthyAdaptive.accent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(['L','M','X','J','V','S','D'][day.weekday-1], style: TextStyle(fontSize: 12, color: ink)),
              ])),
            ])),
            const SizedBox(height: 8),
            const Text('Las barras representan registros guardados, no porcentajes de cumplimiento.',
              style: TextStyle(fontSize: 11, color: Color(0xFF71879A))),
          ])),
          _section('Resumen del mes seleccionado'),
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${monthLogs.length} registros · $monthDays días activos · $monthXp XP',
              style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 8),
            const Text('El resumen corresponde al mes mostrado en el calendario. Los valores se calculan con registros reales.',
              style: TextStyle(fontSize: 12, color: Color(0xFF71879A))),
          ])),
          _section('Calendario de constancia'),
          _panel(Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
              Text('${['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'][month.month-1]} ${month.year}',
                style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              IconButton(onPressed: DateTime(month.year, month.month).isBefore(DateTime(today.year, today.month))
                ? () => setState(() => month = DateTime(month.year, month.month + 1)) : null,
                icon: const Icon(Icons.chevron_right)),
            ]),
            Row(children: [for (final day in ['L','M','X','J','V','S','D']) Expanded(child: Center(child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, color: ink))))]),
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
              style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (sortedHabits.isEmpty) Text(
              'Aún no hay registros. Completa una actividad para comenzar.',
              style: TextStyle(color: HealthyAdaptive.muted)),

            for (final entry in sortedHabits.take(8)) Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
              Expanded(child: Text(entry.key, maxLines: 2, overflow: TextOverflow.ellipsis)),
              Text('${entry.value} registros', style: const TextStyle(fontWeight: FontWeight.bold, color: mint)),
            ])),
          ])),
          _section('Historial de registros'),
          if (logs.isEmpty) _panel(const Text('Todavía no tienes registros para consultar.')),
          for (final log in logs.take(15)) _logCard(log),
          if (logs.length > 15) Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Se muestran los últimos 15 registros.', style: TextStyle(
              color: HealthyAdaptive.muted, fontSize: 12)),
          ),
          const SizedBox(height: 15),
          const Text('Las estadísticas se calculan a partir de los registros disponibles en Firestore. No se estiman días sin historial.',
            style: TextStyle(fontSize: 11, color: Color(0xFF71879A))),
        ])),
    );
  }
}
