import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/auth_service.dart';
import '../../../features/auth/bloc/auth_event.dart';
import '../../../features/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    // --- MANEJADORES DE EVENTOS REGISTRADOS ---

    // ¡NUEVO MANEJADOR AÑADIDO!
    // Se activa cuando el StreamBuilder en main.dart detecta un cambio.
    on<AuthUserChanged>(_onAuthUserChanged);

    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);

    // El StreamSubscription que estaba aquí se ha eliminado
    // para evitar lógica duplicada.
  }

  // --- LÓGICA DE LOS MANEJADORES ---

  /// Este es el nuevo método que maneja el evento que viene desde main.dart
  Future<void> _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user != null) {
      // Si el evento trae un usuario, obtenemos sus datos de Firestore
      // y emitimos el estado de autenticado.
      final userData = await _authService.getCurrentUserData();
      if (userData != null) {
        emit(AuthAuthenticated(userData));
      } else {
        // Caso raro: Firebase Auth tiene un usuario pero no hay datos en Firestore.
        emit(AuthError("No se pudieron cargar los datos del usuario."));
      }
    } else {
      // Si el evento no trae un usuario, significa que cerró sesión.
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    // Este evento sigue siendo útil para una comprobación manual si es necesario,
    // pero ya no es el principal mecanismo de actualización.
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

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithEmailAndPassword(
          event.email, event.password);
      // No emitimos nada aquí. El StreamBuilder en main.dart
      // detectará el cambio y disparará AuthUserChanged automáticamente.
    } catch (e) {
      emit(AuthError(_handleAuthError(e)));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.registerWithEmailAndPassword(
          event.email, event.password, event.name);
      // El StreamBuilder en main.dart se encargará del resto.
    } catch (e) {
      emit(AuthError(_handleAuthError(e)));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.signOut();
      // El StreamBuilder en main.dart se encargará del resto.
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No existe usuario con este correo electrónico';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'email-already-in-use':
          return 'Este correo electrónico ya está registrado';
        default:
          return 'Error de autenticación: ${e.message}';
      }
    }
    return 'Ocurrió un error inesperado.';
  }

  // Ya no necesitamos sobreescribir el método close() porque
  // hemos eliminado el StreamSubscription.
}