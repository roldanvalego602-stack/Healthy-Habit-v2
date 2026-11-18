import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencia de apariencia del dispositivo. No depende de una sesión Firebase.
class HealthyThemeController extends ChangeNotifier {
  HealthyThemeController._();
  static final HealthyThemeController instance = HealthyThemeController._();
  static const preferenceKey = 'healthy_habit_theme_v1';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  static ThemeMode parse(String? value) {
    switch (value) {
      case 'Claro':
      case 'light':
        return ThemeMode.light;
      case 'Oscuro':
      case 'dark':
        return ThemeMode.dark;
      case 'Sistema':
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light; // Mantiene la apariencia clara existente.
    }
  }

  static String label(ThemeMode value) {
    switch (value) {
      case ThemeMode.light: return 'Claro';
      case ThemeMode.dark: return 'Oscuro';
      case ThemeMode.system: return 'Sistema';
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = parse(prefs.getString(preferenceKey));
    notifyListeners();
  }

  Future<void> select(ThemeMode next) async {
    if (next == _mode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, label(next));
    _mode = next;
    notifyListeners();
  }
}

class HealthyThemes {
  static const _green = Color(0xFF00C88C);
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _green, brightness: Brightness.light,
      surface: const Color(0xFFF7F9F8),
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F9F8),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F9F8),
      foregroundColor: Color(0xFF0E1A30),
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _green, brightness: Brightness.dark,
      surface: const Color(0xFF172630),
    ),
    scaffoldBackgroundColor: const Color(0xFF101923),
    cardColor: const Color(0xFF1B2935),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF101923),
      foregroundColor: Color(0xFFF1F5F6),
    ),
  );
}
