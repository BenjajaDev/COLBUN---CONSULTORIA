

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  
  /// Revisa si el dispositivo tiene conexión a WiFi o Datos Móviles.
  Future<bool> isConnected() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    
    // Compara el resultado con la lista de estados de conectividad
    // Si es móvil o wifi, estamos online.
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    
    // Si no, estamos offline.
    return false;
  }
}