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

void main() async {
  // Asegura que todos los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las variables de entorno desde el archivo .env
  await dotenv.load(fileName: ".env");

  // Inicializa Firebase para la plataforma actual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- INICIALIZACIÓN DE SERVICIOS ---
  final faqService = FaqService();
  final openAIService = OpenAIService();
  final authService = AuthService();

  // Carga las FAQs y calcula los puntajes de búsqueda al iniciar la app.
  await faqService.loadFaqsAndCalculateScores();

  runApp(
    // Provee los servicios a toda la aplicación para que sean accesibles.
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider sigue siendo la raíz para los Blocs
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => FaqBloc()),
        BlocProvider(
          create: (context) => AuthBloc(
            authService: context.read<AuthService>(),
          ),
          // NOTA: Ya no disparamos CheckAuthStatus aquí.
          // El StreamBuilder se encargará de la lógica inicial.
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Asistente Colbún',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              fontFamily: 'Poppins',
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark(),
            themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            // Usamos un StreamBuilder para decidir qué pantalla mostrar
            home: StreamBuilder(
              // Escuchamos el stream que nos dice si el usuario está logueado
              stream: context.read<AuthService>().authStateChanges,
              builder: (context, snapshot) {
                // MIENTRAS ESPERA: Muestra un indicador de carga.
                // Esto es crucial en el segundo arranque.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // SI HAY UN USUARIO: El usuario está logueado.
                if (snapshot.hasData) {
                  // Disparamos el evento para que el AuthBloc sepa del usuario
                  context.read<AuthBloc>().add(AuthUserChanged(snapshot.data));
                  return const HomeScreen();
                }

                // SI NO HAY USUARIO: Nadie está logueado.
                // Aquí deberías mostrar tu pantalla de Login.
                // Por ahora, usamos un placeholder.
                return const AuthScreen(); // ¡Asegúrate de tener esta pantalla!
              },
            ),
          );
        },
      ),
    );
  }
}
