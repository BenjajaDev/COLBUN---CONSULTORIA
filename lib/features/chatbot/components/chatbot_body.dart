import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/faq_bloc.dart';
import '../utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),// quite padding vertical
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
          
          // Si el mensaje no es visible, muestra un widget vacío
          if (!(message['visible'] as bool? ?? true)) {
            return const SizedBox.shrink();
          }

          // Renderiza diferentes widgets según el tipo de mensaje
          switch (message['type']) {
            case 'faq_options':
              return _buildFaqOptions(context, message['options']);
            case 'feedback':
              return _buildFeedbackOptions(context, message['id'], message['text']);
            default: // 'text' (mensaje de texto normal)
              return _buildTextMessage(context, message);
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
                backgroundColor: isDarkMode 
                    ? AppColors.darkprimary 
                    : AppColors.lightprimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: BorderSide(color:
                  isDarkMode ? AppColors.lightbackgroundBody: AppColors.darkBackground)
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0, 
                  horizontal: 16.0,
                ),
              ),
              child: Text(option,
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

  Widget _buildFeedbackOptions(BuildContext context, String messageId, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Muestra la pregunta de feedback como un mensaje normal
        _buildTextMessage(context, {'sender': 'bot', 'text': text}),
        
        // Muestra los botones de opciones de feedback
        Padding(
          padding: const EdgeInsets.only(left: 48.0, top: 8.0, bottom: 8.0),
          child: Row(
            children: [
              // Botón de feedback positivo (pulgar arriba)
              ActionChip(
                avatar: const Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 16, 
                  color: Colors.green,
                ),
                label: const Text(
                  'Sí, fue útil',
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => onFeedback(messageId, true),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.green),
              ),
              
              const SizedBox(width: 8),
              
              // Botón de feedback negativo (pulgar abajo)
              ActionChip(
                avatar: const Icon(
                  Icons.thumb_down_alt_outlined,
                  size: 16, 
                  color: Colors.red,
                ),
                label: const Text(
                  'No, no fue útil',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
    final hasLink = message['link'] != null && message['link'].isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      
      child: Row(
        mainAxisAlignment: isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar del bot (solo para mensajes del bot)
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
          // Contenedor del mensaje de texto
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
                          ?  Colors.grey[800]
                          : Colors.white),
                          
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16.0),
                    topRight: const Radius.circular(16.0),
                    bottomLeft: Radius.circular(isUser ? 16.0 : 0.0),
                    bottomRight: Radius.circular(isUser ? 0.0 : 16.0),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    // Mostrar link si existe
                    if (hasLink) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _launchUrl(message['link'], context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.link,
                                size: 16,
                                color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Fuente',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
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
                    // Si el mensaje es de bienvenida, muestra el botón de FAQs
                    if (message['type'] == 'welcome_message')
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            color:isDarkMode? Colors.grey[300] : Colors.black,
                          ),
                          const SizedBox(height: 8),
                          BlocBuilder<FaqBloc, FaqState>(
                            builder: (context, faqState) {
                              return TextButton(
                                onPressed: () => onShowFrequentlyAskedQuestions(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(48, 48),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap
                                ), 
                                child: const Text(
                                  "Preguntas frecuentes",
                                  style: TextStyle(
                                    color: Color(0xff4861DB),
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600, 
                                  ),
                                ) 
                              );
                            }
                          )
                        ],
                      )  
                  ],
                )
              ),
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
    double scale = 0.5 + (0.5 * (1 + math.cos(animationValue * 2 * math.pi)) / 2);
    
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