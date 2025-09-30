// ignore_for_file: avoid_print

/// Clase para filtrar logs de debug molestos
class DebugLogger {
  static bool _showDebugServiceErrors = false;
  
  /// Filtra logs innecesarios de DebugService
  static void log(String message) {
    // Filtrar errores conocidos de DebugService
    if (message.contains('DebugService: Error serving requests') && 
        message.contains('Cannot send Null')) {
      if (_showDebugServiceErrors) {
        print('[FILTERED DEBUG]: $message');
      }
      return;
    }
    
    // Mostrar otros logs normalmente
    print(message);
  }
  
  /// Habilita o deshabilita los logs de DebugService
  static void toggleDebugServiceLogs(bool show) {
    _showDebugServiceErrors = show;
    print('DebugService logs: ${show ? 'ENABLED' : 'DISABLED'}');
  }
}