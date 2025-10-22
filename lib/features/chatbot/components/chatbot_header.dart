// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme_bloc.dart';
import '../utils/app_colors.dart';

// ===========================================================================
// COMPONENTE CHATBOT HEADER
// ===========================================================================
/// Componente que representa la barra de aplicacion (AppBar) personalizada
/// del chatbot, incluyendo el titulo, interruptor de tema y menu de opciones
class ChatbotHeader extends StatelessWidget implements PreferredSizeWidget {
  // ===========================================================================
  // PROPIEDADES
  // ===========================================================================
  final VoidCallback onClearHistory;      // Callback para borrar el historial
  final VoidCallback onContactWhatsApp;   // Callback para contactar por WhatsApp

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================
  const ChatbotHeader({
    super.key,
    required this.onClearHistory,
    required this.onContactWhatsApp,
  });

  // ===========================================================================
  // BUILD - CONSTRUCCION DE LA UI
  // ===========================================================================
  /// Construye la interfaz de usuario de la barra de aplicacion del chatbot
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return AppBar(
          // Configuracion del estilo de la barra de estado del sistema
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // Barra de estado transparente
            statusBarIconBrightness:
                state.isDarkMode ? Brightness.light : Brightness.dark,
          ),
          elevation: 0, // Sin sombra para un diseno mas plano
          backgroundColor:
              state.isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
          iconTheme: const IconThemeData(color: AppColors.lightbackground),
          title: const Text(
            'Asistente',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Color(0xFFFFFFFF),
            ),
          ),
          actions: [
            // ==================================================================
            // MENU DE TAMANO DE FUENTE
            // ==================================================================
            Semantics(
              label: 'Cambiar tamano de fuente',
              hint: 'Toca para cambiar el tamano de fuente',
              button: true,
              child: PopupMenuButton<FontSize>(
                tooltip: 'Tamano de fuente',
                icon: const Icon(
                  Icons.text_fields,
                  color: Colors.white,
                ),
                color: state.isDarkMode
                    ? AppColors.darkprimary
                    : AppColors.lightprimary,
                onSelected: (FontSize size) {
                  context.read<ThemeBloc>().add(ChangeFontSizeEvent(size));
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<FontSize>>[
                  // Opcion de fuente pequena
                  PopupMenuItem<FontSize>(
                    value: FontSize.small,
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 16,
                          color: state.fontSize == FontSize.small
                              ? Colors.green
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pequeno',
                          style: TextStyle(
                            color: state.fontSize == FontSize.small
                                ? Colors.green
                                : Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: state.fontSize == FontSize.small
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Opcion de fuente mediana
                  PopupMenuItem<FontSize>(
                    value: FontSize.medium,
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 20,
                          color: state.fontSize == FontSize.medium
                              ? Colors.green
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mediano',
                          style: TextStyle(
                            color: state.fontSize == FontSize.medium
                                ? Colors.green
                                : Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: state.fontSize == FontSize.medium
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Opcion de fuente grande
                  PopupMenuItem<FontSize>(
                    value: FontSize.large,
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 24,
                          color: state.fontSize == FontSize.large
                              ? Colors.green
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Grande',
                          style: TextStyle(
                            color: state.fontSize == FontSize.large
                                ? Colors.green
                                : Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: state.fontSize == FontSize.large
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================================
            // INTERRUPTOR DE TEMA CLARO/OSCURO
            // ==================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Semantics(
                label: state.isDarkMode ? 'Tema oscuro activado' : 'Tema claro activado',
                hint: 'Toca para cambiar entre tema oscuro y claro',
                child: Row(
                  children: [
                    // Icono que cambia segun el tema actual
                    ExcludeSemantics(
                      child: Icon(
                        state.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Switch para alternar entre tema claro y oscuro
                    Switch(
                      value: state.isDarkMode,
                      onChanged: (value) {
                        context.read<ThemeBloc>().add(ToggleThemeEvent());
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.white.withValues(alpha: 0.5)
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================================
            // MENU DE OPCIONES ADICIONALES
            // ==================================================================
            SizedBox(
              width: 44,
              height: 44,
              child: Semantics(
                label: 'Menu de opciones',
                hint: 'Toca dos veces para abrir el menu con mas opciones',
                button: true,
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFFFFFFFF)),
                  tooltip: 'Menu de opciones',
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
                // Maneja la seleccion de opciones del menu
                onSelected: (value) async {
                  if (value == 'Whatsapp') {
                    onContactWhatsApp();
                  } else if (value == 'Borrar Historial') {
                    // Mostrar dialogo de confirmacion antes de borrar
                    final confirmed = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) {
                        final primaryColor = state.isDarkMode
                            ? AppColors.darkprimary
                            : AppColors.lightprimary;
                        return AlertDialog(
                          insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          title: const Text(
                            'Desea borrar el historial?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: const SizedBox.shrink(),
                          actions: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Boton 'No, volver'
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      Navigator.of(ctx).pop(false);
                                    },
                                    child: const Text('No, volver', style: TextStyle(fontFamily: 'Poppins')),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Boton 'Si, Eliminar'
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red[700],
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.of(ctx).pop(true);
                                    },
                                    child: const Text('Si, Eliminar', style: TextStyle(fontFamily: 'Poppins')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );

                    // Si el usuario confirma, ejecutar callback de borrado
                    if (confirmed == true) {
                      onClearHistory();
                    }
                  }
                },
                // Construye los items del menu desplegable
                itemBuilder: (BuildContext context) {
                  FocusScope.of(context).unfocus(); // Cierra el teclado si esta abierto

                  return [
                    // Opcion para contactar por WhatsApp
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

                    // Opcion para borrar el historial de conversacion
                    const PopupMenuItem(
                      value: 'Borrar Historial',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Borrar Historial de conversacion',
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
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // PROPIEDADES DEL WIDGET
  // ===========================================================================
  /// Define la altura preferida para la AppBar (altura estandar de toolbar)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
