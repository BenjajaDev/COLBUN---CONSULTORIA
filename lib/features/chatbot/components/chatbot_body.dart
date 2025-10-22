// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/faq_bloc.dart';
import '../bloc/theme_bloc.dart';
import '../utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ===========================================================================
// COMPONENTE CHATBOT BODY
// ===========================================================================
/// Componente principal que muestra el cuerpo del chat
/// Renderiza la lista de mensajes, indicador de escritura y opciones de FAQ
/// Soporta diferentes tipos de mensajes (texto, emergencia, FAQ)
class ChatbotBody extends StatelessWidget {
  // ===========================================================================
  // PROPIEDADES
  // ===========================================================================
  final bool isDarkMode;                                   // Estado del tema (claro/oscuro)
  final List<Map<String, dynamic>> messages;               // Lista de mensajes del chat
  final ScrollController scrollController;                 // Controlador de scroll
  final bool isTyping;                                     // Indica si el bot esta escribiendo
  final Animation<double> typingAnimation;                 // Animacion del indicador de escritura
  final Function(String, bool) onFeedback;                // Callback para feedback de mensajes
  final Function(String) onSendMessage;                   // Callback para enviar mensaje
  final VoidCallback onShowFrequentlyAskedQuestions;      // Callback para mostrar FAQs
  final Function(String) onFaqSelected;                   // Callback cuando se selecciona una FAQ
  final List<Map<String, dynamic>> emergencyContacts;     // Lista de contactos de emergencia
  final Function(String) onEmergencyCall;                 // Callback para llamada de emergencia
  final VoidCallback onCloseEmergency;                    // Callback para cerrar emergencia

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================
  const ChatbotBody({
    super.key,
    required this.isDarkMode,
    required this.messages,
    required this.scrollController,
    required this.isTyping,
    required this.typingAnimation,
    required this.onFeedback,
    required this.onSendMessage,
    required this.onShowFrequentlyAskedQuestions,
    required this.onFaqSelected,
    required this.emergencyContacts,
    required this.onEmergencyCall,
    required this.onCloseEmergency,
  });

  // ===========================================================================
  // METODOS AUXILIARES
  // ===========================================================================
  /// Abre una URL en el navegador externo
  /// Muestra un mensaje de error si no se puede abrir el enlace
  void _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo abrir el enlace: $url")),
        );
      }
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final fontMultiplier = themeState.fontSizeMultiplier;
        
        return Container(
          width: double.infinity,
          color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          // ListView invertido para mostrar mensajes mas recientes abajo
          child: ListView.builder(
            controller: scrollController,
            reverse: true, // Invertir lista para scroll natural de chat
            itemCount: messages.length + (isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              // Mostrar indicador de escritura como primer elemento
              if (isTyping && index == 0) {
                return _buildTypingIndicator().animate().fadeIn(duration: 300.ms);
              }

              // Calcular indices correctos por la lista invertida
              final messageIndex = isTyping ? index - 1 : index;
              final reversedIndex = messages.length - 1 - messageIndex;
              final message = messages[reversedIndex];

              // Ocultar mensajes marcados como no visibles
              if (!(message['visible'] as bool? ?? true)) {
                return const SizedBox.shrink();
              }
              
              Widget messageWidget;

              // Determinar tipo de mensaje y construir widget correspondiente
              switch (message['type']) {
            case 'faq_options':
              // Mensaje con opciones de preguntas frecuentes
              final options =
              (message['options'] as List?)?.cast<String>() ?? const <String>[];
          if (options.isEmpty) {
            messageWidget = const SizedBox.shrink();
          } else {
            messageWidget = _buildFaqOptions(context, options);
          }
            break;
          default: // Mensajes de texto normales (texto, feedback, etc)
            messageWidget = _buildTextMessage(context, message, fontMultiplier);
            break;
        }

              // Aplicar animacion de entrada al mensaje mas reciente
              if (index == 0) {
                // Es el mensaje mas reciente, animarlo
                return messageWidget
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.5, end: 0.0, curve: Curves.easeOutCubic);
              } else {
                // Es un mensaje antiguo, mostrarlo sin animacion
                return messageWidget;
              }
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // CONSTRUCCION DE OPCIONES FAQ
  // ===========================================================================
  /// Construye la lista de botones con opciones de preguntas frecuentes
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
                onFaqSelected(option); // Enviar pregunta seleccionada
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(
                        color: isDarkMode
                            ? AppColors.lightbackgroundBody
                            : AppColors.darkBackground)),
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // CONSTRUCCION DE MENSAJE DE TEXTO
  // ===========================================================================
  /// Construye una burbuja de mensaje de texto con avatar, link y feedback
  /// Maneja mensajes del usuario y del bot con estilos diferentes
  Widget _buildTextMessage(BuildContext context, Map<String, dynamic> message, double fontMultiplier) {
    final isUser = message['sender'] == 'user';
    final hasLink = message['link'] != null && message['link'].isNotEmpty;

    // Obtener el idioma del mensaje para textos dinamicos
    final messageLanguage = message['language'] ?? 'es';
    final sourceText = messageLanguage == 'en' ? 'Source' : messageLanguage == 'pt' ?
    'Fonte' : 'Fuente';

    // Logica para el feedback
    final bool shouldShowFeedback =
        message['extras']?['showFeedback'] as bool? ?? false;
    final String? messageId = message['id'];

    // Textos dinamicos para feedback segun idioma
    final yesText = messageLanguage == 'en' ? 'Yes, helpful' : messageLanguage == 'pt' ? 'Sim, útil' : 'Sí, fue útil';
    final noText = messageLanguage == 'en' ? 'No, Not helpful' : messageLanguage == 'pt' ? 'Não, não foi útil' : 'No, no fue útil';
    final thankYouText = messageLanguage == 'en' ? 'Thank you for your feedback!' : messageLanguage == 'pt' ? 'Obrigado pelo seu feedback!' : '¡Gracias por tu feedback!';

    // Columna principal que permite apilar la burbuja del mensaje y los botones de feedback
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Contenedor de la burbuja del mensaje
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar del bot (solo para mensajes del bot)
              if (!isUser) ...[
                Semantics(
                  label: 'Avatar del asistente Colbun',
                  image: true,
                  excludeSemantics: true,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: isDarkMode
                        ? AppColors.darkprimary
                        : AppColors.lightprimary,
                    backgroundImage: const AssetImage('assets/images/Avatar.png'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Contenedor principal del mensaje con texto, links y botones
              if (message['text'] != null && message['text'].isNotEmpty)
                Flexible(
                  child: Semantics(
                    label: isUser
                        ? 'Tu dijiste: ${message['text']}'
                        : 'Asistente Colbun respondio: ${message['text']}',
                    readOnly: true,
                    container: true,
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
                            : (isDarkMode ? Colors.grey[800] : Colors.white),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16.0),
                          topRight: const Radius.circular(16.0),
                          bottomLeft: Radius.circular(isUser ? 16.0 : 0.0),
                          bottomRight: Radius.circular(isUser ? 0.0 : 16.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(50),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      // Columna interna para apilar texto, links y botones
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Texto del mensaje
                          Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : (isDarkMode
                                      ? Colors.white
                                      : Colors.black87),
                              fontSize: 16 * fontMultiplier,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          // Link de fuente (si existe)
                          if (hasLink) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                _launchUrl(message['link'], context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  // Fondo igual al de la burbuja
                                  color: isUser
                                      ? (isDarkMode
                                          ? AppColors.darkprimary
                                          : AppColors.lightprimary)
                                      : (isDarkMode ? Colors.grey[800] : Colors.white),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? const Color(0xFF5AA1E8) // azul personalizado modo oscuro
                                        : Colors.blue[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.link,
                                      size: 16,
                                      color: isDarkMode
                                          ? const Color(0xFF5AA1E8)
                                          : Colors.blue[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        sourceText, // **TEXTO DINÁMICO SEGÚN IDIOMA**
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? const Color(0xFF5AA1E8)
                                              : const Color(0xFF1976D2),
                                          fontSize: 16 * fontMultiplier,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // 3. LÓGICA DEL MENSAJE DE BIENVENIDA (CON TEXTO DINÁMICO)
                          if (message['type'] == 'welcome_message')
                            Column(
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  height: 1,
                                  color: isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                                ),
                                const SizedBox(height: 8),
                                BlocBuilder<FaqBloc, FaqState>(
                                    builder: (context, faqState) {
                                      // **Texto dinámico para FAQs según idioma**
                                      final faqText = messageLanguage == 'en' 
                                          ? "Frequently asked questions" 
                                          : messageLanguage == 'pt' ? "Perguntas frequentes" 
                                          : "Preguntas frecuentes";
                                  return TextButton(
                                      onPressed: () =>
                                          onShowFrequentlyAskedQuestions(),
                                      child: Text(
                                        faqText,// **TEXTO DINÁMICO**
                                        style: TextStyle(
                                          color: const Color(0xff4861DB),
                                          fontFamily: 'Poppins',
                                          fontSize: 16 * fontMultiplier,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ));
                                })
                              ],
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Avatar del usuario (solo para mensajes del usuario)
              if (isUser) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: 'Tu avatar',
                  image: true,
                  excludeSemantics: true,
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Botones de feedback (solo para mensajes del bot que lo requieren)
        if (shouldShowFeedback && messageId != null)
          // Opcion 1: Muestra los botones si se debe pedir feedback
          Padding(
            padding: const EdgeInsets.only(left:48.0, top: 4.0, bottom: 8.0),
            child: Row(
              children: [
                // Boton de feedback positivo
                Semantics(
                  label: 'Respuesta util',
                  hint: 'Toca dos veces para indicar que la respuesta fue util',
                  button: true,
                  child: ActionChip(
                    avatar: const Icon(Icons.thumb_up_alt_outlined,
                        size: 16, color: Colors.green),
                    label: Text(yesText, // Texto dinamico segun idioma
                        style: const TextStyle(
                            color: Colors.green,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600)),
                    onPressed: () => onFeedback(messageId, true),
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                // Boton de feedback negativo
                Semantics(
                  label: 'Respuesta no util',
                  hint: 'Toca dos veces para indicar que la respuesta no fue util',
                  button: true,
                  child: ActionChip(
                    avatar: const Icon(Icons.thumb_down_alt_outlined,
                        size: 16, color: Colors.red),
                    label: Text(noText, // Texto dinamico segun idioma
                        style: const TextStyle(
                            color: Colors.red,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600)),
                    onPressed: () => onFeedback(messageId, false),
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          )
        else if (message['extras']?['feedbackMessage'] != null)
          // Opcion 2: Muestra el mensaje de agradecimiento si ya se dio feedback
          Padding(
            padding: const EdgeInsets.only(left: 56.0, top: 8.0, bottom: 8.0),
            child: Text(
              thankYouText, // Texto dinamico segun idioma
              style: TextStyle(
                color: isDarkMode ? Colors.green[300] : Colors.green[700],
                fontFamily: 'Poppins',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // INDICADOR DE ESCRITURA
  // ===========================================================================
  /// Construye el indicador animado que muestra que el bot esta escribiendo
  Widget _buildTypingIndicator() {
    return Semantics(
      label: 'El asistente esta escribiendo',
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar del bot
            const ExcludeSemantics(
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lightprimary,
                backgroundImage: AssetImage('assets/images/Avatar.png'),
              ),
            ),
            const SizedBox(width: 8),

            // Contenedor con los puntos de animacion
            ExcludeSemantics(
              child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
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
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            // AnimatedBuilder para animar los puntos
            child: AnimatedBuilder(
              animation: typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0), // Primer punto
                    const SizedBox(width: 4),
                    _buildTypingDot(1), // Segundo punto
                    const SizedBox(width: 4),
                    _buildTypingDot(2), // Tercer punto
                  ],
                );
              },
            ),
          ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PUNTO ANIMADO DEL INDICADOR DE ESCRITURA
  // ===========================================================================
  /// Construye un punto individual del indicador de escritura con animacion
  /// Cada punto tiene un retraso diferente para crear efecto de onda
  Widget _buildTypingDot(int index) {
    // Calcular el retraso y valor de animacion para cada punto
    double delay = index * 0.2;
    double animationValue = (typingAnimation.value - delay).clamp(0.0, 1.0);

    // Calcular la escala basada en una funcion coseno para efecto de rebote
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