import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <- Importa Firebase Core
import 'firebase_options.dart'; // <- Importa tus opciones de Firebase
import 'features/home/screen/home_screen.dart';
//Importaciones flutter_bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/chatbot/bloc/theme_bloc.dart';
import 'features/chatbot/bloc/faq_bloc.dart';

// La función main ahora es async y espera la inicialización de Firebase
void main() async {
  // Asegura que todos los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase para la plataforma actual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      //MultiBloc provider para gestion de estado de tema y mostrado de faqs
      providers: [
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => FaqBloc())
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
        return MaterialApp(
          title: 'Mi Aplicación',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            fontFamily: 'Poppins',
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark().copyWith(
              // Opcional: define un tema oscuro explícito
              // ... tus personalizaciones para el tema oscuro
              ),
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      }),
    );
  }
}
