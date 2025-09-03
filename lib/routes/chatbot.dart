import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot App',
      home: const ChatbotScreen(),
    );
  }
}

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header del chatbot
          const ChatbotHeader(),

          // Body - conversación
          const Expanded(
            child: ChatbotBody(),
          ),

          // Footer - input del usuario
          const ChatbotFooter(),
        ],
      ),
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
    return Container(
      // TODO: Implementar diseño del header
      // - Logo/título del chatbot
      // - Botón de configuraciones
      // - Estado de conexión
      height: 80,
      color: Colors.blue.shade100,
      child: const Center(
        child: Text(
          'CHATBOT HEADER',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENTE BODY - Área de conversación entre usuario y chatbot
// ============================================================================

class ChatbotBody extends StatelessWidget {
  const ChatbotBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO: Implementar área de conversación
      // - Lista de mensajes
      // - Scroll automático
      // - Burbujas de chat diferenciadas
      // - Indicador de "escribiendo..."
      width: double.infinity,
      color: Colors.grey.shade50,
      child: const Center(
        child: Text(
          'CHATBOT BODY\n(Área de conversación)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENTE FOOTER - Input del usuario y botón de envío
// ============================================================================

class ChatbotFooter extends StatelessWidget {
  const ChatbotFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO: Implementar área de input
      // - Campo de texto para escribir mensaje
      // - Botón de envío
      // - Botón de adjuntar archivos
      // - Indicadores de estado
      height: 70,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(16.0),
      child: const Center(
        child: Text(
          'CHATBOT FOOTER\n(Input del usuario)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
