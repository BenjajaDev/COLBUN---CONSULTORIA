import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_state.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_event.dart';
import 'package:consultoria_chat_bot/features/auth/screen/auth_screen.dart';
import 'package:consultoria_chat_bot/features/home/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Si está cargando, muestra un indicador de carga
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Si el usuario está autenticado, muestra la pantalla principal
        if (state is AuthAuthenticated) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('App Principal'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión',
                  onPressed: () {
                    context.read<AuthBloc>().add(SignOutRequested());
                  },
                ),
              ],
            ),
            drawer: const AppDrawer(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bienvenido, ${state.user.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text('Email: ${state.user.email}'),
                ],
              ),
            ),
          );
        }
        
        // Si el usuario no está autenticado o hay un error, muestra la pantalla de login
        return const AuthScreen();
      },
    );
  }
}