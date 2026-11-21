import 'dart:convert';

import 'package:flutter/services.dart';

import 'healthy_assistant_reply.dart';

/// Ficha educativa estructurada. No contiene órdenes ni acceso a Firestore.
class HealthyKnowledgeCard {
  const HealthyKnowledgeCard({
    required this.id,
    required this.category,
    required this.title,
    required this.aliases,
    required this.tags,
    required this.answer,
    required this.sourceName,
    required this.sourceUrl,
  });

  final String id;
  final String category;
  final String title;
  final List<String> aliases;
  final List<String> tags;
  final String answer;
  final String sourceName;
  final String sourceUrl;

  factory HealthyKnowledgeCard.fromJson(Map<String, dynamic> raw) {
    final source = Map<String, dynamic>.from(raw['source'] as Map);
    List<String> strings(String name) =>
        (raw[name] as List).map((entry) => entry.toString()).toList();
    return HealthyKnowledgeCard(
      id: raw['id'] as String,
      category: raw['category'] as String,
      title: raw['title'] as String,
      aliases: strings('aliases'),
      tags: strings('tags'),
      answer: raw['answer'] as String,
      sourceName: source['name'] as String,
      sourceUrl: source['url'] as String,
    );
  }
}

class HealthyKnowledgeMatch {
  const HealthyKnowledgeMatch(this.card, this.score);
  final HealthyKnowledgeCard card;
  final int score;
}

/// Recuperación léxica ponderada, tolerante a formulaciones parciales.
/// No es búsqueda semántica neuronal ni generación de texto.
class HealthyKnowledgeIndex {
  const HealthyKnowledgeIndex(this.cards);

  final List<HealthyKnowledgeCard> cards;

  static const _stopWords = <String>{
    'que', 'como', 'cual', 'cuales', 'por', 'para', 'con', 'sin', 'una',
    'uno', 'unas', 'unos', 'del', 'las', 'los', 'hay', 'tiene', 'tienen',
    'puedo', 'debo', 'quiero', 'sobre', 'son', 'mas', 'muy', 'hace',
    'hacer', 'dame', 'dime', 'esta', 'este', 'esto', 'algun', 'algunas',
    'algunos', 'me', 'mi', 'mis', 'tu', 'sus', 'se', 'en', 'la', 'el',
    'un', 'de', 'es', 'y', 'a', 'o', 'lo', 'le', 'te', 'ser',
  };

  static String normalize(String value) {
    final lower = value.toLowerCase();
    const accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'ü': 'u', 'ñ': 'n',
    };
    var normalized = lower;
    for (final entry in accents.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static Set<String> tokens(String text) => normalize(text)
      .split(' ')
      .where((word) => word.length > 2 && !_stopWords.contains(word))
      .toSet();

  static bool containsPhrase(String normalized, String phrase) =>
      (' $normalized ').contains(' ${normalize(phrase)} ');

  static HealthyKnowledgeIndex fromJsonString(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['schemaVersion'] != 1 || data['language'] != 'es') {
      throw const FormatException('Versión o idioma de dataset no compatible.');
    }
    final entries = data['entries'] as List;
    final cards = entries.map((e) =>
      HealthyKnowledgeCard.fromJson(Map<String, dynamic>.from(e as Map)),
    ).toList(growable: false);
    if (cards.isEmpty || cards.map((c) => c.id).toSet().length != cards.length) {
      throw const FormatException('Dataset vacío o con IDs duplicados.');
    }
    return HealthyKnowledgeIndex(cards);
  }

  HealthyKnowledgeMatch? search(String question) {
    final query = normalize(question);
    final words = tokens(query);
    if (words.isEmpty) return null;
    final ranked = <HealthyKnowledgeMatch>[];
    for (final card in cards) {
      var score = 0;
      // Los títulos y alias son señales de mayor fiabilidad que las etiquetas.
      for (final phrase in [card.title, ...card.aliases]) {
        final alias = normalize(phrase);
        if (alias.isEmpty) continue;
        if (containsPhrase(query, alias)) {
          score += 12 + tokens(alias).length * 3;
        } else {
          final overlap = words.intersection(tokens(alias)).length;
          // Una coincidencia parcial de una frase larga no debe bastar.
          if (overlap >= 2) score += overlap * 4;
        }
      }
      final tagMatches = words.intersection(
        card.tags.expand((tag) => tokens(tag)).toSet(),
      ).length;
      score += tagMatches * 2;
      // La pregunta concreta gana a la descripción general del alimento.
      // Sin esto, «¿el huevo me hace daño?» devolvía solo «Huevo».
      final egg = containsPhrase(query, 'huevo') ||
          containsPhrase(query, 'huevos');
      final ham = containsPhrase(query, 'jamon');
      final safety = RegExp(
        r'\b(dano|danino|malo|peligroso|enfermar|alergia|riesgo)\b',
      ).hasMatch(query);
      final cooking = RegExp(
        r'\b(crudo|cocido|coccion|cocinar|salmonella)\b',
      ).hasMatch(query);
      if (egg && ham && card.id == 'huevo_jamon') score += 55;
      if (egg && safety && card.id == 'huevo_seguridad') score += 45;
      if (egg && cooking && !ham &&
          card.id == 'huevo_coccion') {
        score += 40;
      }
      if (score >= 10) ranked.add(HealthyKnowledgeMatch(card, score));
    }
    if (ranked.isEmpty) return null;
    ranked.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      return scoreOrder != 0 ? scoreOrder : a.card.id.compareTo(b.card.id);
    });
    // Si dos fichas compiten casi por igual, no responder con falsa certeza.
    if (ranked.length > 1 && ranked[0].score - ranked[1].score < 3) {
      return null;
    }
    return ranked.first;
  }

  bool looksEducational(String text) {
    final q = normalize(text);
    if (q.isEmpty) return false;
    final words = tokens(q);
    const domain = <String>{
      'alimentacion', 'comida', 'alimento', 'nutricion', 'proteinas',
      'proteina', 'calorias', 'kcal', 'fibra', 'agua', 'hidratacion',
      'ejercicio', 'entrenamiento', 'musculos', 'desayuno', 'dormir',
      'sueno', 'saludable', 'verduras', 'frutas', 'sedentarismo',
      'actividad', 'dieta', 'nutrientes', 'recuperacion',
    };
    return words.intersection(domain).isNotEmpty ||
        cards.any((card) => [card.title, ...card.aliases].any(
          (alias) => alias.isNotEmpty && containsPhrase(q, alias),
        ));
  }
}

/// Orquestador educativo: las órdenes y respuestas del motor funcional
/// tienen precedencia. Nunca escribe en Firebase ni concede recompensas.
class HealthyHybridKnowledge {
  HealthyKnowledgeIndex? _index;
  Future<HealthyKnowledgeIndex>? _pending;

  Future<HealthyKnowledgeIndex> load() => _pending ??=
      rootBundle.loadString('assets/knowledge/mr_healthy_es_v1.json')
        .then((raw) => _index = HealthyKnowledgeIndex.fromJsonString(raw))
        .catchError((Object error) {
          _pending = null; // Permitir reintentar si el asset falla.
          throw error;
        });

  Future<HealthyAssistantReply?> answer(
    String input, {
    required HealthyAssistantReply operational,
    String lastKnowledgeId = '',
  }) async {
    if (operational.text.isNotEmpty || operational.action.isNotEmpty) {
      return null;
    }
    // Un asset ausente no debe inutilizar el chat ni sus acciones.
    late final HealthyKnowledgeIndex index;
    try {
      index = _index ?? await load();
    } catch (_) {
      return const HealthyAssistantReply(
        'Mi base educativa no está disponible en este momento. '
        'Puedes seguir usando tus hábitos, perfil y tienda; '
        'intenta consultar este tema nuevamente más tarde.',
      );
    }
    final normalized = HealthyKnowledgeIndex.normalize(input);
    // Responder a «¿qué más?» con opciones relacionadas, no repetir
    // literalmente la misma ficha del mensaje anterior.
    final asksForMore = const {
      'que mas', 'dime mas', 'explicame mas', 'algo mas',
      'cuentame mas', 'mas informacion', 'quiero saber mas',
    }.contains(normalized);
    if (asksForMore && lastKnowledgeId.startsWith('huevo')) {
      return const HealthyAssistantReply(
        'Sobre el huevo puedo explicarte tres cosas distintas: '
        'cómo cocinarlo de forma segura, si puede causar problemas '
        'en algunas personas o cómo combinarlo con jamón y verduras. '
        '¿Cuál de esos temas te interesa?',
        card: 'knowledge',
        knowledgeId: 'huevo',
      );
    }
    final hasReference = RegExp(
      r'\b(y si|si le|le pongo|le agrego|con eso|y con|eso hace|'
      r'lo puedo|es malo|hace dano|como lo preparo|prepararlo|'
      r'comerlo|con jamon|me podria|me puede hacer)\b',
    ).hasMatch(normalized);
    // Si el usuario está hablando del huevo y dice «¿y con jamón?»,
    // recuperar el sujeto explícito sin alterar la frase original.
    final refersToEgg = lastKnowledgeId == 'huevo' ||
        lastKnowledgeId.startsWith('huevo_');
    final contextualInput = hasReference && refersToEgg &&
            !RegExp(r'\b(huevo|huevos)\b').hasMatch(normalized)
        ? 'huevo $input'
        : input;
    if (!index.looksEducational(contextualInput)) return null;
    final match = index.search(contextualInput);
    if (match == null) {
      return const HealthyAssistantReply(
        'No encontré una ficha suficientemente precisa en mi base educativa '
        'para responder esa pregunta. Prueba con un alimento o tema concreto; '
        'no inventaré nutrientes, cantidades ni recomendaciones clínicas.',
        card: 'knowledge',
      );
    }
    final card = match.card;
    final asksForNumeric = RegExp(
      r'\b(cuantas|cuantos|calorias|kcal|gramos|miligramos|mg|porcentaje)\b',
    ).hasMatch(HealthyKnowledgeIndex.normalize(input));
    final caveat = asksForNumeric
        ? '\nEsta ficha no incluye cantidades verificadas por porción; '
          'no daré una cifra inventada.'
        : '';
    final hasOfficialLink = card.sourceUrl.startsWith('https://') &&
        (Uri.tryParse(card.sourceUrl)?.host == 'www.who.int' ||
         Uri.tryParse(card.sourceUrl)?.host == 'fdc.nal.usda.gov' ||
         Uri.tryParse(card.sourceUrl)?.host == 'www.fda.gov');
    return HealthyAssistantReply(
      '${card.title}: ${card.answer}$caveat\n\n'
      'Referencia para consultar: ${card.sourceName}. '
      'Información general, no valoración clínica individual.',
      card: 'knowledge',
      action: hasOfficialLink ? 'source' : '',
      actionArgument: hasOfficialLink ? card.sourceUrl : '',
      knowledgeId: card.id,
    );
  }
}
