// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:firebase_auth/firebase_auth.dart';

// ===========================================================================
// DEFINICION DE EVENTOS DE AUTENTICACION
// ===========================================================================
/// Clase base abstracta para todos los eventos de autenticacion
abstract class AuthEvent {}

// ===========================================================================
// EVENTO: CAMBIO DE USUARIO
// ===========================================================================
/// Se dispara cuando el estado de autenticacion cambia (login/logout)
/// Este evento se activa automaticamente desde el StreamBuilder en main.dart
class AuthUserChanged extends AuthEvent {
  final User? user; // Usuario de Firebase Auth (null si no hay sesion)
  AuthUserChanged(this.user);
}

// ===========================================================================
// EVENTO: VERIFICAR ESTADO DE AUTENTICACION
// ===========================================================================
/// Verifica manualmente el estado actual de autenticacion
/// Util para comprobaciones puntuales aunque no es el mecanismo principal
class CheckAuthStatus extends AuthEvent {}

// ===========================================================================
// EVENTO: SOLICITUD DE INICIO DE SESION
// ===========================================================================
/// Evento disparado cuando el usuario intenta iniciar sesion
class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  SignInRequested(this.email, this.password);
}

// ===========================================================================
// EVENTO: SOLICITUD DE REGISTRO
// ===========================================================================
/// Evento disparado cuando el usuario intenta registrarse
class SignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  SignUpRequested(this.name, this.email, this.password);
}

// ===========================================================================
// EVENTO: SOLICITUD DE CIERRE DE SESION
// ===========================================================================
/// Evento disparado cuando el usuario cierra sesion
class SignOutRequested extends AuthEvent {}
