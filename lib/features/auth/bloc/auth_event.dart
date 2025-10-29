import 'package:firebase_auth/firebase_auth.dart';
abstract class AuthEvent {}

// ¡NUEVO EVENTO! Se dispara cuando el estado de auth cambia (login/logout)
class AuthUserChanged extends AuthEvent {
  final User? user;
  AuthUserChanged(this.user);
}

// Verificar el estado actual de autenticación
class CheckAuthStatus extends AuthEvent {}

// Evento para iniciar sesión
class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  SignInRequested(this.email, this.password);
}

// Evento para registrarse
class SignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  SignUpRequested(this.name, this.email, this.password);
}

// Evento para cerrar sesión
class SignOutRequested extends AuthEvent {}