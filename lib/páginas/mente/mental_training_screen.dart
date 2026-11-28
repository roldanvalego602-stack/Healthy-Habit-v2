import 'package:flutter/material.dart';

import '../../tema/healthy_theme.dart';
import 'mental_progress_service.dart';
import 'mental_puzzles.dart';
import 'mental_sudoku_screen.dart';
import 'mental_word_search_screen.dart';

/// Rutinas mentales complementarias. No requieren fotografiar actividades,
/// usar la cámara ni almacenar datos de salud.
class MentalTrainingScreen extends StatefulWidget {
  const MentalTrainingScreen({super.key});

  @override
  State<MentalTrainingScreen> createState() => _MentalTrainingScreenState();
}

class _MentalTrainingScreenState extends State<MentalTrainingScreen> {
  final _service = const MentalProgressService();
  late final DateTime _day;
  MentalDailyProgress? _progress;

  @override
  void initState() {
    super.initState();
    _day = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    final progress = await _service.progress(_day);
    if (mounted) setState(() => _progress = progress);
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => page));
    await _load();
  }

  Widget _gameCard({
    required String title,
    required String description,
    required IconData icon,
    required bool completed,
    required VoidCallback onTap,
    required String action,
    required Key key,
  }) {
    return Card(
      key: key,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HealthyAdaptive.accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: HealthyAdaptive.accent, size: 26),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(title,
                        style: TextStyle(
                          color: HealthyAdaptive.text,
                          fontSize: 17, fontWeight: FontWeight.w800,
                        ))),
                      if (completed)
                        Icon(Icons.check_circle_rounded,
                          color: HealthyAdaptive.accent),
                    ]),
                    const SizedBox(height: 5),
                    Text(description,
                      style: TextStyle(
                        color: HealthyAdaptive.muted,
                        fontSize: 12, height: 1.4)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Text(completed ? 'Completado hoy' : action,
                        style: TextStyle(
                          color: HealthyAdaptive.accent,
                          fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded,
                        color: HealthyAdaptive.accent, size: 15),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(title: const Text('Entrena tu mente')),
      body: progress == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        HealthyAdaptive.accent.withValues(alpha: .18),
                        HealthyAdaptive.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: HealthyAdaptive.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.psychology_alt_rounded,
                          color: HealthyAdaptive.accent, size: 32),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Un poco de práctica cada día',
                          style: TextStyle(
                            color: HealthyAdaptive.text,
                            fontSize: 20, fontWeight: FontWeight.w900))),
                      ]),
                      const SizedBox(height: 10),
                      Text('Practica atención, lógica y vocabulario '
                          'con retos breves. No es una prueba de '
                          'inteligencia ni un tratamiento médico.',
                        style: TextStyle(
                          color: HealthyAdaptive.text,
                          fontSize: 12.5, height: 1.4)),
                      const SizedBox(height: 17),
                      Row(children: [
                        Expanded(child: _metric(
                          '${progress.completed}/2',
                          'ejercicios hoy',
                        )),
                        Expanded(child: _metric(
                          '${progress.streak}',
                          'días de constancia',
                        )),
                      ]),
                      const SizedBox(height: 13),
                      LinearProgressIndicator(
                        value: progress.completed / 2,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: 7),
                      Text('Reto diario · '
                          '${MentalDailyKey.forDate(_day)}',
                        style: TextStyle(
                          color: HealthyAdaptive.muted, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _gameCard(
                  key: const ValueKey('mental-open-sudoku'),
                  title: 'Sudoku',
                  description: 'Rellena una cuadrícula 9×9 '
                    'usando lógica. Tres pistas opcionales y '
                    'un tablero distinto cada día.',
                  icon: Icons.grid_on_rounded,
                  completed: progress.sudoku,
                  action: 'Resolver el Sudoku de hoy',
                  onTap: () => _open(const MentalSudokuScreen()),
                ),
                const SizedBox(height: 8),
                _gameCard(
                  key: const ValueKey('mental-open-wordsearch'),
                  title: 'Sopa de letras',
                  description: 'Encuentra siete palabras '
                    'relacionadas con el aprendizaje y la calma. '
                    'Puedes seleccionar en ocho direcciones.',
                  icon: Icons.menu_book_rounded,
                  completed: progress.wordSearch,
                  action: 'Buscar palabras',
                  onTap: () => _open(const MentalWordSearchScreen()),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Estos hábitos mentales guardan su avance '
                      'en el dispositivo, separado por cuenta y día. '
                      'No se envían resultados de los ejercicios '
                      'a Firebase ni se conceden XP o Habit Coins. '
                      'Cuando la beta tenga un validador oficial '
                      'podrán integrarse sin premiar datos del cliente.',
                    style: TextStyle(
                      color: HealthyAdaptive.muted,
                      fontSize: 11, height: 1.5)),
                ),
              ],
            ),
    );
  }

  Widget _metric(String amount, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(amount, style: TextStyle(
        color: HealthyAdaptive.text, fontSize: 26,
        fontWeight: FontWeight.w900,
      )),
      Text(label, style: TextStyle(
        color: HealthyAdaptive.muted, fontSize: 11)),
    ],
  );
}
