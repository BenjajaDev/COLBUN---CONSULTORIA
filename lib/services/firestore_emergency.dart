import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class EmergencyContact {
  final String id;
  final List<String> keyWords;
  final List<String> keyWordsEn;
  final List<String>
      keyWordsPt; // Palabras clave en portugués (si se agregan en Firestore)
  final String name;
  final String nameEn;
  final String namePt; // Nombre en portugués (si se agrega en Firestore)
  final String phone;
  final String type;
  final String typeEn;
  final String typePt;

  EmergencyContact({
    required this.id,
    required this.keyWords,
    required this.keyWordsEn,
    required this.keyWordsPt,
    required this.name,
    required this.nameEn,
    required this.phone,
    required this.type,
    required this.typeEn,
    required this.namePt,
    required this.typePt,
  });

  factory EmergencyContact.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyContact(
      id: doc.id,
      keyWords: List<String>.from(data['key_words'] ?? []),
      keyWordsEn:
          List<String>.from(data['key_words_en'] ?? data['key_words'] ?? []),
      keyWordsPt: List<String>.from(data['key_words_pt'] ?? []),
      name: data['name'] ?? '',
      nameEn: data['name_en'] ?? data['name'] ?? '',
      namePt: data['name_pt'] ?? '',
      phone: data['phone'] ?? '',
      type: data['type'] ?? '',
      typeEn: data['type_en'] ?? data['type'] ?? '',
      typePt: data['type_pt'] ?? '',
    );
  }
  String getName(String language) {
    return language == 'en' && nameEn.isNotEmpty
        ? nameEn
        : language == 'pt' && namePt.isNotEmpty
            ? namePt
            : name;
  }

  String getType(String language) {
    return language == 'en' && typeEn.isNotEmpty
        ? typeEn
        : language == 'pt' && typePt.isNotEmpty
            ? typePt
            : type;
  }

  List<String> getKeyWords(String language) {
    return language == 'en' && keyWordsEn.isNotEmpty
        ? keyWordsEn
        : language == 'pt' && keyWordsPt.isNotEmpty
            ? keyWordsPt
            : keyWords;
  }
}

class EmergencyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<EmergencyContact> _emergencyContacts = [];

  // Palabras clave adicionales para detección (español e inglés)
  static const Map<String, List<String>> _emergencyKeywords = {
    'es': [
      'emergencia',
      'ayuda',
      'auxilio',
      'urgencia',
      'peligro',
      'accidente',
      'riesgo',
      'policía',
      'ambulancia',
      'bomberos',
      'hospital',
      'médico',
      'doctor',
      'enfermo',
      'enferma',
      'me siento mal',
      'me duele',
      'sangrando',
      'herido',
      'herida',
      'incendio',
      'fuego',
      'asalto',
      'robo',
      'amenaza',
      'pérdida',
      'extraviado',
      'desaparecido',
      'violencia',
      'ataque',
      'infarto',
      'derrame',
      'convulsión',
      'ahogando',
      'quemadura',
      'fractura',
      'intoxicación',
      'envenenamiento',
      'suicidio',
      'depresión',
      'ansiedad',
      'crisis',
      'ataque de pánico',
      'desmayo',
      'mareo',
      'numero de'
    ],
    'en': [
      'emergency',
      'help',
      'urgent',
      'danger',
      'accident',
      'risk',
      'police',
      'ambulance',
      'firefighters',
      'hospital',
      'doctor',
      'sick',
      'i feel bad',
      'i feel sick',
      'pain',
      'bleeding',
      'injured',
      'wounded',
      'fire',
      'assault',
      'robbery',
      'threat',
      'lost',
      'missing',
      'violence',
      'attack',
      'heart attack',
      'stroke',
      'seizure',
      'drowning',
      'burn',
      'fracture',
      'poisoning',
      'suicide',
      'depression',
      'anxiety',
      'crisis',
      'panic attack',
      'faint',
      'dizzy',
      'number of'
    ],
    //prompt: necesito tambien palabras clave adicionales para deteccion en portugues que si hay iguales que en español no las coloque
    'pt': [
      'emergência',
      'ajuda',
      'urgente',
      'perigo',
      'acidente',
      'risco',
      'polícia',
      'ambulância',
      'bombeiros',
      'hospital',
      'médico',
      'doente',
      'sinto-me mal',
      'dor',
      'sangrando',
      'ferido',
      'incêndio',
      'assalto',
      'roubo',
      'ameaça',
      'perdido',
      'desaparecido',
      'violência',
      'ataque',
      'infarto',
      'derrame',
      'convulsão',
      'afogamento',
      'queimadura',
      'fratura',
      'intoxicação',
      'suicídio',
      'depressão',
      'ansiedade',
      'crise',
      'ataque de pânico',
      'desmaio',
      'tontura',
      'número de'
    ]
  };

  // Palabras excluidas para evitar falsos positivos
  static const Set<String> _excludeWords = {
    'no es emergencia',
    'no es una emergencia',
    'solo pregunta',
    'información',
    'consultar',
    'preguntar',
    'not emergency',
    'just asking',
    'information',
    'consult',
    'ask',
    'não é emergência',
    'só perguntar',
    'informação',
    'perguntar', 'como te llamas', 'cuál es tu nombre', 'te llamo más tarde', 'llámame', 'no me llames',
    'como te chamas', 'obrigado', 'obrigada', 'estou chamando', 'chama-me',
    'firewall', 'painstaking', 'heartfelt',
  };

  Future<void> loadEmergencyContacts() async {
    try {
      final querySnapshot = await _db.collection('emergency_contacts').get();
      _emergencyContacts = querySnapshot.docs
          .map((doc) => EmergencyContact.fromFirestore(doc))
          .toList();
      print('✅ Emergency contacts loaded: ${_emergencyContacts.length}');
      print(
          '🔍 Contactos cargados con key_words_en: ${_emergencyContacts.where((c) => c.keyWordsEn.isNotEmpty).length}');
    } catch (e, st) {
      try {
        FirebaseCrashlytics.instance.recordError(e, st,
            reason: 'EmergencyService.loadEmergencyContacts');
      } catch (_) {}
      print('❌ Error loading emergency contacts: $e');
    }
  }

  /// Detecta si el mensaje indica una emergencia
  bool detectEmergency(String message, String language) {
    final cleanMessage = message.toLowerCase().trim();

    // Evitar falsos positivos
    for (final excludeWord in _excludeWords) {
      if (cleanMessage.contains(excludeWord)) {
        return false;
      }
    }

    // Buscar en palabras clave del idioma detectado
    final keywords = _emergencyKeywords[language] ?? _emergencyKeywords['es']!;

    // Match keywords as whole words to avoid false positives (e.g., 'obrigado')
    for (final keyword in keywords) {
      final k = keyword.toLowerCase().trim();
      if (k.isEmpty) continue;
      final pattern =
          RegExp(r"\b" + RegExp.escape(k) + r"\b", caseSensitive: false);
      if (pattern.hasMatch(cleanMessage)) {
        print('🚨 Emergency detected by keyword: $keyword');
        return true;
      }
    }

    // Buscar en contactos de emergencia de la base de datos
    for (final contact in _emergencyContacts) {
      final contactKeywords =
          contact.getKeyWords(language); // ✅ USAR getKeyWords CON IDIOMA
      for (final keyword in contactKeywords) {
        final k = keyword.toLowerCase().trim();
        if (k.isEmpty) continue;
        final pattern =
            RegExp(r"\b" + RegExp.escape(k) + r"\b", caseSensitive: false);
        if (pattern.hasMatch(cleanMessage)) {
          print(
              '🚨 Emergency contact match: ${contact.getName(language)} - Keyword: $keyword');
          return true;
        }
      }
    }

    return false;
  }

  /// Obtiene contactos de emergencia relevantes para el mensaje
  List<EmergencyContact> getRelevantContacts(String message, String language) {
    final cleanMessage = message.toLowerCase();
    final relevantContacts = <EmergencyContact>[];

    for (final contact in _emergencyContacts) {
      final contactKeywords = contact.getKeyWords(language);
      for (final keyword in contactKeywords) {
        if (keyword.isNotEmpty &&
            cleanMessage.contains(keyword.toLowerCase())) {
          relevantContacts.add(contact);
          print(
              '🔍 Contacto relevante encontrado: ${contact.getName(language)} - Palabra clave: $keyword');
          break;
        }
      }
    }

    // Si no hay coincidencias específicas, devolver todos los contactos
    return relevantContacts.isNotEmpty ? relevantContacts : _emergencyContacts;
  }

  /// Realiza una llamada telefónica
  Future<void> makeCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'No se pudo realizar la llamada';
      }
    } catch (e, st) {
      try {
        FirebaseCrashlytics.instance
            .recordError(e, st, reason: 'EmergencyService.makeCall');
      } catch (_) {}
      print('❌ Error making call: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> getFormattedContacts(
      List<EmergencyContact> contacts, String language) {
    return contacts.map((contact) {
      return {
        'name': contact.getName(language),
        'phone': contact.phone,
        'type': contact.getType(language),
      };
    }).toList();
  }

  List<EmergencyContact> get allContacts => _emergencyContacts;
}
