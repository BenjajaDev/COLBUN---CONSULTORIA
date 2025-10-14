// lib/services/openai_service.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:consultoria_chat_bot/services/firestore_faq_service.dart'; // Importamos el modelo Faq

// ============================================================================
// Intento de extracion de urls de texto de respuesta ia
// ============================================================================

/// Extrae URLs del texto de respuesta de OpenAI
List<String> _extractUrlsFromResponse(String text) {
  final urlPatterns = [
    // URLs completas con http/https
    RegExp(r'https?://[^\s<>"{}|\\^`[\]]+', caseSensitive: false),
    // URLs con www
    RegExp(r'www\.[^\s<>"{}|\\^`[\]]+', caseSensitive: false),
    // Formato Markdown [texto](url)
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)', caseSensitive: false),
    // Mención de fuentes como "Source: example.com"
    RegExp(r'Source:\s*([^\s.,;!?]+\.\w+)', caseSensitive: false),
    // URLs entre paréntesis
    RegExp(r'\(([^)]*https?://[^)]+)\)', caseSensitive: false),
  ];

  final urls = <String>[];

  for (final pattern in urlPatterns) {
    final matches = pattern.allMatches(text);

    for (final match in matches) {
      String? extractedUrl;

      if (pattern == urlPatterns[2]) {
        // Formato Markdown [texto](url)
        extractedUrl = match.group(2); // El grupo 2 es la URL
      } else if (pattern == urlPatterns[3]) {
        // "Source: example.com"
        String? domain = match.group(1);
        if (domain != null && !domain.startsWith('http')) {
          extractedUrl = 'https://$domain';
        }
      } else if (pattern == urlPatterns[4]) {
        // URLs entre paréntesis
        String? urlInParentheses = match.group(1);
        if (urlInParentheses != null) {
          // Extraer solo la URL del texto entre paréntesis
          final urlMatch =
              RegExp(r'https?://[^\s)]+').firstMatch(urlInParentheses);
          extractedUrl = urlMatch?.group(0);
        }
      } else {
        // Para patrones simples, usar el grupo 0
        extractedUrl = match.group(0);
      }

      // Validar y normalizar la URL
      if (extractedUrl != null) {
        String normalizedUrl = _normalizeUrl(extractedUrl);
        if (_isValidUrl(normalizedUrl) && !urls.contains(normalizedUrl)) {
          urls.add(normalizedUrl);
          print('🔗 URL extraída: $normalizedUrl');
        }
      }
    }
  }

  return urls;
}

/// Normaliza URLs para asegurar formato correcto
String _normalizeUrl(String url) {
  String normalized = url.trim();

  // Remover caracteres no deseados al final
  normalized = normalized.replaceAll(RegExp(r'[.,;!?)]+$'), '');

  // Asegurar que las URLs de dominio tengan protocolo
  if (normalized.startsWith('www.') && !normalized.startsWith('http')) {
    normalized = 'https://$normalized';
  }

  return normalized;
}

/// Valida si una URL tiene formato válido
bool _isValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.isAbsolute &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  } catch (e) {
    return false;
  }
}

/// Servicio completo para integración con OpenAI GPT
class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  // ============================================================================
  // CONFIGURACIÓN - API KEY CARGADA DESDE VARIABLES DE ENTORNO
  // ============================================================================

  /// API Key de OpenAI configurada desde variables de entorno
  /// Obtén tu key en: https://platform.openai.com/api-keys
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-4o-mini'; // O 'gpt-3.5-turbo' si prefieres

  // Headers para las peticiones
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
    required String language, // **AGREGAR ESTE PARÁMETRO**
  }) async {
    print('🎯 GENERATE RAG RESPONSE - Idioma recibido: $language');
    print('🔍 CONTEXT FAQs COUNT: ${contextFaqs.length}');

    String formattedContext = language == 'en'
        ? "No relevant context information found in the database."
        : "No se encontró información de contexto relevante en la base de datos.";

    if (contextFaqs.isNotEmpty) {
      formattedContext = contextFaqs.map((faq) {
        // **USAR EL IDIOMA CORRECTO PARA LAS FAQs**
        String question = language == 'en' && faq.questionEn.isNotEmpty
            ? faq.questionEn
            : faq.question;
        String answer = language == 'en' && faq.answerEn.isNotEmpty
            ? faq.answerEn
            : faq.answer;

        String sourceInfo = faq.link != null && faq.link!.isNotEmpty
            ? 'Specific source: ${faq.link}'
            : 'Source: General information about Colbún';

        print('📚 FAQ CONTEXT - Question ($language): $question');
        print('📚 FAQ CONTEXT - Answer ($language): $answer');
        print('📚 FAQ CONTEXT - Source: $sourceInfo');
        return '''
        Pregunta: "$question"
  Respuesta: "$answer"
  $sourceInfo
        ''';
      }).join('\n\n---\n\n');
    }

    // 2. INSTRUCCIÓN ESPECÍFICA PARA USAR LAS URLs PROPORCIONADAS
    final urlInstruction = language == 'en'
        ? '''
IMPORTANT ABOUT SOURCES AND LINKS:
- If the context includes a "Specific source", you MUST use that exact URL.
- DO NOT invent URLs or mention generic websites.
- If there are multiple sources, use the most relevant one for the question.
- Required format for links: [Descriptive text](Specific_URL)
'''
        : '''
IMPORTANTE SOBRE FUENTES Y ENLACES:
- Si el contexto incluye una "Fuente específica", DEBES usar esa URL exacta.
- NO inventes URLs ni menciones sitios web genéricos.
- Si hay múltiples fuentes, usa la más relevante para la pregunta.
- Formato requerido para enlaces: [Texto descriptivo](URL_específica)
''';

    // 3. Construir el mensaje final para el usuario, inyectando el contexto.
    String finalUserMessage;

    if (contextFaqs.isEmpty) {
      // Si no hay contexto, permitimos que la IA responda con su conocimiento general
      finalUserMessage = '''
INFORMACIÓN DE CONTEXTO:
"""
$formattedContext
"""

$urlInstruction
USER QUESTION: "$userMessage"
FINAL INSTRUCTION: There is no context available from the database for this question. Use your general knowledge about Colbún to provide a concise, helpful answer in ${language.toUpperCase()}. Do not reply that you cannot answer or that no context was found. If you are not certain, provide reasonable options or guidance and suggest verifying with official sources when appropriate. RESPOND IN ${language.toUpperCase()}.
''';
    } else {
      // Si existe contexto, priorizamos responder a partir del mismo (RAG)
      finalUserMessage = '''
INFORMACIÓN DE CONTEXTO:
"""
$formattedContext
"""

$urlInstruction
USER QUESTION: "$userMessage"
FINAL INSTRUCTION: Respond based primarily on the provided context. If you use information from the context,
include the specific link provided using the format [Text](URL). You may supplement with concise general knowledge about Colbún only when it helps clarify or complete the answer. RESPOND IN ${language.toUpperCase()}.
''';
    }

    print('🚀 FINAL MESSAGE TO OPENAI: $finalUserMessage');

    // 3. Llamar al método de envío de mensajes.
    return await _sendMessage(
      userMessage: finalUserMessage,
      conversationHistory: conversationHistory,
      language: language, // **PASAR EL IDIOMA**
    );
  }

  /// Método interno para enviar la petición a la API de OpenAI.
  Future<OpenAIResponse> _sendMessage({
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
    required String language, // Nuevo parámetro
  }) async {
    try {
      // Validar API Key
      if (_apiKey.isEmpty) {
        return OpenAIResponse(
            success: false,
            message: "Error: API Key de OpenAI no configurada.",
            error: "API Key is missing",
            tokensUsed: 0);
      }
      // Prompt base en español o inglés según el idioma detectado
      String systemPrompt = language == 'en' ? _systemPromptEn : _systemPrompt;

      List<Map<String, String>> messages = [
        {'role': 'system', 'content': systemPrompt}
      ];
      // Agregar historial de conversación si existe
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }
      // Agregar mensaje actual del usuario
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Preparar el body de la petición
      final requestBody = {
        'model': _model,
        'messages': messages,
        'max_tokens': 250,
        'temperature':
            0.5, // Un poco menos creativo para que se apegue más al contexto.
      };

      // En web, las llamadas directas a api.openai.com suelen fallar por CORS.
      // Soportamos una variable de entorno OPENAI_PROXY_URL que apunta a un proxy propio
      // que reenvía las peticiones a OpenAI (con la API Key en el servidor).
      String targetUrl = '$_baseUrl/chat/completions';
      final proxyUrl = dotenv.env['OPENAI_PROXY_URL'] ?? '';
      if (kIsWeb) {
        if (proxyUrl.isNotEmpty) {
          targetUrl = proxyUrl;
          print(
              '🌐 Ejecutando en web: usando proxy OPENAI_PROXY_URL -> $proxyUrl');
        } else {
          // Evitar intentar llamada directa desde web sin proxy (causa ClientException/CORS)
          print(
              '⚠️ OpenAI direct call blocked on web (no OPENAI_PROXY_URL configured)');
          return OpenAIResponse(
            success: false,
            message: language == 'en'
                ? 'Unable to contact OpenAI from the web client due to browser CORS restrictions. Configure a server-side proxy and set OPENAI_PROXY_URL in .env.'
                : 'No es posible contactar OpenAI desde el cliente web debido a restricciones CORS del navegador. Configura un proxy en servidor y asigna OPENAI_PROXY_URL en .env.',
            error: 'CORS or web environment without proxy',
            tokensUsed: 0,
          );
        }
      }

      print('🚀 Enviando petición a OpenAI en idioma: $language');

      final response = await http
          .post(
            Uri.parse(targetUrl),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 45));

      print('📡 Respuesta recibida: ${response.statusCode}');

      // Procesar la respuesta
      if (response.statusCode == 200) {
        return _parseSuccessResponse(jsonDecode(response.body));
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('❌ Error en OpenAI Service: $e');
      return OpenAIResponse(
          success: false,
          message: language == 'en'
              ? 'Sorry, there is a technical problem. Please try again in a few moments.'
              : 'Lo siento, hay un problema técnico. Por favor, intenta nuevamente en unos momentos.',
          error: e.toString(),
          tokensUsed: 0);
    }
  }

  //prompt en inglés
  String get _systemPromptEn => '''
## ROLE AND OBJECTIVE
You are "Colbún Assistant", an expert, friendly, and helpful virtual assistant for the Municipality of Colbún, Chile.
Your sole mission is to provide accurate and useful information about the commune of Colbún.

## GOLDEN RULES (UNBREAKABLE)

// --- START MODIFICATION ---
1.  **EXCLUSIVE FOCUS ON COLBÚN, WITH CONTEXTUAL FLEXIBILITY.** Your mission is to respond only about Colbún. Politely decline to answer questions about other places or unrelated general topics.
    - **Exception:** If the user asks you to define a general term (such as "ecotourism", "petroglyphs", "handicrafts") that YOU mentioned in your previous response, you may provide a brief definition. Immediately after, you must reconnect your response with Colbún.
    - **Rejection Example:**
      - User: "What is the capital of France?"
      - Your Response: "I'm sorry, my specialty is exclusively the commune of Colbún. Is there something about Colbún I can help you with?"
    - **Valid Exception Example:**
      - Your Previous Response: "...you can enjoy hiking, fishing, and ecotourism."
      - User: "What is ecotourism?"
      - Your Correct Response: "Of course, ecotourism is a form of tourism focused on visiting natural areas responsibly. In Colbún, this translates into activities like hiking in the El Melado area or bird watching at Lake Machicura."
// --- END MODIFICATION ---

2.  **KNOWLEDGE HIERARCHY.** You must follow this priority order to find information:
    - **Priority 1: CONTEXT INFORMATION.** This is your "source of truth".
    - **Priority 2: CONVERSATION HISTORY.** You must use previous messages to understand follow-up questions.
    - **Priority 3: GENERAL KNOWLEDGE (ONLY ABOUT COLBÚN).**

## STEP-BY-STEP RESPONSE PROCESS

Follow these steps for each user question:

1.  **ANALYZE HISTORY:** Review the previous conversation. Is the current user question ("why?") a direct continuation of your previous response? If so, use that previous response as the main context for your new answer.

2.  **ANALYZE CONTEXT INFORMATION:**
    - **If the EXACT answer is in the context:** Extract it and rephrase it in a conversational and friendly tone. Do not just copy and paste. If the context includes a "Source", cite it at the end.
    - **If the context is relevant but INCOMPLETE:** (Example: the context talks about "licenses" in general, but the user asks about "motorcycle license"). You must state this. Say something like: "The information I have details the requirements for class B license. For other specific license types, I don't have the details, but generally...". Then, you can use your general knowledge to provide a more complete answer.
    - **If the context is NOT relevant:** Ignore it completely and respond using your general knowledge about Colbún.

3.  **FORMULATE THE RESPONSE:**
    // --- START MODIFICATION ---
    - **Be Brief and Concise:** Formulate direct and summarized responses. Your goal is to keep responses around 65 tokens, so get to the point without unnecessary elaboration.
    // --- END MODIFICATION ---
    - **Be an Extractor, not an Inventor:** Your job is to extract and explain, not create new information about Colbún.
    - **Cite Sources:** If you use information from a context that has a link, end your response with: "You can find more official information at this link: [URL]".
    - **Maintain Tone:** Always friendly, helpful, and focused on Colbún.
''';

  /// Envía un mensaje simple sin historial
  Future<OpenAIResponse> sendSimpleMessage(String userMessage) async {
    // Detectar idioma para mensajes simples (por defecto español)
    final language = await _detectLanguageForSimpleMessage(userMessage);
    return await _sendMessage(
      userMessage: userMessage,
      language: language,
    );
  }

  /// Devuelve una URL relevante para la pregunta (si existe) usando el servicio de FAQs
  /// Esta función facilita consultar la fuente desde capas superiores.
  Future<String?> getRelevantFaqUrl(String userMessage,
      {FaqService? service}) async {
    try {
      final faqSvc = service ?? FaqService();
      final url = await faqSvc.findRelevantFaqUrl(userMessage);
      return url;
    } catch (e) {
      print('⚠️ Error al obtener URL relevante de FAQ: $e');
      return null;
    }
  }

  /// Envía un mensaje con contexto específico adicional
  Future<OpenAIResponse> sendMessageWithContext({
    required String userMessage,
    required String additionalContext,
    List<Map<String, String>>? conversationHistory,
  }) async {
    // Detectar idioma para mensajes con contexto
    final language = await _detectLanguageForSimpleMessage(userMessage);
    // Agregar contexto adicional al mensaje del usuario
    final enhancedMessage = '''
CONTEXTO ADICIONAL: $additionalContext

CONSULTA DEL USUARIO: $userMessage
''';

    return await _sendMessage(
      userMessage: enhancedMessage,
      conversationHistory: conversationHistory,
      language: language,
    );
  }

  // ============================================================================
  // MÉTODOS AUXILIARES (Sin cambios significativos)
  // ============================================================================

  /// Método auxiliar para detectar idioma en mensajes simples
  Future<String> _detectLanguageForSimpleMessage(String text) async {
    try {
      // Para ejemplos simples, usar una detección básica
      if (text.contains(RegExp(r'[a-zA-Z]')) &&
          !text.contains(RegExp(r'[áéíóúñ]'))) {
        return 'en';
      }
      return 'es';
    } catch (e) {
      return 'es'; // Fallback a español
    }
  }

  /// Procesa respuesta exitosa de OpenAI
  OpenAIResponse _parseSuccessResponse(Map<String, dynamic> data) {
    try {
      final message = data['choices'][0]['message']['content'] as String;
      final tokensUsed = data['usage']['total_tokens'] as int;

      // Extraer URLs del mensaje
      final extractedUrls = _extractUrlsFromResponse(message);
      // Limpiar el mensaje pero mantener las URLs visibles en el texto
      String cleanMessage = message;

      // Solo limpiar formato Markdown pero mantener las URLs en el texto
      cleanMessage = cleanMessage
          .replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (match) {
        final linkText = match.group(1) ?? '';
        final url = match.group(2) ?? '';
        return '$linkText ($url)'; // Mantener URL visible
      });
      print('✅ Respuesta procesada exitosamente');
      print('📊 Tokens utilizados: $tokensUsed');
      print('🔗 URLs extraídas: $extractedUrls');

      return OpenAIResponse(
        success: true,
        message: message.trim(),
        tokensUsed: tokensUsed,
        extractedUrls: extractedUrls, // Nuevo campo
      );
    } catch (e) {
      return OpenAIResponse(
          success: false,
          message: 'Error al procesar la respuesta.',
          error: e.toString(),
          tokensUsed: 0);
    }
  }

  OpenAIResponse _parseErrorResponse(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error']['message'] as String;
      final errorType = errorData['error']['type'] as String;

      print('❌ Error de OpenAI: $errorType - $errorMessage');

      String userFriendlyMessage;
      switch (response.statusCode) {
        case 401:
          userFriendlyMessage =
              'Error de autenticación. Verifica la configuración.';
          break;
        case 429:
          userFriendlyMessage =
              'Demasiadas consultas. Por favor, espera un momento e intenta nuevamente.';
          break;
        case 500:
        case 502:
        case 503:
          userFriendlyMessage =
              'El servicio está temporalmente no disponible. Intenta más tarde.';
          break;
        default:
          userFriendlyMessage =
              'Lo siento, no pude procesar tu consulta en este momento.';
      }

      return OpenAIResponse(
        success: false,
        message: userFriendlyMessage,
        error: '$errorType: $errorMessage',
        tokensUsed: 0,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('❌ Error al procesar respuesta de error: $e');
      return OpenAIResponse(
          success: false,
          message: "Hubo un error con el servicio de IA.",
          error: response.body,
          tokensUsed: 0);
    }
  }
  // ============================================================================
  // MÉTODOS DE UTILIDAD
  // ============================================================================

  /// Valida que la API Key esté configurada
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
  final int? statusCode;
  final List<String> extractedUrls; // Nuevo campo

  OpenAIResponse({
    required this.success,
    required this.message,
    this.error,
    required this.tokensUsed,
    this.statusCode,
    this.extractedUrls = const [], // Valor por defecto
  });
}
