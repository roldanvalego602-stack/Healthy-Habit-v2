import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'logros_service.dart';
import 'logro_insignia.dart';
import 'logros_vitrina.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_visual_mode.dart';

class LogrosScreen extends StatelessWidget {
  const LogrosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión para consultar tus logros.')));
    }
    final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
    final ref = db.collection('users').doc(user.uid);
    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        backgroundColor: _Palette.bg,
        foregroundColor: _Palette.white,
        title: Text('Logros', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, profile) {
          if (profile.hasError) return const _Status('No se pudo cargar tu perfil.');
          if (!profile.hasData) return const Center(child: CircularProgressIndicator());
          final data = profile.data!.data() ?? <String, dynamic>{};
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ref.collection('user_habits').snapshots(),
            builder: (context, habits) {
              if (habits.hasError) return const _Status('No se pudieron cargar los hábitos.');
              if (!habits.hasData) return const Center(child: CircularProgressIndicator());
              final docs = habits.data!.docs;
              final completed = docs.where((d) => d.data()['latestStatus'] == 'completed').length;
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: ref.collection('achievements').snapshots(),
                builder: (context, achievements) {
                  if (achievements.hasError) return const _Status('No se pudieron cargar las medallas.');
                  if (!achievements.hasData) return const Center(child: CircularProgressIndicator());
                  final ids = achievements.data!.docs.map((d) => d.id).toSet();
                  return LogrosColeccion(items: [
                    for (final def in LogrosService.catalogo)
                      LogroVista(
                        definicion: def,
                        progreso: LogrosService.progreso(def, data, docs.length, completed, ids),
                      ),
                  ]);
                },
              );
            },
          );
        },
      ),
    );
  }
}
class _Status extends StatelessWidget {
  const _Status(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
  );
}
class _Palette {
  static bool get dark {
    final selected = HealthyThemeController.instance.mode;
    if (selected == ThemeMode.dark) return true;
    if (selected == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  static Color get bg => dark ? const Color(0xFF101923) : const Color(0xFFF4F8F7);
  static Color get panel => dark ? const Color(0xFF1B2935) : Colors.white;
  static Color get border => dark ? const Color(0xFF344553) : const Color(0xFFD5E2E0);
  static Color get green => dark ? const Color(0xFF6CD3A1) : const Color(0xFF087D61);
  static Color get white => dark ? const Color(0xFFF1F5F6) : const Color(0xFF183341);
  static Color get secondary => dark ? const Color(0xFFAFBBC4) : const Color(0xFF50636C);
  static Color get gold => dark ? const Color(0xFFEBC77A) : const Color(0xFF98712F);
  static Color get muted => dark ? const Color(0xFF748393) : const Color(0xFF66818D);
}
class LogroVista {
  const LogroVista({required this.definicion, required this.progreso});
  final LogroDefinicion definicion;
  final int progreso;
  bool get obtenido => LogrosService.obtenido(definicion, progreso);
  double get proporcion => definicion.meta <= 0
      ? 0.0 : (progreso / definicion.meta).clamp(0.0, 1.0);
}
enum _Filtro { todos, conseguidos, pendientes }

/// UI independiente de Firebase para facilitar tests de tamaños Android.
class LogrosColeccion extends StatefulWidget {
  const LogrosColeccion({super.key, required this.items});
  final List<LogroVista> items;
  @override
  State<LogrosColeccion> createState() => _LogrosColeccionState();
}
class _LogrosColeccionState extends State<LogrosColeccion> {
  _Filtro _filtro = _Filtro.todos;
  @override
  Widget build(BuildContext context) {
    final unlocked = widget.items.where((i) => i.obtenido).length;
    final total = widget.items.length;
    final ratio = total == 0 ? 0.0 : unlocked / total;
    // Elegir el objetivo pendiente más cercano sin conceder recompensas.
    // Priorizar progreso ya iniciado; desempatar de manera determinista.
    final pending = widget.items.where((i) => !i.obtenido).toList()
      ..sort((a, b) {
        final byProgress = b.proporcion.compareTo(a.proporcion);
        if (byProgress != 0) return byProgress;
        return a.definicion.meta.compareTo(b.definicion.meta);
      });
    final next = pending.isEmpty ? null : pending.first;
    final items = widget.items.where((i) =>
      _filtro == _Filtro.todos ||
      (_filtro == _Filtro.conseguidos && i.obtenido) ||
      (_filtro == _Filtro.pendientes && !i.obtenido)).toList();
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          key: const Key('logros-lista'),
          padding: EdgeInsets.fromLTRB(constraints.maxWidth < 370 ? 12 : 18, 10,
            constraints.maxWidth < 370 ? 12 : 18, 28),
          children: [
            Container(
              key: const Key('logros-resumen'),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _Palette.dark
                  ? const [Color(0xFF243E48), Color(0xFF17252F)]
                  : const [Color(0xFFE4F4ED), Color(0xFFF9FCFA)]),
                border: Border.all(color: _Palette.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.emoji_events_outlined, size: 20, color: _Palette.gold),
                    SizedBox(width: 8),
                    Flexible(child: Text('VITRINA DE LOGROS',
                      style: TextStyle(color: _Palette.gold, fontSize: 12,
                        letterSpacing: 1.3, fontWeight: FontWeight.w800))),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 6,
                    children: [
                      Text('$unlocked / $total', style: TextStyle(
                        color: _Palette.white, fontSize: 30, fontWeight: FontWeight.w900)),
                      Text('insignias conseguidas',
                        style: TextStyle(color: _Palette.secondary, fontSize: 13)),
                    ]),
                  const SizedBox(height: 12),
                  ClipRRect(borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: ratio, minHeight: 7, backgroundColor: _Palette.bg,
                      valueColor: AlwaysStoppedAnimation<Color>(_Palette.green))),
                  const SizedBox(height: 8),
                  Text('${(ratio * 100).round()}% de la colección',
                    style: TextStyle(color: _Palette.secondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (next != null) ...[
              _NextAchievementCard(item: next),
              const SizedBox(height: 12),
            ] else if (total > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _Palette.panel,
                  border: Border.all(color: _Palette.gold.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.workspace_premium_rounded, color: _Palette.gold),
                  const SizedBox(width: 12),
                  Expanded(child: Text('¡Colección completa! Has alcanzado todas las metas disponibles.',
                    style: TextStyle(color: _Palette.white, fontWeight: FontWeight.w700))),
                ]),
              ),
            if (next == null && total > 0) const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('abrir-vitrina-rarezas'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: _Palette.bg,
                  builder: (_) => const FractionallySizedBox(
                    heightFactor: 0.82,
                    child: VitrinaRarezas(),
                  ),
                ),
                icon: Icon(Icons.auto_awesome_rounded, size: 17),
                label: Text('Explorar las cinco rarezas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Palette.green,
                  side: BorderSide(color: _Palette.border),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text('TU COLECCIÓN', style: TextStyle(color: _Palette.white,
              letterSpacing: 1.5, fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('Cada insignia refleja una meta alcanzada.',
              style: TextStyle(color: _Palette.secondary, fontSize: 13)),
            const SizedBox(height: 13),
            Wrap(key: const Key('logros-filtros'), spacing: 8, runSpacing: 8,
              children: [
                _Chip('Todos', _filtro == _Filtro.todos,
                  () => setState(() => _filtro = _Filtro.todos)),
                _Chip('Conseguidos', _filtro == _Filtro.conseguidos,
                  () => setState(() => _filtro = _Filtro.conseguidos)),
                _Chip('Pendientes', _filtro == _Filtro.pendientes,
                  () => setState(() => _filtro = _Filtro.pendientes)),
              ]),
            const SizedBox(height: 15),
            AnimatedSwitcher(
              duration: HealthyVisualEffects.duration(
                context, const Duration(milliseconds: 220)),
              switchInCurve: Curves.easeOutCubic,
              child: Column(
                key: ValueKey(_filtro),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items.isEmpty
                    ? [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: _Palette.panel,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Todavía no hay logros en esta sección.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _Palette.secondary)),
                        ),
                      ]
                    : [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LogroSteamCard(item: item),
                          ),
                      ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Las insignias muestran progreso, sin generar XP ni monedas adicionales.',
              style: TextStyle(color: _Palette.secondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
/// Siguiente meta sugerida a partir de los datos de progreso existentes.
/// Presentación informativa: no escribe en Firebase ni acredita recompensas.
class _NextAchievementCard extends StatelessWidget {
  const _NextAchievementCard({required this.item});
  final LogroVista item;

  @override
  Widget build(BuildContext context) {
    final logro = item.definicion;
    final progress = item.progreso.clamp(0, logro.meta);
    final remaining = logro.meta - progress;
    final tone = colorRareza(logro.rareza);
    return Container(
      key: const Key('logros-siguiente-meta'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.55)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flag_rounded, color: tone, size: 19),
          const SizedBox(width: 7),
          Expanded(child: Text('TU PRÓXIMO OBJETIVO',
            style: TextStyle(color: tone, fontWeight: FontWeight.w900,
              fontSize: 12, letterSpacing: 0.8))),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          LogroInsignia(
            rareza: logro.rareza,
            icono: logro.icono,
            desbloqueado: false,
            size: 62,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(logro.nombre, style: TextStyle(color: _Palette.white,
                fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              Text(logro.descripcion, style: TextStyle(
                color: _Palette.secondary, fontSize: 12)),
            ],
          )),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            key: ValueKey('next-progress-${logro.id}-$progress'),
            tween: Tween<double>(begin: 0, end: item.proporcion),
            duration: HealthyVisualEffects.duration(
              context, const Duration(milliseconds: 480)),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: _Palette.bg,
              color: tone,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('$progress de ${logro.meta}',
            style: TextStyle(color: _Palette.white, fontWeight: FontWeight.w700,
              fontSize: 12))),
          Text('Faltan $remaining',
            style: TextStyle(color: _Palette.secondary, fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _Palette.green : _Palette.panel,
    borderRadius: BorderRadius.circular(6),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Text(label, style: TextStyle(
          color: selected ? _Palette.bg : _Palette.white,
          fontSize: 12, fontWeight: FontWeight.w700)))),
  );
}

/// Steam-style: medalla grande y texto de altura flexible, nunca grid fijo.
class LogroSteamCard extends StatelessWidget {
  const LogroSteamCard({super.key, required this.item});
  final LogroVista item;
  @override
  Widget build(BuildContext context) {
    final achievement = item.definicion;
    final unlocked = item.obtenido;
    final tone = colorRareza(achievement.rareza);
    return TweenAnimationBuilder<double>(
      key: ValueKey('reveal-${achievement.id}-$unlocked'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: HealthyVisualEffects.duration(context,
        const Duration(milliseconds: 420)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        alignment: Alignment.centerLeft,
        scale: unlocked ? 0.96 + 0.04 * value : 1,
        child: child,
      ),
      child: Container(
      key: ValueKey('logro-${achievement.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Palette.panel, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: unlocked ? tone.withValues(alpha: 0.65) : _Palette.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LogroInsignia(
          key: ValueKey('insignia-${achievement.id}'),
          rareza: achievement.rareza,
          icono: achievement.icono,
          desbloqueado: unlocked,
          size: 78,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(achievement.nombre, softWrap: true,
              style: TextStyle(color: _Palette.white,
                fontSize: 15, fontWeight: FontWeight.w800, height: 1.25)),
            const SizedBox(height: 5),
            Text(
              achievement.rareza.etiqueta.toUpperCase(),
              style: TextStyle(
                color: tone,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(achievement.descripcion, softWrap: true,
              style: TextStyle(color: _Palette.secondary,
                fontSize: 12.5, height: 1.3)),
            const SizedBox(height: 10),
            if (unlocked)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_rounded, size: 15, color: _Palette.green),
                const SizedBox(width: 6),
                Flexible(child: Text(
                  achievement.id == LogrosService.primerPasoId
                    ? 'Desbloqueado · recompensa inicial existente'
                    : 'Logro desbloqueado',
                  softWrap: true, style: TextStyle(color: _Palette.green,
                    fontSize: 11.5, fontWeight: FontWeight.w700))),
              ])
            else ...[
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.proporcion, minHeight: 5,
                  backgroundColor: _Palette.bg,
                  valueColor: AlwaysStoppedAnimation<Color>(_Palette.muted))),
              const SizedBox(height: 6),
              Text('${item.progreso.clamp(0, achievement.meta)} de ${achievement.meta}',
                style: TextStyle(color: _Palette.secondary,
                  fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ],
        )),
      ]),
      ),
    );
  }
}
