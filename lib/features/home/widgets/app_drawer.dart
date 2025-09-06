// lib/features/home/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../chatbot/screen/chatbot_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menú de Navegación',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          // 1. REEMPLAZAMOS el ExpansionTile por este ListTile
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('¿Necesitas ayuda?'),
            onTap: () {
              // 2. Al presionar, mostramos el diálogo emergente
              _showHelpDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // 3. ESTA ES LA NUEVA FUNCIÓN QUE MUESTRA LA PANTALLA EMERGENTE (DIÁLOGO)
  void _showHelpDialog(BuildContext context) {
    // Cerramos el Drawer primero para que se vea el diálogo sobre la pantalla principal
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Necesitas ayuda?'),
          content: Column(
            mainAxisSize:
                MainAxisSize.min, // Para que la columna no ocupe todo el alto
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Chatbot de la App'),
                onTap: () {
                  // Cierra el diálogo
                  Navigator.of(dialogContext).pop();
                  // Navega a la pantalla del chatbot usando el contexto del diálogo
                  Navigator.of(dialogContext).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatbotScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Chatbot de WhatsApp'),
                onTap: () {
                  // Cierra el diálogo
                  Navigator.of(dialogContext).pop();
                  // Abre WhatsApp
                  _openWhatsApp();
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                // Simplemente cierra el diálogo
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Función para abrir WhatsApp (se mantiene igual)
  void _openWhatsApp() async {
    const phoneNumber = "+56912345678"; // Reemplaza con tu número
    const message = "Hola, necesito ayuda.";

    final Uri whatsappUri = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // Opcional: Manejar el error si no se puede abrir WhatsApp
      print("No se pudo abrir WhatsApp.");
    }
  }
}
