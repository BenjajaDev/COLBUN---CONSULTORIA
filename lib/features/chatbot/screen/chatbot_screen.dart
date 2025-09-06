import 'package:flutter/material.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Column(
        children: [
          // Header del chatbot
          ChatbotHeader(),

          // Body - conversación
          Expanded(
            child: ChatbotBody(),
          ),

          // Footer - input del usuario
          ChatbotFooter(),
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
      height: 80,
      color: Colors.blue.shade100,
      width: double.infinity,
      child: Column(
          children: [
            const Text(
              'CHATBOT HEADER',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        
      )
    );
  }
}

// ============================================================================
// COMPONENTE BODY - Área de conversación entre usuario y chatbot
// ============================================================================

//Arreglo de mensajes para prueba
final List<Map<String, String>> messages = [
  {"sender": "user", "text": "Hola, ¿cómo estás?"},
  {"sender": "bot", "text": "¡Hola! Estoy aquí para ayudarte."},
  {"sender": "user", "text": "¿Cuál es tu nombre?"},
  {"sender": "bot", "text": "Soy un chatbot creado por OpenAI."},
];

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
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        //Item count sirve para definir cuántos elementos se van a mostrar en la lista
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ListTile(
            //Alineará el texto con su respectivo remitente
            title: Text(message['text'] ?? ''),
            subtitle: Text(message['sender'] ?? ''),
          );
        },
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
      child: Row(
        children: [
          // aqui esta el box que contiene el campo de texto
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              //agregue padding para que el texto no este pegado al borde acordarse las medidas solo multiplo de 8
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              // este es el campo de texto TextField
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                )
              ),


            ),
          )
        ],
      ),
    );
  }
}

