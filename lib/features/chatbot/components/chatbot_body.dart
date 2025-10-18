import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/faq_bloc.dart';
import '../utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatbotBody extends StatelessWidget {
  final bool isDarkMode;
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final bool isTyping;
  final Animation<double> typingAnimation;
  final Function(String, bool) onFeedback;
  final Function(String) onSendMessage;
  final VoidCallback onShowFrequentlyAskedQuestions;
  final Function(String) onFaqSelected;
  final List<Map<String, dynamic>> emergencyContacts;
  final Function(String) onEmergencyCall;
  final VoidCallback onCloseEmergency;

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

// Método para abrir URLs
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


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0), // quite padding vertical
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        itemCount: messages.length + (isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (isTyping && index == 0) {
            return _buildTypingIndicator().animate().fadeIn(duration: 300.ms);
          }

          final messageIndex = isTyping ? index - 1 : index;
          final reversedIndex = messages.length - 1 - messageIndex;
          final message = messages[reversedIndex];

          // Si el mensaje no es visible, muestra un widget vacío
          if (!(message['visible'] as bool? ?? true)) {
            return const SizedBox.shrink();
          }
          Widget messageWidget;

          // 2. El switch ahora ASIGNA el widget a la variable, en lugar de retornarlo directamente.
          switch (message['type']) {
            case 'faq_options':
              final options =
              (message['options'] as List?)?.cast<String>() ?? const <String>[];
          if (options.isEmpty) {
            messageWidget = const SizedBox.shrink();
          } else {
            messageWidget = _buildFaqOptions(context, options);
          }
            break;
          default: // 'text' y 'feedback' (mensajes de texto normales)
            messageWidget = _buildTextMessage(context, message);
            break;
        }
          // 3. Aplicamos la animación al widget guardado y retornamos el resultado final.
          if (index == 0) {
            // Es el mensaje más reciente, ¡anímalo!
            return messageWidget
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.5, end: 0.0, curve: Curves.easeOutCubic);
          } else {
            // Es un mensaje antiguo, muéstralo sin animación.
            return messageWidget;
          }
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
                onFaqSelected(option);
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


  Widget _buildTextMessage(BuildContext context, Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    final hasLink = message['link'] != null && message['link'].isNotEmpty;

    //Obtener el idioma del mensaje para textos dinámicos**
    final messageLanguage = message['language'] ?? 'es';
    final sourceText = messageLanguage == 'en' ? 'Source' : messageLanguage == 'pt' ?
    'Fonte' : 'Fuente';

    // Lógica para el feedback
    final bool shouldShowFeedback =
        message['extras']?['showFeedback'] as bool? ?? false;
    final String? messageId = message['id'];

    //Textos dinámicos para feedback según idioma**
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isDarkMode
                      ? AppColors.darkprimary
                      : AppColors.lightprimary,
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Contenedor principal del mensaje
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Texto del mensaje
                          Text(
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
                          // 2. LÓGICA DEL LINK dinamicos listos
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
                                          fontSize: 16,
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
                                        style: const TextStyle(
                                          color: Color(0xff4861DB),
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ));
                                })
                              ],
                            )
                        ],
                      )),
                ),

              // Avatar del usuario (solo para mensajes del usuario)
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
        ),

        // 4. LÓGICA DE LOS BOTONES DE FEEDBACK idioma dinamico listo
        if (shouldShowFeedback && messageId != null)
          // Opción 1: Muestra los botones si se debe pedir feedback
          Padding(
            padding: const EdgeInsets.only(left:48.0, top: 4.0, bottom: 8.0),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.thumb_up_alt_outlined,
                      size: 16, color: Colors.green),
                  label: Text(yesText, // **TEXTO DINÁMICO**
                      style: const TextStyle(
                          color: Colors.green,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600)),
                  onPressed: () => onFeedback(messageId, true),
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  side: const BorderSide(color: Colors.green),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.thumb_down_alt_outlined,
                      size: 16, color: Colors.red),
                  label: Text(noText, // **TEXTO DINÁMICO**
                      style: const TextStyle(
                          color: Colors.red,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600)),
                  onPressed: () => onFeedback(messageId, false),
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  side: const BorderSide(color: Colors.red),
                ),
              ],
            ),
          )
        else if (message['extras']?['feedbackMessage'] != null)
          // Opción 2: Muestra el mensaje de agradecimiento si ya se dio feedback
          Padding(
            padding: const EdgeInsets.only(left: 56.0, top: 8.0, bottom: 8.0),
            child: Text(
              thankYouText, // **TEXTO DINÁMICO**
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

          // Contenedor con los puntos de animación
          Container(
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
    // Calcula el retraso y valor de animación para cada punto
    double delay = index * 0.2;
    double animationValue = (typingAnimation.value - delay).clamp(0.0, 1.0);

    // Calcula la escala basada en una función coseno para efecto de rebote
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