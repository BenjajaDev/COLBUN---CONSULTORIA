import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:consultoria_chat_bot/services/auth_service.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_event.dart';
import 'package:consultoria_chat_bot/features/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription? _authSubscription;

  AuthBloc({required AuthService authService}) 
      : _authService = authService,
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);

    // Suscribirse a los cambios de estado de autenticación
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      add(CheckAuthStatus());
    });
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit
  ) async {
    emit(AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getCurrentUserData();
        if (userData != null) {
          emit(AuthAuthenticated(userData));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit
  ) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithEmailAndPassword(
        event.email, 
        event.password
      );
      // El listener de authStateChanges actualizará el estado
    } catch (e) {
      emit(AuthError(_handleAuthError(e)));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit
  ) async {
    emit(AuthLoading());
    try {
      await _authService.registerWithEmailAndPassword(
        event.email, 
        event.password, 
        event.name
      );
      // El listener de authStateChanges actualizará el estado
    } catch (e) {
      emit(AuthError(_handleAuthError(e)));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit
  ) async {
    try {
      await _authService.signOut();
      // El listener de authStateChanges actualizará el estado
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
        case 'weak-password':
          return 'La contraseña es demasiado débil';
        case 'invalid-email':
          return 'Correo electrónico inválido';
        default:
          return 'Error de autenticación: ${e.message}';
      }
    }
    return 'Error de autenticación: $e';
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}