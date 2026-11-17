import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// Intenciones reconocidas por la primera versión de Mr. Healthy.
enum MrHealthyIntent {
  showPendingHabits,
  showProgress,
  showStreak,
  openChallenges,
  registerHabit,
  unknown,
}

class MrHealthyIntentResult {
  const MrHealthyIntentResult({
    required this.intent,
    required this.method,
    required this.requiresConfirmation,
  });

  final MrHealthyIntent intent;
  final String method;
  final bool requiresConfirmation;

  factory MrHealthyIntentResult.fromMap(Map<String, dynamic> data) {
    final name = data['intent'];
    final method = data['method'];
    final requiresConfirmation = data['requiresConfirmation'];
    if (name is! String ||
        method is! String ||
        requiresConfirmation is! bool) {
      throw const FormatException('Respuesta inválida del servidor.');
    }

    const values = <String, MrHealthyIntent>{
      'SHOW_PENDING_HABITS': MrHealthyIntent.showPendingHabits,
      'SHOW_PROGRESS': MrHealthyIntent.showProgress,
      'SHOW_STREAK': MrHealthyIntent.showStreak,
      'OPEN_CHALLENGES': MrHealthyIntent.openChallenges,
      'REGISTER_HABIT': MrHealthyIntent.registerHabit,
      'UNKNOWN': MrHealthyIntent.unknown,
    };

    // Un identificador desconocido no autoriza acciones ni navegación.
    final intent = values[name] ?? MrHealthyIntent.unknown;
    return MrHealthyIntentResult(
      intent: intent,
      method: method,
      requiresConfirmation:
          intent == MrHealthyIntent.registerHabit || requiresConfirmation,
    );
  }
}

/// Transporte inyectable: permite probar la conexión sin acceso a Internet.
typedef MrHealthyIntentTransport =
    Future<Map<String, dynamic>> Function(String message);

class MrHealthyIntentService {
  MrHealthyIntentService({MrHealthyIntentTransport? transport})
      : _transport = transport ?? _callFirebase;

  final MrHealthyIntentTransport _transport;

  static Future<Map<String, dynamic>> _callFirebase(String message) async {
    final functions = FirebaseFunctions.instanceFor(
      app: Firebase.app(),
      region: 'us-central1',
    );
    final callable = functions.httpsCallable(
      'interpretMrHealthyIntent',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
    );

    final result = await callable.call(<String, dynamic>{'text': message});
    if (result.data is! Map) {
      throw const FormatException('El servidor devolvió datos no válidos.');
    }
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<MrHealthyIntentResult> interpret(String message) async {
    final text = message.trim();
    if (text.isEmpty || text.length > 500) {
      throw ArgumentError('El mensaje debe contener entre 1 y 500 caracteres.');
    }
    final data = await _transport(text);
    return MrHealthyIntentResult.fromMap(data);
  }
}
