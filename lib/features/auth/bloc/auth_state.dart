// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:consultoria_chat_bot/models/user_model.dart';

// ===========================================================================
// DEFINICION DE ESTADOS DE AUTENTICACION
// ===========================================================================
/// Clase base abstracta para todos los estados de autenticacion
abstract class AuthState {}

// ===========================================================================
// ESTADO: INICIAL
// ===========================================================================
/// Estado inicial cuando se desconoce el estado de autenticacion
/// Se usa al arrancar la aplicacion antes de verificar si hay sesion activa
class AuthInitial extends AuthState {}

// ===========================================================================
// ESTADO: CARGANDO
// ===========================================================================
/// Estado cuando se esta procesando una operacion de autenticacion
/// (verificando credenciales, registrando usuario, etc.)
class AuthLoading extends AuthState {}

// ===========================================================================
// ESTADO: AUTENTICADO
// ===========================================================================
/// Estado cuando el usuario esta autenticado exitosamente
/// Contiene los datos completos del usuario
class AuthAuthenticated extends AuthState {
  final UserModel user; // Datos del usuario autenticado
  
  AuthAuthenticated(this.user);
}

// ===========================================================================
// ESTADO: NO AUTENTICADO
// ===========================================================================
/// Estado cuando no hay usuario autenticado
/// Se muestra la pantalla de login
class AuthUnauthenticated extends AuthState {}

// ===========================================================================
// ESTADO: ERROR
// ===========================================================================
/// Estado para mostrar errores de autenticacion
/// Contiene el mensaje de error para mostrar al usuario
class AuthError extends AuthState {
  final String message; // Mensaje descriptivo del error
  
  AuthError(this.message);
}