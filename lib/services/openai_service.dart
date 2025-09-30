// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  static const String _model = 'gpt-4'; 
  
  // Headers para las peticiones
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apiKey',
  };

  // ============================================================================
  // PROMPT PERSONALIZABLE - AQUÍ PUEDES ESCRIBIR TU CONTEXTO
  // ============================================================================
  
  /// Prompt base personalizable para el chatbot de Colbún
  String get _systemPrompt => '''
Eres un asistente virtual especializado de la Ilustre Municipalidad de Colbún, Talca, Chile,
que ayudará a resolver cualquier duda relacionada únicamente con las actividades, atracciones turísticas, artesanía, gastronomía local, eventos y servicios que ofrece tanto la municipalidad como la comunidad.

Responderás de manera concisa y clara para ayudar a los usuarios a resolver sus dudas de manera eficiente y eficaz.
Te basarás con fuentes REALES de la Municipalidad de Colbún y la comunidad.
Los enlaces para tu consumo de información están en Visitacolbun.cl
Siempre debes citar la fuente de la que sacaste la información.

LIMITACIONES ESTRICTAS:
1. SOLO responderás consultas relacionadas con la Municipalidad de Colbún, Chile y su comuna
2. NO proporcionarás información sobre otras comunas, ciudades o países
3. NO darás consejos médicos, legales, financieros o de inversión
4. NO realizarás tareas de programación, cálculos matemáticos complejos o traducciones
5. NO generarás contenido creativo como poemas, cuentos o canciones no relacionados con Colbún
6. NO responderás preguntas sobre política nacional, internacional o temas controversiales
7. NO proporcionarás información personal de funcionarios municipales más allá de cargos públicos
8. NO darás instrucciones para actividades peligrosas o ilegales
9. NO utilizarás lenguaje soez ni aceptarás apodos
10. NO responderás consultas sobre tecnología que no esté relacionada con servicios municipales
11. Si la consulta NO está relacionada con Colbún, responderás: "Lo siento, solo puedo ayudarte con información sobre la Municipalidad de Colbún y su comuna. ¿Tienes alguna pregunta sobre nuestros servicios, turismo o actividades locales?"
12. NO proporcionarás información que pueda comprometer la seguridad o privacidad de personas
13. NO darás recomendaciones sobre competidores o empresas privadas no relacionadas con servicios municipales
14. Si no tienes información específica sobre algo de Colbún, lo admitirás honestamente y sugerirás contactar directamente la municipalidad

ÁREAS PERMITIDAS ÚNICAMENTE:
- Servicios municipales de Colbún
- Turismo y atracciones de la comuna
- Eventos y actividades locales
- Gastronomía típica de Colbún
- Historia y cultura local
- Artesanía y productos locales
- Información general de la comuna
- Trámites municipales
- Contactos oficiales de la municipalidad
''';

  // ============================================================================
  // MÉTODOS PRINCIPALES
  // ============================================================================

  /// Envía un mensaje a OpenAI y obtiene la respuesta
  Future<OpenAIResponse> sendMessage({
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      // Validar API Key
      if (_apiKey.isEmpty) {
        throw Exception('API Key de OpenAI no configurada. Verifica que el archivo .env esté presente y contenga OPENAI_API_KEY');
      }

      // Construir mensajes para la conversación
      List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': _systemPrompt,
        }
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
        'max_tokens': 500, // Ajustable según necesidades
        'temperature': 0.7, // Creatividad (0.0 - 2.0)
        'presence_penalty': 0.1, // Evita repetición
        'frequency_penalty': 0.1, // Diversidad en respuestas
      };

      print('🚀 Enviando petición a OpenAI...');
      
      // Realizar la petición HTTP
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📡 Respuesta recibida: ${response.statusCode}');

      // Procesar la respuesta
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseSuccessResponse(data, userMessage);
      } else {
        return _parseErrorResponse(response);
      }

    } catch (e) {
      print('❌ Error en OpenAI Service: $e');
      return OpenAIResponse(
        success: false,
        message: 'Lo siento, hay un problema técnico. Por favor, intenta nuevamente en unos momentos.',
        error: e.toString(),
        tokensUsed: 0,
      );
    }
  }

  /// Envía un mensaje simple sin historial
  Future<OpenAIResponse> sendSimpleMessage(String userMessage) async {
    return await sendMessage(userMessage: userMessage);
  }

  /// Envía un mensaje con contexto específico adicional
  Future<OpenAIResponse> sendMessageWithContext({
    required String userMessage,
    required String additionalContext,
    List<Map<String, String>>? conversationHistory,
  }) async {
    // Agregar contexto adicional al mensaje del usuario
    final enhancedMessage = '''
CONTEXTO ADICIONAL: $additionalContext

CONSULTA DEL USUARIO: $userMessage
''';

    return await sendMessage(
      userMessage: enhancedMessage,
      conversationHistory: conversationHistory,
    );
  }

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  /// Procesa respuesta exitosa de OpenAI
  OpenAIResponse _parseSuccessResponse(Map<String, dynamic> data, String originalMessage) {
    try {
      final choices = data['choices'] as List;
      if (choices.isEmpty) {
        return OpenAIResponse(
          success: false,
          message: 'No se recibió respuesta del asistente.',
          error: 'Empty choices array',
          tokensUsed: 0,
        );
      }

      final message = choices[0]['message']['content'] as String;
      final usage = data['usage'] as Map<String, dynamic>;
      final tokensUsed = usage['total_tokens'] as int;

      print('✅ Respuesta procesada exitosamente');
      print('📊 Tokens utilizados: $tokensUsed');

      return OpenAIResponse(
        success: true,
        message: message.trim(),
        tokensUsed: tokensUsed,
        originalMessage: originalMessage,
        model: _model,
        finishReason: choices[0]['finish_reason'] as String?,
      );

    } catch (e) {
      print('❌ Error al procesar respuesta exitosa: $e');
      return OpenAIResponse(
        success: false,
        message: 'Error al procesar la respuesta del asistente.',
        error: e.toString(),
        tokensUsed: 0,
      );
    }
  }

  /// Procesa respuesta de error de OpenAI
  OpenAIResponse _parseErrorResponse(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error']['message'] as String;
      final errorType = errorData['error']['type'] as String;

      print('❌ Error de OpenAI: $errorType - $errorMessage');

      String userFriendlyMessage;
      switch (response.statusCode) {
        case 401:
          userFriendlyMessage = 'Error de autenticación. Verifica la configuración.';
          break;
        case 429:
          userFriendlyMessage = 'Demasiadas consultas. Por favor, espera un momento e intenta nuevamente.';
          break;
        case 500:
        case 502:
        case 503:
          userFriendlyMessage = 'El servicio está temporalmente no disponible. Intenta más tarde.';
          break;
        default:
          userFriendlyMessage = 'Lo siento, no pude procesar tu consulta en este momento.';
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
        message: 'Error técnico inesperado.',
        error: e.toString(),
        tokensUsed: 0,
        statusCode: response.statusCode,
      );
    }
  }

  // ============================================================================
  // MÉTODOS DE UTILIDAD
  // ============================================================================

  /// Valida que la API Key esté configurada
  bool isConfigured() {
    return _apiKey.isNotEmpty && _apiKey.startsWith('sk-');
  }

  /// Obtiene información sobre el modelo actual
  Map<String, dynamic> getModelInfo() {
    return {
      'model': _model,
      'configured': isConfigured(),
      'baseUrl': _baseUrl,
    };
  }

  /// Estima tokens de un texto (aproximación)
  int estimateTokens(String text) {
    // Aproximación: 1 token ≈ 4 caracteres en español
    return (text.length / 4).ceil();
  }

  /// Convierte historial de mensajes al formato de OpenAI
  List<Map<String, String>> formatConversationHistory(List<Map<String, dynamic>> messages) {
    return messages.map((msg) {
      return {
        'role': msg['sender'] == 'user' ? 'user' : 'assistant',
        'content': msg['text'] as String,
      };
    }).toList();
  }

  /// Verifica qué modelos están disponibles en tu cuenta
  Future<List<String>> getAvailableModels() async {
    try {
      print('🔍 Consultando modelos disponibles...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['data'] as List;
        
        // Filtrar solo modelos de chat relevantes
        final chatModels = models
            .where((model) => 
                model['id'].toString().contains('gpt') ||
                model['id'].toString().contains('text-davinci'))
            .map((model) => model['id'].toString())
            .toList();
        
        chatModels.sort(); // Ordenar alfabéticamente
        
        print('✅ Modelos disponibles: ${chatModels.join(', ')}');
        return chatModels;
      } else {
        print('❌ Error al obtener modelos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error al consultar modelos: $e');
      return [];
    }
  }

  /// Prueba si un modelo específico está disponible
  Future<bool> testModelAvailability(String modelToTest) async {
    try {
      print('🧪 Probando disponibilidad del modelo: $modelToTest');
      
      final testMessage = {
        'model': modelToTest,
        'messages': [
          {'role': 'user', 'content': 'Test'}
        ],
        'max_tokens': 5,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode(testMessage),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Modelo $modelToTest disponible');
        return true;
      } else if (response.statusCode == 404) {
        print('❌ Modelo $modelToTest no disponible');
        return false;
      } else {
        print('⚠️ Error al probar $modelToTest: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error al probar modelo $modelToTest: $e');
      return false;
    }
  }
}

// ============================================================================
// CLASE DE RESPUESTA
// ============================================================================

/// Clase para encapsular la respuesta de OpenAI
class OpenAIResponse {
  final bool success;
  final String message;
  final String? error;
  final int tokensUsed;
  final String? originalMessage;
  final String? model;
  final String? finishReason;
  final int? statusCode;

  OpenAIResponse({
    required this.success,
    required this.message,
    this.error,
    required this.tokensUsed,
    this.originalMessage,
    this.model,
    this.finishReason,
    this.statusCode,
  });

  /// Convierte la respuesta a Map para logging o debugging
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'error': error,
      'tokensUsed': tokensUsed,
      'originalMessage': originalMessage,
      'model': model,
      'finishReason': finishReason,
      'statusCode': statusCode,
    };
  }

  @override
  String toString() {
    return 'OpenAIResponse(success: $success, message: "${message.substring(0, message.length > 50 ? 50 : message.length)}...", tokensUsed: $tokensUsed)';
  }
}

// ============================================================================
// CONFIGURACIÓN DE EJEMPLO
// ============================================================================

/// Clase con ejemplos de configuración y uso
class OpenAIExamples {
  static final _openAI = OpenAIService();

  /// Ejemplo básico de uso
  static Future<void> basicExample() async {
    final response = await _openAI.sendSimpleMessage(
      '¿Cuáles son los servicios que ofrece Colbún?'
    );

    if (response.success) {
      print('Respuesta: ${response.message}');
      print('Tokens: ${response.tokensUsed}');
    } else {
      print('Error: ${response.error}');
    }
  }

  /// Ejemplo con historial de conversación
  static Future<void> conversationExample() async {
    final history = [
      {'role': 'user', 'content': 'Hola, ¿qué servicios tienen?'},
      {'role': 'assistant', 'content': 'Ofrecemos servicios municipales...'},
    ];

    final response = await _openAI.sendMessage(
      userMessage: '¿Y cuáles son sus horarios?',
      conversationHistory: history,
    );

    print('Respuesta: ${response.message}');
  }

  /// Ejemplo con contexto adicional
  static Future<void> contextExample() async {
    final response = await _openAI.sendMessageWithContext(
      userMessage: '¿Cómo puedo hacer un trámite?',
      additionalContext: 'El usuario necesita información sobre trámites municipales en Colbún',
    );

    print('Respuesta: ${response.message}');
  }

  /// Ejemplo para verificar modelos disponibles
  static Future<void> checkModelsExample() async {
    print('🔍 Verificando configuración de modelos...');
    
    // Ver modelos disponibles
    final availableModels = await _openAI.getAvailableModels();
    print('📋 Modelos disponibles en tu cuenta:');
    for (final model in availableModels) {
      print('  - $model');
    }
    
    // Probar modelos específicos
    final modelsToTest = ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'];
    
    print('\n🧪 Probando disponibilidad de modelos específicos:');
    for (final model in modelsToTest) {
      final isAvailable = await _openAI.testModelAvailability(model);
      print('  $model: ${isAvailable ? '✅ Disponible' : '❌ No disponible'}');
    }
  }
}