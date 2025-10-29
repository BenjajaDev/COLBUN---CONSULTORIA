import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService._internal();
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> setString(String key, String value) async {
    final prefs = await _preferences;
    return prefs.setString(key, value);
  }

  Future<bool> setStringList(String key, List<String> values) async {
    final prefs = await _preferences;
    return prefs.setStringList(key, values);
  }

  Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }

  Future<List<String>?> getStringList(String key) async {
    final prefs = await _preferences;
    return prefs.getStringList(key);
  }
  Future<bool> remove(String key) async {
    final prefs = await _preferences;
    return prefs.remove(key);
  }
}