import 'dart:convert';

import 'package:flutter/services.dart';

import 'healthy_assistant_engine.dart';

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
    'un', 'de', 'es', 'y', 'a', 'o', 'lo', 'le', 'te', 'se', 'ser',
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
  }) async {
    if (operational.text.isNotEmpty || operational.action.isNotEmpty) {
      return null;
    }
    final index = _index ?? await load();
    if (!index.looksEducational(input)) return null;
    final match = index.search(input);
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
         Uri.tryParse(card.sourceUrl)?.host == 'fdc.nal.usda.gov');
    return HealthyAssistantReply(
      '${card.title}: ${card.answer}$caveat\n\n'
      'Referencia para consultar: ${card.sourceName}. '
      'Información general, no valoración clínica individual.',
      card: 'knowledge',
      action: hasOfficialLink ? 'source' : '',
      actionArgument: hasOfficialLink ? card.sourceUrl : '',
    );
  }
}
