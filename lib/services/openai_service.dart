// lib/services/openai_service.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
Eres "Asistente Colbún", un asistente virtual experto, amigable y servicial para la Municipalidad de Colbún, Chile.
Tu única misión es proporcionar información precisa y útil sobre la comuna de Colbún.

**IMPORTANTE: Tus respuestas deben ser CONCISAS y DIRECTAS (máximo 100-120 palabras). Ve al grano.**

REGLAS DE COMPORTAMIENTO:
1.  **Respuestas Breves:** Da la información esencial de forma directa. Evita introducciones largas o repetir la pregunta.
2.  **Enfoque en Colbún:** Tu conocimiento abarca servicios municipales, turismo, eventos, vida local, cultura, geografía e historia de Colbún.
3.  **Límites Claros:** No respondas temas sensibles como política, violencia, contenido sexual u opiniones personales. Redirige amablemente a temas de Colbún.
4.  **No Inventes:** Si no sabes algo, admítelo brevemente y sugiere contactar a la municipalidad.

**Formato ideal de respuesta:**
- 2-3 oraciones máximo para preguntas simples
- 1 párrafo corto para preguntas complejas
- Lista con viñetas solo si es absolutamente necesario
''';
  String get _systemPromptPt => '''
Você é "Assistente Colbún", um assistente virtual especialista, amigável e prestativo para a Prefeitura de Colbún, Chile.
Sua única missão é fornecer informações precisas e úteis sobre o município de Colbún.

**IMPORTANTE: Suas respostas devem ser CONCISAS e DIRETAS (máximo 100-120 palavras). Vá direto ao ponto.**

REGRAS DE COMPORTAMENTO:
1.  **Respostas Breves:** Forneça informações essenciais de forma direta. Evite introduções longas ou repetir a pergunta.
2.  **Foco em Colbún:** Seu conhecimento abrange serviços municipais, turismo, eventos, vida local, cultura, geografia e história de Colbún.
3.  **Limites Claros:** Não responda sobre política, violência, conteúdo sexual ou opiniões pessoais. Redirecione educadamente para temas de Colbún.
4.  **Não Invente:** Se não souber algo, admita brevemente e sugira contatar a prefeitura.

**Formato ideal de resposta:**
- 2-3 frases no máximo para perguntas simples
- 1 parágrafo curto para perguntas complexas
- Lista com marcadores apenas se absolutamente necessário
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
    //prompt: agregar tambien portugues a los otros dos idiomas

    String formattedContext = language == 'en'
        ? "No relevant context information found in the database."
        : language == 'pt'
            ? "Nenhuma informação de contexto relevante encontrada na base de dados."
            : "No se encontró información de contexto relevante en la base de datos.";

    if (contextFaqs.isNotEmpty) {
      formattedContext = contextFaqs.map((faq) {
        // **USAR EL IDIOMA CORRECTO PARA LAS FAQs**
        String question = language == 'en' && faq.questionEn.isNotEmpty
            ? faq.questionEn
            : language == 'pt' && faq.questionPt.isNotEmpty
                ? faq.questionPt
                : faq.question;

        String answer = language == 'en' && faq.answerEn.isNotEmpty
            ? faq.answerEn
            : language == 'pt' && faq.answerPt.isNotEmpty
                ? faq.answerPt
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
        : language == 'pt'
            ? '''IMPORTANTE SOBRE FONTES E LINKS:
- Se o contexto incluir uma "Fonte específica", VOCÊ DEVE usar essa URL exata
- NÃO invente URLs ou mencione sites genéricos.
- Se houver várias fontes, use a mais relevante para a pergunta.
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
      // Validar API Key (solo en debug para evitar slowdowns)
      if (kDebugMode) {
        print('🔑 Verificando API Key...');
      }

      if (_apiKey.isEmpty) {
        if (kDebugMode) print('❌ API Key vacía');
        return OpenAIResponse(
            success: false,
            message: "Error: API Key de OpenAI no configurada.",
            error: "API Key is missing",
            tokensUsed: 0);
      }

      if (!_apiKey.startsWith('sk-')) {
        if (kDebugMode) print('❌ API Key no empieza con sk-');
        return OpenAIResponse(
            success: false,
            message: "Error: API Key de OpenAI tiene formato inválido.",
            error: "API Key format is invalid",
            tokensUsed: 0);
      }
      // Prompt base en español o inglés según el idioma detectado
      String systemPrompt = language == 'en'
          ? _systemPromptEn
          : language == 'pt'
              ? _systemPromptPt
              : _systemPrompt;

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
        'max_tokens': 150, // Reducido para respuestas más rápidas
        'temperature': 0.3, // Más determinista = más rápido
        'stream': false,
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

      if (kDebugMode) {
        print('🚀 Enviando petición a OpenAI en idioma: $language');
      }

      // Timeout optimizado: 12s para todas las consultas (balanceado)
      const timeoutDuration = Duration(seconds: 12);

      final response = await http
          .post(
            Uri.parse(targetUrl),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Respuesta recibida: ${response.statusCode}');
        if (response.statusCode != 200) {
          print('⚠️ Error: ${response.statusCode}');
        }
      }

      // Procesar la respuesta
      if (response.statusCode == 200) {
        return _parseSuccessResponse(jsonDecode(response.body));
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e, st) {
      // Reportar a Crashlytics y devolver mensaje de error amigable
      try {
        FirebaseCrashlytics.instance
            .recordError(e, st, reason: 'OpenAIService._sendMessage');
      } catch (_) {}

      print('❌ Error en OpenAI Service: $e');

      // Determinar el tipo de error para dar mejor retroalimentación
      String errorMessage;
      if (e.toString().contains('TimeoutException')) {
        print(
            '⏱️ Timeout detectado - La respuesta está tomando más tiempo de lo esperado');
        errorMessage = language == 'en'
            ? 'The response is taking longer than expected. This might be due to network conditions. Please try again.'
            : language == 'pt'
                ? 'A resposta está demorando mais do que o esperado. Isso pode ser devido às condições da rede. Por favor, tente novamente.'
                : 'La respuesta está tardando más de lo esperado. Esto puede deberse a las condiciones de la red. Por favor, intenta nuevamente.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        print('📡 Error de conexión - Problema de red detectado');
        errorMessage = language == 'en'
            ? 'Unable to connect to the service. Please check your internet connection and try again.'
            : language == 'pt'
                ? 'Não foi possível conectar ao serviço. Por favor, verifique sua conexão com a internet e tente novamente.'
                : 'No se pudo conectar al servicio. Por favor, verifica tu conexión a internet e intenta nuevamente.';
      } else {
        errorMessage = language == 'en'
            ? 'Sorry, there is a technical problem. Please try again in a few moments.'
            : language == 'pt'
                ? 'Desculpe, há um problema técnico. Por favor, tente novamente em alguns momentos.'
                : 'Lo siento, hay un problema técnico. Por favor, intenta nuevamente en unos momentos.';
      }

      return OpenAIResponse(
          success: false,
          message: errorMessage,
          error: e.toString(),
          tokensUsed: 0);
    }
  }

  //prompt en inglés
  String get _systemPromptEn => '''
You are "Asistente Colbún," a friendly, helpful, and expert virtual assistant for the Municipality of Colbún, Chile.
Your sole mission is to provide accurate and useful information about the Colbún commune.

**IMPORTANT: Your responses must be CONCISE and DIRECT (maximum 100-120 words). Get straight to the point.**

BEHAVIORAL RULES:
1.  **Brief Responses:** Provide essential information directly. Avoid long introductions or repeating the question.
2.  **Focus on Colbún:** Your knowledge covers municipal services, tourism, events, local life, culture, geography, and history of Colbún.
3.  **Clear Boundaries:** Don't respond to sensitive topics like politics, violence, sexual content, or personal opinions. Politely redirect to Colbún topics.
4.  **Do Not Invent:** If you don't know something, admit it briefly and suggest contacting the municipality.

**Ideal response format:**
- 2-3 sentences maximum for simple questions
- 1 short paragraph for complex questions
- Bullet list only if absolutely necessary
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
    required List<Faq> contextFaqs,
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
      if (text.contains(RegExp(r'[a-zA-Z]')) &&
          !text.contains(RegExp(r'[áéíóúñ]'))) {
        return 'en';
      } else if (text.contains(RegExp(r'[ãõçêéáíóú]'))) {
        return 'pt';
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
      print('❌ Status Code: ${response.statusCode}');
      print('❌ Response completo: ${response.body}');

      String userFriendlyMessage;
      switch (response.statusCode) {
        case 401:
          userFriendlyMessage =
              'Error de autenticación. La API Key es inválida o está mal configurada. Verifica el archivo .env';
          print(
              '💡 SOLUCIÓN: Revisa que la API Key en .env no tenga comillas y empiece con sk-');
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
      print('❌ Response body raw: ${response.body}');
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
  bool isConfigured() {
    final key = _apiKey.trim();
    final isValid = key.isNotEmpty && key.startsWith('sk-');

    if (!isValid) {
      print('❌ API Key inválida o no configurada');
      print('   Key vacía: ${key.isEmpty}');
      print('   Key length: ${key.length}');
      print('   Empieza con sk-: ${key.startsWith('sk-')}');
      if (key.isNotEmpty && key.length < 20) {
        print(
            '   Key (primeros chars): ${key.substring(0, key.length > 10 ? 10 : key.length)}...');
      }
    } else {
      print('✅ API Key configurada correctamente');
    }

    return isValid;
  }

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
