import '/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
// url_launcher no se usa directamente aquí; lo usa WhatsAppService internamente
import '../../../services/whatsapp_service.dart';
import '../../chatbot/screen/chatbot_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../chatbot/bloc/language_block.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Text(
              AppLocalizations.of(context)!.menuNav,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          // 1. REEMPLAZAMOS el ExpansionTile por este ListTile
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(AppLocalizations.of(context)!.necesitaAyuda),
            onTap: () {
              // 2. Al presionar, mostramos el diálogo emergente
              _showHelpDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)?.cambiarIdioma ?? 'Cambiar idioma'),
            onTap: () {
              _changeLanguage(context);
            },
          ),
        ],
      ),
    );
  }

  // esta funcion lo que va hacer es cambiar el idioma de la app, mostrando un dialogo con las opciones de español ingles y portugues
  void _changeLanguage(BuildContext context) {
    // Cerrar el Drawer primero
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)?.cambiarIdioma ?? 'Cambiar idioma'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text(AppLocalizations.of(dialogContext)!.cambiarEs),
                onTap: () {
                  final langBloc = dialogContext.read<LanguageBloc>(); // tomar el bloc antes de cerrar
                  Navigator.of(dialogContext).pop(); // cerrar el diálogo
                  langBloc.add( ChangeLanguage(const Locale('es'))); // despachar cambio
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(dialogContext)!.cambiarEn),
                onTap: () {
                  final langBloc = dialogContext.read<LanguageBloc>();
                  Navigator.of(dialogContext).pop();
                  langBloc.add( ChangeLanguage(const Locale('en')));
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(dialogContext)!.cambiarPt),
                onTap: () {
                  final langBloc = dialogContext.read<LanguageBloc>();
                  Navigator.of(dialogContext).pop();
                  langBloc.add(ChangeLanguage(const Locale('pt')));
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(dialogContext)!.btnCerrar),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }
  }


  // 3. ESTA ES LA NUEVA FUNCIÓN QUE MUESTRA LA PANTALLA EMERGENTE (DIÁLOGO)
  void _showHelpDialog(BuildContext context) {
    // Cerramos el Drawer primero para que se vea el diálogo sobre la pantalla principal
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.necesitaAyuda),
          content: Column(
            mainAxisSize:
                MainAxisSize.min, // Para que la columna no ocupe todo el alto
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(AppLocalizations.of(dialogContext)!.chatbotApp),
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
                title: Text(AppLocalizations.of(dialogContext)!.chatbotWhatsapp),
                onTap: () {
                  // Cierra el diálogo
                  Navigator.of(dialogContext).pop();
                  // Abre WhatsApp
                  _openWhatsApp(dialogContext);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(dialogContext)!.btnCerrar),
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

  // Función para abrir WhatsApp (usa servicio con esquema nativo + fallback web)
  Future<void> _openWhatsApp(BuildContext context) async {
    const phoneNumber = "+56912345678"; // Reemplaza con tu número
  const message = 'Hola, necesito ayuda.';

    final ok = await WhatsAppService.openChat(
      phone: phoneNumber,
      message: message,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }
