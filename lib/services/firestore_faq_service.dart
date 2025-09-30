import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Faq {
  final String id;
  final String question;
  final String answer;
  final String? link;
  final List<String> tags;

  Faq({
    required this.id,
    required this.question,
    required this.answer,
    this.link,
    required this.tags,
  });

  factory Faq.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Faq(
      id: doc.id,
      question: data['question'] ?? 'Pregunta no disponible',
      answer: data['answer'] ?? 'No se encontró respuesta.',
      link: data['source_url'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
}

class FaqService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Faq> _faqsCache = [];
  Map<String, double> _idfScores = {};

  FaqService();

  Future<void> loadFaqsAndCalculateScores() async {
    if (_faqsCache.isNotEmpty) return;
    try {
      final querySnapshot = await _db.collection('faqs').get();
      _faqsCache =
          querySnapshot.docs.map((doc) => Faq.fromFirestore(doc)).toList();
      _calculateIdfScores();
      debugPrint(
          "✅ Búsqueda Ponderada: ${_faqsCache.length} FAQs cargadas y ${_idfScores.length} scores calculados.");
    } catch (e) {
      debugPrint("❌ Error al cargar FAQs: $e");
    }
  }

  void _calculateIdfScores() {
    if (_faqsCache.isEmpty) return;
    final docFrequencies = <String, int>{};
    final totalDocuments = _faqsCache.length;
    for (final faq in _faqsCache) {
      for (final tag in faq.tags.toSet()) {
        docFrequencies[tag] = (docFrequencies[tag] ?? 0) + 1;
      }
    }
    _idfScores.clear();
    for (final entry in docFrequencies.entries) {
      _idfScores[entry.key] = log(totalDocuments / entry.value);
    }
  }

  Future<Faq?> findFaq(String userMessage) async {
    if (_faqsCache.isEmpty) return null;

    final keywords = _generateKeywordsFromText(userMessage);
    if (keywords.isEmpty) return null;

    // CAPA 1: BÚSQUEDA DE ALTA CONFIANZA
    for (final faq in _faqsCache) {
      final faqTags = faq.tags.toSet();
      if (keywords.every((keyword) => faqTags.contains(keyword))) {
        debugPrint(
            "✅ Coincidencia de Alta Confianza encontrada: '${faq.question}'");
        return faq;
      }
    }

    // CAPA 2: BÚSQUEDA PONDERADA (TF-IDF)
    Faq? bestMatch;
    double highestScore = 0.0;
    for (final faq in _faqsCache) {
      double currentScore = 0.0;
      for (final keyword in keywords) {
        if (faq.tags.contains(keyword)) {
          currentScore += _idfScores[keyword] ?? 0.0;
        }
      }
      if (currentScore > highestScore) {
        highestScore = currentScore;
        bestMatch = faq;
      }
    }

    // CAPA 3: UMBRAL DE CONFIANZA
    const double CONFIDENCE_THRESHOLD = 0.8; // Volvemos a un umbral razonable
    if (highestScore < CONFIDENCE_THRESHOLD) {
      debugPrint(
          "ℹ️ Puntuación baja (${highestScore.toStringAsFixed(2)}). Derivando a IA.");
      return null;
    }

    // --- ¡NUEVO! CAPA 4: REGLA DE VETO ---
    // Verificamos que la mejor respuesta contenga la palabra clave más importante de la pregunta.
    if (bestMatch != null) {
      // Encontrar la keyword más importante (la que tiene el score IDF más alto) de la pregunta del usuario.
      String criticalKeyword = '';
      double maxIdf = 0.0;
      for (final keyword in keywords) {
        final score = _idfScores[keyword] ?? 0.0;
        if (score > maxIdf) {
          maxIdf = score;
          criticalKeyword = keyword;
        }
      }

      // Si la mejor coincidencia NO contiene esta palabra crítica, la vetamos.
      if (criticalKeyword.isNotEmpty &&
          !bestMatch.tags.contains(criticalKeyword)) {
        debugPrint(
            "❌ VETO: La mejor coincidencia '${bestMatch.question}' no contiene la palabra clave crítica '${criticalKeyword}'. Derivando a IA.");
        return null;
      }
    }

    debugPrint(
        "✅ Coincidencia Válida: '${bestMatch?.question}' (Score: ${highestScore.toStringAsFixed(2)})");
    return bestMatch;
  }

  Future<List<Faq>> getAllFaqs() async {
    if (_faqsCache.isEmpty) await loadFaqsAndCalculateScores();
    return _faqsCache;
  }

  // El resto del código (generación de keywords, sinónimos, etc.) permanece igual.
  List<String> _generateKeywordsFromText(String text) {
    final keywords = <String>{};
    final initialText = text.toLowerCase().trim();
    final words = initialText.split(RegExp(r'[\s,\.;\?¿¡!]+'));

    for (String word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúñü]'), '');
      final normalizedForFilter = _normalizeChars(cleanWord);

      if (cleanWord.length > 3 &&
          !_excludeWords.contains(normalizedForFilter)) {
        keywords.add(cleanWord);
        final normalizedWord = _normalizeChars(cleanWord);
        final finalWord = _synonyms[normalizedWord] ?? normalizedWord;
        keywords.add(finalWord);
      }
    }
    return keywords.toList();
  }

  String _normalizeChars(String s) {
    return s
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ä', 'a')
        .replaceAll('ë', 'e')
        .replaceAll('ï', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('à', 'a')
        .replaceAll('è', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('ñ', 'n');
  }

  static const Map<String, String> _synonyms = {
    'municipio': 'municipalidad',
    'comuna': 'municipalidad',
    'horarios': 'horario',
    'atencion': 'servicio',
    'servicios': 'servicio',
    'oficinas': 'oficina',
    'telefono': 'contacto',
    'direccion': 'ubicacion',
    'licencias': 'licencia',
    'permisos': 'permiso',
    'documentos': 'documento',
    'tramites': 'tramite',
    'medicos': 'medico',
    'consultorios': 'consultorio',
    'escuelas': 'escuela',
    'colegios': 'colegio',
    'lugares': 'lugar',
    'sitios': 'lugar',
    'destinos': 'destino',
    'hola': 'saludo',
    'buenos': 'saludo',
    'buenas': 'saludo',
    'gracias': 'despedida',
    'adios': 'despedida',
    'chao': 'despedida',
    'tren': 'tren_chico',
    'ferrocarril': 'tren_chico',
    'artesanas': 'artesania',
    'crin': 'artesania_crin',
    'termas': 'aguas_termales',
    'balneario': 'playa',
    'senderismo': 'trekking',
    'caminatas': 'trekking',
    'hiking': 'trekking',
    'mirador': 'vista_panoramica',
    'petroglifos': 'arte_rupestre',
    'volcanes': 'volcan',
    'lagunas': 'laguna',
    'zoit': 'zona_turistica',
    'fiestas': 'eventos',
    'festivales': 'eventos',
    'celebraciones': 'eventos',
    'alojamiento': 'hospedaje',
    'cabañas': 'hospedaje',
    'hoteles': 'hospedaje',
    'camping': 'hospedaje',
    'gastronomia': 'comida',
    'restaurantes': 'comida',
    'comida': 'gastronomia',
    'transporte': 'movilidad',
    'vehiculo': 'movilidad',
    'clima': 'tiempo',
    'epoca': 'temporada',
    'estaciones': 'temporada',
    'salud': 'atencion_medica',
    'cesfam': 'atencion_medica',
    'postas': 'atencion_medica',
    'veterinaria': 'mascotas',
    'empleo': 'trabajo',
    'omil': 'trabajo',
    'omdel': 'desarrollo_economico',
    'dideco': 'programas_sociales',
    'deportes': 'actividad_fisica',
    'talleres': 'actividades_culturales',
    'compras': 'artesanias',
    'souvenirs': 'artesanias'
  };
  static const Set<String> _excludeWords = {
    'como',
    'donde',
    'cuando',
    'cual',
    'cuales',
    'quien',
    'que',
    'para',
    'con',
    'por',
    'una',
    'uno',
    'esta',
    'este',
    'son',
    'hay',
    'tiene',
    'puede',
    'puedo',
    'debo',
    'necesito',
    'quiero',
    'hacer',
    'obtener',
    'encontrar',
    'ubicado',
    'ubicada',
    'algun',
    'algunos',
    'algunas'
  };
}
