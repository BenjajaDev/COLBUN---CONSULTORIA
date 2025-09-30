// lib/features/home/screen/home_screen.dart

import 'package:flutter/material.dart';
import 'package:consultoria_chat_bot/features/home/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  
  const HomeScreen({super.key});

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Principal')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Bienvenido')),
    );
  }
}
