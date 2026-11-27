import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'healthy_motion.dart';

enum HealthyThemeStyle { original, emeraldChristmas }

extension HealthyThemeStyleLabel on HealthyThemeStyle {
  String get label => switch (this) {
    HealthyThemeStyle.original => 'Healthy Original',
    HealthyThemeStyle.emeraldChristmas => 'Navidad Esmeralda',
  };
}

/// Preferencia de apariencia del dispositivo. No depende de una sesión Firebase.
class HealthyThemeController extends ChangeNotifier {
  HealthyThemeController._();
  static final HealthyThemeController instance = HealthyThemeController._();
  static const preferenceKey = 'healthy_habit_theme_v1';
  static const stylePreferenceKey = 'healthy_habit_style_v1';

  // Propiedad confirmada por Firestore; nunca confiar en un booleano local
  // para activar cosméticos de pago.
  bool _ownsCosmos = false;
  bool _equippedCosmos = false;
  bool get cosmosActive => _ownsCosmos && _equippedCosmos;
  void syncCosmos({required bool owned, required bool equipped}) {
    if (_ownsCosmos == owned && _equippedCosmos == equipped) return;
    _ownsCosmos = owned;
    _equippedCosmos = equipped;
    notifyListeners();
  }

  HealthyThemeStyle _style = HealthyThemeStyle.original;
  HealthyThemeStyle get style => _style;

  static HealthyThemeStyle parseStyle(String? value) =>
      value == HealthyThemeStyle.emeraldChristmas.label
          ? HealthyThemeStyle.emeraldChristmas
          : HealthyThemeStyle.original;

  Future<void> selectStyle(HealthyThemeStyle next) async {
    if (next == _style) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(stylePreferenceKey, next.label);
    _style = next;
    notifyListeners();
  }

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
    _style = parseStyle(prefs.getString(stylePreferenceKey));
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
  static ThemeData light() {
    if (HealthyThemeController.instance.cosmosActive) return _cosmos();
    if (HealthyThemeController.instance.style ==
        HealthyThemeStyle.emeraldChristmas) {
      return _christmas(Brightness.light);
    }
    return ThemeData(
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: HealthyRouteTransitions(),
      TargetPlatform.iOS: HealthyRouteTransitions(),
      TargetPlatform.linux: HealthyRouteTransitions(),
      TargetPlatform.windows: HealthyRouteTransitions(),
      TargetPlatform.macOS: HealthyRouteTransitions(),
    }),
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
  }

  static ThemeData dark() {
    if (HealthyThemeController.instance.cosmosActive) return _cosmos();
    if (HealthyThemeController.instance.style ==
        HealthyThemeStyle.emeraldChristmas) {
      return _christmas(Brightness.dark);
    }
    return ThemeData(
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

  static ThemeData _cosmos() {
    const surface = Color(0xFF141E3A);
    const background = Color(0xFF060816);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF85CCFF),
      brightness: Brightness.dark,
      primary: const Color(0xFF85CCFF),
      secondary: const Color(0xFFC59FFF),
      tertiary: const Color(0xFF57E5FF),
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: HealthyRouteTransitions(),
        TargetPlatform.iOS: HealthyRouteTransitions(),
        TargetPlatform.linux: HealthyRouteTransitions(),
        TargetPlatform.windows: HealthyRouteTransitions(),
        TargetPlatform.macOS: HealthyRouteTransitions(),
      }),
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background.withValues(alpha: .68),
      cardColor: surface.withValues(alpha: .88),
      appBarTheme: AppBarTheme(
        backgroundColor: background.withValues(alpha: .8),
        foregroundColor: const Color(0xFFF4F7FF),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF141E3A),
        indicatorColor: const Color(0xFF263D70),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF85CCFF),
          foregroundColor: const Color(0xFF081426),
        ),
      ),
      dividerColor: const Color(0xFF526391),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF57E5FF),
        foregroundColor: Color(0xFF081426),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xEF1C2850),
        labelStyle: const TextStyle(color: Color(0xFFB6C8E3)),
        hintStyle: const TextStyle(color: Color(0xFF92A6CA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF647BB9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF52699F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF57E5FF),
            width: 1.7),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC6E7FF),
          side: const BorderSide(color: Color(0xFF647BB9)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF24345F),
        selectedColor: const Color(0xFF36588B),
        side: const BorderSide(color: Color(0xFF536AA0)),
        labelStyle: const TextStyle(color: Color(0xFFF4F7FF)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C2850),
        contentTextStyle: const TextStyle(color: Color(0xFFF4F7FF)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF57E5FF),
        linearTrackColor: Color(0xFF24345F),
      ),
    );
  }

  static ThemeData _christmas(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    const evergreen = Color(0xFF087B58);
    const ruby = Color(0xFFB9364D);
    const gold = Color(0xFFD6A646);
    final background = dark
        ? const Color(0xFF101E1C) : const Color(0xFFF7FAF6);
    final surface = dark
        ? const Color(0xFF1C302B) : Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: evergreen,
      brightness: brightness,
      primary: dark ? const Color(0xFF75D9AE) : evergreen,
      secondary: dark ? const Color(0xFFE7B969) : ruby,
      tertiary: gold,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: dark
            ? const Color(0xFFF2F8F3) : const Color(0xFF12372F),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: dark
            ? const Color(0xFF285F4A) : const Color(0xFFDDF4E9),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark
            ? const Color(0xFF264B40) : const Color(0xFFE8F4EC),
        selectedColor: dark
            ? const Color(0xFF3C715A) : const Color(0xFFC6EBD9),
      ),
      dividerColor: dark
          ? const Color(0xFF36574D) : const Color(0xFFD8E8DF),
    );
  }
}

/// Tokens compartidos para migrar pantallas que antes tenían colores fijos.
/// La instancia global reconstruye MaterialApp al cambiar la preferencia.
class HealthyAdaptive {
  static bool get isCosmos => HealthyThemeController.instance.cosmosActive;
  static bool get isChristmas =>
      HealthyThemeController.instance.style ==
      HealthyThemeStyle.emeraldChristmas;
  static bool get isDark {
    if (isCosmos) return true;
    final mode = HealthyThemeController.instance.mode;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  static Color get background =>
      isCosmos ? const Color(0xB8060816) :
      isChristmas ? (isDark ? const Color(0xFF101E1C) : const Color(0xFFF7FAF6)) : (isDark ? const Color(0xFF101923) : const Color(0xFFF7F9F8));
  static Color get surface =>
      isCosmos ? const Color(0xE6141E3A) :
      isChristmas ? (isDark ? const Color(0xFF1C302B) : Colors.white) : (isDark ? const Color(0xFF1B2935) : Colors.white);
  static Color get surfaceAlt =>
      isCosmos ? const Color(0xE61C2850) :
      isChristmas ? (isDark ? const Color(0xFF294B3E) : const Color(0xFFE8F4EC)) : (isDark ? const Color(0xFF263947) : const Color(0xFFEAF3EF));
  static Color get text =>
      isCosmos ? const Color(0xFFF4F7FF) :
      isChristmas ? (isDark ? const Color(0xFFF2F8F3) : const Color(0xFF12372F)) : (isDark ? const Color(0xFFF1F5F6) : const Color(0xFF193344));
  static Color get muted =>
      isCosmos ? const Color(0xFFB6C8E3) :
      isChristmas ? (isDark ? const Color(0xFFB8D0C3) : const Color(0xFF627E70)) : (isDark ? const Color(0xFFB4C1CB) : const Color(0xFF71879A));
  static Color get border =>
      isCosmos ? const Color(0xFF647BB9) :
      isChristmas ? (isDark ? const Color(0xFF36574D) : const Color(0xFFD8E8DF)) : (isDark ? const Color(0xFF344A57) : const Color(0xFFE0EAE6));
  static Color get accent =>
      isCosmos ? const Color(0xFF85CCFF) :
      isChristmas ? (isDark ? const Color(0xFF75D9AE) : const Color(0xFF087B58)) : (isDark ? const Color(0xFF6CD3A1) : const Color(0xFF078765));

  /// Tarjetas de categorías conservan su identidad cromática, sin
  /// dejar texto oscuro sobre un panel oscuro.
  static Color get water =>
      isCosmos ? const Color(0xFF183A65) :
      isDark ? const Color(0xFF183E4F) : const Color(0xFFE8F6FC);
  static Color get waterInk =>
      isCosmos ? const Color(0xFF9EEBFF) :
      isDark ? const Color(0xFF8FC9FF) : const Color(0xFF2B7FD1);
  static Color get lavender =>
      isCosmos ? const Color(0xFF392858) :
      isDark ? const Color(0xFF35294A) : const Color(0xFFF0EBFC);
  static Color get mint =>
      isCosmos ? const Color(0xFF143C53) :
      isDark ? const Color(0xFF1D463A) : const Color(0xFFE2F7ED);
  static Color get yellow =>
      isCosmos ? const Color(0xFF47405E) :
      isDark ? const Color(0xFF4B3A20) : const Color(0xFFFDE89D);
}
