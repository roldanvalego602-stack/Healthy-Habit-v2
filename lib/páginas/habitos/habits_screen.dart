import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_coin.dart';
import '../../tema/healthy_motion.dart';
import '../../tema/healthy_visual_mode.dart';
import 'catalogo.dart';
import 'habit_action_service.dart';
import 'habit_add_sheet.dart';
import 'habit_popularity_service.dart';
import 'habit_recommendation_service.dart';
import 'modelo/habit.dart';
import 'registrar_habito_screen.dart';
import 'personal_routines_screen.dart';
import 'habitos_en_pareja_screen.dart';
import '../niveles/levels_system.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key, this.initialSearch = ''});
  final String initialSearch;
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _ActiveHabitEntry {
  final Habit habit;
  final UserHabit attempt;
  const _ActiveHabitEntry({required this.habit, required this.attempt});
}

class _HabitsScreenState extends State<HabitsScreen> {
  Color get navy => HealthyAdaptive.text;
  Color get green => HealthyAdaptive.accent;
  Color get greenDark => HealthyAdaptive.accent;
  Color get background => HealthyAdaptive.background;
  Color get muted => HealthyAdaptive.muted;
  Color get border => HealthyAdaptive.border;
  static const int initialHabitSlots = 3;
  final HabitActionService _habitActions = const HabitActionService();
  final TextEditingController searchController = TextEditingController();
  String selectedCategory = 'Todos';
  String selectedDifficulty = 'Todos';
  bool searching = false;
  bool showingFullCatalog = false;
  int _habitsView = 0;
  final PageController _suggestedPager = PageController(viewportFraction: 0.94);
  final PageController _popularPager = PageController(viewportFraction: 0.94);
  int _suggestedPage = 0;
  int _popularPage = 0;
  bool loading = true;
  bool saving = false;
  bool loadingPopularity = false;
  List<HabitPopularity> popularMetrics = [];
  List<HabitUsageSignal> usageHistory = [];
  final HabitRecommendationService _recommendationService =
      const HabitRecommendationService();
  final HabitPopularityService _popularityService = const HabitPopularityService();
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

  /// Convierte el catálogo local en objetos Habit.*
  List<Habit> get recommendations {
    return habitCatalog.map((data) {
      return Habit.fromMap(
        Map<String, dynamic>.from(data),
        data['id'] as String,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch.trim().isNotEmpty) {
      searching = true;
      searchController.text = widget.initialSearch.trim();
    }
    _load();
    _loadPopularity();
  }

  @override
  void dispose() {
    searchController.dispose();
    _suggestedPager.dispose();
    _popularPager.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      final userDoc = _userDoc;
      final collection = _habitsCollection;
      if (userDoc == null || collection == null) {
        if (!mounted) return;
        setState(() {
          active = [];
          usageHistory = [];
          xp = 0;
          coins = 0;
          level = 1;
          habitSlots = initialHabitSlots;
          loading = false;
        });
        return;
      }
      final results = await Future.wait([userDoc.get(), collection.get()]);
      final userSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final habitsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final userData = userSnapshot.data() ?? {};
      final rawXp = userData['xp'] ?? userData['currentXp'];

      final loadedXp =
          rawXp is num
              ? rawXp.toInt().clamp(0, 1000000000).toInt()
              : (int.tryParse('$rawXp') ?? 0).clamp(0, 1000000000).toInt();

      final loadedCoins = (userData['habitCoins'] as num?)?.toInt() ?? 0;

      final loadedLevel = LevelSystem.fromXp(loadedXp).number;
      final loadedSlots =
          (userData['habitSlots'] as num?)?.toInt() ?? initialHabitSlots;
      final List<_ActiveHabitEntry> loadedActive = [];
      final List<HabitUsageSignal> loadedHistory = [
        for (final habitDoc in habitsSnapshot.docs)
          if ((habitDoc.data()['latestProgress'] as num?) != null)
            HabitUsageSignal(
              habitId: habitDoc.id,
              category: habitDoc.data()['category']?.toString() ?? '',
              registrations: (habitDoc.data()['latestProgress'] as num)
                  .toInt()
                  .clamp(0, 1000000)
                  .toInt(),
              lastActivity: habitDoc.data()['updatedAt'] is Timestamp
                  ? (habitDoc.data()['updatedAt'] as Timestamp).toDate()
                  : null,
            ),
      ];
      final groups = await Future.wait(
        habitsSnapshot.docs.map((habitDoc) async {
          final habit = Habit.fromMap(habitDoc.data(), habitDoc.id);
          final attemptsSnapshot =
              await habitDoc.reference
                  .collection('attempts')
                  .where('status', isEqualTo: 'inProgress')
                  .get();
          return attemptsSnapshot.docs
              .map(
                (doc) => _ActiveHabitEntry(
                  habit: habit,
                  attempt: UserHabit.fromMap(doc.data(), doc.id),
                ),
              )
              .where((entry) => entry.attempt.isInProgress)
              .toList();
        }),
      );
      for (final group in groups) {
        loadedActive.addAll(group);
      }
      if (!mounted) return;
      setState(() {
        active = loadedActive;
        usageHistory = loadedHistory;
        xp = loadedXp;
        coins = loadedCoins;
        level = loadedLevel;
        habitSlots = loadedSlots;
        loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error cargando hábitos: $e');
      debugPrint('$stackTrace');
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

  Future<void> _loadPopularity() async {
    if (!mounted) return;
    setState(() => loadingPopularity = true);
    try {
      final values = await _popularityService.fetchVerified();
      if (!mounted) return;
      setState(() {
        popularMetrics = values;
        loadingPopularity = false;
      });
    } catch (error) {
      // Es información opcional: permisos insuficientes, falta de red o una
      // colección aún no publicada no impiden usar los hábitos oficiales.
      debugPrint('Estadísticas de popularidad no disponibles: $error');
      if (mounted) {
        setState(() {
          popularMetrics = [];
          loadingPopularity = false;
        });
      }
    }
  }

  List<Habit> get _popularHabits {
    final visible = {
      for (final habit in visibleRecommendations) habit.id: habit,
    };
    return [
      for (final score in popularMetrics)
        if (visible.containsKey(score.habitId)) visible[score.habitId]!,
    ].take(8).toList();
  }

  Future<void> _confirmAddHabit(Habit habit) async {
    if (saving) return;
    late final HabitActionPreview preview;
    try {
      // Las comprobaciones siguen ocurriendo antes de abrir la ficha.
      preview = await _habitActions.preview(habit.id, remove: false);
    } catch (error) {
      if (mounted) _showMessage('$error');
      return;
    }
    if (!mounted) return;
    // Una sola ficha y una sola confirmación, sin alterar el backend.
    final interaction = await HabitAddSheet.open(
      context, habit, preview.estimatedCost,
    );
    if (interaction != null && mounted) {
      await addHabit(habit, preview: preview, interaction: interaction);
    }
  }

  bool _isDifficult(Habit habit) {
    final difficulty = habit.difficulty.trim().toLowerCase();
    return difficulty == 'difícil' || difficulty == 'dificil';
  }

  Future<void> _confirmCancelHabit(_ActiveHabitEntry entry) async {
    if (saving) return;
    late final HabitActionPreview preview;
    try {
      preview = await _habitActions.preview(entry.habit.id, remove: true);
      if (preview.attemptId != entry.attempt.id) {
        throw StateError('El intento cambió. Actualiza la pantalla.');
      }
    } catch (error) {
      if (mounted) _showMessage('$error');
      return;
    }
    if (!mounted) return;
    final fee = preview.estimatedCost;
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('¿Abandonar hábito?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.habit.title),
                const SizedBox(height: 10),
                Text(
                  'Sesiones realizadas: ${entry.attempt.progress} de ${entry.attempt.target}',
                ),
                const SizedBox(height: 8),
                const Text('Penalización estimada:'),
                HealthyCoinAmount(amount: '$fee',
                  size: 20, suffix: ' Habit Coins'),
                const SizedBox(height: 8),
                const Text(
                  'Se conservarán tus sesiones anteriores y el XP obtenido.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Conservar hábito'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                child: const Text('Abandonar'),
              ),
            ],
          ),
    );
    if (accepted == true && mounted) {
      await _cancelHabit(entry, preview: preview);
    }
  }

  /// Comparte las mismas validaciones y transacciones que Mr. Healthy.
  Future<void> _cancelHabit(_ActiveHabitEntry entry, {
    HabitActionPreview? preview,
  }) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final checked = preview ??
          await _habitActions.preview(entry.habit.id, remove: true);
      if (checked.attemptId != entry.attempt.id) {
        throw StateError('El intento cambió; actualiza tus hábitos.');
      }
      final result = await _habitActions.execute(checked);
      if (!mounted) return;
      _showMessage(result.chargedCoins == 0
          ? 'Hábito abandonado. Tu historial se conserva.'
          : 'Hábito abandonado. Se descontaron ${result.chargedCoins} Habit Coins.');
      await _load();
    } catch (error) {
      if (mounted) _showMessage('No se pudo abandonar: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> addHabit(Habit habit, {
    HabitActionPreview? preview,
    Map<String, dynamic>? interaction,
  }) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final checked = preview ??
          await _habitActions.preview(habit.id, remove: false);
      await _habitActions.execute(checked, interaction: interaction);
      if (!mounted) return;
      _showMessage('“${habit.title}” se añadió a tus hábitos.');
      await _load();
    } catch (error) {
      if (mounted) _showMessage('No se pudo agregar el hábito: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  bool _isUnlocked(Habit habit) => HabitActionService.isUnlocked(
    habit,
    xp: xp,
    coins: coins,
    activeIds: active.map((entry) => entry.habit.id).toSet(),
  );

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
    if (HealthyAdaptive.isDark) {
      switch (category) {
        case 'Alimentación': return const Color(0xFF302A32);
        case 'Hidratación': return HealthyAdaptive.water;
        case 'Energía': return HealthyAdaptive.yellow;
        case 'Bienestar': return HealthyAdaptive.lavender;
        default: return HealthyAdaptive.surface;
      }
    }
    switch (category) {
      case 'Alimentación': return const Color(0xFFFFEFEC);
      case 'Hidratación': return const Color(0xFFE4F5FB);
      case 'Energía': return const Color(0xFFFFF5D9);
      case 'Bienestar': return const Color(0xFFF2ECFC);
      default: return HealthyAdaptive.surface;
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
    final difficultyOk =
        selectedDifficulty == 'Todos' || habit.difficulty == selectedDifficulty;
    final query = searchController.text.trim().toLowerCase();
    final searchOk =
        query.isEmpty ||
        habit.title.toLowerCase().contains(query) ||
        habit.category.toLowerCase().contains(query) ||
        habit.difficulty.toLowerCase().contains(query) ||
        habit.subtitle.toLowerCase().contains(query);
    return categoryOk && difficultyOk && searchOk;
  }

  List<_ActiveHabitEntry> get visibleActive {
    return active.where((entry) => matches(entry.habit)).toList();
  }

  List<Habit> get visibleRecommendations {
    return recommendations.where((habit) {
      final alreadyActive = active.any((entry) => entry.habit.id == habit.id);
      return !alreadyActive && matches(habit);
    }).toList();
  }

  Set<String> get _activeCategories =>
      active.map((entry) => entry.habit.category).toSet();

  List<Habit> get _suggestedHabits =>
      _recommendationService.rank(
        candidates: visibleRecommendations,
        history: usageHistory,
        activeCategories: _activeCategories,
        isUnlocked: _isUnlocked,
      ).take(8).toList();

  String _suggestionDescription() =>
      _recommendationService.explanation(
        history: usageHistory,
        activeCategories: _activeCategories,
      );

  Widget _twoRowRecommendationCarousel(List<Habit> habits, {
    String carouselId = 'habits-suggested-carousel',
  }) {
    if (habits.isEmpty) return const SizedBox.shrink();
    final popular = carouselId == 'habits-popular-carousel';
    final pager = popular ? _popularPager : _suggestedPager;
    final page = (popular ? _popularPage : _suggestedPage)
        .clamp(0, habits.length - 1).toInt();
    return Column(
      key: ValueKey(carouselId),
      children: [
        SizedBox(
          height: 285,
          child: PageView.builder(
            controller: pager,
            itemCount: habits.length,
            onPageChanged: (index) => setState(() {
              if (popular) {
                _popularPage = index;
              } else {
                _suggestedPage = index;
              }
            }),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 6),
              child: SingleChildScrollView(
                child: _recommendationCard(habits[index]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            tooltip: 'Hábito anterior',
            onPressed: page == 0
                ? null : () => pager.animateToPage(page - 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('${page + 1} de ${habits.length}',
            style: TextStyle(color: muted, fontWeight: FontWeight.w700,
                fontSize: 12)),
          const SizedBox(width: 12),
          for (var i = 0; i < habits.length && i < 8; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: i == page ? 14 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == page ? green : border,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          IconButton(
            tooltip: 'Siguiente hábito',
            onPressed: page >= habits.length - 1
                ? null : () => pager.animateToPage(page + 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ]),
      ],
    );
  }

  Widget _vistasHabitos() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Cómo ver los hábitos', style: TextStyle(
        color: navy, fontWeight: FontWeight.w700, fontSize: 12)),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, icon: Icon(Icons.view_list_rounded),
            label: Text('Lista')),
          ButtonSegment(value: 1, icon: Icon(Icons.grid_view_rounded),
            label: Text('Tarjetas')),
          ButtonSegment(value: 2, icon: Icon(Icons.swipe_rounded),
            label: Text('Deslizar')),
        ],
        selected: {_habitsView},
        showSelectedIcon: false,
        onSelectionChanged: (value) => setState(
          () => _habitsView = value.first),
        ),
      ),
    ]),
  );

  Widget _vistaDeRecomendaciones(List<Habit> habits, {bool popular = false}) {
    if (_habitsView == 2) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Desliza a los lados para explorar', style: TextStyle(
          fontSize: 12, color: muted)),
        const SizedBox(height: 8),
        _twoRowRecommendationCarousel(habits,
          carouselId: popular ? 'habits-popular-carousel'
              : 'habits-suggested-carousel'),
      ]);
    }
    if (_habitsView == 1) {
      return LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < 550 ? 1 : 2;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final habit in habits)
              SizedBox(
                width: width,
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        categoryBg(habit.category),
                        HealthyAdaptive.surface,
                      ]),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    ),
                    child: Center(
                      child: Icon(categoryIcon(habit.category),
                        color: categoryInk(habit.category), size: 48),
                    ),
                  ),
                  _recommendationCard(habit),
                ]),
              ),
          ],
        );
      });
    }
    return Column(children: [
      for (final habit in habits)
        Padding(padding: const EdgeInsets.only(bottom: 12),
          child: _recommendationCard(habit)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child:
            loading
                ? Center(child: CircularProgressIndicator(color: green))
                : Column(
                  children: [
                    _header(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        children: [
                          Text(
                            '¿Qué quieres mejorar?',
                            style: TextStyle(
                              color: navy,
                              fontSize: 28,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pequeños cambios, grandes resultados. '
                            'Elige tu siguiente misión.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            key: const ValueKey('personal-routines-entry'),
                            color: HealthyAdaptive.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(Icons.tune_rounded, color: green, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mis rutinas personales',
                                          style: TextStyle(
                                            color: navy,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Crea rutinas con varios ejercicios, ordénalos y ejecútalos paso a paso. Se guardan en este dispositivo y no conceden XP.',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Abrir rutinas personales',
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PersonalRoutinesScreen(),
                                      ),
                                    ),
                                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            color: HealthyAdaptive.surface,
                            child: ListTile(
                              key: const ValueKey('shared-habits-entry'),
                              leading: Icon(Icons.people_alt_outlined,
                                color: green),
                              title: const Text('Hábitos en pareja',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: const Text(
                                'Invita a un amigo y realicen el mismo hábito.'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                  const HabitosEnParejaScreen())),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _categoryGrid(),
                          const SizedBox(height: 18),
                          _difficultyFilter(),
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
                          Row(
                            children: [
                              Expanded(
                                child: _sectionHeader(
                                  showingFullCatalog
                                      ? 'Catálogo completo'
                                      : 'Hábitos sugeridos',
                                  '',
                                ),
                              ),
                              TextButton.icon(
                                key: const ValueKey('habits-catalog-toggle'),
                                onPressed: () => setState(
                                  () => showingFullCatalog = !showingFullCatalog,
                                ),
                                icon: Icon(
                                  showingFullCatalog
                                      ? Icons.auto_awesome_rounded
                                      : Icons.menu_book_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  showingFullCatalog
                                      ? 'Ver sugeridos'
                                      : 'Ver todos',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            showingFullCatalog
                                ? 'Estás viendo todos los hábitos. Pulsa «Ver sugeridos» para volver a una selección personalizada.'
                                : 'Estas son sugerencias para ti. Pulsa «Ver todos» para consultar todos los hábitos. ${_suggestionDescription()}',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          _vistasHabitos(),
                          if (visibleRecommendations.isEmpty)
                            _empty('No hay hábitos disponibles con estos filtros.')
                          else
                            _vistaDeRecomendaciones(showingFullCatalog
                              ? visibleRecommendations : _suggestedHabits),

                          if (!showingFullCatalog) ...[
                            const SizedBox(height: 24),
                            _sectionHeader('Hábitos populares', ''),
                            const SizedBox(height: 6),
                            Text(
                              'Basados en activaciones verificadas de la comunidad.',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            if (loadingPopularity)
                              const Center(child: CircularProgressIndicator())
                            else if (_popularHabits.isEmpty)
                              _empty(
                                'Aún no hay estadísticas públicas verificadas. '
                                'Los hábitos populares aparecerán cuando estén disponibles.',
                              )
                            else
                              _vistaDeRecomendaciones(
                                _popularHabits, popular: true,
                              ),
                          ],
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
                  fillColor: HealthyAdaptive.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            )
          else ...[
            Expanded(
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
              color: HealthyAdaptive.surface,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Buscar hábitos',
                onPressed: () {
                  setState(() => searching = true);
                },
                icon: Icon(Icons.search_rounded, color: navy, size: 25),
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
        duration: HealthyVisualEffects.duration(context, const Duration(milliseconds: 180)),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: categoryBg(category),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? color : HealthyAdaptive.border,
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
                style: TextStyle(
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

  Widget _difficultyFilter() {
    const difficulties = ['Todos', 'Sencillo', 'Moderado', 'Difícil'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dificultad',
          style: TextStyle(
            color: navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              difficulties.map((difficulty) {
                final selected = selectedDifficulty == difficulty;
                return ChoiceChip(
                  label: Text(difficulty),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      selectedDifficulty = difficulty;
                    });
                  },
                  selectedColor: HealthyAdaptive.mint,
                  backgroundColor: HealthyAdaptive.surface,
                  labelStyle: TextStyle(
                    color: selected ? HealthyAdaptive.text : muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(color: selected ? green : border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String trailing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing.isNotEmpty)
          Text(
            trailing,
            style: TextStyle(
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
    final done = attempt.hasReachedGoal;
    final remaining = (attempt.target - attempt.progress).clamp(
      0,
      attempt.target,
    );
    return HealthyMotionCard(
      key: ValueKey('active-habit-${habit.id}'),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        color: categoryBg(habit.category),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: HealthyAdaptive.border, width: 1.5),
        boxShadow: HealthyVisualEffects.allowDecorativeShadows
            ? [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 6))]
            : null,
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
                  color: HealthyAdaptive.yellow,
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
            style: TextStyle(
              color: navy,
              fontSize: 22,
              height: 1.18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            habit.subtitle,
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 15),
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
                '${attempt.progress} de ${attempt.target} sesiones',
                style: TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  done ? '¡Meta alcanzada!' : 'Faltan $remaining sesiones',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: muted, fontSize: 12),
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
                done ? 'Hábito completado' : 'Registrar sesión',
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
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            children: [
              TextButton.icon(
                key: ValueKey('share-habit-${habit.id}'),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                    HabitosEnParejaScreen(initialHabitId: habit.id))),
                icon: const Icon(Icons.people_alt_outlined, size: 17),
                label: const Text('En pareja'),
              ),
              TextButton.icon(
                onPressed: saving ? null : () => _confirmCancelHabit(entry),
                icon: const Icon(Icons.cancel_outlined, size: 17),
                label: const Text('Abandonar hábito'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFAD5151),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

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
            backgroundColor: HealthyAdaptive.surface,
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
        color: HealthyAdaptive.surface,
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
                  style: TextStyle(
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
                  style: TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  '${habit.target} sesiones para completar',
                  style: TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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
                      style: TextStyle(
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
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: canAdd ? () => _confirmAddHabit(habit) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: HealthyAdaptive.border,
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
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(Icons.spa_outlined, color: green, size: 30),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _encouragement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthyAdaptive.mint,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
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
