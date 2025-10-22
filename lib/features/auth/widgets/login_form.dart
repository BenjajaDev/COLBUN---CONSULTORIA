// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_event.dart';

// ===========================================================================
// FORMULARIO DE INICIO DE SESION
// ===========================================================================
/// Widget que presenta el formulario de inicio de sesion con email y password
/// Incluye validacion de campos y toggle de visibilidad de password
class LoginForm extends StatefulWidget {
  final VoidCallback onRegisterToggle; // Callback para cambiar a registro
  
  const LoginForm({Key? key, required this.onRegisterToggle}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // ===========================================================================
  // CONTROLADORES Y ESTADO
  // ===========================================================================
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Controla si la password es visible

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================
  @override
  void dispose() {
    // Liberar recursos de los controladores
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // METODOS DE VALIDACION Y ENVIO
  // ===========================================================================
  /// Valida el formulario y envia el evento de inicio de sesion
  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        SignInRequested(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        ),
      );
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titulo del formulario
          Text(
            'Iniciar Sesion',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Campo de email con validacion
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electronico',
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo electronico';
              }
              // Validar formato de email con expresion regular
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Ingresa un correo electronico valido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Campo de password con toggle de visibilidad
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Contrasena',
              hintText: 'Ingresa tu contrasena',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contrasena';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Boton de envio
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ingresar'),
          ),
          const SizedBox(height: 16),
          
          // Boton para cambiar a registro
          TextButton(
            onPressed: widget.onRegisterToggle,
            child: const Text('¿No tienes cuenta? Registrate'),
          ),
        ],
      ),
    );
  }
}