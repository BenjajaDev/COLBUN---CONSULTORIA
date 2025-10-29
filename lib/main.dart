import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/firestore_faq_service.dart';
import '../../../services/openai_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_faq_cache_service.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/chatbot/bloc/theme_bloc.dart';
import '../../../features/chatbot/bloc/faq_bloc.dart';
import 'firebase_options.dart';
import '../../../features/auth/screen/auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';
import '../../../features/chatbot/bloc/language_block.dart';
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
  final connectivityService = ConnectivityService();
  final offlineFaqCache = OfflineFaqCacheService();

  // Inicializar conectividad
  await connectivityService.initialize();

  // Carga las FAQs y calcula los puntajes de búsqueda al iniciar la app.
  await faqService.loadFaqsAndCalculateScores();
  
  // Cargar FAQs esenciales desde caché
  await offlineFaqCache.loadEssentialFaqsFromCache();
  
  // Si está online, cachear las FAQs esenciales
  if (connectivityService.isOnline) {
    final allFaqs = await faqService.getAllFaqs();
    await offlineFaqCache.saveEssentialFaqsToCache(allFaqs);
  }

  runApp(
    // Provee los servicios a toda la aplicación para que sean accesibles.
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: faqService),
        RepositoryProvider.value(value: openAIService),
        RepositoryProvider.value(value: authService),
        RepositoryProvider.value(value: connectivityService),
        RepositoryProvider.value(value: offlineFaqCache),
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
        BlocProvider(create: (context) => LanguageBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          ThemeData buildTheme(Brightness brightness) {
            final base = ThemeData(
              useMaterial3: true,
              brightness: brightness,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: brightness,
              ),
              fontFamily: 'Poppins',
            );
            // Mantener tamaños y familia de fuente consistentes en ambos temas
            return base.copyWith(
              textTheme: base.textTheme.apply(fontFamily: 'Poppins'),
            );
          }

          final light = buildTheme(Brightness.light);
          final dark = buildTheme(Brightness.dark);
          return MaterialApp(
            locale: context.select((LanguageBloc bloc) => bloc.state.locale),
            title: 'Asistente Colbun',
            supportedLocales: L10n.all,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: light,
            darkTheme: dark,
            themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            // Evita que el cambio de tema rehaga un StreamBuilder completo
            home: const AuthGate(),
          );
        },
      ),
    );
    
  }
}