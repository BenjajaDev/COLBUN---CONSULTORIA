import 'dart:convert';
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

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> messages = [];
  int _messageIdCounter = 0;
  bool _isTyping = false;
  late AnimationController _typingController;
  Animation<double>? _typingAnimation;
  Map<String, dynamic>? _faqs;
  final ScrollController _scrollController = ScrollController();

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
    _loadFaqs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    final String response = await rootBundle.loadString('assets/faqs.json');
    final data = await json.decode(response);
    setState(() {
      _faqs = data;
      _initializeChat();
    });
  }

  void _initializeChat() {
    addMessage(
        sender: "bot",
        text:
            "¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?",
        type: "welcome_message");
  }

  BotResponse _getBotResponse(String userMessage) {
    if (_faqs == null) {
      return BotResponse(answer: "Cargando respuestas...");
    }

    String message = userMessage.toLowerCase().trim();

    String eliminarTildes(String texto) {
      texto = texto.replaceAll(RegExp(r'[áäàâã]'), 'a');
      texto = texto.replaceAll(RegExp(r'[éëèê]'), 'e');
      texto = texto.replaceAll(RegExp(r'[íïìî]'), 'i');
      texto = texto.replaceAll(RegExp(r'[óöòôõ]'), 'o');
      texto = texto.replaceAll(RegExp(r'[úüùû]'), 'u');
      texto = texto.replaceAll('ñ', 'n');
      texto = texto.replaceAll('Ñ', 'N');
      return texto;
    }

    message = eliminarTildes(message);

    final allEntries = [
      ..._faqs!['greetings'],
      ..._faqs!['faq_turismo'],
      ..._faqs!['faq_servicios'],
      ..._faqs!['fallback'],
      ..._faqs!['farewells'],
      ..._faqs!['faq_emergencias'],
    ];

    for (var entry in allEntries) {
      List<dynamic> tags = entry['tags'];
      if (tags.any((tag) => message.contains(tag.toLowerCase()))) {
        // Determina si la respuesta es un saludo o despedida para no pedir feedback
        bool isGreetingOrFarewell = (_faqs!['greetings'].contains(entry) ||
            _faqs!['farewells'].contains(entry));

        return BotResponse(
          answer: entry['answer'],
          action: entry['action'],
          isStandardResponse: !isGreetingOrFarewell,
        );
      }
    }

    return BotResponse(
      answer: "No encontré una respuesta. Consultando a la IA...",
      action: "query_openai",
    );
  }

  void handleSendMessage(String text) {
    // Elimina las opciones de FAQ anteriores para que no se acumulen
    setState(() => messages.removeWhere((m) => m['type'] == 'faq_options'));

    addMessage(sender: "user", text: text);
    setState(() {
      _isTyping = true;
    });
    _typingController.repeat();

    final botResponse = _getBotResponse(text);
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
            sender: "bot", text: botResponse.answer, messageId: messageId);

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
    int? insertAtIndex, // Nuevo parámetro opcional
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp.")),
      );
    }
  }

  List<String> _getRandomFaqs({int count = 3}) {
    final List<String> allQuestions = [];
    if (_faqs == null) return allQuestions;

    const faqKeys = ['faq_turismo', 'faq_servicios', 'faq_emergencias'];

    for (var key in faqKeys) {
      if (_faqs![key] != null && _faqs![key] is List) {
        for (var entry in _faqs![key]) {
          if (entry['question'] != null && entry['question'] is String) {
            allQuestions.add(entry['question']);
          }
        }
      }
    }

    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }

  void _showFrequentlyAskedQuestions() {
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
