import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/theme_bloc.dart';

// Estructura de colores (sin cambios)
class AppColors {
  static const Color lightprimary = Color(0xFF4D67AE);
  static const Color lightbackground = Colors.white;
  static const Color lightTextFieldBorder = Color(0xFFE0E0E0);
  static const Color darkprimary = Color(0xFF494C6B);
  static const Color darkBackground = Color(0xFF252525);
}

class BotResponse {
  final String answer;
  final String? action; // El action es opcional

  BotResponse({required this.answer, this.action});
}

// Pantalla principal
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

// Estado de la pantalla
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

  // ============== FUNCIÓN MODIFICADA ==============
  void _initializeChat() {
    // 1. Añade el mensaje de bienvenida
    addMessage(
        sender: "bot",
        text:
            "¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?");

    // 2. Procesa y muestra las FAQs aleatorias desde el JSON
    if (_faqs != null) {
      final List<String> allQuestions = [];

      // Lista de claves de donde extraer las FAQs
      const faqKeys = ['faq_turismo', 'faq_servicios', 'faq_emergencias'];

      for (var key in faqKeys) {
        if (_faqs![key] != null && _faqs![key] is List) {
          for (var entry in _faqs![key]) {
            // Asume que la pregunta está en la clave "question"
            if (entry['question'] != null && entry['question'] is String) {
              allQuestions.add(entry['question']);
            }
          }
        }
      }

      // Baraja la lista de todas las preguntas
      allQuestions.shuffle();

      // Toma las primeras 3 preguntas de la lista barajada
      final List<String> randomFaqs = allQuestions.take(3).toList();

      // Añade las preguntas aleatorias como opciones en el chat
      if (randomFaqs.isNotEmpty) {
        addMessage(
          sender: "bot",
          text: "", // El texto puede estar vacío
          type: "faq_options",
          options: randomFaqs,
        );
      }
    }
  }
  // ============== FIN DE LA FUNCIÓN MODIFICADA ==============

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
      texto =
          texto.replaceAll('Ñ', 'N'); // Opcional, si quieres manejar mayúsculas
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
        return BotResponse(
          answer: entry['answer'],
          action: entry['action'],
        );
      }
    }

    return BotResponse(
      answer: "No encontré una respuesta. Consultando a la IA...",
      action: "query_openai",
    );
  }

  void handleSendMessage(String text) {
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

        addMessage(sender: "bot", text: botResponse.answer);

        if (botResponse.action == "open_whatsapp") {
          _launchWhatsApp();
        } else if (botResponse.action == "query_openai") {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              addMessage(
                  sender: "bot",
                  text: "Respuesta simulada de la IA para: \"$text\".");
            }
          });
        }
      }
    });
  }

  void addMessage(
      {required String sender,
      String? text,
      String? type,
      List<String>? options}) {
    setState(() {
      messages.add({
        "id": _messageIdCounter++,
        "sender": sender,
        "text": text,
        "type": type,
        "options": options,
        "feedback": null,
      });
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

  void _handleFeedback(int messageId, String feedbackType) {
    setState(() {
      final messageIndex = messages.indexWhere((m) => m['id'] == messageId);
      if (messageIndex != -1) {
        messages[messageIndex]['feedback'] = feedbackType;
        if (feedbackType == 'good') {
          print('+1 fue válido');
        } else {
          print('+1 no fue válido');
        }
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor:
              state.isDarkMode ? AppColors.darkBackground : Colors.grey[50],
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
      );
    });
  }
}

// ============================================================================
// COMPONENTE HEADER (Sin cambios)
// ============================================================================
class ChatbotHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onClearHistory;
  final VoidCallback onContactWhatsApp;
  const ChatbotHeader({
    super.key,
    required this.onClearHistory,
    required this.onContactWhatsApp,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return AppBar(
          elevation: 0,
          backgroundColor:
              state.isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
          iconTheme: const IconThemeData(color: AppColors.lightbackground),
          title: const Text(
            'Asistente Colbún',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFFFFF),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    state.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: state.isDarkMode,
                    onChanged: (value) {
                      context.read<ThemeBloc>().add(ToggleThemeEvent());
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFFFFFFFF)),
                color: state.isDarkMode
                    ? AppColors.darkprimary
                    : AppColors.lightprimary,
                iconSize: 32,
                position: PopupMenuPosition.under,
                elevation: 8,
                offset: const Offset(0, 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                onSelected: (value) {
                  if (value == 'Whatsapp') {
                    onContactWhatsApp();
                  } else if (value == 'Borrar Historial') {
                    onClearHistory();
                  }
                },
                itemBuilder: (BuildContext context) {
                  FocusScope.of(context).unfocus();
                  return [
                    const PopupMenuItem(
                      value: 'Whatsapp',
                      child: ListTile(
                        leading: Icon(Icons.chat, color: Colors.green),
                        title: Text(
                          'Contactar por WhatsApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const PopupMenuItem(
                      enabled: false,
                      height: 0,
                      child: Divider(
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Borrar Historial',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Borrar Historial de conversación',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ============================================================================
// COMPONENTE BODY (Sin cambios)
// ============================================================================
class ChatbotBody extends StatelessWidget {
  final bool isDarkMode;
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final bool isTyping;
  final Animation<double> typingAnimation;
  final Function(int, String) onFeedback;
  final Function(String) onSendMessage;

  const ChatbotBody({
    super.key,
    required this.isDarkMode,
    required this.messages,
    required this.scrollController,
    required this.isTyping,
    required this.typingAnimation,
    required this.onFeedback,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final lastBotMessageIndex = messages.lastIndexWhere(
        (m) => m['sender'] == 'bot' && m['type'] != 'faq_options');

    return Container(
      width: double.infinity,
      color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        itemCount: messages.length + (isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (isTyping && index == 0) {
            return _buildTypingIndicator();
          }

          final messageIndex = isTyping ? index - 1 : index;
          final reversedIndex = messages.length - 1 - messageIndex;
          final message = messages[reversedIndex];
          final isUser = message['sender'] == 'user';
          final bool isLastBotMessage = reversedIndex == lastBotMessageIndex;

          if (message['type'] == 'faq_options' && message['options'] != null) {
            return _buildFaqOptions(context, message['options']);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUser) ...[
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.lightprimary,
                        child: Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (message['text'] != null && message['text'].isNotEmpty)
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? (isDarkMode
                                    ? AppColors.darkprimary
                                    : AppColors.lightprimary)
                                : (isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.white),
                            borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16.0),
                                topRight: const Radius.circular(16.0),
                                bottomLeft:
                                    Radius.circular(isUser ? 16.0 : 0.0),
                                bottomRight:
                                    Radius.circular(isUser ? 0.0 : 16.0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : (isDarkMode
                                      ? Colors.white
                                      : Colors.black87),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    if (isUser) ...[
                      const SizedBox(width: 8),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isUser && isLastBotMessage) _buildFeedbackButtons(message),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFaqOptions(BuildContext context, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map((option) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ElevatedButton(
              onPressed: () {
                onSendMessage(option);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
              ),
              child: Text(option),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedbackButtons(Map<String, dynamic> message) {
    final feedbackState = message['feedback'];
    final messageId = message['id'];

    if (message['text']
        .toString()
        .contains("¡Hola! Soy el asistente virtual")) {
      return const SizedBox.shrink();
    }

    return feedbackState == null
        ? Padding(
            padding: const EdgeInsets.only(left: 48, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => onFeedback(messageId, 'good'),
                  child: const Icon(Icons.thumb_up_alt_outlined,
                      size: 20, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => onFeedback(messageId, 'bad'),
                  child: const Icon(Icons.thumb_down_alt_outlined,
                      size: 20, color: Colors.grey),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(left: 48, top: 8),
            child: Text(
              "Gracias por tu feedback.",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.lightprimary,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
                bottomLeft: Radius.circular(0.0),
                bottomRight: Radius.circular(16.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    const SizedBox(width: 4),
                    _buildTypingDot(1),
                    const SizedBox(width: 4),
                    _buildTypingDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    double delay = index * 0.2;
    double animationValue = (typingAnimation.value - delay).clamp(0.0, 1.0);
    double scale =
        0.5 + (0.5 * (1 + math.cos(animationValue * 2 * math.pi)) / 2);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white70 : Colors.grey[600],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENTE FOOTER (Sin cambios)
// ============================================================================
class ChatbotFooter extends StatefulWidget {
  final bool isDarkMode;
  final Function(String) onSendMessage;

  const ChatbotFooter({
    super.key,
    required this.isDarkMode,
    required this.onSendMessage,
  });

  @override
  State<ChatbotFooter> createState() => _ChatbotFooterState();
}

class _ChatbotFooterState extends State<ChatbotFooter> {
  final TextEditingController _textController = TextEditingController();

  void _sendMessage() {
    final messageText = _textController.text.trim();
    if (messageText.isNotEmpty) {
      widget.onSendMessage(messageText);
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightbackground,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? AppColors.darkBackground
                      : AppColors.lightbackground,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.grey[600]!
                          : AppColors.lightTextFieldBorder)),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _textController,
                style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: widget.isDarkMode
                        ? Colors.grey[400]
                        : const Color(0xFF828282),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? AppColors.darkBackground
                  : AppColors.lightbackground,
            ),
            child: IconButton(
              icon: Icon(Icons.send,
                  color: widget.isDarkMode
                      ? Colors.white
                      : const Color(0XFF1d1b20)),
              iconSize: 24,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
