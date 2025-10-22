// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:consultoria_chat_bot/features/auth/screen/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:consultoria_chat_bot/services/firestore_faq_service.dart';
import 'package:consultoria_chat_bot/services/openai_service.dart';
import 'package:consultoria_chat_bot/services/auth_service.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_event.dart';
import 'package:consultoria_chat_bot/features/home/screen/home_screen.dart';
import 'package:consultoria_chat_bot/features/chatbot/bloc/theme_bloc.dart';
import 'package:consultoria_chat_bot/features/chatbot/bloc/faq_bloc.dart';
import 'firebase_options.dart';

// ===========================================================================
// PUNTO DE ENTRADA PRINCIPAL DE LA APLICACION
// ===========================================================================
/// Funcion principal que inicializa Firebase, servicios globales y ejecuta la app
void main() async {
  // Asegura que todos los bindings de Flutter esten inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las variables de entorno desde el archivo .env
  await dotenv.load(fileName: ".env");

  // Inicializa Firebase para la plataforma actual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ===========================================================================
  // INICIALIZACION DE SERVICIOS GLOBALES
  // ===========================================================================
  final faqService = FaqService();
  final openAIService = OpenAIService();
  final authService = AuthService();

  // Carga las FAQs y calcula los puntajes de busqueda al iniciar la app
  await faqService.loadFaqsAndCalculateScores();

  // Ejecuta la aplicacion con los servicios provistos globalmente
  runApp(
    // Provee los servicios a toda la aplicacion para que sean accesibles
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: faqService),
        RepositoryProvider.value(value: openAIService),
        RepositoryProvider.value(value: authService),
      ],
      child: const MyApp(),
    ),
  );
}

// ===========================================================================
// WIDGET PRINCIPAL DE LA APLICACION
// ===========================================================================
/// Widget raiz que configura el tema, rutas y autenticacion
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider provee los BLoCs a toda la aplicacion
    return MultiBlocProvider(
      providers: [
        // BLoC para gestion de tema (modo claro/oscuro)
        BlocProvider(create: (context) => ThemeBloc()),
        // BLoC para gestion de FAQs
        BlocProvider(create: (context) => FaqBloc()),
        // BLoC para gestion de autenticacion
        BlocProvider(
          create: (context) => AuthBloc(
            authService: context.read<AuthService>(),
          ),
          // NOTA: No disparamos CheckAuthStatus aqui
          // El StreamBuilder se encargara de la logica inicial
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Asistente Colbun',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              fontFamily: 'Poppins',
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark(),
            themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            
            // ===========================================================================
            // MANEJO DE AUTENTICACION CON STREAMBUILDER
            // ===========================================================================
            // Usamos un StreamBuilder para decidir que pantalla mostrar
            home: StreamBuilder(
              // Escuchamos el stream que nos dice si el usuario esta logueado
              stream: context.read<AuthService>().authStateChanges,
              builder: (context, snapshot) {
                // MIENTRAS ESPERA: Muestra un indicador de carga
                // Esto es crucial en el segundo arranque
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // SI HAY UN USUARIO: El usuario esta logueado
                if (snapshot.hasData) {
                  // Disparamos el evento para que el AuthBloc sepa del usuario
                  context.read<AuthBloc>().add(AuthUserChanged(snapshot.data));
                  return const HomeScreen();
                }

                // SI NO HAY USUARIO: Nadie esta logueado
                // Mostramos la pantalla de autenticacion
                return const AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
