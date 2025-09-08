import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme_bloc.dart';

class AppColors{
  static const Color lightprimary = Color(0xFF4D67AE);
  static const Color lightbackground = Colors.white;
  static const Color lightTextFieldBorder = Color(0xFFE0E0E0);
  static const Color darkprimary = Color(0xFF494C6B);
  static const Color darkBackground = Color(0xFF252525);
}

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            // Esto quita el foco del teclado cuando se toca fuera del campo de texto
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: state.isDarkMode
                ? AppColors.darkBackground
                : Colors.grey[50],
            body: Column(
              children: [
                // Header del chatbot
                ChatbotHeader(),

                // Body - conversación
                Expanded(
                  child: ChatbotBody(isDarkMode: state.isDarkMode),
                ),

                // Footer - input del usuario
                ChatbotFooter(isDarkMode: state.isDarkMode),
              ],
            ),
          ),
        );
      }
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
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return AppBar(
          elevation: 0,//sin sombra el apartado
          backgroundColor: state.isDarkMode
            ? AppColors.darkprimary
            : AppColors.lightprimary,
          iconTheme: IconThemeData(color: AppColors.lightbackground),
          title: Text(
            'CHATBOT HEADER',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          actions: [
            //=============================================================================
            // Switch modo oscuro/claro
            //=============================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    state.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4,),
                  Switch(
                    value: state.isDarkMode, 
                    onChanged: (value){
                      context.read<ThemeBloc>().add(ToggleThemeEvent());
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white.withValues(alpha: 0.5),
                  )
                ],
              ),
            ),

            //=============================================================================
            // Botón de tres puntos tipo popup
            //=============================================================================
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFFFFFFFF)),
              color: state.isDarkMode ? AppColors.darkprimary : AppColors.lightprimary,
              iconSize: 34,
              position: PopupMenuPosition.under,
              elevation: 8, //sombra del popup
              offset: Offset(0, 13),
              
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              

              onSelected: (value) {
                // Aquí puedes manejar las opciones
                if (value == 'Whatsapp') {
                  print('Contactar por WhatsApp');
                } else if (value == 'Borrar Historial') {
                  print('Borrar Historial');
                }
              },
              itemBuilder: (BuildContext context) {
                // Cierra el teclado antes de mostrar el menú
                FocusScope.of(context).unfocus();

                //=============================================================================
                // Opciones del menú
                //=============================================================================
                return [
                  PopupMenuItem(
                    value: 'Whatsapp',
                    child: ListTile(
                      leading: Icon(Icons.chat, color: Colors.green),
                      title: Text(
                        'Contactar por WhatsApp',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    
                  ),
                  //=============================================================================
                  //Esta opcion solo es para poner la linea blanca divisora entre las opciones
                  //=============================================================================
                  PopupMenuItem(
                    enabled: false, // No se pueda seleccionar
                    height: 0, // Eliminar padding superior/inferior
                    child: Divider(
                      color: Colors.white, // Línea blanca
                      height: 1,
                    ),
                  ),
                  
                  PopupMenuItem(
                    value: 'Borrar Historial',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Borrar Historial de conversación',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        );
      }
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
  final bool isDarkMode;
  const ChatbotBody({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO: Implementar área de conversación
      // - Lista de mensajes
      // - Scroll automático
      // - Burbujas de chat diferenciadas
      // - Indicador de "escribiendo..."
      width: double.infinity,
      color: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        //Item count sirve para definir cuántos elementos se van a mostrar en la lista
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ListTile(
            //Alineará el texto con su respectivo remitente
            title: Text(
              message['text'] ?? '',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black
              ) 
            ),
            subtitle: Text(
              message['sender'] ?? '',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600]
              ),  
            ),
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
  final bool isDarkMode;
  const ChatbotFooter({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO:Implementar área de input
      // - Campo de texto para escribir mensaje
      // - Botón de envío
      // - Botón de adjuntar archivos
      // - Indicadores de estado
      height: 70,
      color: isDarkMode ? AppColors.darkBackground : AppColors.lightbackground,
      padding: const EdgeInsets.all(16.0),

      child: Row(
        children: [
          // aqui esta el box que contiene el campo de texto
          Expanded(
            child: Container(
              //===============================================================
              //decoracion del contenedor que contiene al campo de textfield
              //===============================================================
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkBackground : AppColors.lightbackground, //Color relleno textField
                borderRadius: BorderRadius.circular(12.0),
                // color de bordes E0E0E0 mockup de field del texto
                border: Border.all(color: isDarkMode ? Colors.grey[600]! : AppColors.lightTextFieldBorder)
              ),


              //agregue padding para que el texto no este pegado al borde acordarse las medidas solo multiplo de 8
              padding: const EdgeInsets.symmetric(horizontal: 16.0),

              //===============================================================
              //este es el campo de texto TextField
              //===============================================================
              child: TextField(
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black
                ),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Color(0xFF828282)),// color de texto escribe un mensaje 828282 mockup
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          //boton de enviar el mensaje
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkBackground : AppColors.lightbackground,

            ),

            //===============================================================
            //boton de enviar tipo  ICONBUTTON
            //===============================================================
            child: IconButton(
              icon: Icon(Icons.send, color: isDarkMode ? Colors.white :Color(0XFF1d1b20)),// color del icono de enviar 1d1b20 mockup
              iconSize: 24,
              onPressed: () {
                // aqui iria la logica para enviar el mensaje del usuario
              },
            ),
          ),
        ],
      ),
    );
  }
}
