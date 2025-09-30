import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme_bloc.dart';
import '../utils/app_colors.dart';

// =============================================================================
// COMPONENTE CHATBOT HEADER
// =============================================================================

/// Componente que representa la barra de aplicación (AppBar) personalizada
/// del chatbot, incluyendo el título, interruptor de tema y menú de opciones.
class ChatbotHeader extends StatelessWidget implements PreferredSizeWidget {
  // ============================ PROPIEDADES ==================================

  final VoidCallback onClearHistory;
  final VoidCallback onContactWhatsApp;

  /// Constructor del componente ChatbotHeader
  const ChatbotHeader({
    super.key,
    required this.onClearHistory,
    required this.onContactWhatsApp,
  });

  // ============================ CONSTRUCCIÓN DE LA UI ========================

  /// Construye la interfaz de usuario de la barra de aplicación del chatbot
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            // Hacemos que la barra de estado sea transparente
            statusBarColor: Colors.transparent,

            // Ponemos los iconos (hora, batería) en color claro para que se lean bien
            statusBarIconBrightness:
                state.isDarkMode ? Brightness.light : Brightness.dark,
          ),
          elevation: 0, // Sin sombra para un diseño más plano
          backgroundColor:
              state.isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
          iconTheme: const IconThemeData(color: AppColors.lightbackground),
          title: const Text(
            'Asistente Colbún',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Color(0xFFFFFFFF),
            ),
          ),
          actions: [
            // Interruptor de cambio de tema (claro/oscuro)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  // Icono que cambia según el tema actual
                  Icon(
                    state.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),

                  // Interruptor para cambiar entre temas claro y oscuro
                  Switch(
                    value: state.isDarkMode,
                    onChanged: (value) {
                      // Dispara el evento para cambiar el tema
                      context.read<ThemeBloc>().add(ToggleThemeEvent());
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white.withValues(alpha: 0.5)
                  ),
                ],
              ),
            ),

            // Menú de opciones adicionales (tres puntos verticales)
            SizedBox(
              width: 44,
              height: 44,
              child: PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFFFFFFFF)),
                color: state.isDarkMode
                    ? AppColors.darkprimary
                    : AppColors.lightprimary,
                iconSize: 32,
                position: PopupMenuPosition.under,
                elevation: 8,
                offset: const Offset(0, 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                // Maneja la selección de opciones del menú
                onSelected: (value) {
                  if (value == 'Whatsapp') {
                    onContactWhatsApp();
                  } else if (value == 'Borrar Historial') {
                    onClearHistory();
                  }
                },
                // Construye los ítems del menú desplegable
                itemBuilder: (BuildContext context) {
                  FocusScope.of(context)
                      .unfocus(); // Cierra el teclado si está abierto

                  return [
                    // Opción para contactar por WhatsApp
                    const PopupMenuItem(
                      value: 'Whatsapp',
                      child: ListTile(
                        leading: Icon(Icons.chat, color: Colors.green),
                        title: Text(
                          'Contactar por WhatsApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),

                    // Separador entre opciones
                    const PopupMenuItem(
                      enabled: false,
                      height: 0,
                      child: Divider(
                        color: Colors.white,
                        height: 1,
                      ),
                    ),

                    // Opción para borrar el historial de conversación
                    const PopupMenuItem(
                      value: 'Borrar Historial',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Borrar Historial de conversación',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================ PROPIEDADES DEL WIDGET =======================

  /// Define la altura preferida para la AppBar (altura estándar de toolbar)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
