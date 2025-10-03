import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// =============================================================================
// COMPONENTE CHATBOT FOOTER
// =============================================================================

/// Componente que representa el pie de página del chat, conteniendo el campo
/// de entrada de texto y el botón para enviar mensajes.
class ChatbotFooter extends StatefulWidget {
  // ============================ PROPIEDADES ==================================
  
  final bool isDarkMode;
  final Function(String) onSendMessage;

  /// Constructor del componente ChatbotFooter
  const ChatbotFooter({
    super.key,
    required this.isDarkMode,
    required this.onSendMessage,
  });

  @override
  State<ChatbotFooter> createState() => _ChatbotFooterState();
}

// =============================================================================
// ESTADO DEL COMPONENTE CHATBOT FOOTER
// =============================================================================

/// Estado que gestiona la lógica y los datos del componente ChatbotFooter
class _ChatbotFooterState extends State<ChatbotFooter> {
  // ============================ CONTROLADORES ================================
  
  /// Controlador para el campo de texto de entrada de mensajes
  final TextEditingController _textController = TextEditingController();

  // ============================ MÉTODOS DE GESTIÓN ===========================

  /// Envía el mensaje escrito por el usuario y limpia el campo de texto
  void _sendMessage() {
    final messageText = _textController.text.trim();
    
    // Solo envía el mensaje si no está vacío
    if (messageText.isNotEmpty) {
      widget.onSendMessage(messageText);
      _textController.clear();
      FocusScope.of(context).unfocus(); // Cierra el teclado
    }
  }

  // ============================ MÉTODOS DE CICLO DE VIDA =====================

  /// Se ejecuta cuando el widget es eliminado, liberando recursos
  @override
  void dispose() {
    _textController.dispose(); // Libera el controlador de texto
    super.dispose();
  }

  // ============================ CONSTRUCCIÓN DE LA UI ========================

  /// Construye la interfaz de usuario del pie de página del chat
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightbackground,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Campo de texto expandido para escribir mensajes
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 44,  // Altura mínima para el campo de texto
                maxHeight: 120, // Altura máxima para el campo de texto
              ),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? AppColors.darkBackground
                    : AppColors.lightbackground,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: widget.isDarkMode
                      ? Colors.grey[600]!
                      : AppColors.lightTextFieldBorder,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
                maxLines: null, // Permite múltiples líneas,
                minLines: 1,
                keyboardType: TextInputType.multiline, // Teclado para múltiples líneas
                textInputAction: TextInputAction.newline, // Acción de nueva línea
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  isDense: true, //Compacta el campo de texto
                  hintStyle: TextStyle(
                    color: widget.isDarkMode
                        ? Colors.grey[400]
                        : const Color(0xFF828282),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,

                    fontSize: 16,
                  ),
                ),
                // Envía el mensaje al presionar Enter/Submit en el teclado
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          // Espaciado entre el campo de texto y el botón de enviar
          const SizedBox(width: 12.0),
          
          // Contenedor del botón de enviar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? AppColors.darkBackground
                  : AppColors.lightbackground
                  
            ),
            // Botón de enviar mensaje
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: widget.isDarkMode
                    ? Colors.white
                    : const Color(0XFF1d1b20),
              ),
              iconSize: 32,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}