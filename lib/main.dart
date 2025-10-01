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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => FaqBloc()),
        BlocProvider(
          create: (context) {
            final authBloc = AuthBloc(
              authService: context.read<AuthService>(),
            );
            // Verificar el estado de autenticación al iniciar
            authBloc.add(CheckAuthStatus());
            return authBloc;
          },
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
        return MaterialApp(
          title: 'Asistente Colbún',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            fontFamily: 'Poppins',
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark().copyWith(
              // Opcional: define un tema oscuro explícito
              ),
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      }),
    );
  }
}
