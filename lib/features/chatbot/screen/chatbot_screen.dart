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
    _initializeChat();
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

  void _initializeChat() {
    addMessage(
        sender: "bot",
        text:
            "¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?",
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
        // ...
      );
    } else {
      // Si no, se procede a la lógica de fallback
      return BotResponse(
        answer: "No encontré una respuesta. Consultando a la IA...",
        // ...
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
        );

        if (botResponse.action == "open_whatsapp") {
          _launchWhatsApp();
        } else if (botResponse.action == "query_openai") {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              final aiMessageId =
                  DateTime.now().millisecondsSinceEpoch.toString();
              addMessage(
                sender: "bot",
                text: "Respuesta simulada de la IA para: \"$text\".",
                messageId: aiMessageId,
              );
              // Pide feedback para la respuesta de la IA
              addMessage(
                sender: "bot",
                text: "¿Fue útil esta información?",
                type: "feedback",
                messageId: aiMessageId,
              );
            }
          });
        } else {
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
    String? source, // Nuevo parámetro opcional
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
      };

      if (insertAtIndex != null) {
        // Insertar en posición específica
        messages.insert(insertAtIndex, newMessage);
      } else {
        // Agregar al final (comportamiento normal)
        messages.add(newMessage);
      }
    });

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

  void _handleFeedback(String messageId, bool wasUseful) {
    // Oculta los botones de feedback para que no se pueda volver a votar
    if (!mounted) return;
    setState(() {
      final feedbackIndex = messages
          .indexWhere((m) => m['type'] == 'feedback' && m['id'] == messageId);
      if (feedbackIndex != -1) messages[feedbackIndex]['visible'] = false;
    });

    // Muestra un mensaje de agradecimiento
    addMessage(
      sender: "bot",
      text: "¡Gracias por tu feedback!",
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
              body: Column(
                children: [
                  ChatbotHeader(
                    onClearHistory: _clearChatHistory,
                    onContactWhatsApp: _launchWhatsApp,
                  ),
                  Expanded(
                    child: _typingAnimation != null
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
