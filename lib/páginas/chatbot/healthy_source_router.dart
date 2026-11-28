import 'healthy_hybrid_knowledge.dart';
import 'healthy_web_search_service.dart';

/// Determina el destino de una solicitud antes de consultar servicios.
/// No ejecuta operaciones y nunca habilita búsquedas automáticas.
enum HealthySourceRoute { local, encyclopedia, privateData, sensitive, clarification }

class HealthySourceDecision {
  const HealthySourceDecision(this.route, {this.query = '', this.message = ''});
  final HealthySourceRoute route;
  final String query;
  final String message;
}

class HealthySourceRouter {
  const HealthySourceRouter._();

  static final _private = RegExp(
    r'\b(mi|mis|mio|mios|cuanto tengo|cuantas tengo|'
    r'comprar|compra|canjear|activar|agregar|registra|registrar|'
    r'eliminar|borrar|borra|cancela|cancelar|desactivar)\b',
  );
  static final _appData = RegExp(
    r'\b(cuenta|perfil|saldo|xp|habit coins|habitcoins|monedas|'
    r'racha|inventario|misiones|desafios|amigos|contrasena|'
    r'correo|sesion|tienda|compras)\b',
  );
  static final _sensitive = RegExp(
    r'\b(suicidio|suicidarme|autolesion|matarme|asfixia|'
    r'no puedo respirar|intoxicacion|envenenamiento|'
    r'diagnostico|diagnosticar|tratamiento|receta|recetar|'
    r'dosis|medicamento|insulina|alergia|embarazo|'
    r'dolor en el pecho|emergencia)\b',
  );

  static HealthySourceDecision decide(String input) {
    final query = HealthyWebSearchService.extractQuery(input);
    if (query == null) {
      return const HealthySourceDecision(HealthySourceRoute.local);
    }
    final clean = HealthyKnowledgeIndex.normalize(query);
    if (clean.length < 3 || clean.length > 120) {
      return const HealthySourceDecision(HealthySourceRoute.clarification,
        message: 'Escribe un tema específico de entre 3 y 120 caracteres '
            'para consultar Wikipedia en español.');
    }
    if (_sensitive.hasMatch(clean)) {
      return const HealthySourceDecision(HealthySourceRoute.sensitive,
        message: 'Esa consulta puede requerir información sanitaria '
            'especializada. No la enviaré a Wikipedia. '
            'Puedes formular una duda general y revisar fuentes de salud '
            'fiables; ante una urgencia busca atención inmediata.');
    }
    if ((_private.hasMatch(clean) && _appData.hasMatch(clean)) ||
        _appData.hasMatch(clean) && RegExp(r'\b(mi|mis|mio|mios)\b').hasMatch(clean)) {
      return const HealthySourceDecision(HealthySourceRoute.privateData,
        message: 'Esa solicitud parece referirse a tu cuenta o a una acción '
            'de Healthy Habit. Por privacidad no la enviaré a Wikipedia. '
            'Pregúntame directamente sin «buscar en internet» para usar '
            'las funciones internas de la aplicación.');
    }
    return HealthySourceDecision(HealthySourceRoute.encyclopedia, query: query);
  }
}
