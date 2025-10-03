import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';


class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);

  /// Detecta el idioma del texto (español o inglés)
  Future<String> detectLanguage(String text) async {
    try {
      print("🔤 LANGUAGE SERVICE - Texto a analizar: '$text'");
      if (text.isEmpty) {
        print("🔤 LANGUAGE SERVICE - Texto vacío, usando español por defecto");
        return 'es';
      }

      final String response = await _languageIdentifier.identifyLanguage(text);
      print("🔤 LANGUAGE SERVICE - Respuesta ML Kit: '$response'");

      // Mapear códigos de idioma a nuestros códigos internos
      if (response == 'en') {
        print("🔤 LANGUAGE SERVICE - Idioma detectado: INGLÉS");
        return 'en';
      } else if (response == 'es') {
        print("🔤 LANGUAGE SERVICE - Idioma detectado: ESPAÑOL");
        return 'es';
      } else {
        print("🔤 LANGUAGE SERVICE - Idioma no reconocido: '$response', usando español");
        // Para cualquier otro idioma, usar español como fallback
        return 'es';
      }
    } catch (e) {
      print('❌ Error en detección de idioma: $e');
      return 'es'; // Fallback a español
    }
  }

  /// Cierra el identificador de idioma cuando ya no se necesite
  void close() {
    _languageIdentifier.close();
  }
}