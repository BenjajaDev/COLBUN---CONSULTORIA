import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/theme_bloc.dart'; // Asegúrate que la ruta a tu BLoC sea correcta

// ============================================================================
// SCREEN - Pantalla principal del Chatbot
// ============================================================================

class AppColors {
  static const Color lightprimary = Color(0xFF4D67AE);
  static const Color lightbackground = Colors.white;
  static const Color lightTextFieldBorder = Color(0xFFE0E0E0);
  static const Color darkprimary = Color(0xFF494C6B);
  static const Color darkBackground = Color(0xFF252525);
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class BotResponse {
  final String answer;
  final String? action; // El action es opcional

  BotResponse({required this.answer, this.action});
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // El arreglo de mensajes ahora empieza vacío
  final List<Map<String, String>> messages = [];

  // Variable para guardar los datos del JSON
  Map<String, dynamic>? _faqs;
  final ScrollController _scrollController =
      ScrollController(); // Agregado ScrollController

  @override
  void initState() {
    super.initState();
    // Cargar el JSON al iniciar la pantalla
    _loadFaqs();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Es importante liberar el controlador
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
    // <--- CAMBIO AQUÍ: Ahora retorna BotResponse
    if (_faqs == null) {
      return BotResponse(
          answer: "Cargando respuestas..."); // Retorna BotResponse
    }

    String message = userMessage.toLowerCase().trim();
    final allEntries = [
      ..._faqs!['greetings'],
      ..._faqs!['faq_turismo'],
      ..._faqs!['faq_servicios'],
      ..._faqs!['fallback'],
      ..._faqs!['farewells'],
    ];

    for (var entry in allEntries) {
      List<dynamic> tags = entry['tags'];
      if (tags.any((tag) => message.contains(tag.toLowerCase()))) {
        // <--- CAMBIO AQUÍ: Retorna BotResponse con la respuesta y la acción (si existe)
        return BotResponse(
          answer: entry['answer'],
          action:
              entry['action'], // El action puede ser null si no está en el JSON
        );
      }
    }

    // Si no encuentra respuesta, simula el paso a la IA
    return BotResponse(
        answer: "No encontré una respuesta. Consultando a la IA...",
        action:
            "query_openai"); // Acción para indicar que se debe consultar a la IA
  }

  // Función para agregar mensajes a la lista y actualizar la UI
  void addMessage(String sender, String text) {
    setState(() {
      messages.add({"sender": sender, "text": text});
    });
    // Agregamos un pequeño retraso para asegurar que el mensaje se añada antes de scrollear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Función para manejar el envío de mensajes del usuario
  void handleSendMessage(String text) {
    // 1. Agrega el mensaje del usuario a la lista
    addMessage("user", text);

    // 2. Obtiene la respuesta del bot desde el JSON
    final botResponse = _getBotResponse(text);

    // 3. Simula un retraso y agrega la respuesta del bot
    Future.delayed(const Duration(milliseconds: 500), () {
      addMessage("bot", botResponse.answer); // <--- Usa botResponse.answer

      // 4. Si hay una acción, la ejecuta
      if (botResponse.action == "open_whatsapp") {
        // <--- Verifica la acción
        _launchWhatsApp();
      }
      // Puedes agregar más acciones aquí, por ejemplo para la IA
      else if (botResponse.action == "query_openai") {
        // Simulación de respuesta de IA
        Future.delayed(const Duration(seconds: 2), () {
          addMessage("bot", "Respuesta simulada de la IA para: \"$text\".");
        });
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
              // Header (sin cambios, excepto que le pasamos las funciones de callback)
              ChatbotHeader(
                onClearHistory: _clearChatHistory,
                onContactWhatsApp: _launchWhatsApp,
              ),

              // Body - conversación (ahora con el ScrollController)
              Expanded(
                child: ChatbotBody(
                  isDarkMode: state.isDarkMode,
                  messages: messages,
                  scrollController:
                      _scrollController, // Pasa el controlador aquí
                ),
              ),

              // Footer - input del usuario (se pasa la función de handleSendMessage)
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
// COMPONENTE HEADER - Título y configuraciones del chatbot
// (Se modificó para recibir callbacks)
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
    return BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
      return AppBar(
        elevation: 0,
        backgroundColor:
            state.isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
        iconTheme: const IconThemeData(color: AppColors.lightbackground),
        title: const Text(
          'Asistente Colbún',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
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
                const SizedBox(
                  width: 4,
                ),
                Switch(
                  value: state.isDarkMode,
                  onChanged: (value) {
                    context.read<ThemeBloc>().add(ToggleThemeEvent());
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white.withOpacity(0.5),
                )
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFFFFFFF)),
            color: state.isDarkMode
                ? AppColors.darkprimary
                : AppColors.lightprimary,
            iconSize: 34,
            onSelected: (value) {
              if (value == 'Whatsapp') {
                onContactWhatsApp(); // Llama al callback
              } else if (value == 'Borrar Historial') {
                onClearHistory(); // Llama al callback
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'Whatsapp',
                  child: ListTile(
                    leading: Icon(Icons.chat, color: Colors.green),
                    title: Text('Contactar por WhatsApp',
                        style: TextStyle(color: Colors.white)),
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
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ];
            },
          ),
        ],
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ============================================================================
// COMPONENTE BODY - Área de conversación entre usuario y chatbot
// (Aquí se realizan las correcciones de diseño)
// ============================================================================
class ChatbotBody extends StatelessWidget {
  final bool isDarkMode;
  final List<Map<String, String>> messages;
  final ScrollController scrollController; // Recibe el controlador

  const ChatbotBody({
    super.key,
    required this.isDarkMode,
    required this.messages,
    required this.scrollController, // Asegúrate de requerirlo
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        controller: scrollController, // Asigna el controlador aquí
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isUser = message['sender'] == 'user';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              // Alineación para toda la fila
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              // Estira los elementos para que el avatar y la burbuja estén alineados por abajo
              crossAxisAlignment: CrossAxisAlignment
                  .start, // CAMBIO CLAVE AQUÍ: Dejar que el texto se alinee arriba y la burbuja se ajuste
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
                          topLeft: const Radius.circular(12.0),
                          topRight: const Radius.circular(12.0),
                          bottomLeft: Radius.circular(isUser ? 12.0 : 0.0),
                          bottomRight: Radius.circular(isUser ? 0.0 : 12.0)),
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
}

// ============================================================================
// COMPONENTE FOOTER - Input del usuario y botón de envío
// (Sin cambios significativos en la UI, solo en la función de envío)
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
      height: 70,
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
                  borderRadius: BorderRadius.circular(12.0),
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
                          : const Color(0xFF828282)),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Container(
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
