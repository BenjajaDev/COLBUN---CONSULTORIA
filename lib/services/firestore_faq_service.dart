import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// --- MODELO FAQ MODIFICADO PARA INCLUIR ETIQUETAS ---
class Faq {
  final String id;
  final String question;
  final String answer;
  final String? link;
  final List<String> tags;
  final String category;

  Faq({
    required this.id,
    required this.question,
    required this.answer,
    this.link,
    required this.tags,
    required this.category,
  });
  // Constructor desde Firestore
  factory Faq.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Faq(
      id: doc.id,
      question: data['question'] ?? 'Pregunta no disponible',
      answer: data['answer'] ?? 'No se encontró respuesta.',
      link: data['source_url'],
      tags: List<String>.from(data['tags'] ?? []),
      category: data['category'] ?? 'general',
    );
  }
}

// --- MODELO CATEGORÍA  ---
class Category {
  final String id;
  final String name;
  final String icon;
  final int priority;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.priority,
  });
  // Constructor desde Firestore
  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'ℹ️',
      priority: data['priority'] ?? 99,
    );
  }
}

// --- SERVICIO FAQ MODIFICADO PARA USAR TF-IDF Y DEVOLVER MÚLTIPLES RESPUESTAS ---
class FaqService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Faq> _faqsCache = [];
  Map<String, double> _idfScores = {};

  FaqService();

  // Carga las FAQs y calcula los puntajes IDF.
  Future<void> loadFaqsAndCalculateScores() async {
    if (_faqsCache.isNotEmpty) return;
    try {
      // Carga todas las FAQs desde Firestore
      final querySnapshot = await _db.collection('faqs_curadas').get();
      _faqsCache =
          querySnapshot.docs.map((doc) => Faq.fromFirestore(doc)).toList();
      _calculateIdfScores();
      debugPrint(
          "✅ Context Finder: ${_faqsCache.length} FAQs cargadas y listas para buscar contexto.");
    } catch (e) {
      debugPrint("❌ Error al cargar FAQs para contexto: $e");
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

  // Encuentra las FAQs más relevantes basadas en TF-IDF.
  Future<List<Faq>> findContextFaqs(String userMessage) async {
    if (_faqsCache.isEmpty) return [];

    final keywords = _generateKeywordsFromText(userMessage);
    if (keywords.isEmpty) return [];

    // Calcula el puntaje TF-IDF para todas las FAQs en la caché.
    final scoredFaqs = _faqsCache.map((faq) {
      double score = 0.0;
      for (final keyword in keywords) {
        if (faq.tags.contains(keyword)) {
          score += _idfScores[keyword] ?? 0.0;
        }
      }
      return MapEntry(faq, score);
    }).toList();

    // Ordena las FAQs de mayor a menor puntaje.
    scoredFaqs.sort((a, b) => b.value.compareTo(a.value));

    // Filtra y devuelve solo las mejores, si tienen un puntaje mínimo.
    final relevantFaqs = scoredFaqs
        .where((entry) =>
            entry.value > 0.5) // Umbral bajo para no descartar contexto útil
        .map((entry) => entry.key)
        .take(1) // Tomamos la mejor como contexto
        .toList();

    if (relevantFaqs.isNotEmpty) {
      debugPrint(
          "📚 Contexto encontrado para IA: ${relevantFaqs.map((f) => f.question).join(' | ')}");
    } else {
      debugPrint(
          "ℹ️ No se encontró contexto local relevante para la pregunta.");
    }

    return relevantFaqs;
  }

  // Devuelve todas las FAQs (usado para administración o debugging).
  Future<List<Faq>> getAllFaqs() async {
    if (_faqsCache.isEmpty) await loadFaqsAndCalculateScores();
    return _faqsCache;
  }

  Future<List<Category>> getCategories() async {
    try {
      final querySnapshot =
          await _db.collection('categories_v2').orderBy('priority').get();
      return querySnapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener las categorías: $e');
      return [];
    }
  }

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
