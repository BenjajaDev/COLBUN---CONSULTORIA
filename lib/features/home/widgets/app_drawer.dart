// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../chatbot/screen/chatbot_screen.dart';

// ===========================================================================
// MENU LATERAL DE NAVEGACION
// ===========================================================================
/// Widget que implementa el menu lateral (drawer) de la aplicacion
/// Proporciona acceso a diferentes funcionalidades como ayuda y chatbot
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header del menu con titulo
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu de Navegacion',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          // Opcion de ayuda que muestra dialogo con opciones de chatbot
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('¿Necesitas ayuda?'),
            onTap: () {
              // Mostrar dialogo emergente con opciones de ayuda
              _showHelpDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DIALOGO DE AYUDA
  // ===========================================================================
  /// Muestra un dialogo emergente con opciones de ayuda
  /// Incluye acceso al chatbot de la app y al chatbot de WhatsApp
  void _showHelpDialog(BuildContext context) {
    // Cerrar el Drawer primero para que se vea el dialogo sobre la pantalla principal
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Necesitas ayuda?'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Para que la columna no ocupe todo el alto
            children: <Widget>[
              // Opcion para abrir el chatbot integrado en la app
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Chatbot de la App'),
                onTap: () {
                  // Cerrar el dialogo
                  Navigator.of(dialogContext).pop();
                  // Navegar a la pantalla del chatbot
                  Navigator.of(dialogContext).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatbotScreen(),
                    ),
                  );
                },
              ),
              // Opcion para abrir WhatsApp
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Chatbot de WhatsApp'),
                onTap: () {
                  // Cerrar el dialogo
                  Navigator.of(dialogContext).pop();
                  // Abrir WhatsApp con numero predefinido
                  _openWhatsApp();
                },
              ),
            ],
          ),
          actions: <Widget>[
            // Boton para cerrar el dialogo
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // ABRIR WHATSAPP
  // ===========================================================================
  /// Abre la aplicacion de WhatsApp con un numero y mensaje predefinido
  /// Utiliza url_launcher para abrir aplicaciones externas
  void _openWhatsApp() async {
    const phoneNumber = "14155238886"; // Numero de contacto del chatbot de WhatsApp
    const message = "Hola, necesito ayuda.";

    // Construir la URL de WhatsApp con numero y mensaje
    final Uri whatsappUri = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    // Intentar abrir WhatsApp
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // Manejar el error si no se puede abrir WhatsApp
      print("No se pudo abrir WhatsApp.");
    }
  }
}
