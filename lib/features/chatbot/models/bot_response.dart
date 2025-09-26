class BotResponse {
  final String answer;
  final String? action; // El action es opcional
  final bool isStandardResponse;
  final String? link; // Nuevo campo para el link/fuente
  final String? source; // Indica si es una respuesta estándar que requiere feedback

  BotResponse({
    required this.answer,
    this.action,
    this.isStandardResponse = true,
    this.link, // Nuevo parámetro opcional
    this.source,
  });
}