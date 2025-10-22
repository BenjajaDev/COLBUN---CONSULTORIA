// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_state.dart';
import 'package:consultoria_chat_bot/features/auth/widgets/login_form.dart';
import 'package:consultoria_chat_bot/features/auth/widgets/register_form.dart';

// ===========================================================================
// PANTALLA DE AUTENTICACION
// ===========================================================================
/// Pantalla principal de autenticacion que alterna entre login y registro
/// Muestra mensajes de error cuando hay problemas de autenticacion
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // ===========================================================================
  // ESTADO
  // ===========================================================================
  bool _isLogin = true; // Controla si se muestra login o registro

  // ===========================================================================
  // METODOS DE CONTROL
  // ===========================================================================
  /// Alterna entre la vista de login y registro
  void _toggleView() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Escucha errores de autenticacion para mostrarlos al usuario
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  // Alterna entre formulario de login y registro
                  child: _isLogin
                      ? LoginForm(onRegisterToggle: _toggleView)
                      : RegisterForm(onLoginToggle: _toggleView),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}