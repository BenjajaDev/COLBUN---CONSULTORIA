import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme_bloc.dart';

class AppColors{
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

class _ChatbotScreenState extends State<ChatbotScreen> {
  //Arreglo de mensajes para prueba
  final List<Map<String, String>> messages = [
    {"sender": "user", "text": "Hola, ¿cómo estás?"},
    {"sender": "bot", "text": "¡Hola! Estoy aquí para ayudarte."},
    {"sender": "user", "text": "¿Cuál es tu nombre?"},
    {"sender": "bot", "text": "Soy un chatbot creado por OpenAI."},
  ];

  // Función para agregar mensajes
  void addMessage(String sender, String text) {
    setState(() {
      messages.add({
        "sender": sender,
        "text": text,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            // Esto quita el foco del teclado cuando se toca fuera del campo de texto
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: state.isDarkMode
                ? AppColors.darkBackground
                : Colors.grey[50],
            body: Column(
              children: [
                // Header del chatbot
                ChatbotHeader(),

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
                  onSendMessage: addMessage,
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

// ============================================================================
// COMPONENTE HEADER - Título y configuraciones del chatbot
// ============================================================================

class ChatbotHeader extends StatelessWidget {
  const ChatbotHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return AppBar(
          elevation: 0,//sin sombra el apartado
          backgroundColor: state.isDarkMode
            ? AppColors.darkprimary
            : AppColors.lightprimary,
          iconTheme: IconThemeData(color: AppColors.lightbackground),
          title: Text(
            'CHATBOT HEADER',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
                  const SizedBox(width: 4,),
                  Switch(
                    value: state.isDarkMode, 
                    onChanged: (value){
                      context.read<ThemeBloc>().add(ToggleThemeEvent());
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white.withValues(alpha: 0.5),
                  )
                ],
              ),
            ),

            //=============================================================================
            // Botón de tres puntos tipo popup
            //=============================================================================
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFFFFFFFF)),
              color: state.isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
              iconSize: 34,
              position: PopupMenuPosition.under,
              elevation: 8, //sombra del popup
              offset: Offset(0, 13),
              
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
                  PopupMenuItem(
                    value: 'Whatsapp',
                    child: ListTile(
                      leading: Icon(Icons.chat, color: Colors.green),
                      title: Text(
                        'Contactar por WhatsApp',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    
                  ),
                  //=============================================================================
                  //Esta opcion solo es para poner la linea blanca divisora entre las opciones
                  //=============================================================================
                  PopupMenuItem(
                    enabled: false, // No se pueda seleccionar
                    height: 0, // Eliminar padding superior/inferior
                    child: Divider(
                      color: Colors.white, // Línea blanca
                      height: 1,
                    ),
                  ),
                  
                  PopupMenuItem(
                    value: 'Borrar Historial',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Borrar Historial de conversación',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        );
      }
    );  
  }
}


// ============================================================================
// COMPONENTE BODY - Área de conversación entre usuario y chatbot
// ============================================================================

class ChatbotBody extends StatelessWidget {
  final bool isDarkMode;
  final List<Map<String, String>> messages;
  const ChatbotBody({super.key, required this.isDarkMode, required this.messages});

  @override
  Widget build(BuildContext context) {
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
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar del bot (izquierda)
                if (!isUser) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Burbuja del mensaje
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
                          ? (isDarkMode ? AppColors.darkprimary : AppColors.lightprimary)
                          : (isDarkMode ? Colors.grey[800] : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade400,
                    child: const Icon(
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
// ============================================================================


class ChatbotFooter extends StatefulWidget {
  final bool isDarkMode;
  final Function(String, String) onSendMessage;
  const ChatbotFooter({super.key, required this.isDarkMode, required this.onSendMessage});

  @override
  State<ChatbotFooter> createState() => _ChatbotFooterState();
}

class _ChatbotFooterState extends State<ChatbotFooter> {
  final TextEditingController _textController = TextEditingController();

  // Función para enviar mensaje
  void _sendMessage() {
    final messageText = _textController.text.trim();
    if (messageText.isNotEmpty) {
      // Agregar mensaje del usuario usando el callback
      widget.onSendMessage("user", messageText);
      
      // Simular respuesta del bot (puedes personalizar esto)
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onSendMessage("bot", "Gracias por tu mensaje: \"$messageText\". ¿En qué más puedo ayudarte?");
      });
      
      // Limpiar el campo de texto
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
    return Container(
      height: 70,
      color: widget.isDarkMode ? AppColors.darkBackground : AppColors.lightbackground,
      padding: const EdgeInsets.all(16.0),

      child: Row(
        children: [
          // aqui esta el box que contiene el campo de texto
          Expanded(
            child: Container(
              //===============================================================
              //decoracion del contenedor que contiene al campo de textfield
              //===============================================================
              decoration: BoxDecoration(
                color: widget.isDarkMode ? AppColors.darkBackground : AppColors.lightbackground, //Color relleno textField
                borderRadius: BorderRadius.circular(12.0),
                // color de bordes E0E0E0 mockup de field del texto
                border: Border.all(color: widget.isDarkMode ? Colors.grey[600]! : AppColors.lightTextFieldBorder)
              ),

              //agregue padding para que el texto no este pegado al borde acordarse las medidas solo multiplo de 8
              padding: const EdgeInsets.symmetric(horizontal: 16.0),

              //===============================================================
              //este es el campo de texto TextField
              //===============================================================
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black
                ),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: widget.isDarkMode ? Colors.grey[400] : Color(0xFF828282)),// color de texto escribe un mensaje 828282 mockup
                ),
                onSubmitted: (_) => _sendMessage(), // Enviar con Enter
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          //boton de enviar el mensaje
          Container(
            decoration: BoxDecoration(
              color: widget.isDarkMode ? AppColors.darkBackground : AppColors.lightbackground,
            ),

            //===============================================================
            //boton de enviar tipo  ICONBUTTON
            //===============================================================
            child: IconButton(
              icon: Icon(Icons.send, color: widget.isDarkMode ? Colors.white :Color(0XFF1d1b20)),// color del icono de enviar 1d1b20 mockup
              iconSize: 24,
              onPressed: _sendMessage, // Llamar a la función de enviar mensaje
            ),
          ),
        ],
      ),
    );
  }
}
