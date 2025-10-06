import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContact {
  final String id;
  final List<String> keyWords;
  final List<String> keyWordsEn;
  final String name;
  final String nameEn;
  final String phone;
  final String type;
  final String typeEn;

  EmergencyContact({
    required this.id,
    required this.keyWords,
    required this.keyWordsEn,
    required this.name,
    required this.nameEn,
    required this.phone,
    required this.type,
    required this.typeEn,
  });

  factory EmergencyContact.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyContact(
      id: doc.id,
      keyWords: List<String>.from(data['key_words'] ?? []),
      keyWordsEn: List<String>.from(data['key_words_en'] ?? data['key_words'] ?? []),
      name: data['name'] ?? '',
      nameEn: data['name_en'] ?? data['name'] ?? '',
      phone: data['phone'] ?? '',
      type: data['type'] ?? '',
      typeEn: data['type_en'] ?? data['type'] ?? '',
    );
  }
  String getName(String language) {
    return language == 'en' && nameEn.isNotEmpty ? nameEn : name;
  }
  String getType(String language) {
    return language == 'en' && typeEn.isNotEmpty ? typeEn : type;
  }
  List<String> getKeyWords(String language){
    return language == 'en' && keyWordsEn.isNotEmpty ? keyWordsEn : keyWords;
  }

}

class EmergencyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<EmergencyContact> _emergencyContacts = [];

  // Palabras clave adicionales para detección (español e inglés)
  static const Map<String, List<String>> _emergencyKeywords = {
    'es': [
      'emergencia', 'ayuda', 'socorro', 'auxilio', 'urgencia', 'peligro',
      'accidente', 'riesgo', 'policía', 'ambulancia', 'bomberos', 'hospital',
      'médico', 'doctor', 'enfermo', 'enferma', 'me siento mal', 'me duele',
      'sangrando', 'herido', 'herida', 'incendio', 'fuego', 'asalto', 'robo',
      'amenaza', 'pérdida', 'extraviado', 'desaparecido', 'violencia',
      'ataque', 'infarto', 'derrame', 'convulsión', 'ahogando', 'quemadura',
      'fractura', 'intoxicación', 'envenenamiento', 'suicidio', 'depresión',
      'ansiedad', 'crisis', 'ataque de pánico', 'desmayo', 'mareo', 'numero de'
    ],
    'en': [
      'emergency', 'help', 'urgent', 'danger', 'accident', 'risk',
      'police', 'ambulance', 'firefighters', 'hospital', 'doctor',
      'sick', 'i feel bad', 'i feel sick', 'pain', 'bleeding',
      'injured', 'wounded', 'fire', 'assault', 'robbery', 'threat',
      'lost', 'missing', 'violence', 'attack', 'heart attack',
      'stroke', 'seizure', 'drowning', 'burn', 'fracture',
      'poisoning', 'suicide', 'depression', 'anxiety', 'crisis',
      'panic attack', 'faint', 'dizzy', 'number of'
    ]
  };

  // Palabras excluidas para evitar falsos positivos
  static const Set<String> _excludeWords = {
    'no es emergencia', 'no es una emergencia', 'solo pregunta',
    'información', 'consultar', 'preguntar', 'not emergency',
    'just asking', 'information', 'consult'
  };

  Future<void> loadEmergencyContacts() async {
    try {
      final querySnapshot = await _db.collection('emergency_contacts').get();
      _emergencyContacts = querySnapshot.docs
          .map((doc) => EmergencyContact.fromFirestore(doc))
          .toList();
      print('✅ Emergency contacts loaded: ${_emergencyContacts.length}');
      print('🔍 Contactos cargados con key_words_en: ${_emergencyContacts.where((c) => c.keyWordsEn.isNotEmpty).length}');
    } catch (e) {
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
    
    for (final keyword in keywords) {
      if (cleanMessage.contains(keyword.toLowerCase())) {
        print('🚨 Emergency detected: $keyword');
        return true;
      }
    }

    // Buscar en contactos de emergencia de la base de datos
    for (final contact in _emergencyContacts) {
      final contactKeywords = contact.getKeyWords(language); // ✅ USAR getKeyWords CON IDIOMA
      for (final keyword in contactKeywords) {
        if (keyword.isNotEmpty && cleanMessage.contains(keyword.toLowerCase())) {
          print('🚨 Emergency contact match: ${contact.getName(language)} - Keyword: $keyword');
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
        if (keyword.isNotEmpty && cleanMessage.contains(keyword.toLowerCase())) {
          relevantContacts.add(contact);
          print('🔍 Contacto relevante encontrado: ${contact.getName(language)} - Palabra clave: $keyword');
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
    } catch (e) {
      print('❌ Error making call: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> getFormattedContacts(List<EmergencyContact> contacts, String language) {
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