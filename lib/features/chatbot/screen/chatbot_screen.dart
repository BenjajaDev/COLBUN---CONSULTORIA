// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

// --- Simulación del BLoC de Tema ---
// Para que este widget sea autoejecutable y no dependa de una implementación externa,
// se simula un BLoC (Cubit en este caso) para manejar el estado del tema (claro/oscuro).
// En un proyecto real, deberías importar tu propio ThemeBloc.

/// Un Cubit que gestiona el estado del tema de la aplicación.
class ThemeBloc extends Cubit<ThemeState> {
  /// El constructor inicializa el estado con el tema claro (isDarkMode: false).
  ThemeBloc() : super(const ThemeState(isDarkMode: false));

  /// Cambia el estado del tema actual al opuesto.
  void add(ToggleThemeEvent event) =>
      emit(ThemeState(isDarkMode: !state.isDarkMode));
}

/// Un evento para solicitar el cambio de tema.
class ToggleThemeEvent {}

/// Representa el estado del tema, indicando si el modo oscuro está activo.
class ThemeState {
  final bool isDarkMode;
  const ThemeState({required this.isDarkMode});
}
// --- Fin de la simulación del BLoC ---

/// Define una paleta de colores centralizada para la aplicación.
class AppColors {
  // Colores para el tema claro.
  static const Color lightprimary = Color(0xFF4D67AE);
  static const Color lightbackground = Colors.white;
  static const Color lightTextFieldBorder = Color(0xFFE0E0E0);
  // Colores para el tema oscuro.
  static const Color darkprimary = Color(0xFF494C6B);
  static const Color darkBackground = Color(0xFF252525);
}

/// Modelo que encapsula la respuesta generada por el bot.
class BotResponse {
  final String answer; // El texto de la respuesta.
  final String? action; // Una acción opcional a ejecutar (ej: "open_whatsapp").
  final bool
      isStandardResponse; // Indica si es una respuesta estándar que requiere feedback.

  BotResponse({
    required this.answer,
    this.action,
    this.isStandardResponse = true,
  });
}

/// El widget principal que construye la pantalla del chatbot.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

/// El estado asociado al widget `ChatbotScreen`. Maneja la lógica y la UI.
class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  // Lista que almacena todos los mensajes del chat.
  final List<Map<String, dynamic>> messages = [];
  // Contadores para el feedback.
  int _thumbsUpCount = 0;
  int _thumbsDownCount = 0;
  // Estado que controla la visibilidad del indicador "escribiendo...".
  bool _isTyping = false;
  // Controlador de animación para el indicador "escribiendo...".
  late AnimationController _typingController;
  // Animación específica para el efecto de los puntos.
  Animation<double>? _typingAnimation;
  // Almacena las preguntas y respuestas frecuentes cargadas desde el JSON.
  Map<String, dynamic>? _faqs;
  // Controlador para la lista de mensajes, permite hacer scroll automáticamente.
  final ScrollController _scrollController = ScrollController();

  /// Se ejecuta una vez cuando el widget se inserta en el árbol de widgets.
  @override
  void initState() {
    super.initState();
    // Inicializa el controlador de la animación "escribiendo...".
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..addListener(() {
        // Redibuja el widget mientras la animación está activa.
        if (_isTyping) setState(() {});
      });
    // Define la curva y el rango de la animación.
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _typingController, curve: Curves.easeInOut));
    // Carga las preguntas frecuentes desde el archivo JSON.
    _loadFaqs();
  }

  /// Se ejecuta cuando el widget es eliminado permanentemente del árbol de widgets.
  @override
  void dispose() {
    // Libera los recursos de los controladores para evitar fugas de memoria.
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  /// Carga el contenido del archivo `faqs.json` y prepara el estado inicial del chat.
  Future<void> _loadFaqs() async {
    // Carga el archivo JSON desde los assets de la aplicación.
    final String response = await rootBundle.loadString('assets/faqs.json');
    final data = await json.decode(response);
    // Actualiza el estado con las FAQs cargadas.
    setState(() {
      _faqs = data;
      // Añade el mensaje de bienvenida inicial del bot.
      addMessage("bot",
          "¡Hola! Soy el asistente virtual de Colbún. ¿En qué puedo ayudarte?");
      // Obtiene y muestra las respuestas rápidas.
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

  /// Extrae una selección de preguntas del JSON para usarlas como respuestas rápidas.
  List<String> _getQuickReplyQuestions() {
    if (_faqs == null) return [];
    List<String> questions = [];
    final turismo = _faqs!['faq_turismo'] as List;
    final servicios = _faqs!['faq_servicios'] as List;
    // Añade algunas preguntas preseleccionadas a la lista.
    if (turismo.isNotEmpty) questions.add(turismo[0]['question']);
    if (servicios.isNotEmpty) questions.add(servicios[0]['question']);
    if (turismo.length > 1) questions.add(turismo[1]['question']);
    return questions;
  }

  /// Procesa el mensaje del usuario y busca la mejor respuesta en el JSON de FAQs.
  BotResponse _getBotResponse(String userMessage) {
    if (_faqs == null) return BotResponse(answer: "Cargando respuestas...");

    // Normaliza y limpia el mensaje del usuario para mejorar la coincidencia.
    String message = userMessage.toLowerCase().trim();
    String sanitizedMessage =
        message.replaceAll(RegExp(r'[^\w\s\u00C0-\u017F]'), '');

    // Combina todas las categorías de FAQs en una sola lista para la búsqueda.
    final allEntries = [
      ..._faqs!['greetings'],
      ..._faqs!['faq_turismo'],
      ..._faqs!['faq_servicios'],
      ..._faqs!['faq_emergencias'],
      ..._faqs!['faq_cultura_eventos'],
      ..._faqs!['faq_tramites'],
      ..._faqs!['farewells'],
      ..._faqs!['fallback'],
    ].cast<Map<String, dynamic>>();

    Map<String, dynamic>? bestMatch;
    int maxScore = 0;

    // Itera sobre cada entrada del JSON para encontrar la mejor coincidencia.
    for (var entry in allEntries) {
      int currentScore = 0;
      List<dynamic> tags = entry['tags'];
      // Compara cada 'tag' con el mensaje del usuario.
      for (var tag in tags) {
        if (RegExp(r'\b' + RegExp.escape(tag.toLowerCase()) + r'\b')
            .hasMatch(sanitizedMessage)) {
          currentScore++; // Incrementa el puntaje por cada coincidencia.
        }
      }
      // Si el puntaje actual es el más alto, se guarda como la mejor coincidencia.
      if (currentScore > maxScore) {
        maxScore = currentScore;
        bestMatch = entry;
      }
    }

    // Si se encontró una coincidencia con puntaje mayor a 0.
    if (bestMatch != null && maxScore > 0) {
      // Determina si la respuesta es un saludo o despedida para no pedir feedback.
      bool isGreetingOrFarewell = (_faqs!['greetings'].contains(bestMatch) ||
          _faqs!['farewells'].contains(bestMatch));
      return BotResponse(
        answer: bestMatch['answer'],
        action: bestMatch['action'],
        isStandardResponse: !isGreetingOrFarewell,
      );
    }

    // Si no hay coincidencias, devuelve una respuesta para escalar a una IA (simulada).
    return BotResponse(
        answer: "No encontré una respuesta. Consultando a la IA...",
        action: "query_openai");
  }

  /// Gestiona el flujo completo del envío de un mensaje por parte del usuario.
  void handleSendMessage(String text) {
    // Elimina las respuestas rápidas anteriores para que no se acumulen.
    setState(() => messages.removeWhere((m) => m['type'] == 'quick_replies'));
    // Añade el mensaje del usuario a la lista de mensajes.
    addMessage("user", text);
    // Activa el indicador "escribiendo...".
    setState(() => _isTyping = true);
    _typingController.repeat();
    // Obtiene la respuesta del bot.
    final botResponse = _getBotResponse(text);
    // Simula un tiempo de respuesta variable para el bot.
    int totalTTR =
        (800 + (math.Random().nextDouble() * 2200)).toInt().clamp(800, 3000);

    // Espera el tiempo simulado antes de mostrar la respuesta del bot.
    Future.delayed(Duration(milliseconds: totalTTR), () {
      if (!mounted) return; // Verifica si el widget sigue en pantalla.
      // Desactiva el indicador "escribiendo...".
      setState(() => _isTyping = false);
      _typingController.stop();

      // Añade la respuesta del bot al chat.
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      addMessage("bot", botResponse.answer, messageId: messageId);

      // Ejecuta acciones especiales basadas en la respuesta del bot.
      if (botResponse.action == "open_whatsapp") {
        _launchWhatsApp();
      } else if (botResponse.action == "query_openai") {
        // Simula una consulta a una IA externa.
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
          addMessage("bot", "Respuesta simulada de la IA para: \"$text\".",
              messageId: aiMessageId);
          // Pide feedback para la respuesta de la IA.
          addMessage("bot", "¿Fue útil esta infomación?",
              type: "feedback", messageId: aiMessageId);
        });
      } else {
        // Si es una respuesta estándar, pide feedback.
        if (botResponse.isStandardResponse) {
          addMessage("bot", "¿Fue útil esta infomación?",
              type: "feedback", messageId: messageId);
        }
      }
    });
  }

  /// Añade un nuevo mensaje a la lista `messages` y actualiza la UI.
  void addMessage(String sender, String text,
      {String? type, dynamic payload, String? messageId}) {
    if (!mounted) return;
    setState(() {
      messages.add({
        "id": messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        "sender": sender, // 'user' o 'bot'
        "text": text, // Contenido del mensaje
        "type": type ?? "text", // Tipo: 'text', 'quick_replies', 'feedback'
        "payload": payload, // Datos adicionales (ej: lista de preguntas)
        "visible":
            true, // Controla si el mensaje es visible (para ocultar feedback)
      });
    });
    // Se asegura de que la UI se actualice y luego hace scroll al mensaje más reciente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  /// Maneja la selección de feedback (útil o no útil) por parte del usuario.
  void _handleFeedback(String messageId, bool wasUseful) {
    // Incrementa el contador correspondiente.
    if (wasUseful) {
      _thumbsUpCount++;
    } else {
      _thumbsDownCount++;
    }

    // Oculta los botones de feedback para que no se pueda volver a votar.
    if (!mounted) return;
    setState(() {
      final feedbackIndex = messages
          .indexWhere((m) => m['type'] == 'feedback' && m['id'] == messageId);
      if (feedbackIndex != -1) messages[feedbackIndex]['visible'] = false;
    });

    // Muestra un mensaje de agradecimiento.
    addMessage("bot", "¡Gracias por tu feedback!");
    // Muestra el recuento actual de votos.
    addMessage(
        "bot", "Feedback actual: $_thumbsUpCount 👍 / $_thumbsDownCount 👎");
  }

  /// Reinicia el historial de chat a su estado inicial.
  void _clearChatHistory() {
    setState(() {
      messages.clear();
      _thumbsUpCount = 0; // Resetea contadores
      _thumbsDownCount = 0;
      _loadFaqs(); // Vuelve a cargar el saludo inicial y las preguntas.
    });
  }

  /// Abre la aplicación de WhatsApp con un número y mensaje predefinidos.
  void _launchWhatsApp() async {
    const phoneNumber = "+56912345678"; // Número de teléfono de destino.
    const message =
        "Hola, necesito ayuda de un asesor."; // Mensaje pre-escrito.
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    // Intenta abrir la URL de WhatsApp.
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      // Muestra un error si no se pudo abrir.
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir WhatsApp.")));
    }
  }

  /// Construye la estructura visual principal de la pantalla del chatbot.
  @override
  Widget build(BuildContext context) {
    // Provee el ThemeBloc al árbol de widgets descendientes.
    return BlocProvider(
      create: (context) => ThemeBloc(),
      // Reconstruye la UI cuando el estado del ThemeBloc cambia.
      child: BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
        return GestureDetector(
          // Permite cerrar el teclado al tocar fuera del campo de texto.
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            // Barra de navegación superior.
            appBar: ChatbotHeader(
                onClearHistory: _clearChatHistory,
                onContactWhatsApp: _launchWhatsApp),
            // Color de fondo dependiente del tema.
            backgroundColor:
                state.isDarkMode ? AppColors.darkBackground : Colors.grey[50],
            body: Column(
              children: [
                // Cuerpo del chat que contiene la lista de mensajes.
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
                // Pie de página con el campo de texto y el botón de enviar.
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

/// Widget para la barra de aplicación (AppBar) personalizada del chatbot.
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
    // Escucha los cambios del tema para ajustar los colores.
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return AppBar(
          elevation: 1,
          backgroundColor:
              state.isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Asistente Colbún',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          actions: [
            // Fila para el interruptor de cambio de tema.
            Row(
              children: [
                Icon(state.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                    color: Colors.white),
                Switch(
                  value: state.isDarkMode,
                  onChanged: (value) =>
                      // Dispara el evento para cambiar el tema.
                      context.read<ThemeBloc>().add(ToggleThemeEvent()),
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
            // Menú desplegable con opciones adicionales.
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                // Ejecuta la acción correspondiente a la opción seleccionada.
                if (value == 'Whatsapp') {
                  onContactWhatsApp();
                } else if (value == 'Borrar Historial') onClearHistory();
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                    value: 'Whatsapp', child: Text('Contactar por WhatsApp')),
                const PopupMenuItem(
                    value: 'Borrar Historial', child: Text('Borrar Historial')),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Define la altura preferida para el AppBar.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Widget que muestra la lista de mensajes del chat.
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
    // ListView.builder es eficiente para listas largas.
    return ListView.builder(
      controller: scrollController,
      reverse: true, // Muestra los mensajes de abajo hacia arriba.
      padding: const EdgeInsets.all(16.0),
      // El tamaño de la lista incluye el indicador "escribiendo..." si está activo.
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Si el indicador está activo y es el primer item, lo muestra.
        if (isTyping && index == 0) return _buildTypingIndicator();
        // Ajusta el índice para acceder a la lista de mensajes.
        final messageIndex = isTyping ? index - 1 : index;
        // La lista se invierte para que el último mensaje esté al final.
        final reversedIndex = messages.length - 1 - messageIndex;
        final message = messages[reversedIndex];
        // Si el mensaje no es visible, muestra un widget vacío.
        if (!(message['visible'] as bool? ?? true)) {
          return const SizedBox.shrink();
        }
        // Renderiza diferentes widgets según el tipo de mensaje.
        switch (message['type']) {
          case 'quick_replies':
            return _buildQuickReplies(
                context, message['text'], message['payload']);
          case 'feedback':
            return _buildFeedbackOptions(
                context, message['id'], message['text']);
          default: // 'text'
            return _buildTextMessage(context, message);
        }
      },
    );
  }

  /// Construye el widget para las respuestas rápidas.
  Widget _buildQuickReplies(
      BuildContext context, String title, List<String> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Muestra un título antes de los botones.
        _buildTextMessage(context, {'sender': 'bot', 'text': title}),
        Padding(
          padding: const EdgeInsets.only(
              left: 48.0, top: 8.0, right: 8.0, bottom: 8.0),
          // Wrap permite que los botones se ajusten a la siguiente línea si no caben.
          child: Wrap(
            spacing: 8.0, // Espacio horizontal entre botones.
            runSpacing: 8.0, // Espacio vertical entre líneas de botones.
            children: questions
                .map((q) => ActionChip(
                      label: Text(q,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.lightprimary)),
                      onPressed: () => onQuickReply(q),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                          color: AppColors.lightprimary.withOpacity(0.5)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Construye el widget para las opciones de feedback (pulgares arriba/abajo).
  Widget _buildFeedbackOptions(
      BuildContext context, String messageId, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Muestra la pregunta de feedback.
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

  /// Construye la burbuja de un mensaje de texto estándar.
  Widget _buildTextMessage(BuildContext context, Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        // Alinea los mensajes del usuario a la derecha y los del bot a la izquierda.
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Muestra el avatar del bot si el mensaje no es del usuario.
          if (!isUser) ...[
            const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.lightprimary,
                child: Icon(Icons.smart_toy, color: Colors.white, size: 18)),
            const SizedBox(width: 8),
          ],
          // Contenedor flexible para que la burbuja se ajuste al texto.
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                // Aplica colores diferentes según el emisor y el tema.
                color: isUser
                    ? (isDarkMode
                        ? AppColors.darkprimary
                        : AppColors.lightprimary)
                    : (isDarkMode ? Colors.grey[800] : Colors.white),
                // Da forma de burbuja de chat a las esquinas.
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: Radius.circular(isUser ? 16.0 : 0.0),
                  bottomRight: Radius.circular(isUser ? 0.0 : 16.0),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                    fontFamily: 'Poppins'),
              ),
            ),
          ),
          // Muestra el avatar del usuario si el mensaje es del usuario.
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 18)),
          ],
        ],
      ),
    );
  }

  /// Construye el indicador animado de "escribiendo...".
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Avatar del bot.
          const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.lightprimary,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18)),
          const SizedBox(width: 8),
          // Contenedor para los puntos animados.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                  bottomRight: Radius.circular(16.0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3)
              ],
            ),
            // AnimatedBuilder reconstruye los puntos en cada tick de la animación.
            child: AnimatedBuilder(
              animation: typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      3,
                      (i) => Transform.translate(
                            // La función seno crea el efecto de subida y bajada de los puntos.
                            offset: Offset(
                                0,
                                math.sin((typingAnimation.value * 2 * math.pi) +
                                        (i * math.pi / 2)) *
                                    2),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              child: CircleAvatar(
                                  radius: 4,
                                  backgroundColor: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[600]),
                            ),
                          )),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para el pie de página que contiene el campo de texto y el botón de enviar.
class ChatbotFooter extends StatefulWidget {
  final bool isDarkMode;
  final Function(String) onSendMessage;

  const ChatbotFooter(
      {super.key, required this.isDarkMode, required this.onSendMessage});

  @override
  State<ChatbotFooter> createState() => _ChatbotFooterState();
}

class _ChatbotFooterState extends State<ChatbotFooter> {
  // Controlador para leer y limpiar el campo de texto.
  final TextEditingController _textController = TextEditingController();

  /// Valida y envía el mensaje del campo de texto.
  void _sendMessage() {
    final messageText = _textController.text.trim();
    if (messageText.isNotEmpty) {
      widget.onSendMessage(messageText);
      _textController.clear(); // Limpia el campo después de enviar.
      FocusScope.of(context).unfocus(); // Cierra el teclado.
    }
  }

  /// Libera el controlador de texto cuando el widget es eliminado.
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding para separar el contenido de los bordes.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.darkBackground : Colors.white,
        boxShadow: [
          // Sombra sutil en la parte superior del contenedor.
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          // Campo de texto expandido para ocupar el espacio disponible.
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: TextStyle(
                    color: widget.isDarkMode
                        ? Colors.grey[400]
                        : const Color(0xFF828282)),
                filled: true,
                fillColor:
                    widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                // Borde redondeado sin línea visible.
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              // Permite enviar el mensaje con la tecla "Enter" o "Enviar" del teclado.
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12.0),
          // Botón de enviar.
          Material(
            color: AppColors.lightprimary,
            borderRadius: BorderRadius.circular(24),
            // InkWell proporciona el efecto de salpicadura al tocar.
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _sendMessage,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
