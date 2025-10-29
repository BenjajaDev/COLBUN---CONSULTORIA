import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'language_service.dart';

// --- MODELO FAQ MODIFICADO PARA INCLUIR ETIQUETAS ---
class Faq {
  final String id;
  final String question;
  final String answer;
  final String? link;
  final List<String> tags;
  final String category;
  // Nuevos campos para soportar múltiples idiomas
  final String questionEn;
  final String answerEn;
  final String questionPt;
  final String answerPt;

  Faq({
    required this.id,
    required this.question,
    required this.answer,
    this.link,
    required this.tags,
    required this.category,
    required this.questionEn, // Nuevo
    required this.answerEn, // Nuevo
    required this.questionPt, // Nuevo
    required this.answerPt, // Nuevo
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
      questionEn: data['question_en'] ??
          data['question'] ??
          'Question not available', // Nuevo
      answerEn:
          data['answer_en'] ?? data['answer'] ?? 'No answer found.', // Nuevo
      questionPt: data['question_pt'] ??
          data['question'] ??
          'Pergunta não disponível', // Nuevo
      answerPt:
          data['answer_pt'] ?? data['answer'] ?? 'Nenhuma resposta encontrada.',
    );
  }
  // Nuevo método para obtener pregunta según idioma ingles español y portugues
  String getQuestion(String language) {
    return language == 'en'
        ? questionEn
        : language == 'pt'
            ? questionPt
            : question;
  }

  // Nuevo método para obtener respuesta según idioma
  String getAnswer(String language) {
    return language == 'en'
        ? answerEn
        : language == 'pt'
            ? answerPt
            : answer;
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
  final LanguageService _languageService = LanguageService();
  List<Faq> _faqsCache = [];
  Map<String, double> _idfScores = {};

  // NUEVA: Caché de búsquedas recientes para respuestas instantáneas
  final Map<String, List<Faq>> _searchCache = {};
  static const int _maxCacheSize = 50;

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
      print(
          "✅ Context Finder: ${_faqsCache.length} FAQs cargadas y listas para buscar contexto.");
    } catch (e, st) {
      try {
        FirebaseCrashlytics.instance.recordError(e, st,
            reason: 'FaqService.loadFaqsAndCalculateScores');
      } catch (_) {}
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

  /// Obtiene FAQs aleatorias en el idioma especificado
  List<String> getRandomFaqsByLanguage(String language, {int count = 3}) {
    if (_faqsCache.isEmpty) return [];

    // Filtrar para excluir saludos_despedidas como antes
    final filteredFaqs = _faqsCache
        .where((faq) => faq.category != 'saludos_despedidas')
        .toList();

    final shuffledFaqs = filteredFaqs..shuffle();

    return shuffledFaqs.take(count).map((faq) {
      // Usar getQuestion con el idioma especificado
      return faq.getQuestion(language);
    }).toList();
  }

  // Encuentra las FAQs más relevantes basadas en TF-IDF.
  Future<List<Faq>> findContextFaqs(String userMessage) async {
    if (_faqsCache.isEmpty) return [];

    // OPTIMIZACIÓN 1: Normalizar y crear clave de caché
    final normalizedQuery = userMessage.toLowerCase().trim();

    // Verificar caché primero para respuesta instantánea
    if (_searchCache.containsKey(normalizedQuery)) {
      print('⚡ Respuesta desde caché para: "$userMessage"');
      return _searchCache[normalizedQuery]!;
    }

    // OPTIMIZACIÓN 2: Detectar idioma en paralelo con generación de keywords
    final detectionFuture = _languageService.detectLanguage(userMessage);
    final keywords = _generateKeywordsFromText(userMessage);

    if (keywords.isEmpty) return [];

    // Esperar detección de idioma (ya completada o casi)
    final String detectedLanguage = await detectionFuture;

    debugPrint(
        "🌐 Idioma detectado: $detectedLanguage para mensaje: $userMessage");
    print("🔍 FAQ SERVICE - Idioma detectado: $detectedLanguage");
    print("🔍 FAQ SERVICE - Búsqueda para: '$userMessage'");
    print("🔍 FAQ SERVICE - Keywords generadas: $keywords");

    // OPTIMIZACIÓN 3: Pre-filtrar FAQs que tienen al menos una keyword
    final candidateFaqs = <Faq>[];
    for (final faq in _faqsCache) {
      bool hasMatch = false;
      for (final keyword in keywords) {
        if (faq.tags.contains(keyword)) {
          hasMatch = true;
          break;
        }
      }
      if (hasMatch) candidateFaqs.add(faq);
    }

    // Si no hay candidatos, retornar vacío rápidamente
    if (candidateFaqs.isEmpty) {
      debugPrint(
          "ℹ️ No se encontró contexto local relevante para la pregunta (idioma: $detectedLanguage).");
      return [];
    }

    // OPTIMIZACIÓN 4: Calcular scores solo para candidatos (no todas las FAQs)
    final scoredFaqs = candidateFaqs.map((faq) {
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

    // OPTIMIZACIÓN 5: Guardar en caché (con límite de tamaño)
    if (_searchCache.length >= _maxCacheSize) {
      // Eliminar entrada más antigua
      _searchCache.remove(_searchCache.keys.first);
    }
    _searchCache[normalizedQuery] = relevantFaqs;

    if (relevantFaqs.isNotEmpty) {
      debugPrint(
          "📚 Contexto encontrado para IA (idioma: $detectedLanguage): ${relevantFaqs.map((f) => f.getQuestion(detectedLanguage)).join(' | ')}");
    } else {
      debugPrint(
          "ℹ️ No se encontró contexto local relevante para la pregunta (idioma: $detectedLanguage).");
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
    } catch (e, st) {
      try {
        FirebaseCrashlytics.instance
            .recordError(e, st, reason: 'FaqService.getCategories');
      } catch (_) {}
      debugPrint('Error al obtener las categorías: $e');
      return [];
    }
  }

  List<String> _generateKeywordsFromText(String text) {
    final keywords = <String>{};
    final initialText = text.toLowerCase().trim();
    final words = initialText.split(RegExp(r'[\s,\.;\?¿¡!]+'));

    print("🔍 GENERANDO KEYWORDS PARA: '$text'");
    print("🔍 PALABRAS ORIGINALES: $words");
    for (String word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúñü]'), '');
      final normalizedForFilter = _normalizeChars(cleanWord);
      if (cleanWord.length > 2 &&
          !_excludeWords.contains(normalizedForFilter)) {
        keywords.add(cleanWord);
        final normalizedWord = _normalizeChars(cleanWord);
        final finalWord = _synonyms[normalizedWord] ?? normalizedWord;
        keywords.add(finalWord);
      }
    }
    return keywords.toList();
  }

  /// Encuentra la FAQ más relevante y devuelve su URL específica
  Future<String?> findRelevantFaqUrl(String userMessage) async {
    final contextFaqs = await findContextFaqs(userMessage);
    if (contextFaqs.isNotEmpty) {
      final bestMatch = contextFaqs.first;
      if (bestMatch.link != null && bestMatch.link!.isNotEmpty) {
        print('🎯 URL específica encontrada: ${bestMatch.link}');
        return bestMatch.link;
      }
    }
    print('ℹ️ No se encontró URL específica en la base de datos');
    return null;
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
    // --- SINÓNIMOS EXISTENTES ---
    'municipio': 'municipalidad', 'comuna': 'municipalidad',
    'horarios': 'horario',
    'atencion': 'servicio', 'servicios': 'servicio', 'oficinas': 'oficina',
    'telefono': 'contacto', 'direccion': 'ubicacion', 'licencias': 'licencia',
    'permisos': 'permiso', 'documentos': 'documento', 'tramites': 'tramite',
    'medicos': 'medico', 'consultorios': 'consultorio', 'escuelas': 'escuela',
    'colegios': 'colegio', 'lugares': 'lugar', 'sitios': 'lugar',
    'destinos': 'destino',
    'hola': 'saludo', 'buenos': 'saludo', 'buenas': 'saludo',
    'gracias': 'despedida',
    'adios': 'despedida', 'chao': 'despedida', 'tren': 'tren_chico',
    'ferrocarril': 'tren_chico',
    'artesanas': 'artesania', 'crin': 'artesania_crin',
    'termas': 'aguas_termales',
    'balneario': 'playa', 'senderismo': 'trekking', 'caminatas': 'trekking',
    'mirador': 'vista_panoramica', 'petroglifos': 'arte_rupestre',
    'volcanes': 'volcan',
    'lagunas': 'laguna', 'zoit': 'zona_turistica', 'fiestas': 'eventos',
    'festivales': 'eventos',
    'celebraciones': 'eventos', 'alojamiento': 'hospedaje',
    'cabañas': 'hospedaje',
    'hoteles': 'hospedaje', 'camping': 'hospedaje', 'gastronomia': 'comida',
    'restaurantes': 'comida', 'comida': 'gastronomia',
    'transporte': 'movilidad',
    'vehiculo': 'movilidad', 'clima': 'tiempo', 'epoca': 'temporada',
    'estaciones': 'temporada',
    'salud': 'atencion_medica', 'cesfam': 'atencion_medica',
    'postas': 'atencion_medica',
    'veterinaria': 'mascotas', 'empleo': 'trabajo', 'omil': 'trabajo',
    'omdel': 'desarrollo_economico',
    'dideco': 'programas_sociales', 'deportes': 'actividad_fisica',
    'talleres': 'actividades_culturales',
    'compras': 'artesanias', 'souvenirs': 'artesanias',
    // --- NUEVOS SINÓNIMOS EN PORTUGUÉS ---
    'prefeito': 'alcalde',
    'prefeitura': 'municipalidad',
    'município': 'comuna',
    'escola': 'escuela',
    'colégio': 'colegio',
    'educação': 'educacion',
    'turismo': 'turismo',
    'trilhas': 'senderismo',
    'artesanato': 'artesania',
    'lago': 'lago',
    'saúde': 'salud',
    'médico': 'medico',
    'atendimento médico': 'atencion_medica',
    'serviços': 'servicios',
    'permissões': 'permisos',
    'licenças': 'licencias',
    'trâmites': 'tramites',
    'emergência': 'emergencia',
    'ajuda': 'ayuda',
    'perigo': 'peligro',
    'polícia': 'policia',
    'bombeiros': 'bomberos',
    'veículo': 'vehiculo',
    'mobilidade': 'movilidad',
    'cultura': 'cultura',
    'eventos': 'eventos',
    'festivais': 'festivales',
    'celebrações': 'celebraciones',
    'telefone': 'telefono',
    'endereço': 'direccion',
    'obrigado': 'gracias',
    'olá': 'hola',
    'adeus': 'adios',
    'horsehair': 'crin',
    'crafts': 'artesania',
    'rari': 'rari',
    'artisans': 'artesanas',
    'atividades': 'actividades',
    'atividades aquáticas': 'deportes_acuaticos',
    'esportes aquáticos': 'deportes_acuaticos',
    'água': 'agua',
    'lagoa': 'lago',
    'colbún': 'colbún',
    'pesca': 'pesca',
    'natação': 'natacion',
    'praia': 'playa',
    'remo': 'remo',
    'barco': 'bote',
    'barcos': 'bote',
    'canoagem': 'canoa',
    'caiaque': 'kayak',
    'catamarã': 'catamaran',
    'trilha': 'sendero',
    'caminhada': 'senderismo',
    'montanhas': 'montañas',
    'volcão': 'volcan',
    'vista panorâmica': 'vista_panoramica',
    'patrimônio cultural': 'patrimonio_cultural',
    'tradições': 'tradiciones',
    'artesanato tradicional': 'artesania_tradicional',
    'mercado artesanal': 'mercado_artesanal',
    'alojamento': 'hospedaje',
    'hospedagem': 'hospedaje',
    'comida típica': 'comida_tipica',
    'comunidade': 'comunidad',
    'escolas': 'escuelas',
    'biblioteca': 'biblioteca',
    'esportes': 'deportes',
    'tradição': 'tradicion',
    'prazer': 'relajacion',
    'bem-estar': 'bienestar',
    'terapia': 'terapia',
    'natureza': 'naturaleza',
    'aventura': 'aventura',
    'ecoturismo': 'ecoturismo',
    'igreja': 'iglesia',
    'pedra': 'piedra',
    'tecelagem': 'tejido',
    'tecido': 'tejido',
    'cobertor': 'manta',
    'trenzinho': 'tren_chico',
    'ferrovia': 'ferrocarril',
    'história': 'historia',
    'praça': 'plaza',
    'guia': 'guia',
    'reserva': 'reserva',
    'parque': 'parque',
    'roteiro': 'ruta',
    'roteiros': 'rutas',
    'curativo': 'curativo',
    'águas termais': 'aguas_termales',
    'banho': 'baño',
    'banhos': 'baños',
    // --- NUEVOS SINÓNIMOS PARA INGLÉS ---
    'who': 'quien', 'what': 'que', 'where': 'donde', 'when': 'cuando',
    'how': 'como',
    'mayor': 'alcalde', 'town': 'comuna', 'city': 'comuna',
    'municipality': 'municipalidad',
    'services': 'servicios', 'offer': 'ofrece', 'offers': 'ofrece',
    'provides': 'ofrece',
    'colbun': 'colbún', 'information': 'informacion', 'help': 'ayuda',
    'need': 'necesito',
    'want': 'quiero', 'find': 'encontrar', 'get': 'obtener', 'tell': 'decir',
    'know': 'saber', 'explain': 'explicar', 'show': 'mostrar', 'give': 'dar',
    'located': 'ubicado', 'address': 'direccion', 'phone': 'telefono',
    'email': 'correo',
    'schedule': 'horario', 'hours': 'horario', 'time': 'hora',
    'open': 'abierto',
    'closed': 'cerrado', 'available': 'disponible', 'cost': 'costo',
    'price': 'precio',
    'free': 'gratis', 'paid': 'pagado',
    'water activities': 'deportes acuaticos',
    'stand up paddle': 'paddle',
    'boat': 'bote',
    'boats': 'bote',
    'rowing': 'remo',
    'canoeing': 'canoa',
    'jet ski': 'moto_agua',
    'jet skiing': 'moto_agua',
    'catamaran': 'catamaran',
    'catamaraning': 'catamaran',
    'recreation': 'recreacion',

    // --- AUTORIDADES Y GOBIERNO ---
    'authorities': 'autoridades', 'government': 'gobierno',
    'official': 'funcionario',
    'leader': 'lider', 'president': 'presidente', 'director': 'director',
    'pedro': 'alcalde', 'pablo': 'alcalde', 'muñoz': 'alcalde',
    'munoz': 'alcalde',
    'oses': 'alcalde', 'pedro pablo': 'alcalde', 'alcalde': 'municipalidad',
    'activities': 'actividades',

    // --- SERVICIOS MUNICIPALES ---
    'veterinary': 'veterinaria', 'clinic': 'clinica', 'animal': 'mascota',
    'pet': 'mascota',
    'job': 'trabajo', 'employment': 'empleo', 'work': 'trabajo',
    'labor': 'laboral',
    'social': 'social', 'programs': 'programas', 'subsidy': 'subsidio',
    'scholarship': 'beca',
    'benefit': 'beneficio', 'assistance': 'asistencia', 'support': 'apoyo',
    'aid': 'ayuda',
    'cultural': 'cultural', 'dance': 'danza', 'theater': 'teatro',
    'music': 'musica',
    'painting': 'pintura', 'library': 'biblioteca', 'books': 'libros',
    'internet': 'internet',

    // --- TRÁMITES ---
    'driver': 'conductor', 'license': 'licencia', 'driving': 'conducir',
    'vehicle': 'vehiculo',
    'car': 'auto', 'motorcycle': 'motocicleta', 'permit': 'permiso',
    'circulation': 'circulacion',
    'renew': 'renovar', 'online': 'en_linea', 'portal': 'portal',
    'website': 'sitio_web',

    // --- SALUD ---
    'health': 'salud', 'hospital': 'hospital', 'doctor': 'doctor',
    'medical': 'medico',
    'appointment': 'cita', 'emergency': 'emergencia', 'rural': 'rural',

    // --- TURISMO Y ARTESANÍA ---
    'tourism': 'turismo', 'tourist': 'turista', 'attractions': 'atractivos',
    'handicraft': 'artesania', 'craft': 'artesania',
    'traditional': 'tradicional',
    'unesco': 'unesco',
    'lake': 'lago', 'water': 'agua', 'sports': 'deportes', 'kayak': 'kayak',
    'paddle': 'remo', 'fishing': 'pesca', 'beach': 'playa',
    'swimming': 'natacion',
    'history': 'historia', 'railway': 'ferrocarril', 'train': 'tren',
    'wagon': 'vagón',
    'square': 'plaza', 'festival': 'fiesta', 'goat': 'chivo',
    'tradition': 'tradicion',
    'archaeology': 'arqueologia', 'rock': 'roca', 'carvings': 'grabados',
    'thermal': 'termal', 'waters': 'aguas', 'mineral': 'mineral',
    'healing': 'curativo',
    'relaxation': 'relajacion', 'wellness': 'bienestar', 'therapy': 'terapia',
    'nature': 'naturaleza', 'adventure': 'aventura', 'ecotourism': 'ecoturismo',
    'panimavida': 'termas', 'quinamavida': 'termas', 'church': 'iglesia',
    'stone': 'piedra', 'toba': 'toba', 'loom': 'telar', 'mapuche': 'mapuche',
    'blanket': 'manta', 'poncho': 'poncho', 'mountains': 'montañas',
    'hiking': 'senderismo',
    'trekking': 'senderismo', 'birdwatching': 'avistamiento_aves',
    'view': 'vista',
    'panoramic': 'panoramica', 'cabin': 'cabana',
    'arriero': 'arriero', 'trails': 'senderos', 'paths': 'senderos',
    'route': 'ruta',
    'volcano': 'volcan', 'san pedro': 'volcan', 'san pablo': 'volcan',
    'hight': 'altura',
    'guide': 'guia', 'reservoir': 'embalse', 'machicura': 'balneario',
    'grill': 'quincho', 'playground': 'juegos_infantiles', 'rental': 'arriendo',
    'equipment': 'equipo', 'office': 'oficina',
    'tourist information': 'informacion_turistica',
    'craftsmanship': 'artesania',
    'handicrafts': 'artesania',
    'artisan': 'artesano',
    'weaving': 'tejido',
    'textiles': 'textiles',
    'hot springs': 'termas',
    'thermal waters': 'aguas_termales',
    'petroglyphs': 'arte_rupestre',
    'panoramic view': 'vista_panoramica',
    'cultural heritage': 'patrimonio_cultural',
    'traditions': 'tradiciones',
    'destination': 'destino',
    'spa': 'terapia',
    'traditional crafts': 'artesania_tradicional',
    'volcanic tuff': 'toba_volcanica',
    'festivals': 'eventos',
    'celebrations': 'celebraciones',
    'events': 'eventos',
    'commune': 'comuna',
    'health services': 'servicios_de_salud',
    'schools': 'escuelas',
    'water sports': 'deportes acuaticos',
    'kayaking': 'kayak',
    'lodging': 'hospedaje',
    'accommodation': 'hospedaje',
    'restaurants': 'restaurantes',
    'gastronomy': 'gastronomia',
    'local food': 'comida_tipica',
    'artisan market': 'mercado_artesanal',
    'culture': 'cultura',

    // --- EDUCACIÓN ---
    'education': 'educacion', 'school': 'escuela', 'high school': 'liceo',
    'kindergarten': 'jardin_infantil', 'basic': 'basica', 'studies': 'estudios',

    // --- INFORMACIÓN GENERAL ---
    'mission': 'mision', 'vision': 'vision', 'community': 'comunidad',
    'progress': 'progreso', 'economic': 'economico',
    'foundation': 'fundacion', 'name': 'nombre',
    'meaning': 'significado', 'snake': 'culebra', 'trees': 'arboles',

    // --- SALUDOS Y DESPEDIDAS ---
    'hello': 'saludo', 'hi': 'saludo', 'good morning': 'saludo',
    'good afternoon': 'saludo',
    'good evening': 'saludo', 'thanks': 'despedida', 'thank you': 'despedida',
    'bye': 'despedida', 'goodbye': 'despedida', 'see you': 'despedida',

    // --- PALABRAS VACÍAS (se mapean a cadena vacía) ---
    'does': '', 'is': '', 'the': '', 'a': '', 'an': '', 'and': '', 'or': '',
    'but': '',
    'in': '', 'on': '', 'at': '', 'to': '', 'for': '', 'of': '', 'with': '',
    'by': '',
    'about': '', 'as': '', 'into': '', 'like': '', 'through': '', 'after': '',
    'over': '',
    'between': '', 'out': '', 'against': '', 'during': '', 'without': '',
    'before': '',
    'under': '', 'around': '', 'among': '', 'upon': '', 'within': '',
    'throughout': '',
    'towards': '', 'from': '', 'up': '', 'down': '', 'off': '', 'above': '',
    'below': '',
    'behind': '', 'beside': '', 'beyond': '', 'near': '', 'since': '',
    'until': '',
    'while': '', 'although': '', 'because': '', 'unless': '', 'whether': '',
    'both': '', 'either': '', 'neither': '', 'each': '', 'every': '', 'all': '',
    'any': '',
    'some': '', 'such': '', 'own': '', 'same': '', 'so': '', 'than': '',
    'too': '',
    'very': '', 'just': '', 'now': '', 'then': '', 'more': '', 'most': '',
    'less': '',
    'least': '', 'only': '', 'much': '', 'many': '', 'few': '', 'little': '',
    'several': '', 'no': '',
    'not': '', 'nor': '', 'also': '', 'however': '', 'therefore': '',
    'thus': '',
    'consequently': '', 'furthermore': '', 'moreover': '', 'nevertheless': '',
    'nonetheless': '', 'otherwise': '', 'similarly': '', 'accordingly': '',
    'hence': '', 'meanwhile': '', 'finally': '', 'ultimately': ''
  };
  static const Set<String> _excludeWords = {
    // --- PALABRAS EXCLUIDAS EN ESPAÑOL ---
    'como', 'donde', 'cuando', 'cual', 'cuales', 'quien', 'que', 'para', 'con',
    'por',
    'una', 'uno', 'esta', 'este', 'son', 'hay', 'tiene', 'puede', 'puedo',
    'debo',
    'necesito', 'quiero', 'hacer', 'obtener', 'encontrar', 'ubicado', 'ubicada',
    'algun', 'algunos', 'algunas', 'otros', 'otras', 'mismo', 'misma', 'mismos',
    'mismas', 'todo', 'toda', 'todos', 'todas', 'ningun', 'ninguna', 'nada',
    'nadie', 'siempre', 'nunca', 'jamas', 'tampoco', 'ademas', 'incluso',
    'solo', 'solamente', 'unicamente', 'aparte', 'encima', 'debajo', 'delante',
    'detras', 'cerca', 'lejos', 'arriba', 'abajo', 'dentro', 'fuera', 'antes',
    'despues', 'durante', 'mientras', 'hasta', 'desde', 'hacia', 'sobre',
    'bajo',
    'entre', 'contra', 'según', 'mediante', 'versus', 'vía', 'excepto', 'salvo',
    'menos', 'mas', 'muy', 'mucho', 'poco', 'bastante', 'demasiado', 'tan',
    'tanto',
    'casi', 'apenas', 'justo', 'exacto', 'preciso', 'quizas', 'acaso', 'talvez',
    'probablemente', 'posiblemente', 'definitivamente', 'ciertamente',
    'realmente',
    'verdaderamente', 'actualmente', 'finalmente', 'inicialmente',
    'basicamente',
    'esencialmente', 'fundamentalmente', 'principalmente', 'especialmente',
    'particularmente', 'generalmente', 'normalmente', 'usualmente',
    'habitualmente',
    'frecuentemente', 'constantemente', 'si', 'no', 'tambien',
    'inclusive', 'exclusivamente', 'específicamente',
    // --- PALABRAS EXCLUIDAS EN PORTUGUÉS ---
    'onde', 'quando', 'qual', 'quais', 'quem', 'com',
    'um', 'uma', 'uns', 'umas', 'estes', 'estas', 'isso',
    'aquele', 'aquela', 'aqueles', 'aquelas', 'há', 'tem', 'pode', 'posso',
    'devo',
    'quero', 'fazer', 'obter', 'localizado', 'localizada',
    'algum', 'alguns', 'algumas', 'outro', 'outra', 'outros', 'outras', 'mesmo',
    'mesma', 'mesmos', 'mesmas', 'nenhum',
    'nenhuma', 'ninguém', 'sempre', 'jamais', 'tampouco',
    'além', 'somente', 'só', 'em cima', 'embaixo',
    'na frente', 'atrás', 'perto', 'longe', 'acima', 'abaixo', 'fora',
    'depois', 'enquanto', 'até', 'sob',
    'segundo', 'via', 'exceto',
    'mais', 'muito', 'pouco', 'demais', 'tão',
    'quase', 'exato', 'provavelmente',
    'possivelmente', 'certamente', 'verdadeiramente',
    'atualmente', 'essencialmente',
    'geralmente', 'frequentemente',
    'sim', 'não', 'também', 'especificamente',
    'porque', 'se', 'caso', 'embora', 'apesar',
    'contudo', 'entretanto', 'portanto', 'além disso', 'porém', 'todavia',
    // --- PALABRAS EXCLUIDAS EN INGLÉS ---
    'how', 'where', 'when', 'which', 'what', 'who', 'whos', 'the', 'a', 'an',
    'is',
    'are', 'am', 'do', 'does', 'can', 'could', 'should', 'would', 'have', 'has',
    'need', 'want', 'get', 'find', 'located', 'some', 'any', 'this', 'that',
    'these',
    'those', 'there', 'here', 'and', 'or', 'but', 'if', 'because', 'although',
    'while', 'since', 'until', 'unless', 'whether', 'though', 'even', 'rather',
    'quite', 'very', 'too', 'so', 'such', 'just', 'only', 'merely', 'simply',
    'actually', 'really', 'truly', 'certainly', 'definitely', 'probably',
    'possibly',
    'perhaps', 'maybe', 'almost', 'nearly', 'hardly', 'scarcely', 'barely',
    'completely', 'totally', 'absolutely', 'entirely', 'fully', 'wholly',
    'partially',
    'partly', 'mostly', 'mainly', 'chiefly', 'primarily', 'essentially',
    'basically',
    'fundamentally', 'generally', 'usually', 'normally', 'typically', 'often',
    'frequently', 'sometimes', 'occasionally', 'rarely', 'seldom', 'never',
    'always',
    'ever', 'already', 'yet', 'still', 'now', 'then', 'soon', 'later',
    'early', 'late', 'recently', 'currently', 'presently', 'formerly',
    'previously',
    'initially', 'finally', 'eventually', 'ultimately', 'consequently',
    'therefore',
    'thus', 'hence', 'accordingly', 'however', 'nevertheless', 'nonetheless',
    'otherwise', 'instead', 'meanwhile', 'furthermore', 'moreover', 'besides',
    'additionally', 'also', 'as well', 'either', 'neither', 'both', 'each',
    'every', 'all', 'none', 'nothing', 'nobody', 'nowhere',
    'once', 'twice', 'thrice', 'first', 'second', 'third', 'last',
    'next', 'previous', 'former', 'latter', 'above', 'below', 'under', 'over',
    'beneath', 'beside', 'between', 'among', 'around', 'behind', 'beyond',
    'through',
    'throughout', 'toward', 'towards', 'upon', 'within', 'without', 'against',
    'along', 'amongst', 'amid', 'amidst', 'atop', 'barring', 'concerning',
    'considering', 'despite', 'during', 'except', 'excluding', 'following',
    'including', 'like', 'minus', 'near', 'onto', 'opposite', 'outside', 'past',
    'per', 'plus', 'regarding', 'round', 'save', 'than', 'times', 'unto',
    'worth', 'aboard', 'about', 'across', 'after',
    'anti', 'as', 'at', 'before',
    'by', 'down', 'excepting',
    'for', 'from', 'in', 'inside', 'into',
    'of', 'off', 'on', 'to', 'underneath', 'unlike', 'up',
    'with',
  };
}
