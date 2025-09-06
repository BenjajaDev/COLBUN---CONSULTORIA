import 'package:flutter/material.dart';
// Asegúrate de que el nombre del proyecto sea el correcto
import 'package:consultoria_chat_bot/features/home/screen/home_screen.dart';

// ESTA FUNCIÓN ES LA QUE FALTA
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Aplicación',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}