import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'modelo/habit.dart';
import 'registrar_habito_screen.dart';

/// Pantalla de hábitos. La barra inferior se conserva en main.dart.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _ActiveHabitEntry {
  final Habit habit;
  final UserHabit attempt;

  const _ActiveHabitEntry({required this.habit, required this.attempt});
}

class _HabitsScreenState extends State<HabitsScreen> {
  static const navy = Color(0xFF193344);
  static const green = Color(0xFF08B889);
  static const greenDark = Color(0xFF078765);
  static const background = Color(0xFFF5F8F6);
  static const muted = Color(0xFF71879A);
  static const border = Color(0xFFDCE8E3);

  static const int initialHabitSlots = 3;

  final searchController = TextEditingController();

  String selectedCategory = 'Todos';
  bool searching = false;
  bool loading = true;
  bool saving = false;

  int xp = 0;
  int coins = 0;
  int level = 1;
  int habitSlots = initialHabitSlots;

  List<_ActiveHabitEntry> active = [];

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
      difficulty: 'Sencillo',
      subtitle: '1 porción al día',
      xp: 10,
      target: 1,
      unlockType: 'none',
      coinCost: 0,
      repeatable: true,
      cooldownDays: 0,
    ),
    Habit(
      id: 'breakfast_9',
      title: 'Desayuna antes de las 9:00',
      category: 'Energía',
      difficulty: 'Moderado',
      subtitle: '5 días por semana',
      xp: 10,
      target: 5,
      unlockType: 'none',
      coinCost: 0,
      repeatable: true,
      cooldownDays: 0,
    ),
    Habit(
      id: 'sleep_9',
      title: 'Duerme 9 horas al día',
      category: 'Bienestar',
      difficulty: 'Difícil',
      subtitle: 'Todos los días',
      xp: 15,
      target: 1,
      unlockType: 'level',
      requiredLevel: 2,
      coinCost: 0,
      repeatable: true,
      cooldownDays: 0,
    ),
    Habit(
      id: 'fruit',
      title: 'Comer una fruta',
      category: 'Alimentación',
      difficulty: 'Sencillo',
      subtitle: '1 fruta al día',
      xp: 10,
      target: 1,
      unlockType: 'none',
      coinCost: 0,
      repeatable: true,
      cooldownDays: 0,
    ),
    Habit(
      id: 'water',
      title: 'Toma 6 vasos de agua',
      category: 'Hidratación',
      difficulty: 'Moderado',
      subtitle: '6 vasos al día',
      xp: 10,
      target: 6,
      unlockType: 'none',
      coinCost: 0,
      repeatable: true,
      cooldownDays: 0,
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

  Future<void> _load() async {
    try {
      final userDoc = _userDoc;
      final collection = _habitsCollection;

      if (userDoc == null || collection == null) {
        if (!mounted) return;

        setState(() {
          active = [];
          xp = 0;
          loading = false;
        });
        return;
      }

      final results = await Future.wait([userDoc.get(), collection.get()]);

      final userSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;

      final habitsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

      final userData = userSnapshot.data() ?? {};

      final loadedXp = (userData['xp'] as num?)?.toInt() ?? 0;
      final loadedCoins = (userData['coins'] as num?)?.toInt() ?? 0;
      final loadedLevel = (userData['level'] as num?)?.toInt() ?? 1;
      final loadedSlots =
          (userData['habitSlots'] as num?)?.toInt() ?? initialHabitSlots;

      final List<_ActiveHabitEntry> loadedActive = [];

      for (final habitDoc in habitsSnapshot.docs) {
        final habitData = habitDoc.data();
        final habit = Habit.fromMap(habitData, habitDoc.id);

        final attemptsSnapshot =
            await habitDoc.reference
                .collection('attempts')
                .where('status', isEqualTo: 'inProgress')
                .get();

        for (final attemptDoc in attemptsSnapshot.docs) {
          final attempt = UserHabit.fromMap(attemptDoc.data(), attemptDoc.id);

          if (attempt.isInProgress) {
            loadedActive.add(_ActiveHabitEntry(habit: habit, attempt: attempt));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        active = loadedActive;
        xp = loadedXp;
        coins = loadedCoins;
        level = loadedLevel;
        habitSlots = loadedSlots;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando hábitos: $e');

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

  Future<void> addHabit(Habit habit) async {
    final collection = _habitsCollection;

    if (collection == null) {
      _showMessage('Inicia sesión para guardar tus hábitos.');
      return;
    }

    if (saving) return;

    if (active.any((entry) => entry.habit.id == habit.id)) {
      _showMessage('Este hábito ya está en progreso.');
      return;
    }

    if (active.length >= habitSlots) {
      _showMessage(
        'Ya ocupaste tus $habitSlots espacios disponibles. '
        'Completa o cancela un hábito para liberar uno.',
      );
      return;
    }

    if (!_isUnlocked(habit)) {
      _showMessage('Todavía no cumples los requisitos para desbloquearlo.');
      return;
    }

    if (habit.coinCost > 0 && coins < habit.coinCost) {
      _showMessage('No tienes suficientes monedas para adquirirlo.');
      return;
    }

    setState(() => saving = true);

    try {
      final habitRef = collection.doc(habit.id);
      final attemptsRef = habitRef.collection('attempts');

      final previousAttempts = await attemptsRef.get();
      final attemptNumber = previousAttempts.docs.length + 1;
      final attemptRef = attemptsRef.doc();

      final now = DateTime.now();

      final attempt = UserHabit(
        id: attemptRef.id,
        habitId: habit.id,
        status: UserHabitStatus.inProgress,
        progress: 0,
        target: habit.target,
        attemptNumber: attemptNumber,
        xpEarned: 0,
        acquiredAt: now,
        completedAt: null,
        cancelledAt: null,
        availableAgainAt: null,
      );

      final batch = _db.batch();

      batch.set(habitRef, {
        ...habit.toMap(),
        'acquiredAt': FieldValue.serverTimestamp(),
        'lastAttemptId': attemptRef.id,
      }, SetOptions(merge: true));

      batch.set(attemptRef, attempt.toMap());

      batch.set(_userDoc!, {
        'uid': _user!.uid,
        'habitSlots': habitSlots,
      }, SetOptions(merge: true));

      await batch.commit();

      if (!mounted) return;

      setState(() {
        active.add(_ActiveHabitEntry(habit: habit, attempt: attempt));
      });

      _showMessage('“${habit.title}” se añadió a tus hábitos.');
    } catch (e, stackTrace) {
      debugPrint('ERROR AL GUARDAR HÁBITO: $e');
      debugPrint('DETALLES: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  bool _isUnlocked(Habit habit) {
    switch (habit.unlockType) {
      case 'none':
        return true;

      case 'level':
        return level >= (habit.requiredLevel ?? 1);

      case 'coins':
        return coins >= habit.coinCost;

      case 'habit':
        return active.any((entry) => entry.habit.id == habit.requiredHabitId);

      case 'combined':
        final levelOk = level >= (habit.requiredLevel ?? 1);
        final coinsOk = coins >= habit.coinCost;

        final habitOk =
            habit.requiredHabitId == null ||
            active.any((entry) => entry.habit.id == habit.requiredHabitId);

        return levelOk && coinsOk && habitOk;

      default:
        return false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _abrirRegistroHabito(_ActiveHabitEntry entry) async {
    final habit = entry.habit;
    final attempt = entry.attempt;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => RegistrarHabitoScreen(
              habitId: habit.id,
              attemptId: attempt.id,
              habitTitle: habit.title,
              category: habit.category,
              currentProgress: attempt.progress,
              goal: attempt.target,
            ),
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  Color categoryBg(String category) {
    switch (category) {
      case 'Alimentación':
        return const Color(0xFFFFEFEC);
      case 'Hidratación':
        return const Color(0xFFE4F5FB);
      case 'Energía':
        return const Color(0xFFFFF5D9);
      case 'Bienestar':
        return const Color(0xFFF2ECFC);
      default:
        return Colors.white;
    }
  }

  Color categoryInk(String category) {
    switch (category) {
      case 'Alimentación':
        return const Color(0xFFE66C65);
      case 'Hidratación':
        return const Color(0xFF299FCB);
      case 'Energía':
        return const Color(0xFFB88713);
      case 'Bienestar':
        return const Color(0xFF9473C9);
      default:
        return greenDark;
    }
  }

  IconData categoryIcon(String category) {
    switch (category) {
      case 'Alimentación':
        return Icons.restaurant_rounded;
      case 'Hidratación':
        return Icons.water_drop_rounded;
      case 'Energía':
        return Icons.bolt_rounded;
      case 'Bienestar':
        return Icons.favorite_rounded;
      default:
        return Icons.track_changes_rounded;
    }
  }

  bool matches(Habit habit) {
    final categoryOk =
        selectedCategory == 'Todos' || habit.category == selectedCategory;

    final query = searchController.text.trim().toLowerCase();

    return categoryOk &&
        (query.isEmpty ||
            habit.title.toLowerCase().contains(query) ||
            habit.category.toLowerCase().contains(query));
  }

  List<_ActiveHabitEntry> get visibleActive =>
      active.where((entry) => matches(entry.habit)).toList();

  List<Habit> get visibleRecommendations =>
      recommendations
          .where(
            (habit) =>
                !active.any((entry) => entry.habit.id == habit.id) &&
                matches(habit),
          )
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
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
                            'Pequeños cambios, grandes resultados. '
                            'Elige tu siguiente misión.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _categoryGrid(),
                          const SizedBox(height: 28),
                          _sectionHeader(
                            'Mis hábitos activos',
                            '${active.length}/$habitSlots espacios',
                          ),
                          const SizedBox(height: 14),
                          if (visibleActive.isEmpty)
                            _empty(
                              'Todavía no tienes hábitos activos en '
                              'esta categoría. ¡Elige uno para comenzar!',
                            )
                          else
                            ...visibleActive.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _activeCard(entry),
                              ),
                            ),
                          const SizedBox(height: 14),
                          _sectionHeader(
                            'Descubre nuevos hábitos',
                            '${visibleRecommendations.length}',
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Encuentra una misión que se adapte a ti.',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          if (visibleRecommendations.isEmpty)
                            _empty(
                              'No hay recomendaciones pendientes '
                              'en esta categoría.',
                            )
                          else
                            ...visibleRecommendations.map(
                              (habit) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _recommendationCard(habit),
                              ),
                            ),
                          const SizedBox(height: 18),
                          _encouragement(),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
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
                    onPressed: () {
                      setState(() {
                        searching = false;
                        searchController.clear();
                      });
                    },
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
                onPressed: () {
                  setState(() => searching = true);
                },
                icon: const Icon(Icons.search_rounded, color: navy, size: 25),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _categoryGrid() {
    const cats = [
      ('Alimentación', Icons.restaurant_rounded),
      ('Hidratación', Icons.water_drop_rounded),
      ('Energía', Icons.bolt_rounded),
      ('Bienestar', Icons.favorite_rounded),
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
              onPressed: () {
                setState(() => selectedCategory = 'Todos');
              },
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
    final color = categoryInk(category);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () {
        setState(() {
          selectedCategory = selected ? 'Todos' : category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: categoryBg(category),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? color : Colors.white,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 9),
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
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String trailing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing.isNotEmpty)
          Text(
            trailing,
            style: const TextStyle(
              color: greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _activeCard(_ActiveHabitEntry entry) {
    final habit = entry.habit;
    final attempt = entry.attempt;

    final color = categoryInk(habit.category);
    final progress =
        attempt.target > 0
            ? (attempt.progress / attempt.target).clamp(0.0, 1.0)
            : 0.0;

    final done = attempt.hasReachedGoal;
    final isWater = habit.category == 'Hidratación' && habit.id == 'water';

    final remaining = (attempt.target - attempt.progress).clamp(
      0,
      attempt.target,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        color: categoryBg(habit.category),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(categoryIcon(habit.category), color: color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  habit.category.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2C8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${habit.xp} XP',
                  style: const TextStyle(
                    color: Color(0xFF9B7415),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            habit.title,
            style: const TextStyle(
              color: navy,
              fontSize: 22,
              height: 1.18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),

          if (isWater)
            _waterProgress(attempt.progress, attempt.target)
          else
            _generalProgress(
              attempt.progress,
              attempt.target,
              color,
              habit.category,
            ),

          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${attempt.progress} de ${attempt.target}',
                style: const TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  done
                      ? '¡Meta alcanzada!'
                      : isWater
                      ? 'Solo faltan $remaining vasos'
                      : 'Sigue avanzando',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 51,
            child: ElevatedButton.icon(
              onPressed: done ? null : () => _abrirRegistroHabito(entry),
              icon: Icon(
                done ? Icons.check_circle_rounded : Icons.add_rounded,
                size: 21,
              ),
              label: Text(
                done ? 'Hábito completado' : 'Registrar avance',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFDDE9E4),
                disabledForegroundColor: greenDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Indicador de vasos para el hábito de hidratación.
  Widget _waterProgress(int progress, int target) {
    final safeTarget = target.clamp(1, 10);

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: List.generate(safeTarget, (index) {
        final completed = index < progress;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 43,
          height: 49,
          decoration: BoxDecoration(
            color:
                completed ? Colors.white : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: completed ? Colors.white : const Color(0xFFB7DCE9),
            ),
          ),
          child: Icon(
            completed ? Icons.water_drop_rounded : Icons.local_drink_outlined,
            color:
                completed ? const Color(0xFF36A9D6) : const Color(0xFF9BC7D8),
            size: 27,
          ),
        );
      }),
    );
  }

  /// Indicador genérico para otros tipos de hábitos.
  Widget _generalProgress(
    int progress,
    int target,
    Color color,
    String category,
  ) {
    final safeTarget = target.clamp(1, 10);

    return Column(
      children: [
        Row(
          children: List.generate(safeTarget, (index) {
            final completed = index < progress;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == safeTarget - 1 ? 0 : 6,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 39,
                  decoration: BoxDecoration(
                    color:
                        completed
                            ? color.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color:
                          completed
                              ? color.withValues(alpha: 0.35)
                              : Colors.white,
                    ),
                  ),
                  child: Icon(
                    completed ? categoryIcon(category) : Icons.circle_outlined,
                    color: completed ? color : const Color(0xFFB8C8C3),
                    size: 19,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: target > 0 ? (progress / target).clamp(0.0, 1.0) : 0,
            minHeight: 7,
            backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _recommendationCard(Habit habit) {
    final color = categoryInk(habit.category);
    final unlocked = _isUnlocked(habit);
    final hasSlot = active.length < habitSlots;
    final canAdd = unlocked && hasSlot && !saving;

    final buttonText =
        !unlocked
            ? 'Bloqueado'
            : !hasSlot
            ? 'Sin espacio'
            : saving
            ? 'Guardando'
            : 'Agregar';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: categoryBg(habit.category),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(categoryIcon(habit.category), color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  habit.category,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${habit.subtitle} · ${habit.difficulty}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFD6A52B),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${habit.xp} XP',
                      style: const TextStyle(
                        color: navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (!unlocked || !hasSlot) ...[
                  const SizedBox(height: 6),
                  Text(
                    !unlocked
                        ? 'Requisitos aún no cumplidos'
                        : 'Libera un espacio para agregarlo',
                    style: const TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: canAdd ? () => addHabit(habit) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5ECE9),
                disabledForegroundColor: muted,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const Icon(Icons.spa_outlined, color: green, size: 30),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _encouragement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F6ED),
        borderRadius: BorderRadius.circular(19),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.spa_outlined, color: greenDark, size: 25),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No necesitas hacerlo todo hoy. '
              'Empieza con un hábito, repítelo y hazlo tuyo.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
