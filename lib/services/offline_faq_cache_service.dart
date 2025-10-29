import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'firestore_faq_service.dart';

/// Servicio para cachear FAQs esenciales para uso offline
class OfflineFaqCacheService {
  static const String _essentialFaqsCacheKey = 'essential_faqs_offline_cache';
  static const String _cacheVersionKey = 'essential_faqs_cache_version';
  static const int _currentCacheVersion = 1;
  
  // IDs de las 20 FAQs esenciales relacionadas al turismo
  static const List<String> essentialFaqIds = [
    // Estas IDs deberán actualizarse con las IDs reales de Firestore
    // Por ahora usaremos categorías/keywords para identificarlas
  ];

  List<Faq> _essentialFaqsCache = [];
  
  /// Obtener FAQs esenciales desde caché local
  List<Faq> get cachedFaqs => _essentialFaqsCache;
  
  /// Verificar si hay FAQs en caché
  bool get hasCachedFaqs => _essentialFaqsCache.isNotEmpty;

  /// Cargar FAQs esenciales desde caché local
  Future<void> loadEssentialFaqsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_essentialFaqsCacheKey);
      final cachedVersion = prefs.getInt(_cacheVersionKey) ?? 0;
      
      if (cachedJson != null && cachedVersion == _currentCacheVersion) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _essentialFaqsCache = decoded
            .map((json) => _faqFromJson(json))
            .toList();
        
        debugPrint('✅ ${_essentialFaqsCache.length} FAQs esenciales cargadas desde caché offline');
      } else if (cachedVersion != _currentCacheVersion) {
        debugPrint('⚠️ Versión de caché obsoleta, se requiere actualización');
        await _clearCache();
      }
    } catch (e) {
      debugPrint('❌ Error cargando FAQs esenciales desde caché: $e');
      _essentialFaqsCache = [];
    }
  }

  /// Guardar FAQs esenciales en caché local (NO se borran con "Borrar Historial")
  Future<void> saveEssentialFaqsToCache(List<Faq> faqs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Filtrar las 20 FAQs esenciales relacionadas al turismo
      final essentialFaqs = _selectEssentialFaqs(faqs);
      
      final jsonList = essentialFaqs.map((faq) => _faqToJson(faq)).toList();
      await prefs.setString(_essentialFaqsCacheKey, jsonEncode(jsonList));
      await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
      
      _essentialFaqsCache = essentialFaqs;
      
      debugPrint('💾 ${essentialFaqs.length} FAQs esenciales guardadas en caché offline');
      debugPrint('📋 Categorías cacheadas: ${_getCategorySummary(essentialFaqs)}');
    } catch (e) {
      debugPrint('❌ Error guardando FAQs esenciales: $e');
    }
  }

  /// Seleccionar las 20 FAQs más esenciales relacionadas al turismo
  List<Faq> _selectEssentialFaqs(List<Faq> allFaqs) {
    // Palabras clave para identificar FAQs esenciales de turismo
    const essentialKeywords = [
      // Atracciones principales
      'lago_colbun', 'embalse', 'machicura', 'balneario',
      'termas', 'panimavida', 'quinamavida',
      'volcan', 'laguna_maule', 'trekking', 'senderismo',
      'rari', 'artesania', 'crin',
      
      // Servicios turísticos
      'hospedaje', 'camping', 'restaurantes', 'gastronomia',
      'alojamiento', 'comida_tipica',
      
      // Actividades
      'deportes_acuaticos', 'kayak', 'pesca', 'natacion',
      'avistamiento_aves', 'ecoturismo',
      
      // Información práctica
      'como_llegar', 'transporte', 'horarios',
      'contacto', 'informacion_turistica',
      'clima', 'temporada',
      
      // Cultura y patrimonio
      'patrimonio_cultural', 'iglesia_piedra',
      'tren_chico', 'arte_rupestre',
      
      // Emergencias
      'emergencia', 'salud', 'seguridad',
    ];

    final scoredFaqs = <MapEntry<Faq, int>>[];
    
    for (final faq in allFaqs) {
      // Excluir saludos y despedidas
      if (faq.category == 'saludos_despedidas') continue;
      
      int score = 0;
      
      // Puntuar por categorías prioritarias
      if (faq.category.contains('turismo')) score += 10;
      if (faq.category.contains('artesania')) score += 8;
      if (faq.category.contains('atractivos')) score += 9;
      if (faq.category.contains('servicios')) score += 5;
      if (faq.category.contains('emergencia')) score += 15; // Alta prioridad
      
      // Puntuar por keywords esenciales
      for (final keyword in essentialKeywords) {
        if (faq.tags.contains(keyword)) {
          score += 3;
        }
      }
      
      // Bonus por tener información en múltiples idiomas
      if (faq.questionEn.isNotEmpty && faq.questionEn != faq.question) {
        score += 2;
      }
      if (faq.questionPt.isNotEmpty && faq.questionPt != faq.question) {
        score += 2;
      }
      
      if (score > 0) {
        scoredFaqs.add(MapEntry(faq, score));
      }
    }
    
    // Ordenar por score descendente y tomar las 20 mejores
    scoredFaqs.sort((a, b) => b.value.compareTo(a.value));
    
    final selected = scoredFaqs.take(20).map((entry) => entry.key).toList();
    
    // Log de FAQs seleccionadas
    debugPrint('📊 FAQs esenciales seleccionadas:');
    for (int i = 0; i < selected.length; i++) {
      debugPrint('  ${i + 1}. ${selected[i].question} (${selected[i].category})');
    }
    
    return selected;
  }

  /// Buscar FAQs en caché offline
  List<Faq> searchInCache(String query, String language) {
    if (_essentialFaqsCache.isEmpty) {
      debugPrint('⚠️ No hay FAQs en caché offline');
      return [];
    }

    final queryLower = query.toLowerCase();
    final results = <MapEntry<Faq, double>>[];

    for (final faq in _essentialFaqsCache) {
      double score = 0.0;
      
      // Obtener textos según idioma
      final question = faq.getQuestion(language).toLowerCase();
      final answer = faq.getAnswer(language).toLowerCase();
      final tags = faq.tags.join(' ').toLowerCase();
      
      // Scoring simple por coincidencias
      if (question.contains(queryLower)) score += 10.0;
      if (answer.contains(queryLower)) score += 5.0;
      if (tags.contains(queryLower)) score += 7.0;
      
      // Scoring por palabras individuales
      final queryWords = queryLower.split(' ');
      for (final word in queryWords) {
        if (word.length <= 2) continue; // Ignorar palabras muy cortas
        
        if (question.contains(word)) score += 2.0;
        if (answer.contains(word)) score += 1.0;
        if (tags.contains(word)) score += 1.5;
      }
      
      if (score > 0) {
        results.add(MapEntry(faq, score));
      }
    }

    // Ordenar por score y retornar top 3
    results.sort((a, b) => b.value.compareTo(a.value));
    final topResults = results.take(3).map((e) => e.key).toList();
    
    if (topResults.isNotEmpty) {
      debugPrint('💾 Encontradas ${topResults.length} FAQs en caché offline');
    }
    
    return topResults;
  }

  /// Obtener todas las FAQs del caché (para mostrar en botón de FAQs)
  List<Faq> getAllCachedFaqs() {
    return List.unmodifiable(_essentialFaqsCache);
  }

  /// Limpiar caché (solo en caso de actualización forzada, NO con "Borrar Historial")
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_essentialFaqsCacheKey);
      await prefs.remove(_cacheVersionKey);
      _essentialFaqsCache = [];
      debugPrint('🗑️ Caché de FAQs esenciales limpiado');
    } catch (e) {
      debugPrint('❌ Error limpiando caché de FAQs: $e');
    }
  }

  /// Obtener resumen de categorías cacheadas
  String _getCategorySummary(List<Faq> faqs) {
    final categories = <String>{};
    for (final faq in faqs) {
      categories.add(faq.category);
    }
    return categories.join(', ');
  }

  // Métodos de serialización
  Map<String, dynamic> _faqToJson(Faq faq) {
    return {
      'id': faq.id,
      'question': faq.question,
      'answer': faq.answer,
      'link': faq.link,
      'tags': faq.tags,
      'category': faq.category,
      'question_en': faq.questionEn,
      'answer_en': faq.answerEn,
      'question_pt': faq.questionPt,
      'answer_pt': faq.answerPt,
    };
  }

  Faq _faqFromJson(Map<String, dynamic> json) {
    return Faq(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      link: json['link'],
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] ?? 'general',
      questionEn: json['question_en'] ?? '',
      answerEn: json['answer_en'] ?? '',
      questionPt: json['question_pt'] ?? '',
      answerPt: json['answer_pt'] ?? '',
    );
  }
}
