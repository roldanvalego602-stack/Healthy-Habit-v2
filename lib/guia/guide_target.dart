import 'package:flutter/material.dart';

/// Claves estables para localizar controles de la pantalla de Hábitos.
/// Son referencias visuales: no activan acciones ni modifican información.
class HealthyGuideTargets {
  HealthyGuideTargets._();

  static final GlobalKey habitsHeader = GlobalKey(debugLabel: 'guide-habits-header');
  static final GlobalKey habitsRoutines = GlobalKey(debugLabel: 'guide-habits-routines');
  static final GlobalKey habitsCategories = GlobalKey(debugLabel: 'guide-habits-categories');
  static final GlobalKey habitsActive = GlobalKey(debugLabel: 'guide-habits-active');
  static final GlobalKey habitsCard = GlobalKey(debugLabel: 'guide-habits-first-card');

  static GlobalKey? forHabitsStep(int index) {
    switch (index) {
      case 0: return habitsActive;
      case 1: return habitsCategories;
      case 2: return habitsHeader;
      case 3: return habitsRoutines;
      default: return null;
    }
  }
}
