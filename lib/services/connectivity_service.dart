import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Servicio para detectar y monitorear el estado de conectividad de red
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isOnline = true;
  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream que emite true/false según el estado de conectividad
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  
  /// Estado actual de conectividad
  bool get isOnline => _isOnline;

  /// Inicializar servicio y escuchar cambios
  Future<void> initialize() async {
    // Verificar estado inicial
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Escuchar cambios en tiempo real
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        debugPrint('⚠️ Error en connectivity listener: $error');
      },
    );
    
    debugPrint('✅ ConnectivityService inicializado (estado: ${_isOnline ? "online" : "offline"})');
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    
    // Considerar online si hay cualquier tipo de conexión
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    // Solo emitir si cambió el estado
    if (wasOnline != _isOnline) {
      _connectivityController.add(_isOnline);
      
      if (_isOnline) {
        final connectionTypes = results
            .where((r) => r != ConnectivityResult.none)
            .map((r) => r.name)
            .join(', ');
        debugPrint('📡 Conectado a red ($connectionTypes)');
      } else {
        debugPrint('📴 Sin conexión - modo offline activado');
      }
    }
  }

  /// Liberar recursos
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
    debugPrint('🔌 ConnectivityService disposed');
  }
}
