import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuración de intensidad visual. No desactiva ninguna funcionalidad.
enum HealthyVisualMode { lite, normal }

/// Preferencia global independiente del tema claro/oscuro y de Firebase.
class HealthyVisualController extends ChangeNotifier {
  HealthyVisualController._();

  static final HealthyVisualController instance = HealthyVisualController._();
  static const preferenceKey = 'healthy_habit_visual_mode_v1';

  HealthyVisualMode _mode = HealthyVisualMode.normal;
  HealthyVisualMode get mode => _mode;
  bool get isLite => _mode == HealthyVisualMode.lite;

  static HealthyVisualMode parse(String? value) =>
      value == 'Lite' || value == 'lite'
          ? HealthyVisualMode.lite
          : HealthyVisualMode.normal;

  static String label(HealthyVisualMode value) =>
      value == HealthyVisualMode.lite ? 'Lite' : 'Normal';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final next = parse(prefs.getString(preferenceKey));
    if (next == _mode) return;
    _mode = next;
    notifyListeners();
  }

  Future<void> select(HealthyVisualMode next) async {
    if (next == _mode) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(preferenceKey, label(next));
    if (!saved) throw StateError('No se pudo guardar el modo visual');
    _mode = next;
    notifyListeners();
  }
}

/// Un único punto de consulta para futuras animaciones y efectos.
/// Se respeta el ajuste de accesibilidad de reducir animaciones del sistema.
class HealthyVisualEffects {
  static bool enabled(BuildContext context) =>
      !HealthyVisualController.instance.isLite &&
      !MediaQuery.disableAnimationsOf(context);

  static Duration duration(BuildContext context, Duration normal) =>
      enabled(context) ? normal : Duration.zero;

  static bool get allowDecorativeShadows =>
      !HealthyVisualController.instance.isLite;
}
