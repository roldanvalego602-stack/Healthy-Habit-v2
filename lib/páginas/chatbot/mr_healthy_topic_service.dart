import 'dart:convert';
import 'package:flutter/services.dart';
import 'healthy_assistant_reply.dart';
import 'healthy_hybrid_knowledge.dart';

/// Banco editorial de preguntas y respuestas. No es modelo de lenguaje,
/// no accede a Firestore ni ejecuta acciones; su salida es solo texto.
class MrHealthyTopic {
  const MrHealthyTopic({
    required this.id, required this.category, required this.terms,
    required this.answer, required this.followUp, required this.detail,
  });
  final String id, category, answer, followUp, detail;
  final List<String> terms;

  factory MrHealthyTopic.fromJson(Map<String, dynamic> value) {
    return MrHealthyTopic(
      id: value['id'] as String,
      category: value['category'] as String,
      terms: (value['terms'] as List).cast<String>(),
      answer: value['answer'] as String,
      followUp: value['followUp'] as String,
      detail: value['detail'] as String,
    );
  }
}

/// 25 plantillas * >=4 expresiones de cada uno de los 115 temas:
/// al menos 11,500 formulaciones candidatas, aunque algunos duplicados
/// entre temas se descartan. Nunca se confunden con 11,500 respuestas
/// redactadas de forma independiente ni con entrenamiento neuronal.
class MrHealthyResponseBank {
  const MrHealthyResponseBank(this.topics);

  final List<MrHealthyTopic> topics;

  static const templates = <String>[
    '{tema}',
    '¿qué es {tema}?',
    '¿qué significa {tema}?',
    'explícame {tema}',
    'háblame de {tema}',
    'quiero saber de {tema}',
    'dime sobre {tema}',
    'necesito información de {tema}',
    'tengo una duda sobre {tema}',
    'cuéntame sobre {tema}',
    'quiero aprender sobre {tema}',
    'me interesa {tema}',
    'ayúdame con {tema}',
    '¿cómo funciona {tema}?',
    '¿qué debo saber sobre {tema}?',
    '¿qué me puedes decir de {tema}?',
    'podrías explicarme {tema}',
    '¿qué sabes de {tema}?',
    'orientación sobre {tema}',
    'consejos acerca de {tema}',
    'tengo preguntas sobre {tema}',
    'información sobre {tema}',
    'quiero entender {tema}',
    'explícamelo: {tema}',
    'tengo curiosidad por {tema}',
  ];

  late final Map<String, MrHealthyTopic> _topicsById =
      {for (final topic in topics) topic.id: topic};

  late final Map<String, MrHealthyTopic> _exactIndex = _buildIndex();

  static String normalize(String text) =>
      HealthyKnowledgeIndex.normalize(text);

  /// Cuenta únicamente expresiones distintas que tienen un tema inequívoco.
  int get recognizedPhrasings => _exactIndex.length;

  Map<String, MrHealthyTopic> _buildIndex() {
    final result = <String, MrHealthyTopic>{};
    final ambiguous = <String>{};
    for (final topic in topics) {
      for (final term in topic.terms) {
        for (final template in templates) {
          final key = normalize(template.replaceAll('{tema}', term));
          if (key.isEmpty || ambiguous.contains(key)) continue;
          final existing = result[key];
          if (existing != null && existing.id != topic.id) {
            result.remove(key);
            ambiguous.add(key);
          } else {
            result[key] = topic;
          }
        }
      }
    }
    return result;
  }

  static MrHealthyResponseBank fromJsonString(String raw) {
    final document = jsonDecode(raw) as Map<String, dynamic>;
    if (document['schemaVersion'] != 2 || document['language'] != 'es') {
      throw const FormatException('Versión del banco no compatible');
    }
    final records = (document['entries'] as List)
        .map((e) => MrHealthyTopic.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    if (records.isEmpty ||
        records.map((t) => t.id).toSet().length != records.length ||
        records.any((t) => t.terms.length < 4 ||
            t.answer.trim().isEmpty || t.followUp.trim().isEmpty ||
            t.detail.trim().isEmpty)) {
      throw const FormatException('Banco de diálogo incompleto o duplicado');
    }
    return MrHealthyResponseBank(records);
  }

  static final RegExp _continuation = RegExp(
    r'^(que mas|dime mas|explicame mas|cuentame mas|'
    r'dame un ejemplo|puedes ampliar|me explicas mejor|'
    r'y eso|y como|por que|porque|y entonces|'
    r'como lo hago|como funciona|y despues|'
    r'que recomiendas|y si|otro ejemplo|si|claro|vale|'
    r'una economica|economica|barata|una facil|facil|'
    r'para principiantes|con ejemplos|paso a paso|'
    r'una rapida|rapida|la primera|la segunda)\??$',
  );

    static final RegExp _referentialFollowUp = RegExp(
    r'^(y si |y con |y cuando |y en caso de |'
    r'le pongo |le agrego |y eso |y lo |'
    r'se puede combinar |puedo combinarlo |'
    r'y que pasa si |y de noche )',
  );

  static bool isFollowUpPhrase(String input) {
    final q = normalize(input);
    return _continuation.hasMatch(q) || _referentialFollowUp.hasMatch(q);
  }

  static final RegExp _riskTerms = RegExp(
    r'\b(alergia|asfixia|intoxicacion|envenenamiento|'
    r'dolor fuerte|pecho|desmayo|embaraz|lactancia|'
    r'diabetes|cancer|enfermedad|tratamiento|'
    r'medicamento|diagnostico|dosis|adelgazar rapido|'
    r'comer nada|vomitar|laxantes|autolesion|suicidio)\b',
  );

  static final RegExp _unsafeRequests = RegExp(
    r'\b(cuantas calorias|cuantos gramos|cuantos mg|'
    r'cuanta proteina|cuanto debo|dosis exacta|'
    r'cantidad exacta|recetame|diagnostica|'
    r'cura|curarme|tratame|debo tomar)\b',
  );

  // La app y seguridad operativa se resuelven en HealthyAssistantEngine.
  static final RegExp _operationalCommands = RegExp(
    r'^(agrega|agregar|anade|anadir|elimina|eliminar|'
    r'quita|quitar|compra|comprar|cancela|cancelar|'
    r'borra|borrar|abre|abrir|pon|activa|desactiva)\b',
  );

  static bool _shouldDeferToSpecialist(String query) {
    if (_riskTerms.hasMatch(query) || _unsafeRequests.hasMatch(query) ||
        _operationalCommands.hasMatch(query)) return true;
    // Preserve the existing, more specific egg/cooking safety cards.
    return query.contains('huevo') && RegExp(
      r'\b(jamon|crudo|salmonella|coccion|danino|dano|peligroso)\b',
    ).hasMatch(query);
  }

  /// Returns null if ambiguous. No silent guesses on sensitive questions.
  HealthyAssistantReply? answer(
    String input, {
    String previousTopicId = '',
    int followUpDepth = 0,
  }) {
    final q = normalize(input);
    if (q.isEmpty || _shouldDeferToSpecialist(q)) return null;

    if (isFollowUpPhrase(q) && previousTopicId.isNotEmpty) {
      final previous = _topicsById[previousTopicId];
      if (previous == null || followUpDepth >= 3) return null;
      if (_referentialFollowUp.hasMatch(q)) {
        return HealthyAssistantReply(
          'Seguimos hablando de ${previous.terms.first}. '
          'Tu pregunta añade un detalle nuevo y no quiero asumir '
          'cantidades, ingredientes o condiciones. '
          '${previous.detail} ¿Puedes concretar a qué te refieres?',
          card: 'topic', actionArgument: previous.id,
          knowledgeId: previous.id,
        );
      }
      return HealthyAssistantReply(
        followUpDepth == 0
            ? '${previous.detail}\n\n${previous.followUp}'
            : followUpDepth == 1
                ? 'Para orientarte mejor sobre ${previous.terms.first}, '
                    'dime qué parte quieres aplicar a tu situación. '
                    '${previous.followUp}'
                : 'Puedo seguir con un aspecto concreto de '
                    '${previous.terms.first}, pero no quiero repetir '
                    'información o suponer detalles personales. '
                    '${previous.followUp}',
        card: 'topic',
        actionArgument: previous.id,
        knowledgeId: previous.id,
      );
    }

    var match = _exactIndex[q];
    if (match == null && q.length > 8) {
      // Only accept a unique, sufficiently specific alias as a whole phrase.
      // Single-word matches are too risky for arbitrary questions.
      final candidates = <MrHealthyTopic>{};
      for (final topic in topics) {
        if (topic.terms.any((term) {
          final alias = normalize(term);
          return alias.split(' ').length >= 2 && alias.length >= 9 &&
              (' $q ').contains(' $alias ');
        })) candidates.add(topic);
        if (candidates.length > 1) break;
      }
      if (candidates.length == 1) match = candidates.single;
    }
    if (match == null) return null;
    return HealthyAssistantReply(
      '${match.answer}\n\n${match.followUp}',
      card: 'topic',
      actionArgument: match.id,
      knowledgeId: match.id,
    );
  }
}

class MrHealthyTopicService {
  MrHealthyResponseBank? _bank;
  Future<MrHealthyResponseBank>? _pending;

  Future<MrHealthyResponseBank> load() => _pending ??=
      rootBundle.loadString('assets/knowledge/mr_healthy_topics_v2.json')
          .then((raw) => _bank = MrHealthyResponseBank.fromJsonString(raw))
          .catchError((Object error) {
            _pending = null;
            throw error;
          });

  Future<HealthyAssistantReply?> answer(
    String input, {
    String previousTopicId = '',
    int followUpDepth = 0,
  }) async {
    try {
      final bank = _bank ?? await load();
      return bank.answer(input, previousTopicId: previousTopicId,
          followUpDepth: followUpDepth);
    } catch (_) {
      // Preserve legacy knowledge and natural conversation on asset failures.
      return null;
    }
  }
}
