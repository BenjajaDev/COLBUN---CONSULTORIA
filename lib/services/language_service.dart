// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

// ===========================================================================
// SERVICIO DE DETECCION DE IDIOMA
// ===========================================================================
/// Servicio para detectar el idioma de un texto usando ML Kit de Google
/// Soporta deteccion de espanol, ingles y portugues
/// Implementa patron Singleton y fallback a heuristica si ML Kit no esta disponible
class LanguageService {
  // ===========================================================================
  // PATRON SINGLETON
  // ===========================================================================
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  
  // ===========================================================================
  // CONSTRUCTOR E INICIALIZACION
  // ===========================================================================
  LanguageService._internal() {
    // Inicializar el identificador solo cuando no estemos en web
    if (!kIsWeb) {
      try {
        _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      } catch (e, st) {
        // En caso de error, registramos y seguiremos con heuristica
        try {
          FirebaseCrashlytics.instance
              .recordError(e, st, reason: 'LanguageService.init');
        } catch (_) {}
        print('⚠️ No se pudo inicializar MLKit LanguageIdentifier: $e');
        _languageIdentifier = null;
      }
    } else {
      _languageIdentifier = null;
    }
  }

  // ===========================================================================
  // PROPIEDADES
  // ===========================================================================
  LanguageIdentifier? _languageIdentifier; // Identificador de ML Kit (null en web)

  // ===========================================================================
  // DETECCION DE IDIOMA
  // ===========================================================================
  /// Detecta el idioma del texto (espanol, ingles o portugues)
  /// Usa ML Kit si esta disponible, sino usa heuristica basada en caracteres especiales
  Future<String> detectLanguage(String text) async {
    print("🔤 LANGUAGE SERVICE - Texto a analizar: '$text'");

    // Validar texto vacio
    if (text.isEmpty) {
      print("🔤 LANGUAGE SERVICE - Texto vacio, usando espanol por defecto");
      return 'es';
    }
    
    // Detectar caracteres especiales para heuristica
    final containsAsciiLetters = RegExp(r'[A-Za-z]').hasMatch(text);
    final containsSpanishChars = RegExp(r'[áéíóúñüÁÉÍÓÚÑ]').hasMatch(text);
    final containsPortugueseChars =
        RegExp(r'[ãõâêôáéíóúçÁÉÍÓÚÂÊÔÃÕÇ]').hasMatch(text);

    // ===========================================================================
    // FALLBACK: HEURISTICA SIMPLE (SI NO HAY ML KIT)
    // ===========================================================================
    // Si no hay implementacion del plugin (p. ej. web) usar heuristica simple
    if (_languageIdentifier == null) {
      try {
        // Detectar portugues por caracteres especificos
        if (containsPortugueseChars) {
          print("🔤 LANGUAGE SERVICE (heuristica) - Detectado: PT");
          return 'pt';
        }
        // Detectar ingles por ausencia de caracteres en espanol
        if (containsAsciiLetters && !containsSpanishChars) {
          print("🔤 LANGUAGE SERVICE (heuristica) - Detectado: EN");
          return 'en';
        }
        // Por defecto asumir espanol
        print("🔤 LANGUAGE SERVICE (heuristica) - Detectado: ES");
        return 'es';
      } catch (e, st) {
        try {
          FirebaseCrashlytics.instance
              .recordError(e, st, reason: 'LanguageService.heuristic');
        } catch (_) {}
        print('❌ Error en heuristica de idioma: $e');
        return 'es';
      }
    }

    // ===========================================================================
    // DETECCION CON ML KIT
    // ===========================================================================
    try {
      final String response = await _languageIdentifier!.identifyLanguage(text);
      print("🔤 LANGUAGE SERVICE - Respuesta ML Kit: '$response'");

      // Mapear respuesta de ML Kit a codigo de idioma
      if (response == 'en') {
        print("🔤 LANGUAGE SERVICE - Idioma detectado: INGLES");
        return 'en';
      } else if (response == 'es') {
        print("🔤 LANGUAGE SERVICE - Idioma detectado: ESPANOL");
        return 'es';
      } else if (response == 'pt') {
        print("🔤 LANGUAGE SERVICE - Idioma detectado: PORTUGUES");
        return 'pt';
      } else {
        print(
            "🔤 LANGUAGE SERVICE - Idioma no reconocido: '$response', usando espanol");
        return 'es';
      }
    } catch (e, st) {
      // Si ML Kit falla, usar heuristica como fallback
      try {
        FirebaseCrashlytics.instance
            .recordError(e, st, reason: 'LanguageService.detectLanguage_mlkit');
      } catch (_) {}
      print('❌ Error en deteccion de idioma (ML Kit): $e');
      
      // Fallback a heuristica
      final containsAsciiLetters = RegExp(r'[A-Za-z]').hasMatch(text);
      final containsSpanishChars = RegExp(r'[áéíóúñüÁÉÍÓÚÑ]').hasMatch(text);
      final containsPortugueseChars =
          RegExp(r'[ãõâêôáéíóúçÁÉÍÓÚÂÊÔÃÕÇ]').hasMatch(text);
      if (containsPortugueseChars) return 'pt';
      if (containsAsciiLetters && !containsSpanishChars) return 'en';
      return 'es';
    }
  }

  // ===========================================================================
  // LIMPIEZA DE RECURSOS
  // ===========================================================================
  /// Cierra el identificador de idioma cuando ya no se necesite
  /// Libera recursos de ML Kit
  void close() {
    if (_languageIdentifier != null) {
      _languageIdentifier!.close();
    }
  }
}
