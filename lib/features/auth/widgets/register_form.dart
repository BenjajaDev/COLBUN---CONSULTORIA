// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_bloc.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_event.dart';

// ===========================================================================
// FORMULARIO DE REGISTRO
// ===========================================================================
/// Widget que presenta el formulario de registro de nuevos usuarios
/// Solicita nombre, email y password con validaciones correspondientes
class RegisterForm extends StatefulWidget {
  final VoidCallback onLoginToggle; // Callback para cambiar a login
  
  const RegisterForm({Key? key, required this.onLoginToggle}) : super(key: key);

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  // ===========================================================================
  // CONTROLADORES Y ESTADO
  // ===========================================================================
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Controla si la password es visible

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================
  @override
  void dispose() {
    // Liberar recursos de los controladores
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // METODOS DE VALIDACION Y ENVIO
  // ===========================================================================
  /// Valida el formulario y envia el evento de registro
  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        SignUpRequested(
          _nameController.text.trim(),
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
            'Crear Cuenta',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Campo de nombre con validacion
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Tu nombre completo',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Campo de email con validacion de formato
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
          
          // Campo de password con validacion de longitud minima
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Contrasena',
              hintText: 'Crea una contrasena',
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
                return 'Por favor crea una contrasena';
              }
              // Validar longitud minima de 6 caracteres
              if (value.length < 6) {
                return 'La contrasena debe tener al menos 6 caracteres';
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
            child: const Text('Registrarse'),
          ),
          const SizedBox(height: 16),
          
          // Boton para cambiar a login
          TextButton(
            onPressed: widget.onLoginToggle,
            child: const Text('¿Ya tienes cuenta? Inicia sesion'),
          ),
        ],
      ),
    );
  }
}