// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:consultoria_chat_bot/services/auth_service.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_event.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ===========================================================================
// BLOC DE AUTENTICACION
// ===========================================================================
/// Gestiona la logica de negocio de autenticacion de usuarios
/// Coordina el AuthService con los estados y eventos de la UI
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // ===========================================================================
  // SERVICIOS
  // ===========================================================================
  final AuthService _authService;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================
  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    // Registro de manejadores de eventos
    
    // Maneja cambios automaticos de autenticacion desde Firebase
    on<AuthUserChanged>(_onAuthUserChanged);
    // Verifica manualmente el estado de autenticacion
    on<CheckAuthStatus>(_onCheckAuthStatus);
    // Procesa solicitud de inicio de sesion
    on<SignInRequested>(_onSignInRequested);
    // Procesa solicitud de registro
    on<SignUpRequested>(_onSignUpRequested);
    // Procesa solicitud de cierre de sesion
    on<SignOutRequested>(_onSignOutRequested);

    // NOTA: El StreamSubscription que estaba aqui se ha eliminado
    // para evitar logica duplicada con el StreamBuilder de main.dart
  }

  // ===========================================================================
  // MANEJADORES DE EVENTOS
  // ===========================================================================
  
  /// Maneja el evento disparado desde main.dart cuando Firebase detecta cambios
  /// Este es el mecanismo principal de actualizacion de estado
  Future<void> _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user != null) {
      // Si el evento trae un usuario, obtenemos sus datos de Firestore
      // y emitimos el estado de autenticado
      final userData = await _authService.getCurrentUserData();
      if (userData != null) {
        emit(AuthAuthenticated(userData));
      } else {
        // Caso raro: Firebase Auth tiene un usuario pero no hay datos en Firestore
        emit(AuthError("No se pudieron cargar los datos del usuario."));
      }
    } else {
      // Si el evento no trae un usuario, significa que cerro sesion
      emit(AuthUnauthenticated());
    }
  }

  /// Verifica manualmente el estado de autenticacion
  /// Util para comprobaciones puntuales aunque no es el mecanismo principal
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final userData = await _authService.getCurrentUserData();
      if (userData != null) {
        emit(AuthAuthenticated(userData));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Procesa la solicitud de inicio de sesion con email y password
  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithEmailAndPassword(
          event.email, event.password);
      // No emitimos nada aqui. El StreamBuilder en main.dart
      // detectara el cambio y disparara AuthUserChanged automaticamente
    } catch (e) {
      emit(AuthError(_handleAuthError(e)));
    }
  }

  /// Procesa la solicitud de registro de nuevo usuario
  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.registerWithEmailAndPassword(
          event.email, event.password, event.name);
      // El StreamBuilder en main.dart se encargara del resto
    } catch (e) {
      emit(AuthError(_handleAuthError(e)));
    }
  }

  /// Procesa la solicitud de cierre de sesion
  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.signOut();
      // El StreamBuilder en main.dart se encargara del resto
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ===========================================================================
  // METODOS AUXILIARES
  // ===========================================================================
  
  /// Traduce los errores de Firebase a mensajes amigables para el usuario
  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No existe usuario con este correo electronico';
        case 'wrong-password':
          return 'Contrasena incorrecta';
        case 'email-already-in-use':
          return 'Este correo electronico ya esta registrado';
        default:
          return 'Error de autenticacion: ${e.message}';
      }
    }
    return 'Ocurrio un error inesperado.';
  }
}
