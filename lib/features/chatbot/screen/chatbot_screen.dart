// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Simulación del BLoC de tema para que el código sea autoejecutable
class ThemeBloc extends Cubit<ThemeState> {
  ThemeBloc() : super(const ThemeState(isDarkMode: false));
  void add(ToggleThemeEvent event) =>
      emit(ThemeState(isDarkMode: !state.isDarkMode));
}

class ToggleThemeEvent {}

class ThemeState {
  final bool isDarkMode;
  const ThemeState({required this.isDarkMode});
}
// Fin de la simulación del BLoC

class AppColors {
  static const Color lightprimary = Color(0xFF4D67AE);
  static const Color lightbackground = Colors.white;
  static const Color lightTextFieldBorder = Color(0xFFE0E0E0);
  static const Color darkprimary = Color(0xFF494C6B);
  static const Color darkBackground = Color(0xFF252525);
}

class BotResponse {
  final String answer;
  final String? action;
  final bool isStandardResponse;

  BotResponse({
    required this.answer,
    this.action,
    this.isStandardResponse = true,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> messages = [];
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
        if (_isTyping) setState(() {});
      });
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _typingController, curve: Curves.easeInOut));
    _loadFaqs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  // ============================================================================
  // NUEVA VERSIÓN DE _loadFaqs
  // ============================================================================
  Future<void> _loadFaqs() async {
    final String response = await rootBundle.loadString('assets/faqs.json');
    final data = await json.decode(response);
    setState(() {
      _faqs = data;
      // Añadir el mensaje de bienvenida una vez que el JSON esté cargado
      addMessage("bot",
          "¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?");
      // Añadir las preguntas frecuentes iniciales
      final quickReplies = _getQuickReplyQuestions();
      if (quickReplies.isNotEmpty) {
        addMessage(
          "bot",
          "Preguntas Frecuentes",
          type: "quick_replies",
          payload: quickReplies,
        );
      }
    });
  }

  List<String> _getQuickReplyQuestions() {
    if (_faqs == null) return [];
    List<String> questions = [];
    final turismo = _faqs!['faq_turismo'] as List;
    final servicios = _faqs!['faq_servicios'] as List;
    if (turismo.isNotEmpty) questions.add(turismo[0]['question']);
    if (servicios.isNotEmpty) questions.add(servicios[0]['question']);
    if (turismo.length > 1) questions.add(turismo[1]['question']);
    return questions;
  }

  BotResponse _getBotResponse(String userMessage) {
    if (_faqs == null) return BotResponse(answer: "Cargando respuestas...");

    String message = userMessage.toLowerCase().trim();
    final allEntries = [
      ..._faqs!['greetings'],
      ..._faqs!['faq_turismo'],
      ..._faqs!['faq_servicios'],
      ..._faqs!['faq_emergencias'],
      ..._faqs!['faq_cultura_eventos'],
      ..._faqs!['faq_tramites'],
      ..._faqs!['farewells'],
      ..._faqs!['fallback'],
    ].cast<Map<String, dynamic>>(); // Aseguramos el tipo

    Map<String, dynamic>? bestMatch;
    int maxScore = 0;

    // 1. Calcular el puntaje para cada entrada del JSON
    for (var entry in allEntries) {
      int currentScore = 0;
      List<dynamic> tags = entry['tags'];

      for (var tag in tags) {
        // Usamos una expresión regular para buscar palabras completas o frases,
        // esto hace la búsqueda más precisa que un simple .contains()
        // \b -> Límite de palabra (evita que "rari" coincida en "horario")
        if (RegExp(r'\b' + RegExp.escape(tag.toLowerCase()) + r'\b')
            .hasMatch(message)) {
          currentScore++;
        }
      }

      if (currentScore > maxScore) {
        maxScore = currentScore;
        bestMatch = entry;
      }
    }

    // 2. Si encontramos una coincidencia con puntaje, la devolvemos
    if (bestMatch != null && maxScore > 0) {
      bool isGreetingOrFarewell = (_faqs!['greetings'].contains(bestMatch) ||
          _faqs!['farewells'].contains(bestMatch));
      return BotResponse(
        answer: bestMatch['answer'],
        action: bestMatch['action'],
        isStandardResponse: !isGreetingOrFarewell,
      );
    }

    // 3. Si no hay ninguna coincidencia, pasamos a la IA
    return BotResponse(
        answer: "No encontré una respuesta. Consultando a la IA...",
        action: "query_openai");
  }

  void handleSendMessage(String text) {
    setState(() => messages.removeWhere((m) => m['type'] == 'quick_replies'));
    addMessage("user", text);
    setState(() => _isTyping = true);
    _typingController.repeat();
    final botResponse = _getBotResponse(text);
    int totalTTR =
        (800 + (math.Random().nextDouble() * 2200)).toInt().clamp(800, 3000);

    Future.delayed(Duration(milliseconds: totalTTR), () {
      if (mounted) {
        setState(() => _isTyping = false);
        _typingController.stop();

        final messageId = DateTime.now().millisecondsSinceEpoch.toString();
        addMessage("bot", botResponse.answer, messageId: messageId);

        // --- INICIO DE LA LÓGICA CORREGIDA ---
        if (botResponse.action == "open_whatsapp") {
          _launchWhatsApp();
        } else if (botResponse.action == "query_openai") {
          // Si es una consulta a la IA, esperamos la respuesta simulada
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              final aiMessageId =
                  DateTime.now().millisecondsSinceEpoch.toString();
              addMessage("bot", "Respuesta simulada de la IA para: \"$text\".",
                  messageId: aiMessageId);

              // Pedimos feedback DESPUÉS de dar la respuesta de la IA
              addMessage("bot", "¿Fue útil esta infomación?",
                  type: "feedback", messageId: aiMessageId);
            }
          });
        } else {
          // Para respuestas normales del JSON, pedimos feedback inmediatamente
          if (botResponse.isStandardResponse) {
            addMessage("bot", "¿Fue útil esta infomación?",
                type: "feedback", messageId: messageId);
          }
        }
      }
    });
  }

  void addMessage(String sender, String text,
      {String? type, dynamic payload, String? messageId}) {
    setState(() {
      messages.add({
        "id": messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        "sender": sender,
        "text": text,
        "type": type ?? "text",
        "payload": payload,
        "visible": true,
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _handleFeedback(String messageId, bool wasUseful) {
    final messageContext =
        messages.firstWhere((m) => m['id'] == messageId)['text'];
    _saveFeedbackLocally({
      'messageId': messageId,
      'wasUseful': wasUseful,
      'timestamp': DateTime.now().toIso8601String(),
      'context': messageContext,
    });
    setState(() {
      final feedbackIndex = messages
          .indexWhere((m) => m['type'] == 'feedback' && m['id'] == messageId);
      if (feedbackIndex != -1) messages[feedbackIndex]['visible'] = false;
    });
    addMessage("bot", "¡Gracias por tu feedback!");
  }

  Future<void> _saveFeedbackLocally(Map<String, dynamic> newFeedback) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/feedback.json';
      final file = File(path);
      List<dynamic> feedbackList = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty)
          feedbackList = json.decode(content) as List<dynamic>;
      }
      feedbackList.add(newFeedback);
      await file.writeAsString(json.encode(feedbackList));
      print("Feedback guardado localmente en: $path");
    } catch (e) {
      print("Error al guardar feedback localmente: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo guardar tu feedback.")));
    }
  }

  void _clearChatHistory() {
    setState(() {
      messages.clear();
      _loadFaqs();
    });
  }

  void _launchWhatsApp() async {
    const phoneNumber = "+56912345678";
    const message = "Hola, necesito ayuda de un asesor.";
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir WhatsApp.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor:
                state.isDarkMode ? AppColors.darkBackground : Colors.grey[50],
            body: Column(
              children: [
                ChatbotHeader(
                    onClearHistory: _clearChatHistory,
                    onContactWhatsApp: _launchWhatsApp),
                Expanded(
                  child: ChatbotBody(
                    isDarkMode: state.isDarkMode,
                    messages: messages,
                    scrollController: _scrollController,
                    isTyping: _isTyping,
                    typingAnimation: _typingAnimation!,
                    onQuickReply: handleSendMessage,
                    onFeedback: _handleFeedback,
                  ),
                ),
                ChatbotFooter(
                    isDarkMode: state.isDarkMode,
                    onSendMessage: handleSendMessage),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// NUEVA VERSIÓN DE ChatbotHeader
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
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.5),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.5),
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
                    borderRadius: BorderRadius.circular(8.0)),
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
                        title: Text('Contactar por WhatsApp',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Poppins')),
                      ),
                    ),
                    const PopupMenuItem(
                      enabled: false,
                      height: 0,
                      child: Divider(color: Colors.white, height: 1),
                    ),
                    const PopupMenuItem(
                      value: 'Borrar Historial',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Borrar Historial',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Poppins')),
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

class ChatbotBody extends StatelessWidget {
  final bool isDarkMode;
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final bool isTyping;
  final Animation<double> typingAnimation;
  final Function(String) onQuickReply;
  final Function(String, bool) onFeedback;

  const ChatbotBody({
    super.key,
    required this.isDarkMode,
    required this.messages,
    required this.scrollController,
    required this.isTyping,
    required this.typingAnimation,
    required this.onQuickReply,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        itemCount: messages.length + (isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (isTyping && index == 0) return _buildTypingIndicator();
          final messageIndex = isTyping ? index - 1 : index;
          final reversedIndex = messages.length - 1 - messageIndex;
          final message = messages[reversedIndex];
          if (!(message['visible'] as bool? ?? true))
            return const SizedBox.shrink();
          switch (message['type']) {
            case 'quick_replies':
              return _buildQuickReplies(
                  context, message['text'], message['payload']);
            case 'feedback':
              return _buildFeedbackOptions(
                  context, message['id'], message['text']);
            default:
              return _buildTextMessage(context, message);
          }
        },
      ),
    );
  }

  Widget _buildQuickReplies(
      BuildContext context, String title, List<String> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextMessage(context, {'sender': 'bot', 'text': title}),
        Padding(
          padding: const EdgeInsets.only(
              left: 48.0, top: 8.0, right: 8.0, bottom: 8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: questions
                .map((q) => ActionChip(
                      label: Text(q,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.lightprimary)),
                      onPressed: () => onQuickReply(q),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.lightprimary),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackOptions(
      BuildContext context, String messageId, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextMessage(context, {'sender': 'bot', 'text': text}),
        Padding(
          padding: const EdgeInsets.only(left: 48.0, top: 8.0, bottom: 8.0),
          child: Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.thumb_up_alt_outlined,
                    size: 16, color: Colors.green),
                label: const Text('Sí, fue útil',
                    style:
                        TextStyle(fontFamily: 'Poppins', color: Colors.green)),
                onPressed: () => onFeedback(messageId, true),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.green),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.thumb_down_alt_outlined,
                    size: 16, color: Colors.red),
                label: const Text('No, no fue útil',
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.red)),
                onPressed: () => onFeedback(messageId, false),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextMessage(BuildContext context, Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.lightprimary,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDarkMode
                        ? AppColors.darkprimary
                        : AppColors.lightprimary)
                    : (isDarkMode ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: Radius.circular(isUser ? 16.0 : 0.0),
                  bottomRight: Radius.circular(isUser ? 0.0 : 16.0),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3)
                ],
              ),
              child: Text(
                message['text'] ?? '',
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDarkMode ? Colors.white : Colors.black87),
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
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
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
                bottomRight: Radius.circular(16.0),
              ),
            ),
            child: AnimatedBuilder(
              animation: typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    double delay = index * 0.2;
                    double animationValue =
                        (typingAnimation.value - delay).clamp(0.0, 1.0);
                    double scale = 0.5 +
                        (0.5 *
                            (1 + math.cos(animationValue * 2 * math.pi)) /
                            2);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Transform.scale(
                        scale: scale,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor:
                              isDarkMode ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NUEVA VERSIÓN DE ChatbotFooter
// ============================================================================
class ChatbotFooter extends StatefulWidget {
  final bool isDarkMode;
  final Function(String) onSendMessage;
  const ChatbotFooter(
      {super.key, required this.isDarkMode, required this.onSendMessage});

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
      height: 80,
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
