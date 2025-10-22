// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_state.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_event.dart';
import 'package:consultoria_chat_bot/features/auth/screen/auth_screen.dart';
import 'package:consultoria_chat_bot/features/home/widgets/app_drawer.dart';

// ===========================================================================
// PANTALLA PRINCIPAL (HOME)
// ===========================================================================
/// Pantalla principal de la aplicacion que se muestra cuando el usuario esta autenticado
/// Incluye menu lateral y opciones de navegacion
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Si esta cargando, muestra un indicador de carga
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Si el usuario esta autenticado, muestra la pantalla principal
        if (state is AuthAuthenticated) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('App Principal'),
              actions: [
                // Boton de cierre de sesion
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesion',
                  onPressed: () {
                    context.read<AuthBloc>().add(SignOutRequested());
                  },
                ),
              ],
            ),
            drawer: const AppDrawer(), // Menu lateral de navegacion
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mensaje de bienvenida personalizado
                  Text(
                    'Bienvenido, ${state.user.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  // Muestra el email del usuario
                  Text('Email: ${state.user.email}'),
                ],
              ),
            ),
          );
        }
        
        // Si el usuario no esta autenticado o hay un error, muestra la pantalla de login
        return const AuthScreen();
      },
    );
  }
}