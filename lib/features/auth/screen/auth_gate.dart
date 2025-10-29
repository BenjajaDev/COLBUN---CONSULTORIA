import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/auth_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../../home/screen/home_screen.dart';
import 'auth_screen.dart';

/// AuthGate mantiene una suscripción estable al estado de autenticación para
/// evitar pantallazos cuando el MaterialApp reconstruye (por ejemplo, al cambiar tema).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription? _sub;
  Object? _user; // FirebaseAuth User o null
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _sub = auth.authStateChanges.listen((u) {
      if (!mounted) return;
      setState(() {
        _user = u;
        _loading = false;
      });
      // Informar al AuthBloc del usuario actual
      context.read<AuthBloc>().add(AuthUserChanged(u));
    }, onError: (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _user != null ? const HomeScreen() : const AuthScreen();
  }
}
