import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/theme_bloc.dart';
import '../bloc/faq_bloc.dart';
import '../models/bot_response.dart';
import '../utils/app_colors.dart';
import '../components/chatbot_header.dart';
import '../components/chatbot_body.dart';
import '../components/chatbot_footer.dart';
import '../../../services/firestore_conn.dart';
import '../../../services/openai_service.dart';
import 'package:consultoria_chat_bot/services/firestore_faq_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> messages = [];
  List<Faq> _allLoadedFaqs = [];
  int _messageIdCounter = 0;
  bool _isTyping = false;
  late AnimationController _typingController;
  Animation<double>? _typingAnimation;
  final ScrollController _scrollController = ScrollController();
  
  // Servicios
  final FirestoreConnection _firestoreService = FirestoreConnection();
  final OpenAIService _openAIService = OpenAIService();
  
  // ID de conversación actual
  String? _currentConversationId;
  bool _isLoadingConversation = false;

  final FaqService _faqService = FaqService();

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..addListener(() {
        if (_isTyping) {
          setState(() {});
        }
      });
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
    _loadAllFaqs();
    _initializeConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _loadAllFaqs() async {
    final faqs = await _faqService.getAllFaqs();
    // Esta línea nos dirá si la carga de datos fue exitosa
    print('FAQs cargadas desde Firestore: ${faqs.length} preguntas');
    if (mounted) {
      setState(() {
        _allLoadedFaqs = faqs;
      });
    }
  }

  /// Inicializa la conversación cargando mensajes existentes o creando una nueva
  Future<void> _initializeConversation() async {
    setState(() {
      _isLoadingConversation = true;
    });

    try {
      // Obtener o crear conversación
      _currentConversationId = await _firestoreService.getOrCreateConversation();
      print('🔗 Conversación inicializada: $_currentConversationId');

      // Cargar mensajes existentes
      if (_currentConversationId != null) {
        final existingMessages = await _firestoreService.loadConversationMessages(_currentConversationId!);
        
        if (existingMessages.isNotEmpty) {
          // Hay mensajes previos, cargarlos
          setState(() {
            messages.clear();
            messages.addAll(existingMessages);
            _messageIdCounter = messages.length;
          });
          print('📥 Cargados ${existingMessages.length} mensajes existentes');
        } else {
          // No hay mensajes previos, inicializar chat nuevo
          _initializeChat();
        }
      } else {
        // Error al obtener conversación, inicializar chat normal
        _initializeChat();
      }

    } catch (e) {
      print('❌ Error al inicializar conversación: $e');
      _initializeChat();
    } finally {
      setState(() {
        _isLoadingConversation = false;
      });
    }
  }

  void _initializeChat() {
    addMessage(
        sender: "bot",
        text: "¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?",
        type: "welcome_message");
  }

// -> 3. La función de obtener respuesta ahora es async y usa el servicio
  Future<BotResponse> _getBotResponse(String userMessage) async {
    // Primero, buscar en la base de conocimiento de Firestore
    final Faq? localFaq = await _faqService.findFaq(userMessage);

    print(localFaq != null
        ? '✅ Coincidencia encontrada en Firestore para: "$userMessage"'
        : '❌ No se encontró coincidencia en Firestore para: "$userMessage"');

    if (localFaq != null) {
      // Se encontró una respuesta en Firestore
      return BotResponse(
        answer: localFaq.answer,
        link: localFaq.link,
        source: 'firestore',
        isStandardResponse: true, // Para pedir feedback
      );
    } else {
      // Si no se encuentra en FAQ, activar consulta a IA
      print('🤖 No se encontró en FAQ, activando consulta a OpenAI...');
      return BotResponse(
        answer: "No encontré una respuesta específica. Déjame consultar mi base de conocimiento avanzada...",
        action: "query_openai", // Esta es la clave para activar OpenAI
        source: 'ai_fallback',
        isStandardResponse: false, // No pedir feedback aquí, se hará después de la respuesta de IA
      );
    }
  }

  void handleSendMessage(String text) async {
    // Elimina las opciones de FAQ anteriores para que no se acumulen
    setState(() => messages.removeWhere((m) => m['type'] == 'faq_options'));

    addMessage(sender: "user", text: text);
    setState(() {
      _isTyping = true;
    });
    _typingController.repeat();

    final botResponse = await _getBotResponse(text);
    final random = math.Random();
    int baseTime = 300;
    int complexityTime = (text.length * 10).clamp(0, 1000);
    int responseComplexity = (botResponse.answer.length * 3).clamp(0, 300);
    int randomVariation = random.nextInt(300);
    int totalTTR =
        (baseTime + complexityTime + responseComplexity + randomVariation)
            .clamp(800, 3000);

    Future.delayed(Duration(milliseconds: totalTTR), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _typingController.stop();

        final messageId = DateTime.now().millisecondsSinceEpoch.toString();
        addMessage(
          sender: "bot",
          text: botResponse.answer,
          messageId: messageId,
          source: botResponse.source,
          link: botResponse.link, // Pasar el link al mensaje
        );

        print('🔍 Procesando acción: "${botResponse.action}"');
        
        if (botResponse.action == "open_whatsapp") {
          print('📱 Abriendo WhatsApp...');
          _launchWhatsApp();
        } else if (botResponse.action == "query_openai") {
          print('🤖 Activando consulta a OpenAI para: "$text"');
          _handleOpenAIQuery(text);
        } else {
          print('💬 Respuesta estándar de FAQ');
          // Si es una respuesta estándar, pide feedback
          if (botResponse.isStandardResponse) {
            addMessage(
              sender: "bot",
              text: "¿Fue útil esta información?",
              type: "feedback",
              messageId: messageId,
            );
          }
        }
      }
    });
  }

  void addMessage({
    required String sender,
    String? text,
    String? type,
    List<String>? options,
    String? messageId,
    int? insertAtIndex,
    bool saveToDatabase = true, // Parámetro para controlar si se guarda
    String? source, // Parámetro opcional
    String? link, // Parámetro para el link
  }) {
    setState(() {
      final newMessage = {
        "id": messageId ?? _messageIdCounter++,
        "sender": sender,
        "text": text,
        "type": type,
        "options": options,
        "feedback": null,
        "visible": true,
        "source": source,
        "link": link, // Nuevo campo para el link
      };

      if (insertAtIndex != null) {
        // Insertar en posición específica
        messages.insert(insertAtIndex, newMessage);
      } else {
        // Agregar al final (comportamiento normal)
        messages.add(newMessage);
      }
    });

    // Guardar en Firestore si es un mensaje de texto válido y la conversación está inicializada
    if (saveToDatabase && 
        _currentConversationId != null && 
        text != null && 
        text.isNotEmpty &&
        (type == null || type == 'text' || type == 'welcome_message')) {
      _saveMessageToFirestore(
        sender: sender,
        text: text,
        type: type ?? 'text',
        messageId: messageId?.toString(),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Guarda un mensaje en Firestore de forma asíncrona
  Future<void> _saveMessageToFirestore({
    required String sender,
    required String text,
    required String type,
    String? messageId,
  }) async {
    if (_currentConversationId == null) return;

    try {
      await _firestoreService.saveMessage(
        conversationId: _currentConversationId!,
        sender: sender,
        text: text,
        type: type,
        messageId: messageId,
        metadata: {
          'timestamp_local': DateTime.now().toIso8601String(),
          'platform': 'flutter',
        },
      );
    } catch (e) {
      print('❌ Error al guardar mensaje en Firestore: $e');
      // No interrumpir la experiencia del usuario por errores de guardado
    }
  }

  /// Maneja consultas a OpenAI
  Future<void> _handleOpenAIQuery(String userMessage) async {
    print('🚀 INICIANDO CONSULTA A OPENAI para: "$userMessage"');
    
    try {
      // Obtener historial de mensajes para contexto
      final conversationHistory = _firestoreService.formatMessagesForOpenAI(
        messages.where((m) => m['type'] == 'text' || m['type'] == null).toList()
      );

      print('🤖 Enviando consulta a OpenAI con ${conversationHistory.length} mensajes de contexto...');
      
      // Llamar a OpenAI
      final openAIResponse = await _openAIService.sendMessage(
        userMessage: userMessage,
        conversationHistory: conversationHistory,
      );

      if (mounted) {
        if (openAIResponse.success) {
          // Respuesta exitosa de OpenAI
          final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
          addMessage(
            sender: "bot",
            text: openAIResponse.message,
            messageId: aiMessageId,
          );
          
          // Pedir feedback para la respuesta de IA
          addMessage(
            sender: "bot",
            text: "¿Fue útil esta información?",
            type: "feedback",
            messageId: aiMessageId,
            saveToDatabase: false, // No guardar el mensaje de feedback
          );
          
          print('✅ Respuesta de OpenAI: ${openAIResponse.message.substring(0, 50)}...');
          print('📊 Tokens utilizados: ${openAIResponse.tokensUsed}');
          
        } else {
          // Error en OpenAI, mostrar mensaje de fallback
          addMessage(
            sender: "bot",
            text: "Lo siento, no pude procesar tu consulta en este momento. Por favor, contacta a nuestro equipo de soporte para ayuda personalizada.",
          );
          print('❌ Error en OpenAI: ${openAIResponse.error}');
        }
      }
      
    } catch (e) {
      print('❌ Error al consultar OpenAI: $e');
      
      if (mounted) {
        addMessage(
          sender: "bot",
          text: "Disculpa, hay un problema técnico. Te recomiendo contactar directamente a nuestro equipo de soporte.",
        );
      }
    }
  }

  void _handleFeedback(String messageId, bool wasUseful) {
    // Oculta los botones de feedback para que no se pueda volver a votar
    if (!mounted) return;
    setState(() {
      final feedbackIndex = messages
          .indexWhere((m) => m['type'] == 'feedback' && m['id'] == messageId);
      if (feedbackIndex != -1) messages[feedbackIndex]['visible'] = false;
    });

    // Guardar feedback en Firestore
    if (_currentConversationId != null) {
      _firestoreService.saveFeedback(
        conversationId: _currentConversationId!,
        messageId: messageId,
        wasUseful: wasUseful,
      );
    }

    // Muestra un mensaje de agradecimiento
    addMessage(
      sender: "bot",
      text: "¡Gracias por tu feedback!",
      saveToDatabase: false, // No guardar este mensaje de agradecimiento
    );
  }

  void _clearChatHistory() {
    setState(() {
      messages.clear();
      _initializeChat();
    });
  }

  void _launchWhatsApp() async {
    const phoneNumber = "+56912345678";
    const message = "Hola, necesito ayuda de un asesor.";
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return; // <-- Añade esta línea de seguridad
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp.")),
      );
    }
  }

  List<String> _getRandomFaqs({int count = 3}) {
    // Usa la lista local que cargamos desde initState
    if (_allLoadedFaqs.isEmpty) return [];

    final shuffledFaqs = List<Faq>.from(_allLoadedFaqs)..shuffle();

    return shuffledFaqs.take(count).map((faq) => faq.question).toList();
  }

  void _showFrequentlyAskedQuestions() {
    print('Se presionó el botón de Preguntas Frecuentes.');
    print(
        'Número de FAQs disponibles en la lista local: ${_allLoadedFaqs.length}');

    final faqBloc = context.read<FaqBloc>();
    final currentState = faqBloc.state;

    if (!currentState.showFaqs || currentState.currentFaqs.isEmpty) {
      final List<String> randomFaqs = _getRandomFaqs(count: 3);

      if (randomFaqs.isNotEmpty) {
        // Encontrar la posición del mensaje de bienvenida
        final welcomeIndex =
            messages.indexWhere((m) => m['type'] == 'welcome_message');

        if (welcomeIndex != -1) {
          //Enviar evento a FAQS
          faqBloc.add(ToggleFaqsEvent(newFaqs: randomFaqs));

          // Insertar las FAQs justo después del mensaje de bienvenida
          addMessage(
            sender: "bot",
            text: "Aquí tienes algunas preguntas frecuentes:",
            type: "faq_options",
            options: randomFaqs,
            insertAtIndex: welcomeIndex + 1, // Insertar después del welcome
          );
        }
      }
    } else {
      //Ocultar faqs
      faqBloc.add(ToggleFaqsEvent());

      // Eliminar FAQs existentes
      setState(() {
        messages.removeWhere((message) => message['type'] == 'faq_options');
      });
    }
  }

  void _onFaqSelected(String selectedFaq) {
    print('Se seleccionó la FAQ y se enviará este texto: "$selectedFaq"');
    //1ro oculta faqs actuales
    final faqBloc = context.read<FaqBloc>();
    faqBloc.add(ToggleFaqsEvent());

    handleSendMessage(selectedFaq);
  }

  /// Widget para mostrar indicador de carga durante la inicialización
  Widget _buildLoadingIndicator(bool isDarkMode) {
    return Container(
      width: double.infinity,
      color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando conversación...',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conectando con Firestore',
            style: TextStyle(
              color: isDarkMode ? Colors.white38 : Colors.black38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }



  /// Método temporal para probar modelos de OpenAI
  Future<void> _testOpenAIModels() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificando modelos OpenAI...')),
      );

      // Obtener modelos disponibles
      final models = await _openAIService.getAvailableModels();
      
      // Probar modelos específicos
      final hasGPT35 = await _openAIService.testModelAvailability('gpt-3.5-turbo');
      final hasGPT4 = await _openAIService.testModelAvailability('gpt-4');
      
      // Mostrar información en un diálogo
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🤖 Modelos OpenAI'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔧 API Configurada: ${_openAIService.isConfigured() ? "✅ SÍ" : "❌ NO"}'),
                const SizedBox(height: 8),
                Text('📋 Modelos encontrados: ${models.length}'),
                const SizedBox(height: 8),
                Text('⚡ GPT-3.5-turbo: ${hasGPT35 ? "✅ Disponible" : "❌ No disponible"}'),
                Text('🧠 GPT-4: ${hasGPT4 ? "✅ Disponible" : "❌ No disponible"}'),
                const SizedBox(height: 16),
                const Text('🔍 Todos los modelos:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    child: Text(
                      models.isEmpty ? 'No se pudieron obtener modelos' : models.join('\n'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Hacer una prueba real con OpenAI
                  _handleOpenAIQuery('¿Cuáles son los servicios de Colbún?');
                },
                child: const Text('Probar IA'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar modelos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
      //
      // --- CAMBIO 1: Envolvemos todo en AnnotatedRegion ---
      //
      return AnnotatedRegion<SystemUiOverlayStyle>(
        // Le damos el estilo dinámico a la barra de estado
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              state.isDarkMode ? Brightness.light : Brightness.dark,
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          //
          // --- CAMBIO 2: Añadimos 'top: false' al SafeArea ---
          //
          child: SafeArea(
            top: false, // Evita un doble espaciado en la parte de arriba
            child: Scaffold(
              backgroundColor:
                  state.isDarkMode ? AppColors.darkBackground : Colors.grey[50],
              resizeToAvoidBottomInset: true,
              floatingActionButton: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.extended(
                    onPressed: _testOpenAIModels,
                    heroTag: "test_ai_models",
                    backgroundColor: state.isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
                    icon: const Icon(Icons.model_training, color: Colors.white),
                    label: const Text('Ver Modelos', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              body: Column(
                children: [
                  ChatbotHeader(
                    onClearHistory: _clearChatHistory,
                    onContactWhatsApp: _launchWhatsApp,
                  ),
                  Expanded(
                    child: _isLoadingConversation
                        ? _buildLoadingIndicator(state.isDarkMode)
                        : _typingAnimation != null
                            ? ChatbotBody(
                                isDarkMode: state.isDarkMode,
                                messages: messages,
                                scrollController: _scrollController,
                                isTyping: _isTyping,
                                typingAnimation: _typingAnimation!,
                                onFeedback: _handleFeedback,
                                onSendMessage: handleSendMessage,
                                onShowFrequentlyAskedQuestions:
                                    _showFrequentlyAskedQuestions,
                                onFaqSelected: _onFaqSelected,
                              )
                            : Container(),
                  ),
                  ChatbotFooter(
                    isDarkMode: state.isDarkMode,
                    onSendMessage: handleSendMessage,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
