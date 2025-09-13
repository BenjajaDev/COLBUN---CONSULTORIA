import 'package:flutter/material.dart';
// Asegúrate de que el nombre del proyecto sea el correcto
import 'package:consultoria_chat_bot/features/home/screen/home_screen.dart';
//Importaciones flutter_bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/chatbot/bloc/theme_bloc.dart';
import 'features/chatbot/bloc/faq_bloc.dart';

// ESTA FUNCIÓN ES LA QUE FALTA
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(               //MultiBloc provider para gestion de estado de tema y mostrado de faqs
      providers: [
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => FaqBloc())
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Mi Aplicación',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          );
        }
      ), 
    );
  }
}