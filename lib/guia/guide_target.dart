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

  // Una clave por objetivo, exclusivamente para widgets montados y visibles.
  static final GlobalKey homeHeader = GlobalKey(debugLabel: 'guide-home-header');
  static final GlobalKey homeCoins = GlobalKey(debugLabel: 'guide-home-coins');
  static final GlobalKey homeLevel = GlobalKey(debugLabel: 'guide-home-level');
  static final GlobalKey mainNavigation = GlobalKey(debugLabel: 'guide-main-navigation');

  static final GlobalKey shopHeader = GlobalKey(debugLabel: 'guide-shop-header');
  static final GlobalKey shopFeatured = GlobalKey(debugLabel: 'guide-shop-featured');
  static final GlobalKey shopCategories = GlobalKey(debugLabel: 'guide-shop-categories');
  static final GlobalKey shopRewards = GlobalKey(debugLabel: 'guide-shop-rewards');

  static final GlobalKey catalogTabs = GlobalKey(debugLabel: 'guide-catalog-tabs');
  static final GlobalKey catalogSearch = GlobalKey(debugLabel: 'guide-catalog-search');
  static final GlobalKey catalogFilters = GlobalKey(debugLabel: 'guide-catalog-filters');
  static final GlobalKey catalogOptions = GlobalKey(debugLabel: 'guide-catalog-options');

  static final GlobalKey profileHeader = GlobalKey(debugLabel: 'guide-profile-header');
  static final GlobalKey profileIdentity = GlobalKey(debugLabel: 'guide-profile-identity');
  static final GlobalKey profileFriends = GlobalKey(debugLabel: 'guide-profile-friends');
  static final GlobalKey profileSettings = GlobalKey(debugLabel: 'guide-profile-settings');

  static GlobalKey? forSectionStep(String section, int index) {
    final keys = switch (section) {
      'inicio' => <GlobalKey>[homeHeader, homeLevel, homeCoins, mainNavigation],
      'tienda' => <GlobalKey>[shopHeader, shopCategories, shopRewards, shopFeatured],
      'catalogo' => <GlobalKey>[catalogTabs, catalogSearch, catalogFilters, catalogOptions],
      'perfil' => <GlobalKey>[profileIdentity, profileHeader, profileFriends, profileSettings],
      _ => <GlobalKey>[],
    };
    return index >= 0 && index < keys.length ? keys[index] : null;
  }

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
