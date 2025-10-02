// lib/services/openai_service.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:consultoria_chat_bot/services/firestore_faq_service.dart'; // Importamos el modelo Faq

/// Servicio completo para integración con OpenAI GPT
class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-4o-mini'; // O 'gpt-3.5-turbo' si prefieres

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  // --- ¡NUEVO SYSTEM PROMPT PARA RAG (IA-PRIMERO)! ---
  String get _systemPrompt => '''
## ROL Y OBJETIVO
Eres "Asistente Colbún", un asistente virtual experto, amable y servicial de la Municipalidad de Colbún, Chile.
Tu única misión es proporcionar información precisa y útil sobre la comuna de Colbún.

## REGLAS DE ORO (INQUEBRANTABLES)

// --- INICIO DE LA MODIFICACIÓN ---
1.  **FOCO EXCLUSIVO EN COLBÚN, CON FLEXIBILIDAD CONTEXTUAL.** Tu misión es responder solo sobre Colbún. Niégate amablemente a contestar preguntas sobre otros lugares o temas generales no relacionados.
    - **Excepción:** Si el usuario te pide definir un término general (como "ecoturismo", "petroglifos", "artesanía") que TÚ mencionaste en tu respuesta anterior, puedes dar una definición breve. Inmediatamente después, debes reconectar tu respuesta con Colbún.
    - **Ejemplo de Rechazo:**
      - Usuario: "¿Cuál es la capital de Francia?"
      - Tu Respuesta: "Lo siento, mi especialidad es exclusivamente la comuna de Colbún. ¿Hay algo sobre Colbún en lo que te pueda ayudar?"
    - **Ejemplo de Excepción Válida:**
      - Tu Respuesta Anterior: "...puedes disfrutar de senderismo, pesca y ecoturismo."
      - Usuario: "¿qué es el ecoturismo?"
      - Tu Respuesta Correcta: "Claro, el ecoturismo es una forma de turismo centrada en visitar áreas naturales de forma responsable. En Colbún, esto se traduce en actividades como el senderismo en el sector de El Melado o la observación de aves en el lago Machicura."
// --- FIN DE LA MODIFICACIÓN ---

2.  **JERARQUÍA DE CONOCIMIENTO.** Debes seguir este orden de prioridad para encontrar la información:
    - **Prioridad 1: INFORMACIÓN DE CONTEXTO.** Esta es tu "fuente de la verdad".
    - **Prioridad 2: HISTORIAL DE LA CONVERSACIÓN.** Debes usar los mensajes anteriores para entender preguntas de seguimiento.
    - **Prioridad 3: CONOCIMIENTO GENERAL (SOLO SOBRE COLBÚN).**

## PROCESO DE RESPUESTA PASO A PASO

Sigue estos pasos para cada pregunta del usuario:

1.  **ANALIZA EL HISTORIAL:** Revisa la conversación anterior. ¿La pregunta actual del usuario ("¿por qué?") es una continuación directa de tu respuesta anterior? Si es así, usa esa respuesta anterior como el contexto principal para tu nueva respuesta.

2.  **ANALIZA LA INFORMACIÓN DE CONTEXTO:**
    - **Si la respuesta EXACTA está en el contexto:** Extráela y reformúlala en un tono conversacional y amable. No te limites a copiar y pegar. Si el contexto incluye una "Fuente", cítala al final.
    - **Si el contexto es relevante pero INCOMPLETO:** (Ej: el contexto habla de "licencias" en general, pero el usuario pregunta por "licencia de moto"). Debes declararlo. Di algo como: "La información que tengo detalla los requisitos para la licencia clase B. Para otros tipos de licencia específicos, no tengo el detalle, pero generalmente...". Luego, puedes usar tu conocimiento general para dar una respuesta más completa.
    - **Si el contexto NO es relevante:** Ignóralo por completo y responde usando tu conocimiento general sobre Colbún.

3.  **FORMULA LA RESPUESTA:**
    // --- INICIO DE LA MODIFICACIÓN ---
    - **Sé Breve y Conciso:** Formula respuestas directas y resumidas. Tu objetivo es mantener las respuestas alrededor de 65 tokens, así que ve al punto sin extenderte innecesariamente.
    // --- FIN DE LA MODIFICACIÓN ---
    - **Sé un Extractor, no un Inventor:** Tu trabajo es extraer y explicar, no crear información nueva sobre Colbún.
    - **Cita Fuentes:** Si usas información de un contexto que tiene un enlace, finaliza tu respuesta con: "Puedes encontrar más información oficial en este enlace: [URL]".
    - **Mantén el Tono:** Siempre amable, servicial y enfocado en Colbún.
''';

  // ============================================================================
  // ¡NUEVO MÉTODO PRINCIPAL!
  // ============================================================================

  /// Genera una respuesta usando el modelo RAG (Retrieval-Augmented Generation).
  Future<OpenAIResponse> generateRAGResponse({
    required String userMessage,
    required List<Faq> contextFaqs, // Recibe las FAQs encontradas como contexto
    List<Map<String, String>>? conversationHistory,
  }) async {
    // 1. Formatear el contexto para que la IA lo entienda.
    String formattedContext =
        "No se encontró información de contexto relevante en la base de datos.";
    if (contextFaqs.isNotEmpty) {
      formattedContext = contextFaqs.map((faq) {
        return 'Pregunta: "${faq.question}"\nRespuesta: "${faq.answer}"\nFuente: ${faq.link ?? "No disponible"}';
      }).join('\n\n---\n\n');
    }

    // 2. Construir el mensaje final para el usuario, inyectando el contexto.
    final finalUserMessage = '''
INFORMACIÓN DE CONTEXTO:
"""
$formattedContext
"""

PREGUNTA DEL USUARIO: "$userMessage"
''';

    // 3. Llamar al método de envío de mensajes.
    return await _sendMessage(
      userMessage: finalUserMessage,
      conversationHistory: conversationHistory,
    );
  }

  /// Método interno para enviar la petición a la API de OpenAI.
  Future<OpenAIResponse> _sendMessage({
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
  }) async {
    if (_apiKey.isEmpty) {
      return OpenAIResponse(
          success: false,
          message: "Error: API Key de OpenAI no configurada.",
          error: "API Key is missing",
          tokensUsed: 0);
    }

    try {
      List<Map<String, String>> messages = [
        {'role': 'system', 'content': _systemPrompt}
      ];
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }
      messages.add({'role': 'user', 'content': userMessage});

      final requestBody = {
        'model': _model,
        'messages': messages,
        'max_tokens': 65,
        'temperature':
            0.5, // Un poco menos creativo para que se apegue más al contexto.
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return _parseSuccessResponse(jsonDecode(response.body));
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('❌ Error en OpenAI Service: $e');
      return OpenAIResponse(
          success: false,
          message: 'Lo siento, hay un problema técnico. Intenta de nuevo.',
          error: e.toString(),
          tokensUsed: 0);
    }
  }

  // ============================================================================
  // MÉTODOS AUXILIARES (Sin cambios significativos)
  // ============================================================================

  OpenAIResponse _parseSuccessResponse(Map<String, dynamic> data) {
    try {
      final message = data['choices'][0]['message']['content'] as String;
      final tokensUsed = data['usage']['total_tokens'] as int;
      return OpenAIResponse(
          success: true, message: message.trim(), tokensUsed: tokensUsed);
    } catch (e) {
      return OpenAIResponse(
          success: false,
          message: 'Error al procesar la respuesta.',
          error: e.toString(),
          tokensUsed: 0);
    }
  }

  OpenAIResponse _parseErrorResponse(http.Response response) {
    // ... (este método se queda igual que en tu versión original)
    return OpenAIResponse(
        success: false,
        message: "Hubo un error con el servicio de IA.",
        error: response.body,
        tokensUsed: 0);
  }

  bool isConfigured() => _apiKey.isNotEmpty && _apiKey.startsWith('sk-');

  List<Map<String, String>> formatMessagesForOpenAI(
      List<Map<String, dynamic>> messages) {
    final List<Map<String, String>> formattedHistory = [];

    for (var message in messages) {
      // La única condición importante es que el mensaje tenga texto.
      if (message['text'] != null && (message['text'] as String).isNotEmpty) {
        String role = (message['sender'] == 'user') ? 'user' : 'assistant';

        // Creamos el mapa limpio que OpenAI espera.
        formattedHistory.add({
          'role': role,
          'content': message['text'],
        });
      }
    }
    // Se ignoran todos los mensajes sin texto, como las opciones de FAQs.
    return formattedHistory;
  }
}

// ============================================================================
// CLASE DE RESPUESTA (Sin cambios)
// ============================================================================
class OpenAIResponse {
  final bool success;
  final String message;
  final String? error;
  final int tokensUsed;

  OpenAIResponse({
    required this.success,
    required this.message,
    this.error,
    required this.tokensUsed,
  });
}
