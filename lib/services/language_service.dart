import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal() {
    // Inicializar el identificador solo cuando no estemos en web
    if (!kIsWeb) {
      try {
        _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      } catch (e) {
        // En caso de error, lo registramos y seguiremos con la heurística
        print('⚠️ No se pudo inicializar MLKit LanguageIdentifier: $e');
        _languageIdentifier = null;
      }
    } else {
      _languageIdentifier = null;
    }
  }

  LanguageIdentifier? _languageIdentifier;

  /// Detecta el idioma del texto (español o inglés)
  Future<String> detectLanguage(String text) async {
    print("🔤 LANGUAGE SERVICE - Texto a analizar: '$text'");

    if (text.isEmpty) {
      print("🔤 LANGUAGE SERVICE - Texto vacío, usando español por defecto");
      return 'es';
    }

    // Si no hay implementacion del plugin (p. ej. web) usar heurística simple
    if (_languageIdentifier == null) {
      try {
        // Heurística: si contiene letras ASCII sin tildes y no contiene caracteres acentuados en español => ingles
        final containsAsciiLetters = RegExp(r'[A-Za-z]').hasMatch(text);
        final containsSpanishChars = RegExp(r'[áéíóúñüÁÉÍÓÚÑ]').hasMatch(text);
        if (containsAsciiLetters && !containsSpanishChars) {
          print("🔤 LANGUAGE SERVICE (heurística) - Detectado: EN");
          return 'en';
        }
        print("🔤 LANGUAGE SERVICE (heurística) - Detectado: ES");
        return 'es';
      } catch (e) {
        print('❌ Error en heurística de idioma: $e');
        return 'es';
      }
    }

    try {
      final String response = await _languageIdentifier!.identifyLanguage(text);
      print("🔤 LANGUAGE SERVICE - Respuesta ML Kit: '$response'");

      if (response == 'en') {
        print("🔤 LANGUAGE SERVICE - Idioma detectado: INGLÉS");
        return 'en';
      } else if (response == 'es') {
        print("🔤 LANGUAGE SERVICE - Idioma detectado: ESPAÑOL");
        return 'es';
      } else {
        print(
            "🔤 LANGUAGE SERVICE - Idioma no reconocido: '$response', usando español");
        return 'es';
      }
    } catch (e) {
      print('❌ Error en detección de idioma (ML Kit): $e');
      // Fallback a heurística
      final containsAsciiLetters = RegExp(r'[A-Za-z]').hasMatch(text);
      final containsSpanishChars = RegExp(r'[áéíóúñüÁÉÍÓÚÑ]').hasMatch(text);
      if (containsAsciiLetters && !containsSpanishChars) return 'en';
      return 'es';
    }
  }

  /// Cierra el identificador de idioma cuando ya no se necesite
  void close() {
    if (_languageIdentifier != null) {
      _languageIdentifier!.close();
    }
  }
}
