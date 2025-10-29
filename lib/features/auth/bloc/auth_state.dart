import 'package:consultoria_chat_bot/models/user_model.dart';

abstract class AuthState {}

// Estado inicial cuando se desconoce el estado de autenticación
class AuthInitial extends AuthState {}

// Estado cuando se está cargando (verificando credenciales, etc.)
class AuthLoading extends AuthState {}

// Estado cuando el usuario está autenticado
class AuthAuthenticated extends AuthState {
  final UserModel user;
  
  AuthAuthenticated(this.user);
}

// Estado cuando el usuario no está autenticado
class AuthUnauthenticated extends AuthState {}

// Estado para mostrar errores de autenticación
class AuthError extends AuthState {
  final String message;
  
  AuthError(this.message);
}