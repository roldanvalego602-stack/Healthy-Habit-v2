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

/// Tokens compartidos para migrar pantallas que antes tenían colores fijos.
/// La instancia global reconstruye MaterialApp al cambiar la preferencia.
class HealthyAdaptive {
  static bool get isDark {
    final mode = HealthyThemeController.instance.mode;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  static Color get background =>
      isDark ? const Color(0xFF101923) : const Color(0xFFF7F9F8);
  static Color get surface =>
      isDark ? const Color(0xFF1B2935) : Colors.white;
  static Color get surfaceAlt =>
      isDark ? const Color(0xFF263947) : const Color(0xFFEAF3EF);
  static Color get text =>
      isDark ? const Color(0xFFF1F5F6) : const Color(0xFF193344);
  static Color get muted =>
      isDark ? const Color(0xFFB4C1CB) : const Color(0xFF71879A);
  static Color get border =>
      isDark ? const Color(0xFF344A57) : const Color(0xFFE0EAE6);
  static Color get accent =>
      isDark ? const Color(0xFF6CD3A1) : const Color(0xFF078765);

  /// Tarjetas de categorías conservan su identidad cromática, sin
  /// dejar texto oscuro sobre un panel oscuro.
  static Color get water =>
      isDark ? const Color(0xFF183E4F) : const Color(0xFFE8F6FC);
  static Color get waterInk =>
      isDark ? const Color(0xFF8FC9FF) : const Color(0xFF2B7FD1);
  static Color get lavender =>
      isDark ? const Color(0xFF35294A) : const Color(0xFFF0EBFC);
  static Color get mint =>
      isDark ? const Color(0xFF1D463A) : const Color(0xFFE2F7ED);
  static Color get yellow =>
      isDark ? const Color(0xFF4B3A20) : const Color(0xFFFDE89D);
}
