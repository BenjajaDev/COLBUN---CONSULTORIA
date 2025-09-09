import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme_bloc.dart';

// Estructura de colores (sin cambios)
class AppColors {
  static const Color lightprimary = Color(0xFF4D67AE);
  static const Color lightbackground = Colors.white;
  static const Color lightTextFieldBorder = Color(0xFFE0E0E0);
  static const Color darkprimary = Color(0xFF494C6B);
  static const Color darkBackground = Color(0xFF252525);
}

// Pantalla principal (Widget Stateful, sin cambios en su declaración)
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

// Estado de la pantalla (aquí se agrega la lógica del JSON)
class _ChatbotScreenState extends State<ChatbotScreen> {
  // El arreglo de mensajes ahora empieza vacío
  final List<Map<String, String>> messages = [];

  // ============================================================================
  // === INICIO: CÓDIGO NUEVO PARA MANEJAR LÓGICA DEL CHATBOT ===
  // ============================================================================

  // Variable para guardar los datos del JSON
  Map<String, dynamic>? _faqs;

  @override
  void initState() {
    super.initState();
    // Cargar el JSON al iniciar la pantalla
    _loadFaqs();
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
  String _getBotResponse(String userMessage) {
    if (_faqs == null) {
      return "Cargando respuestas...";
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
        return entry['answer'];
      }
    }

    // Si no encuentra respuesta, simula el paso a la IA
    return "No encontré una respuesta. Consultando a la IA...";
  }

  // Función para agregar mensajes (modificada para manejar la lógica de respuesta)
  void handleSendMessage(String text) {
    // 1. Agrega el mensaje del usuario a la lista
    addMessage("user", text);

    // 2. Obtiene la respuesta del bot desde el JSON
    final botText = _getBotResponse(text);

    // 3. Simula un retraso y agrega la respuesta del bot
    Future.delayed(const Duration(milliseconds: 500), () {
      addMessage("bot", botText);
    });
  }

  // Función base para agregar mensajes a la lista y actualizar la UI
  void addMessage(String sender, String text) {
    setState(() {
      messages.add({"sender": sender, "text": text});
    });
  }

  // ============================================================================
  // === FIN: CÓDIGO NUEVO PARA MANEJAR LÓGICA DEL CHATBOT ===
  // ============================================================================

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

              const ChatbotHeader(),

              // Body - conversación
              Expanded(
                child: ChatbotBody(
                  isDarkMode: state.isDarkMode,
                  messages: messages,
                ),
              ),

              // Footer - input del usuario
              ChatbotFooter(
                isDarkMode: state.isDarkMode,
                // Se pasa la nueva función que contiene la lógica
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
class ChatbotHeader extends StatelessWidget {
  const ChatbotHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return AppBar(
          elevation: 0, //sin sombra el apartado
          backgroundColor: state.isDarkMode
              ? AppColors.darkprimary
              : AppColors.lightprimary,
          iconTheme: const IconThemeData(color: AppColors.lightbackground),
          title: const Text(
            'CHATBOT HEADER',
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
            Container(
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
                  // Aquí puedes manejar las opciones
                  if (value == 'Whatsapp') {
                    print('Contactar por WhatsApp');
                  } else if (value == 'Borrar Historial') {
                    print('Borrar Historial');
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
                        leading: Icon(Icons.chat, color: Colors.green),
                        title: Text(
                          'Contactar por WhatsApp',
                          style: TextStyle(color: Colors.white,
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
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Borrar Historial de conversación',
                          style: TextStyle(color: Colors.white,
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
}

// ============================================================================
// COMPONENTE BODY
// ============================================================================
class ChatbotBody extends StatelessWidget {
  final bool isDarkMode;
  final List<Map<String, String>> messages;
  const ChatbotBody(
      {super.key, required this.isDarkMode, required this.messages});

  @override
  Widget build(BuildContext context) {
    // Tu código del Body se mantiene exactamente igual...
    return Container(
      width: double.infinity,
      color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isUser = message['sender'] == 'user';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isDarkMode
                        ? AppColors.darkprimary
                        : AppColors.lightprimary,
                    child: const Icon(Icons.smart_toy,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (isDarkMode
                              ? AppColors.darkprimary
                              : AppColors.lightprimary)
                          : (isDarkMode ? Colors.grey[800] : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16.0),
                        topRight: const Radius.circular(16.0),
                        bottomLeft: Radius.circular(isUser ? 16.0 : 4.0),
                        bottomRight: Radius.circular(isUser ? 4.0 : 16.0),
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
                if (isUser) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade400,
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 18),
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
      // Llama a la función del widget padre para que él maneje la lógica
      widget.onSendMessage(messageText);
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tu código de la UI del Footer se mantiene exactamente igual...
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
