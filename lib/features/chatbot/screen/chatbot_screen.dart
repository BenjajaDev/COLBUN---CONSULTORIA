import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/theme_bloc.dart';
import '../bloc/faq_bloc.dart';
import '../../../services/firestore_conversations.dart';
import '../utils/app_colors.dart';
import '../components/chatbot_header.dart';
import '../components/chatbot_body.dart';
import '../components/chatbot_footer.dart';
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

  bool _isTyping = false;
  late AnimationController _typingController;
  Animation<double>? _typingAnimation;
  final ScrollController _scrollController = ScrollController();

  // Servicios
  final FirestoreConnection _firestoreConnection = FirestoreConnection();
  late FaqService _faqService;
  late OpenAIService _openAIService;

  // ID de conversación actual
  String? _currentConversationId;
  bool _isLoadingConversation = false;

  // Palabras clave para detectar preguntas de seguimiento
  final Set<String> _contextualTriggers = const {
    'por que',
    'porqué',
    'porque',
    'why',
    'explica mas',
    'dame mas detalles',
    'a que te refieres'
  };

  @override
  void initState() {
    super.initState();
    _faqService = context.read<FaqService>();
    _openAIService = context.read<OpenAIService>();
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
      _currentConversationId = await _firestoreConnection.createConversation(
          userId: _firestoreConnection.currentUserId!, language: 'es');
      print('🔗 Conversación inicializada: $_currentConversationId');

      // Cargar mensajes existentes
      if (_currentConversationId != null) {
        final conversationData = await _firestoreConnection
            .getCompleteConversation(_currentConversationId!);
        final existingMessages =
            conversationData?['messageDetails'] as List<dynamic>? ?? [];

        if (existingMessages.isNotEmpty) {
          // Convertimos cada item de la lista al tipo correcto (Map<String, dynamic>)
          final correctlyTypedMessages = existingMessages
              .map((msg) => Map<String, dynamic>.from(msg))
              .toList();

          setState(() {
            messages.clear();
            messages.addAll(correctlyTypedMessages);
            // La variable _messageIdCounter ya no es necesaria y se puede eliminar de la clase.
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
      text:
          "¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?",
      type: "welcome_message",
      saveToDatabase: true, // Guardamos el mensaje de bienvenida
    );
  }

  void handleSendMessage(String text) async {
    setState(() => messages.removeWhere((m) => m['type'] == 'faq_options'));

    final conversationHistory =
        _openAIService.formatMessagesForOpenAI(messages);
    addMessage(sender: "user", text: text);

    setState(() {
      _isTyping = true;
    });
    _typingController.repeat();

    try {
      // PLAN A: Intentar obtener una respuesta de la IA (Lógica online)
      print("🌐 Intentando conectar con el servicio de IA...");

      List<Faq> contextFaqs = [];
      final cleanText =
          text.toLowerCase().trim().replaceAll(RegExp(r'[?¿]'), '');

      if (!_contextualTriggers.contains(cleanText)) {
        contextFaqs = await _faqService.findContextFaqs(text);
      }

      final openAIResponse = await _openAIService.generateRAGResponse(
        userMessage: text,
        contextFaqs: contextFaqs,
        conversationHistory: conversationHistory,
      );

      if (mounted) {
        if (openAIResponse.success) {
          final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
          addMessage(
            sender: "bot",
            text: openAIResponse.message,
            messageId: aiMessageId,
            source: 'openai_rag',
            extras: {'showFeedback': true},
          );
        } else {
          // La IA devolvió un error controlado, aquí también podríamos activar el fallback
          throw Exception(openAIResponse.message);
        }
      }
    } catch (e) {
      // PLAN B: La conexión falló, buscar respuesta en la base de datos local (Lógica offline)
      print(
          "🔴 Falló la conexión con la IA, iniciando fallback offline. Error: $e");

      // Reutilizamos el servicio de FAQs para buscar en la lista local (_allLoadedFaqs)
      final List<Faq> localResults = await _faqService.findContextFaqs(text);

      if (mounted) {
        if (localResults.isNotEmpty) {
          // ¡Éxito! Encontramos una respuesta local.
          final bestMatch =
              localResults.first; // Tomamos el resultado más relevante
          final offlineAnswer =
              "No tengo conexión en este momento, pero encontré esto que podría ayudarte:\n\n${bestMatch.answer}";
          final offlineMessageId =
              DateTime.now().millisecondsSinceEpoch.toString();
          addMessage(
            sender: "bot",
            text: offlineAnswer,
            messageId: offlineMessageId,
            source:
                'offline_faq', // Un nuevo source para identificar la respuesta
            link: bestMatch.link,
            extras: {
              'showFeedback': true
            }, // También podemos mostrar el link si existe
          );
        } else {
          // Falló la conexión Y no encontramos nada en la base de datos local.
          addMessage(
              sender: "bot",
              text:
                  "Lo siento, no pude conectarme y no encontré una respuesta local para tu pregunta. Por favor, revisa tu conexión a internet.",
              source: 'error');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _typingController.stop();
      }
    }
  }

  Future<String?> addMessage({
    required String sender,
    String? text,
    String? type,
    List<String>? options,
    String? messageId,
    int? insertAtIndex,
    bool saveToDatabase = true,
    String? source,
    String? link,
    Map<String, dynamic>? extras,
  }) async {
    final newMessage = {
      "id": messageId, // El ID ahora vendrá de Firestore
      "sender": sender, "text": text, "type": type, "options": options,
      "feedback": null, "visible": true, "source": source, "link": link,
      "extras": extras,
    };

    String? generatedMessageId;

    if (saveToDatabase &&
        _currentConversationId != null &&
        text != null &&
        text.isNotEmpty) {
      try {
        // Usamos el nuevo servicio para guardar el mensaje
        generatedMessageId =
            await _firestoreConnection.addMessageToConversation(
          conversationId: _currentConversationId!,
          text: text,
          sender: sender,
          isFaq: source != null && source.contains('firestore'),
          faqSource: source,
        );
        newMessage['id'] = generatedMessageId;
      } catch (e) {
        debugPrint("❌ Error al guardar mensaje con el nuevo servicio: $e");
      }
    }

    if (mounted) {
      setState(() {
        if (insertAtIndex != null) {
          messages.insert(insertAtIndex, newMessage);
        } else {
          messages.add(newMessage);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Va al final de la lista porque está invertida
          duration: const Duration(
              milliseconds: 400), // <-- Puedes ajustar la duración
          curve: Curves.easeOut, // <-- Esta curva da una sensación suave
        );
      }
    });

    return generatedMessageId;
  }

  void _handleFeedback(String messageId, bool wasUseful) {
    if (!mounted) return;

    setState(() {
      final messageIndex = messages.indexWhere((m) => m['id'] == messageId);

      if (messageIndex != -1) {
        final message = messages[messageIndex];
        if (message['extras'] is Map) {
          // 1. Ocultamos los botones como antes
          (message['extras'] as Map)['showFeedback'] = false;
          // 2. ¡NUEVO! Añadimos el mensaje de agradecimiento al mismo objeto
          (message['extras'] as Map)['feedbackMessage'] =
              "¡Gracias por tu feedback!";
        }
      }
    });

    // Guardamos la calificación en Firestore como antes
    if (_currentConversationId != null) {
      _firestoreConnection.saveMessageRating(
        conversationId: _currentConversationId!,
        messageId: messageId,
        helpful: wasUseful,
      );
    }
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
    if (_allLoadedFaqs.isEmpty) return [];

    // 1. Filtra la lista para excluir la categoría 'saludos_despedidas'
    final filteredFaqs = _allLoadedFaqs
        .where((faq) => faq.category != 'saludos_despedidas')
        .toList();

    // 2. Baraja la lista ya filtrada
    final shuffledFaqs = filteredFaqs..shuffle();

    // 3. Toma las preguntas de la lista barajada
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

  @override
  Widget build(BuildContext context) {
    print('--- Reconstruyendo la lista de mensajes ---');
    for (var msg in messages.reversed.take(5)) {
      // Imprime los últimos 5 mensajes
      print('TIPO: ${msg['type']} | TEXTO: ${msg['text']}');
    }
    print('-----------------------------------------');
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
