import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/theme_bloc.dart';
import '../bloc/faq_bloc.dart';
import '../utils/app_colors.dart';
import '../components/chatbot_header.dart';
import '../components/chatbot_body.dart';
import '../components/chatbot_footer.dart';
import '../../../services/openai_service.dart';
import '../../../services/firestore_conversations.dart';
import '../../../services/firestore_faq_service.dart';
import '../../../services/language_service.dart';
import '../../../services/chat_history_service.dart';
import '../../../services/firestore_emergency.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  // ===========================================================================
  // CONTROLADORES Y ANIMACIONES
  // ===========================================================================
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;
  Animation<double>? _typingAnimation;

  // ===========================================================================
  // ESTADO DE LA APLICACIÓN
  // ===========================================================================
  final List<Map<String, dynamic>> messages = [];
  bool _isTyping = false;
  bool _isLoadingConversation = false;
  bool _hasRestoredLocalHistory = false;

  // ===========================================================================
  // DATOS Y SERVICIOS
  // ===========================================================================
  List<Faq> _allLoadedFaqs = [];
  List<EmergencyContact> _currentEmergencyContacts = [];
  String? _currentConversationId;
  String _currentLanguage = 'es';
  final Map<String, String> _messageLanguages = {};

  // Servicios
  final FirestoreConnection _firestoreConnection = FirestoreConnection();
  final LanguageService _languageService = LanguageService();
  final EmergencyService _emergencyService = EmergencyService();
  late FaqService _faqService;
  late OpenAIService _openAIService;
  late final ChatHistoryService _chatHistoryService;

  // ===========================================================================
  // CONSTANTES Y CONFIGURACIÓN
  // ===========================================================================
  final Set<String> _contextualTriggers = const {
    'por que', 'porqué', 'porque', 'why', 
    'explica mas', 'dame mas detalles', 'a que te refieres'
  };

  @override
  void initState() {
    super.initState();
    _faqService = context.read<FaqService>();
    _openAIService = context.read<OpenAIService>();
    _chatHistoryService = ChatHistoryService(); // Inicializa el servicio de caché local
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
    _loadEmergencyContacts();
  // Restaura historial local y luego inicializa conversación en Firestore
  _restoreCachedHistory().whenComplete(_initializeConversation);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingController.dispose();
    _languageService.close(); // Cerrar el servicio de idioma
    super.dispose();
  }

  // ===========================================================================
  // GESTIÓN DE CONVERSACIONES E HISTORIAL
  // ===========================================================================
  Future<void> _restoreCachedHistory() async {
    final cached = await _chatHistoryService.loadLastConversation();
    if (!mounted || cached == null) return;

    setState(() {
      messages
        ..clear()
        ..addAll(cached.messages);
      _currentConversationId = cached.conversationId;
    });

    _currentLanguage = cached.lastLanguage ?? 'es';
    _rebuildMessageLanguageIndex(messages);
    _hasRestoredLocalHistory = true;
    // Historial local restaurado
  }

  void _rebuildMessageLanguageIndex(List<Map<String, dynamic>> source) {
    _messageLanguages.clear();
    for (final message in source) {
      final id = message['id'] as String?;
      final language = message['language'] as String?;
      if (id != null && language != null) {
        _messageLanguages[id] = language;
      }
    }
  }

  Future<void> _persistMessages() async {
    await _chatHistoryService.saveHistory(
      conversationId: _currentConversationId,
      messages: List<Map<String, dynamic>>.from(messages),
      language: _currentLanguage,
    );
    // Guarda el historial localmente
  }

  /// Inicializa la conversación cargando mensajes existentes o creando una nueva
  Future<void> _initializeConversation() async {
    setState(() {
      _isLoadingConversation = true;
    });

    try {
      if (_currentConversationId == null) {
        _currentConversationId =
            await _firestoreConnection.createConversation(
          userId: _firestoreConnection.currentUserId!,
          language: _currentLanguage,
        );
        print('🔗 Conversación inicializada: $_currentConversationId');
        // Conversación creada en Firestore
      }

      final conversationId = _currentConversationId!;
      final conversationData =
          await _firestoreConnection.getCompleteConversation(conversationId);
      final existingMessages =
          conversationData?['messageDetails'] as List<dynamic>? ?? [];

      if (existingMessages.isNotEmpty) {
        final correctlyTypedMessages = existingMessages
            .map((msg) => Map<String, dynamic>.from(msg))
            .toList();

        setState(() {
          messages
            ..clear()
            ..addAll(correctlyTypedMessages);
        });
        _rebuildMessageLanguageIndex(messages);
        await _persistMessages(); // Cachea la última versión
        // Cache actualizado con mensajes de Firestore
        print('📥 Cargados ${existingMessages.length} mensajes existentes');
      } else if (!_hasRestoredLocalHistory && messages.isEmpty) {
        _initializeChat();
      }
    } catch (e) {
      print('❌ Error al inicializar conversación: $e');
      if (!_hasRestoredLocalHistory && messages.isEmpty) {
        _initializeChat();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConversation = false;
        });
      }
    }
  }

  void _initializeChat() {
    final welcomeMessage = _currentLanguage == 'en'
      ? "Hello! I am the virtual assistant of Colbún. How can I help you?"
      : "¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?";
    addMessage(
      sender: "bot",
      text: welcomeMessage,
      type: "welcome_message",
      language: _currentLanguage, // Pasar el idioma
      saveToDatabase: true, // Guardamos el mensaje de bienvenida
    ).then((_) => _persistMessages()); // Cachea el mensaje de bienvenida
  }

  void _clearChatHistory() {
    setState(() {
      messages.clear();
      _initializeChat();
    });
    _chatHistoryService.clearHistory(conversationId: _currentConversationId); // Borra historial local
    // Borra historial en Firestore
    _firestoreConnection.deleteAllUserConversations();
  }

  // ===========================================================================
  // GESTIÓN DE MENSAJES
  // ===========================================================================
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
    String? language, // parametro nuevo
  }) async {
    final newMessage = {
      "id": messageId, // El ID ahora vendrá de Firestore
      "sender": sender, "text": text, "type": type, "options": options,
      "feedback": null, "visible": true, "source": source, "link": link,
      "extras": extras, "language": language, //parametro nuevo
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
  // Usar el ID generado o el original para el índice de idiomas
  final effectiveId = generatedMessageId ?? messageId;
  if (effectiveId != null && language != null) {
    _messageLanguages[effectiveId] = language;
  }

  if (mounted) {
    setState(() {
      if (insertAtIndex != null) {
        messages.insert(insertAtIndex, newMessage);
      } else {
        messages.add(newMessage);
      }
    });
      // Persistir historial local después de cada cambio
      await _persistMessages();
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

  // ===========================================================================
  // PROCESAMIENTO DE MENSAJES Y IA
  // ===========================================================================
  void handleSendMessage(String text) async {

    // **AGREGAR LOGS DE DEBUG COMPLETOS**
    print("🎯🎯🎯 INICIANDO handleSendMessage 🎯🎯🎯");
    print("📝 Mensaje recibido: '$text'");
  
  // **DETECTAR IDIOMA CON MÁS LOGS**
  try {
    _currentLanguage = await _languageService.detectLanguage(text);
    print("🌐🌐🌐 IDIOMA DETECTADO: $_currentLanguage para mensaje: $text");
    // Verificar si es emergencia
      if (_emergencyService.detectEmergency(text, _currentLanguage)) {
        print("🚨🚨🚨 EMERGENCIA DETECTADA! 🚨🚨🚨");
        _activateEmergencyMode(text);
        return; // Detener procesamiento normal
      }
  } catch (e) {
    print("❌ ERROR en detección de idioma: $e");
    _currentLanguage = 'es'; // Fallback a español
  }
  

    setState(() => messages.removeWhere((m) => m['type'] == 'faq_options'));

    final conversationHistory =
        _openAIService.formatMessagesForOpenAI(messages);
    addMessage(sender: "user", text: text,language: _currentLanguage,);

    setState(() {
      _isTyping = true;
    });
    _typingController.repeat();

    try {
      // PLAN A: Intentar obtener una respuesta de la IA (Lógica online)
      print("🌐 Intentando conectar con el servicio de IA...");
      print("🤖 BUSCANDO FAQs PARA: '$text'");

      List<Faq> contextFaqs = [];
      final cleanText =
          text.toLowerCase().trim().replaceAll(RegExp(r'[?¿]'), '');

      if (!_contextualTriggers.contains(cleanText)) {
      contextFaqs = await _faqService.findContextFaqs(text);
      print("📚 FAQs encontradas: ${contextFaqs.length}");
      
      // **DEBUG DETALLADO DE LAS FAQs CON IDIOMA**
      for (var i = 0; i < contextFaqs.length; i++) {
        var faq = contextFaqs[i];
        print('📖 FAQ $i - ID: ${faq.id}');
        print('📖 FAQ $i - Pregunta ES: ${faq.question}');
        print('📖 FAQ $i - Pregunta EN: ${faq.questionEn}');
        print('📖 FAQ $i - Respuesta ES: ${faq.answer}');
        print('📖 FAQ $i - Respuesta EN: ${faq.answerEn}');
        print('📖 FAQ $i - Categoría: ${faq.category}');
        print('📖 FAQ $i - Tags: ${faq.tags}');
        print('📖 FAQ $i - Link: ${faq.link}');
      }
    }
      // **OBTENER LA URL REAL ANTES DE LLAMAR A OPENAI**
      String? realUrl;
      if (contextFaqs.isNotEmpty) {
        realUrl = contextFaqs.first.link;
        print('🔗 URL real obtenida de la base de datos: $realUrl');
      }

      print("🚀 LLAMANDO A OPENAI CON IDIOMA: $_currentLanguage");
      final openAIResponse = await _openAIService.generateRAGResponse(
        userMessage: text,
        contextFaqs: contextFaqs,
        conversationHistory: conversationHistory,
        language: _currentLanguage, // **PASAR EL IDIOMA A OPENAI**
      );

      if (mounted) {
        if (openAIResponse.success) {
          final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();

          // **PRIORIDAD: URL REAL > URL EXTRAÍDA**
          String? finalUrl = realUrl;
          if (finalUrl == null || finalUrl.isEmpty) {
            finalUrl = openAIResponse.extractedUrls.isNotEmpty 
                ? openAIResponse.extractedUrls.first 
                : null;
            print('🔗 Usando URL extraída como fallback: $finalUrl');
          }
          print("✅ RESPUESTA OPENAI: ${openAIResponse.message.substring(0, 100)}...");
          addMessage(
            sender: "bot",
            text: openAIResponse.message,
            messageId: aiMessageId,
            source: 'openai_rag',
            link: finalUrl,
            language: _currentLanguage, 
            extras: {'showFeedback': true},
          );
          print('✅ Respuesta procesada con URL: $realUrl');
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
          final bestMatch = localResults.first; // Tomamos el resultado más relevante

          // **USAR LA RESPUESTA EN EL IDIOMA CORRECTO**
          String offlineAnswer;
          if (_currentLanguage == 'en' && bestMatch.answerEn.isNotEmpty) {
            offlineAnswer = "I don't have connection right now, but I found this that might help you:\n\n${bestMatch.answerEn}";
          } else {
            offlineAnswer = "No tengo conexión en este momento, pero encontré esto que podría ayudarte:\n\n${bestMatch.answer}";
          }
          final offlineMessageId = DateTime.now().millisecondsSinceEpoch.toString();
          addMessage(
            sender: "bot",
            text: offlineAnswer,
            messageId: offlineMessageId,
            source: 'offline_faq', // Un nuevo source para identificar la respuesta
            link: bestMatch.link, // ← URL real de la FAQ
            language: _currentLanguage,
            extras: {
              'showFeedback': true
            }, // También podemos mostrar el link si existe
          );
        } else {
          String errorMessage = _currentLanguage == 'en'
            ? "Sorry, I couldn't connect and didn't find a local answer for your question. Please check your internet connection."
            : "Lo siento, no pude conectarme y no encontré una respuesta local para tu pregunta. Por favor, revisa tu conexión a internet.";
          // Falló la conexión Y no encontramos nada en la base de datos local.
          addMessage(
              sender: "bot",
              text: errorMessage,
              source: 'error',
              language: _currentLanguage,
              );
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
    print("🏁🏁🏁 FINALIZANDO handleSendMessage 🏁🏁🏁");
  }
  // ===========================================================================
  // GESTIÓN DE EMERGENCIAS
  // ===========================================================================
  void _activateEmergencyMode(String userMessage) {
    addMessage(
      sender: "user", 
      text: userMessage,
      language: _currentLanguage,
    );
    final relevantContacts = _emergencyService.getRelevantContacts(userMessage, _currentLanguage);
    
    setState(() {
    _currentEmergencyContacts = relevantContacts;
    });
    
    /// Mensaje automático del bot
    final emergencyMessage = _currentLanguage == 'en'
        ? "I've detected an emergency situation. I'm showing emergency contacts that can help you."
        : "He detectado una situación de emergencia. Estoy mostrando contactos de emergencia que pueden ayudarte.";
    
    addMessage(
      sender: "bot",
      text: emergencyMessage,
      type: "emergency",
      language: _currentLanguage,
    );
    
    // Mostrar el modal de emergencia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showEmergencyModal();
    });
  }

  void _deactivateEmergencyMode() {
  setState(() {
    _currentEmergencyContacts = [];
  });
  }

  Future<void> _makeEmergencyCall(String phoneNumber) async {
    try {
      await _emergencyService.makeCall(phoneNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentLanguage == 'en'
                  ? "Could not make the call. Please dial $phoneNumber manually"
                  : "No se pudo realizar la llamada. Por favor marca $phoneNumber manualmente",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Agregar este método para mostrar el modal de emergencia
  void _showEmergencyModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54, // Fondo semitransparente
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return _buildEmergencyModal();
      },
    );
  }

  Future<void> _loadEmergencyContacts() async {
    await _emergencyService.loadEmergencyContacts();
  }
  
  // Reemplazar el método _buildEmergencyCard por este:
  Widget _buildEmergencyModal() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8, // 80% de la altura
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ?
          AppColors.darkBackground : Colors.grey[50],
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyHeader(),
            const SizedBox(height: 16),
            _buildEmergencyDescription(),
            const SizedBox(height: 16),
            Expanded(//scroll en caso de muchos numeros
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildEmergencyContacts(),
                )
              )
            ),
            
            const SizedBox(height: 20),
            _buildCloseButton(),
          ],
        ),
      ),
      )
    );
  }
  // Header de emergencia
  Widget _buildEmergencyHeader(){
    return Row(
      children: [
                Icon(Icons.warning_amber_rounded, 
                    color: Colors.red[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentLanguage == 'en' ? 'EMERGENCY DETECTED' : 'EMERGENCIA DETECTADA',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            );
  }
  // Descripcion de emergencia
  Widget _buildEmergencyDescription(){
    return Text(
      _currentLanguage == 'en'
          ? "I've detected an emergency situation. Here are contacts that can help you immediately:"
          : "He detectado una situación de emergencia. Aquí tienes contactos que pueden ayudarte inmediatamente:",
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFamily: 'Poppins',
      ),
    );
  }
  // Lista de contactos de emergencia
  List<Widget> _buildEmergencyContacts(){
    return _currentEmergencyContacts.map((contact) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        elevation: 2,
        child: ListTile(
          title: Text(
            contact.getName(_currentLanguage),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          subtitle: Text(
            '${contact.phone} • ${contact.getType(_currentLanguage)}',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
            ),
          ),
          trailing: FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar modal
              _makeEmergencyCall(contact.phone);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[100],
              foregroundColor: Colors.red[900],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 4),
                Text(
                  _currentLanguage == 'en' ? 'Call' : 'Llamar',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
  // Botón de cierre
  Widget _buildCloseButton(){
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deactivateEmergencyMode();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              _currentLanguage == 'en' ? 'Close' : 'Cerrar',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
  // ===========================================================================
  // GESTIÓN DE FAQs
  // ===========================================================================
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

  void _showFrequentlyAskedQuestions() {
    print('Se presionó el botón de Preguntas Frecuentes.');
    print(
        'Número de FAQs disponibles en la lista local: ${_allLoadedFaqs.length}');
    print('🌐 Idioma actual para FAQs: $_currentLanguage');

    final faqBloc = context.read<FaqBloc>();
    final currentState = faqBloc.state;

    if (!currentState.showFaqs || currentState.currentFaqs.isEmpty) {
      final List<String> randomFaqs = _faqService.getRandomFaqsByLanguage(_currentLanguage, count: 3);

      if (randomFaqs.isNotEmpty) {
        // Encontrar la posición del mensaje de bienvenida
        final welcomeIndex =
            messages.indexWhere((m) => m['type'] == 'welcome_message');

        if (welcomeIndex != -1) {
          //Enviar evento a FAQS
          faqBloc.add(ToggleFaqsEvent(newFaqs: randomFaqs));

          // Texto dinámico según idioma para la introducción de FAQs
          final introText = _currentLanguage == 'en' 
              ? "Here are some frequently asked questions:" 
              : "Aquí tienes algunas preguntas frecuentes:";

          // Insertar las FAQs justo después del mensaje de bienvenida
          addMessage(
            sender: "bot",
            text: introText,
            type: "faq_options",
            options: randomFaqs,
            insertAtIndex: welcomeIndex + 1, // Insertar después del welcome
            language: _currentLanguage, // ← IMPORTANTE: pasar el idioma
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

    // 2. Eliminar el mensaje de FAQs de la interfaz
    setState(() {
      messages.removeWhere((message) => message['type'] == 'faq_options');
    });

    handleSendMessage(selectedFaq);
  }

  // ===========================================================================
  // MÉTODOS DE UI AUXILIARES
  // ===========================================================================
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

  // ===========================================================================
  // CONSTRUCCIÓN DE LA UI
  // ===========================================================================
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
              floatingActionButton: const Column(
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
                                emergencyContacts: _currentEmergencyContacts.map((contact) {
                                  return {
                                    'name': contact.name,
                                    'phone': contact.phone,
                                    'type': contact.type,
                                  };
                                }).toList(),
                                onEmergencyCall: _makeEmergencyCall,
                                onCloseEmergency: _deactivateEmergencyMode,
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
