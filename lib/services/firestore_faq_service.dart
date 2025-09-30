import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Necesario para el debugPrint

// --- El Modelo Faq no cambia, está correcto. ---
class Faq {
  final String id;
  final String question;
  final String answer;
  final String? action;
  final List<String> tags;
   final String? link; // Nuevo campo para el link

  Faq({
    required this.id,
    required this.question,
    required this.answer,
    this.action,
    this.tags = const [],
    this.link, // Nuevo campo
  });

  factory Faq.fromFirestore(Map<String, dynamic> data, String documentId) {
    final tagsFromDb = data['tags'];
    final List<String> tagsList =
        tagsFromDb is List ? List<String>.from(tagsFromDb) : [];

    return Faq(
      id: documentId,
      question: data['question'] ?? 'Pregunta no disponible',
      answer: data['answer'] ?? 'No se encontró respuesta.',
      action: data['action'],
      tags: tagsList,
      link: data['source_url'], // Inicialización del nuevo campo
    );
  }
}

// --- La Clase de Servicio con la Lógica de Depuración Integrada ---
class FaqService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// **[FUNCIÓN DE DEPURACIÓN]**
  /// Llama a esta función desde tu UI para probar la generación de keywords de forma aislada.
  /// Ejemplo: FaqService().testKeywordGeneration("¿Cuál es el horario de atención?");
  void testKeywordGeneration(String testMessage) {
    final keywords = _generateKeywordsFromText(testMessage);
    debugPrint('--- PRUEBA DE GENERACIÓN DE KEYWORDS ---', wrapWidth: 1024);
    debugPrint('Mensaje de entrada: "$testMessage"', wrapWidth: 1024);
    debugPrint('Keywords generadas: $keywords', wrapWidth: 1024);
    debugPrint('--- FIN DE LA PRUEBA ---', wrapWidth: 1024);
  }

  /// Busca la FAQ más relevante en Firestore.
  Future<Faq?> findFaq(String userMessage) async {
    // 1. Generar palabras clave.
    final keywords = _generateKeywordsFromText(userMessage);

    if (keywords.isEmpty) {
      debugPrint('DEBUG: No se generaron keywords para "$userMessage"',
          wrapWidth: 1024);
      return null;
    }
    debugPrint('DEBUG: Buscando en Firestore con keywords: $keywords',
        wrapWidth: 1024);

    try {
      // 2. Consultar documentos candidatos.
      final querySnapshot = await _db
          .collection('faqs')
          .where('tags', arrayContainsAny: keywords)
          .limit(10)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
            'DEBUG: Firestore no encontró NINGÚN documento con esas keywords.',
            wrapWidth: 1024);
        return null;
      }

      debugPrint(
          'DEBUG: Firestore encontró ${querySnapshot.docs.length} documentos candidatos.',
          wrapWidth: 1024);

      // 3. Sistema de Puntuación (Scoring).
      Faq? bestMatch;
      int maxScore = 0;

      debugPrint('--- INICIO SCORING ---', wrapWidth: 1024);
      for (var doc in querySnapshot.docs) {
        final faq = Faq.fromFirestore(doc.data(), doc.id);
        int currentScore = 0;

        for (String keyword in keywords) {
          if (faq.tags.contains(keyword)) {
            currentScore++;
          }
        }

        // Imprime el análisis de cada candidato
        debugPrint(
            'Candidato: "${faq.question}" | Puntaje: $currentScore | Tags en DB: ${faq.tags}',
            wrapWidth: 1024);

        if (currentScore > maxScore ||
            (currentScore > 0 &&
                currentScore == maxScore &&
                (bestMatch == null ||
                    faq.tags.length < bestMatch.tags.length))) {
          maxScore = currentScore;
          bestMatch = faq;
        }
      }
      debugPrint('--- FIN SCORING ---', wrapWidth: 1024);

      // 4. Devolver el mejor resultado.
      if (maxScore > 0) {
        debugPrint(
            '✅ MEJOR RESULTADO: "${bestMatch?.question}" con puntaje $maxScore',
            wrapWidth: 1024);
        return bestMatch;
      } else {
        debugPrint(
            '⚠️ Ningún candidato tuvo puntaje positivo. No se encontró respuesta relevante.',
            wrapWidth: 1024);
        return null;
      }
    } catch (e) {
      debugPrint('❌ ERROR en la consulta a Firestore: $e', wrapWidth: 1024);
      return null;
    }
  }

  /// Obtiene todos los documentos de la colección 'faqs'.
  Future<List<Faq>> getAllFaqs() async {
    try {
      final querySnapshot = await _db.collection('faqs').get();
      return querySnapshot.docs
          .map((doc) => Faq.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener todas las FAQs: $e', wrapWidth: 1024);
      return [];
    }
  }

  // ========================================================================
  // LÓGICA DE NORMALIZACIÓN - VERSIÓN ESPEJO DEL SCRIPT DE NODE.JS
  // (Esta parte no se modifica, ya que asumimos que es correcta)
  // ========================================================================

  List<String> _generateKeywordsFromText(String text) {
    String initialText = text.toLowerCase().trim();
    List<String> words = initialText.split(RegExp(r'\s+'));
    Set<String> keywords = {};

    for (String word in words) {
      String cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      if (cleanWord.length > 3 && !_excludeWords.contains(cleanWord)) {
        String normalizedWord = _normalizeChars(cleanWord);
        String finalWord = _synonyms[normalizedWord] ?? normalizedWord;
        keywords.add(finalWord);
      }
    }
    return keywords.toList();
  }

  String _normalizeChars(String s) {
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ñ': 'n',
      'ü': 'u'
    };
    String result = s;
    replacements.forEach((from, to) {
      result = result.replaceAll(from, to);
    });
    return result;
  }

  static const Map<String, String> _synonyms = {
    'municipio': 'municipalidad',
    'comuna': 'municipalidad',
    'horarios': 'horario',
    'atencion': 'servicio',
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
    'alojamiento': 'hospedeje',
    'cabañas': 'hospedeje',
    'hoteles': 'hospedeje',
    'camping': 'hospedeje',
    'gastronomia': 'comida',
    'comida': 'gastronomia',
    'restaurantes': 'comida',
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
    'souvenirs': 'artesanias',
    'servicios': 'servicio'
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
