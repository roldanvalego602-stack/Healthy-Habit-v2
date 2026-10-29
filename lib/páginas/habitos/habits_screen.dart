import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'registrar_habito_screen.dart';

/// Pantalla de hábitos. La barra inferior se conserva en main.dart.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  static const navy = Color(0xFF193344);
  static const green = Color(0xFF08B889);
  static const greenDark = Color(0xFF078765);
  static const background = Color(0xFFF5F8F6);
  static const muted = Color(0xFF71879A);
  static const border = Color(0xFFDCE8E3);

  final searchController = TextEditingController();

  String selectedCategory = 'Todos';
  bool searching = false;
  bool loading = true;
  bool saving = false;
  int xp = 0;
  List<Habit> active = [];

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final user = _user;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid);
  }

  CollectionReference<Map<String, dynamic>>? get _habitsCollection {
    final userDoc = _userDoc;
    if (userDoc == null) return null;
    return userDoc.collection('user_habits');
  }

  final List<Habit> recommendations = const [
    Habit(
      id: 'vegetable_lunch',
      title: 'Añade una verdura al almuerzo',
      category: 'Alimentación',
      subtitle: '1 porción al día',
      xp: 10,
      target: 1,
      progress: 0,
    ),
    Habit(
      id: 'breakfast_9',
      title: 'Desayuna antes de las 9:00',
      category: 'Energía',
      subtitle: '5 días por semana',
      xp: 10,
      target: 5,
      progress: 0,
    ),
    Habit(
      id: 'sleep_9',
      title: 'Duerme 9 horas al día',
      category: 'Bienestar',
      subtitle: 'Todos los días',
      xp: 15,
      target: 1,
      progress: 0,
    ),
    Habit(
      id: 'fruit',
      title: 'Comer una fruta',
      category: 'Alimentación',
      subtitle: '1 fruta al día',
      xp: 10,
      target: 1,
      progress: 0,
    ),
    Habit(
      id: 'water',
      title: '6 vasos de agua',
      category: 'Hidratación',
      subtitle: '6 vasos al día',
      xp: 10,
      target: 6,
      progress: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Habit> _defaults() => [
    const Habit(
      id: 'water',
      title: '6 vasos de agua',
      category: 'Hidratación',
      subtitle: '6 vasos al día',
      xp: 10,
      target: 6,
      progress: 4,
    ),
    const Habit(
      id: 'fruit',
      title: 'Comer una fruta',
      category: 'Alimentación',
      subtitle: '1 fruta al día',
      xp: 10,
      target: 1,
      progress: 0,
    ),
  ];

  Future<void> _load() async {
    try {
      final userDoc = _userDoc;
      final habitsCollection = _habitsCollection;

      if (userDoc == null || habitsCollection == null) {
        if (!mounted) return;
        setState(() {
          active = [];
          xp = 0;
          loading = false;
        });
        return;
      }

      final results = await Future.wait([
        userDoc.get(),
        habitsCollection.get(),
      ]);

      final userSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final habitsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

      final loadedHabits =
          habitsSnapshot.docs.map((doc) {
            return Habit.fromFirestore(doc.id, doc.data());
          }).toList();

      // Solo crea hábitos predeterminados si la colección está vacía.
      if (habitsSnapshot.docs.isEmpty) {
        loadedHabits.addAll(_defaults());

        final batch = _db.batch();
        for (final habit in loadedHabits) {
          batch.set(habitsCollection.doc(habit.id), habit.toJson());
        }
        await batch.commit();
      }

      final userData = userSnapshot.data() ?? {};

      if (!mounted) return;
      setState(() {
        active = loadedHabits;
        xp = (userData['xp'] as num?)?.toInt() ?? 0;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar los hábitos. '
            'Revisa tu conexión y las reglas de Firestore.',
          ),
        ),
      );
    }
  }

  Future<void> _saveXp() async {
    final userDoc = _userDoc;
    if (userDoc == null) return;

    await userDoc.set({'uid': _user!.uid, 'xp': xp}, SetOptions(merge: true));
  }

  Future<void> addHabit(Habit habit) async {
    final collection = _habitsCollection;
    if (collection == null) {
      _showMessage('Inicia sesión para guardar tus hábitos.');
      return;
    }

    if (active.any((h) => h.id == habit.id)) return;

    final newHabit = habit.copy();

    setState(() {
      active.add(newHabit);
      saving = true;
    });

    try {
      await collection.doc(newHabit.id).set(newHabit.toJson());

      if (!mounted) return;
      _showMessage('“${habit.title}” se añadió a tus hábitos.');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        active.removeWhere((h) => h.id == newHabit.id);
      });

      _showMessage('No se pudo guardar el hábito en Firestore.');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _abrirRegistroHabito(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => RegistrarHabitoScreen(
              habitId: habit.id,
              habitTitle: habit.title,
              category: habit.category,
              currentProgress: habit.progress,
            ),
      ),
    );
  }

  Color categoryBg(String category) {
    switch (category) {
      case 'Alimentación':
        return const Color(0xFFFBE9E7);
      case 'Hidratación':
        return const Color(0xFFDFF3FA);
      case 'Energía':
        return const Color(0xFFFFF3CC);
      case 'Bienestar':
        return const Color(0xFFF0E7FA);
      default:
        return Colors.white;
    }
  }

  Color categoryInk(String category) {
    switch (category) {
      case 'Alimentación':
        return const Color(0xFFEF5B62);
      case 'Hidratación':
        return const Color(0xFF2BA8DB);
      case 'Energía':
        return const Color(0xFFB88713);
      case 'Bienestar':
        return const Color(0xFF9A78D6);
      default:
        return greenDark;
    }
  }

  IconData categoryIcon(String category) {
    switch (category) {
      case 'Alimentación':
        return Icons.apple_rounded;
      case 'Hidratación':
        return Icons.water_drop_outlined;
      case 'Energía':
        return Icons.bolt_rounded;
      case 'Bienestar':
        return Icons.favorite_border_rounded;
      default:
        return Icons.track_changes_rounded;
    }
  }

  bool matches(Habit h) {
    final categoryOk =
        selectedCategory == 'Todos' || h.category == selectedCategory;
    final q = searchController.text.trim().toLowerCase();

    return categoryOk &&
        (q.isEmpty ||
            h.title.toLowerCase().contains(q) ||
            h.category.toLowerCase().contains(q));
  }

  List<Habit> get visibleActive => active.where(matches).toList();

  List<Habit> get visibleRecommendations =>
      recommendations
          .where((h) => !active.any((a) => a.id == h.id) && matches(h))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child:
            loading
                ? const Center(child: CircularProgressIndicator(color: green))
                : Column(
                  children: [
                    _header(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                        children: [
                          const Text(
                            '¿Qué quieres mejorar?',
                            style: TextStyle(
                              color: navy,
                              fontSize: 28,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Elige el tipo de hábito. Nosotros lo convertimos en misión.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _categoryGrid(),
                          const SizedBox(height: 27),
                          _sectionHeader('Activos', '${active.length} hábitos'),
                          const SizedBox(height: 14),
                          if (visibleActive.isEmpty)
                            _empty('No hay hábitos en esta categoría.')
                          else
                            ...visibleActive.map(
                              (h) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _activeCard(h),
                              ),
                            ),
                          const SizedBox(height: 12),
                          _sectionHeader('Recomendados para ti', ''),
                          const SizedBox(height: 8),
                          const Text(
                            'Ve chequeando tu próximo hábito',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          if (visibleRecommendations.isEmpty)
                            _empty(
                              'No hay recomendaciones pendientes en esta categoría.',
                            )
                          else
                            _recommendationList(visibleRecommendations),
                          const SizedBox(height: 30),
                          _encouragement(),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(17, 10, 17, 12),
    child: Row(
      children: [
        if (searching)
          Expanded(
            child: TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar hábitos...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed:
                      () => setState(() {
                        searching = false;
                        searchController.clear();
                      }),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          )
        else ...[
          const Expanded(
            child: Text(
              'Hábitos',
              style: TextStyle(
                color: navy,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Buscar hábitos',
              onPressed: () => setState(() => searching = true),
              icon: const Icon(Icons.search_rounded, color: navy, size: 25),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _categoryGrid() {
    const cats = [
      ('Alimentación', Icons.apple_rounded),
      ('Hidratación', Icons.water_drop_outlined),
      ('Energía', Icons.bolt_rounded),
      ('Bienestar', Icons.favorite_border_rounded),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _categoryButton(cats[0].$1, cats[0].$2)),
            const SizedBox(width: 10),
            Expanded(child: _categoryButton(cats[1].$1, cats[1].$2)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _categoryButton(cats[2].$1, cats[2].$2)),
            const SizedBox(width: 10),
            Expanded(child: _categoryButton(cats[3].$1, cats[3].$2)),
          ],
        ),
        if (selectedCategory != 'Todos')
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => selectedCategory = 'Todos'),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Mostrar todas las categorías'),
              style: TextButton.styleFrom(foregroundColor: greenDark),
            ),
          ),
      ],
    );
  }

  Widget _categoryButton(String category, IconData icon) {
    final selected = selectedCategory == category;

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap:
          () => setState(() {
            selectedCategory = selected ? 'Todos' : category;
          }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: categoryBg(category),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? categoryInk(category) : Colors.white,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: categoryInk(category), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String trailing) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (trailing.isNotEmpty)
        Text(
          trailing,
          style: const TextStyle(
            color: green,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );

  Widget _activeCard(Habit h) {
    final done = h.progress >= h.target;
    final isWater = h.id == 'water';
    final color = categoryInk(h.category);

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
      decoration: BoxDecoration(
        color: categoryBg(h.category),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon(h.category), color: color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.title,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWater
                          ? '${h.progress} de ${h.target} hoy · +${h.xp} XP'
                          : done
                          ? 'Completado hoy · +${h.xp} XP'
                          : '${h.subtitle} · +${h.xp} XP',
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _actionButton(
                done
                    ? 'Listo'
                    : isWater
                    ? 'Registrar'
                    : 'Completar',
                onPressed: done ? null : () => _abrirRegistroHabito(h),
                disabled: done,
              ),
            ],
          ),
          if (isWater) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (h.progress / h.target).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF51C7E9)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recommendationList(List<Habit> habits) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.6),
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(23),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (int i = 0; i < habits.length; i++) ...[
          _recommendationRow(habits[i]),
          if (i < habits.length - 1) const Divider(height: 1, color: border),
        ],
      ],
    ),
  );

  Widget _recommendationRow(Habit h) {
    final color = categoryInk(h.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryBg(h.category),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(categoryIcon(h.category), color: color, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${h.subtitle} · +${h.xp} XP',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _actionButton('Agregar', onPressed: () => addHabit(h)),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label, {
    required VoidCallback? onPressed,
    bool disabled = false,
  }) => SizedBox(
    height: 34,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: disabled ? const Color(0xFFDDE9E4) : green,
        foregroundColor: disabled ? greenDark : Colors.white,
        disabledBackgroundColor: const Color(0xFFDDE9E4),
        disabledForegroundColor: greenDark,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        elevation: 0,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
      child: Text(label),
    ),
  );

  Widget _empty(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border),
    ),
    child: Text(message, style: const TextStyle(color: muted, fontSize: 13)),
  );

  Widget _encouragement() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE1F6ED),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.spa_outlined, color: greenDark, size: 25),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'No necesitas hacerlo todo hoy. Como dicen: '
            '“Empieza con un hábito, repítelo y hazlo tuyo.”',
            style: TextStyle(color: muted, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class Habit {
  final String id;
  final String title;
  final String category;
  final String subtitle;
  final int xp;
  final int target;
  final int progress;

  const Habit({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.xp,
    required this.target,
    required this.progress,
  });

  Habit copy({int? progress}) => Habit(
    id: id,
    title: title,
    category: category,
    subtitle: subtitle,
    xp: xp,
    target: target,
    progress: progress ?? this.progress,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'subtitle': subtitle,
    'xp': xp,
    'target': target,
    'progress': progress,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    subtitle: json['subtitle'] as String,
    xp: (json['xp'] as num).toInt(),
    target: (json['target'] as num).toInt(),
    progress: (json['progress'] as num).toInt(),
  );

  factory Habit.fromFirestore(String documentId, Map<String, dynamic> data) =>
      Habit(
        id: documentId,
        title: data['title']?.toString() ?? 'Hábito',
        category: data['category']?.toString() ?? 'Bienestar',
        subtitle: data['subtitle']?.toString() ?? '',
        xp: (data['xp'] as num?)?.toInt() ?? 0,
        target: (data['target'] as num?)?.toInt() ?? 1,
        progress: (data['progress'] as num?)?.toInt() ?? 0,
      );
}
