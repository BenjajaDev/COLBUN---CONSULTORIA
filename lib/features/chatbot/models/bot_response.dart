// ===========================================================================
// MODELO DE RESPUESTA DEL BOT
// ===========================================================================
/// Clase que representa una respuesta generada por el chatbot
/// Incluye el texto de respuesta, acciones opcionales, enlaces y metadatos
class BotResponse {
  // ===========================================================================
  // PROPIEDADES
  // ===========================================================================
  final String answer;              // Texto de la respuesta del bot
  final String? action;             // Accion opcional asociada a la respuesta
  final bool isStandardResponse;    // Indica si es una respuesta estandar que requiere feedback
  final String? link;               // URL de fuente o enlace relacionado
  final String? source;             // Fuente de la informacion
  final String language;            // Idioma de la respuesta (es, en, pt)

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================
  BotResponse({
    required this.answer,
    this.action,
    this.isStandardResponse = true,
    this.link,
    this.source,
    required this.language,
  });
}