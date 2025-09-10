import 'dart:convert';
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

// Pantalla principal (Widget Stateful, sin cambios en su declaración)
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

// Estado de la pantalla (aquí se agrega la lógica del JSON)
class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  // El arreglo de mensajes ahora empieza vacío
  final List<Map<String, String>> messages = [];

  // Variables para la animación de typing
  bool _isTyping = false;
  late AnimationController _typingController;
  Animation<double>? _typingAnimation;

  // Variable para guardar los datos del JSON
  Map<String, dynamic>? _faqs;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador de animación
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..addListener(() {
        // Solo actualizar si está typing
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

    // Cargar el JSON al iniciar la pantalla
    _loadFaqs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  // Función para cargar y decodificar el archivo faqs.json
  Future<void> _loadFaqs() async {
    final String response = await rootBundle.loadString('assets/faqs.json');
    final data = await json.decode(response);
    setState(() {
      _faqs = data;
      // Añadir el mensaje de bienvenida una vez que el JSON esté cargado
      addMessage("bot",
          "¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?");
    });
  }

  // Función que busca una respuesta en el JSON cargado
  BotResponse _getBotResponse(String userMessage) {
    if (_faqs == null) {
      return BotResponse(answer: "Cargando respuestas...");
    }

    String message = userMessage.toLowerCase().trim();
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

    // Si no encuentra respuesta, simula el paso a la IA
    return BotResponse(
      answer: "No encontré una respuesta. Consultando a la IA...",
      action: "query_openai",
    );
  }

  // Función para manejar el envío de mensajes del usuario
  void handleSendMessage(String text) {
    // 1. Agrega el mensaje del usuario a la lista
    addMessage("user", text);

    // 2. Activar la animación de typing
    setState(() {
      _isTyping = true;
    });
    _typingController.repeat();

    // 3. Obtiene la respuesta del bot desde el JSON
    final botResponse = _getBotResponse(text);

    // 4. Calcular TTR realista con máximo de 3 segundos
    final random = math.Random();
    int baseTime = 300; // Tiempo base mínimo

    // Agregar tiempo basado en complejidad
    int complexityTime = (text.length * 10).clamp(0, 1000);
    int responseComplexity = (botResponse.answer.length * 3).clamp(0, 300);
    int randomVariation = random.nextInt(300);

    // TTR total con máximo de 3 segundos
    int totalTTR =
        (baseTime + complexityTime + responseComplexity + randomVariation)
            .clamp(800, 3000);

    // 5. Simula el retraso de respuesta
    Future.delayed(Duration(milliseconds: totalTTR), () {
      if (mounted) {
        // Detener la animación de typing
        setState(() {
          _isTyping = false;
        });
        _typingController.stop();

        // Agregar la respuesta del bot
        addMessage("bot", botResponse.answer);

        // Ejecutar acciones si existen
        if (botResponse.action == "open_whatsapp") {
          _launchWhatsApp();
        } else if (botResponse.action == "query_openai") {
          // Simulación de respuesta de IA
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              addMessage("bot", "Respuesta simulada de la IA para: \"$text\".");
            }
          });
        }
      }
    });
  }

  // Función para agregar mensajes a la lista y actualizar la UI
  void addMessage(String sender, String text) {
    setState(() {
      messages.add({"sender": sender, "text": text});
    });
    // Auto-scroll al último mensaje con animación suave (scroll invertido)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Ir al inicio (que es el final por reverse: true)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Función para borrar el historial de chat
  void _clearChatHistory() {
    setState(() {
      messages.clear();
      addMessage("bot", "Historial borrado. ¿Necesitas algo más?");
    });
  }

  // Función para abrir WhatsApp
  void _launchWhatsApp() async {
    const phoneNumber = "+56912345678"; // Reemplazar con número real
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
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor:
              state.isDarkMode ? AppColors.darkBackground : Colors.grey[50],
          body: Column(
            children: [
              // Header (con callbacks para las funciones)
              ChatbotHeader(
                onClearHistory: _clearChatHistory,
                onContactWhatsApp: _launchWhatsApp,
              ),

              // Body - conversación (ahora con el ScrollController y animación)
              Expanded(
                child: _typingAnimation != null
                    ? ChatbotBody(
                        isDarkMode: state.isDarkMode,
                        messages: messages,
                        scrollController: _scrollController,
                        isTyping: _isTyping,
                        typingAnimation: _typingAnimation!,
                      )
                    : Container(),
              ),

              // Footer - input del usuario
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
// COMPONENTE HEADER
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
          elevation: 0, //sin sombra el apartado
          backgroundColor:
              state.isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
          iconTheme: const IconThemeData(color: AppColors.lightbackground),
          title: const Text(
            'Asistente Colbún',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28, // 28-32 puntos para títulos
              fontWeight: FontWeight.w600, //peso 600
              color: Color(0xFFFFFFFF),
            ),
          ),
          actions: [
            //=============================================================================
            // Switch modo oscuro/claro
            //=============================================================================
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
                    activeTrackColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),

            //=============================================================================
            // Botón de tres puntos tipo popup
            //=============================================================================
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
                elevation: 8, //sombra del popup
                offset: const Offset(0, 15),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),

                onSelected: (value) {
                  // Manejar las opciones usando los callbacks
                  if (value == 'Whatsapp') {
                    onContactWhatsApp();
                  } else if (value == 'Borrar Historial') {
                    onClearHistory();
                  }
                },
                itemBuilder: (BuildContext context) {
                  // Cierra el teclado antes de mostrar el menú
                  FocusScope.of(context).unfocus();

                  //=============================================================================
                  // Opciones del menú
                  //=============================================================================
                  return [
                    const PopupMenuItem(
                      value: 'Whatsapp',
                      child: ListTile(
                        leading: const Icon(Icons.chat, color: Colors.green),
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
                    //=============================================================================
                    //Esta opcion solo es para poner la linea blanca divisora entre las opciones
                    //=============================================================================
                    const PopupMenuItem(
                      enabled: false, // No se pueda seleccionar
                      height: 0, // Eliminar padding superior/inferior
                      child: Divider(
                        color: Colors.white, // Línea blanca
                        height: 1,
                      ),
                    ),

                    const PopupMenuItem(
                      value: 'Borrar Historial',
                      child: ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
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
// COMPONENTE BODY
// ============================================================================
class ChatbotBody extends StatelessWidget {
  final bool isDarkMode;
  final List<Map<String, String>> messages;
  final ScrollController scrollController;
  final bool isTyping;
  final Animation<double> typingAnimation;

  const ChatbotBody({
    super.key,
    required this.isDarkMode,
    required this.messages,
    required this.scrollController,
    required this.isTyping,
    required this.typingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        controller: scrollController,
        reverse:
            true, // ¡CLAVE! Scroll invertido para que último mensaje esté abajo
        itemCount: messages.length + (isTyping ? 1 : 0), // +1 si está typing
        itemBuilder: (context, index) {
          // Si está typing y es el primer item (último mensaje)
          if (isTyping && index == 0) {
            return _buildTypingIndicator();
          }

          // Ajustar el índice por el reverse y el typing indicator
          final messageIndex = isTyping ? index - 1 : index;
          final reversedIndex = messages.length - 1 - messageIndex;
          final message = messages[reversedIndex];
          final isUser = message['sender'] == 'user';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              // Alineación para toda la fila
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              // Estira los elementos para que el avatar y la burbuja estén alineados por abajo
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar del bot (izquierda)
                if (!isUser) ...[
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        AppColors.lightprimary, // Color fijo para el bot
                    child: Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Burbuja del mensaje
                Flexible(
                  // Flexible asegura que la burbuja no exceda el ancho disponible
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width *
                          0.7, // Limita el ancho al 70%
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
                          : (isDarkMode ? Colors.grey[800] : Colors.white),
                      borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16.0),
                          topRight: const Radius.circular(16.0),
                          bottomLeft: Radius.circular(isUser ? 16.0 : 0.0),
                          bottomRight: Radius.circular(isUser ? 0.0 : 16.0)),
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
                            : (isDarkMode ? Colors.white : Colors.black87),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                // Avatar del usuario (derecha)
                if (isUser) ...[
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey, // Color fijo para el usuario
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget para el indicador de typing
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
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
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
// COMPONENTE FOOTER (Lógica de simulación de respuesta fue removida)
// ============================================================================
class ChatbotFooter extends StatefulWidget {
  final bool isDarkMode;
  // El callback ahora solo notifica el texto del mensaje
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
      FocusScope.of(context).unfocus(); // Cierra el teclado después de enviar
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
