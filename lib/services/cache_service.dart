// ===========================================================================
// IMPORTACIONES
// ===========================================================================
import 'package:shared_preferences/shared_preferences.dart';

// ===========================================================================
// SERVICIO DE CACHE LOCAL
// ===========================================================================
/// Servicio para gestionar el almacenamiento local usando SharedPreferences
/// Implementa el patron Singleton para tener una unica instancia
/// Permite guardar y recuperar datos de forma persistente en el dispositivo
class CacheService {
  // ===========================================================================
  // PATRON SINGLETON
  // ===========================================================================
  CacheService._internal(); // Constructor privado
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;

  // ===========================================================================
  // PROPIEDADES
  // ===========================================================================
  SharedPreferences? _prefs; // Instancia de SharedPreferences cacheada

  // ===========================================================================
  // OBTENCION DE PREFERENCIAS
  // ===========================================================================
  /// Obtiene la instancia de SharedPreferences (la crea si no existe)
  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // ===========================================================================
  // METODOS DE ALMACENAMIENTO
  // ===========================================================================
  
  /// Guarda un string en el cache local
  Future<bool> setString(String key, String value) async {
    final prefs = await _preferences;
    return prefs.setString(key, value);
  }

  /// Guarda una lista de strings en el cache local
  Future<bool> setStringList(String key, List<String> values) async {
    final prefs = await _preferences;
    return prefs.setStringList(key, values);
  }

  // ===========================================================================
  // METODOS DE RECUPERACION
  // ===========================================================================
  
  /// Recupera un string del cache local
  /// Retorna null si la clave no existe
  Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }

  /// Recupera una lista de strings del cache local
  /// Retorna null si la clave no existe
  Future<List<String>?> getStringList(String key) async {
    final prefs = await _preferences;
    return prefs.getStringList(key);
  }
  
  // ===========================================================================
  // METODOS DE ELIMINACION
  // ===========================================================================
  
  /// Elimina un valor del cache local por su clave
  Future<bool> remove(String key) async {
    final prefs = await _preferences;
    return prefs.remove(key);
  }
}