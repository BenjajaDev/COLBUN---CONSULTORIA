import 'dart:async';
import 'dart:convert';
import 'cache_service.dart';

/// Servicio de caché para respuestas de OpenAI
/// Optimiza los tiempos de respuesta almacenando consultas frecuentes
class ResponseCacheService {
  static final ResponseCacheService _instance =
      ResponseCacheService._internal();
  factory ResponseCacheService() => _instance;
  ResponseCacheService._internal();

  final CacheService _cacheService = CacheService();

  // Caché en memoria para acceso ultra-rápido
  final Map<String, CachedResponse> _memoryCache = {};

  // Configuración
  static const String _cachePrefix = 'openai_response_';
  static const int _maxMemoryCacheSize = 100;
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Guarda una respuesta en caché
  Future<void> cacheResponse({
    required String query,
    required String response,
    required String language,
    String? link,
  }) async {
    final normalizedQuery = _normalizeQuery(query);
    final cacheKey = _getCacheKey(normalizedQuery, language);

    final cachedResponse = CachedResponse(
      query: normalizedQuery,
      response: response,
      language: language,
      link: link,
      timestamp: DateTime.now(),
    );

    // Guardar en memoria
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      // Eliminar la entrada más antigua
      final oldestKey = _memoryCache.entries
          .reduce(
              (a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
    }
    _memoryCache[cacheKey] = cachedResponse;

    // Guardar en disco de forma asíncrona (fire-and-forget)
    unawaited(_persistToStorage(cacheKey, cachedResponse));
  }

  /// Obtiene una respuesta de caché si existe y no ha expirado
  Future<CachedResponse?> getCachedResponse({
    required String query,
    required String language,
  }) async {
    final normalizedQuery = _normalizeQuery(query);
    final cacheKey = _getCacheKey(normalizedQuery, language);

    // 1. Verificar caché en memoria (ultra-rápido)
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey]!;
      if (!_isExpired(cached)) {
        print('⚡ Respuesta desde caché en memoria');
        return cached;
      } else {
        _memoryCache.remove(cacheKey);
      }
    }

    // 2. Verificar caché en disco
    try {
      final cachedData = await _cacheService.getString(cacheKey);
      if (cachedData != null) {
        final cached = CachedResponse.fromJson(jsonDecode(cachedData));
        if (!_isExpired(cached)) {
          // Cargar en memoria para próximas consultas
          _memoryCache[cacheKey] = cached;
          print('⚡ Respuesta desde caché en disco');
          return cached;
        } else {
          // Expirado, eliminar
          await _cacheService.remove(cacheKey);
        }
      }
    } catch (e) {
      print('⚠️ Error leyendo caché: $e');
    }

    return null;
  }

  /// Limpia el caché (memoria y disco)
  Future<void> clearCache() async {
    _memoryCache.clear();
    // En un escenario real, aquí eliminaríamos todas las claves con el prefijo
    print('🗑️ Caché de respuestas limpiado');
  }

  String _normalizeQuery(String query) {
    return query.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _getCacheKey(String query, String language) {
    return '$_cachePrefix${language}_${query.hashCode}';
  }

  bool _isExpired(CachedResponse cached) {
    return DateTime.now().difference(cached.timestamp) > _cacheDuration;
  }

  Future<void> _persistToStorage(String key, CachedResponse response) async {
    try {
      await _cacheService.setString(key, jsonEncode(response.toJson()));
    } catch (e) {
      print('⚠️ Error persistiendo caché: $e');
    }
  }
}

/// Modelo para respuestas cacheadas
class CachedResponse {
  final String query;
  final String response;
  final String language;
  final String? link;
  final DateTime timestamp;

  CachedResponse({
    required this.query,
    required this.response,
    required this.language,
    this.link,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'response': response,
        'language': language,
        'link': link,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CachedResponse.fromJson(Map<String, dynamic> json) => CachedResponse(
        query: json['query'] as String,
        response: json['response'] as String,
        language: json['language'] as String,
        link: json['link'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
