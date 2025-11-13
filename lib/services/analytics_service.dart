import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
class AnalyticsService {
  // Instancia única de FirebaseAnalytics
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  /// Método genérico
  static Future<void> logEvent(String name, Map<String, dynamic>? params) async {
    await _analytics.logEvent(
      name: name,
      parameters: params == null ? null : Map<String, Object>.from(params),
    );
    print(  'Logged event: $name with params: $params');
  }

  /// ---- EVENTOS PERSONALIZADOS ----

  static Future<void> logAbrirRuta(String rutaId, String nombre) async {
    await logEvent('abrir_ruta', {
      'ruta_id': rutaId,
      'nombre': nombre,
    });
  }

  static Future<void> logAbrirPOI(String poiId, String nombre) async {
    await logEvent('abrir_poi', {
      'poi_id': poiId,
      'nombre': nombre,
    });
  }

  static Future<void> logAbrirVista360(String ubicacionId, String nombre) async {
    await logEvent('abrir_vista_360', {
      'ubicacion_id': ubicacionId,
      'nombre': nombre,
    });
  }

  static Future<void> logMarcarFavorito(
    String tipo,
    String id, {
    String? nombre,
    String? accion, // opcional: 'agregar' | 'quitar'
  }) async {
    await logEvent('marcar_favorito', {
      'tipo': tipo,
      'id': id,
      if (nombre != null) 'nombre': nombre,
      if (accion != null) 'accion': accion,
    });
  }

  static Future<void> logAplicarFiltro({
    required String categoria,
    double? distanciaMaxKm,
    String? temporada,
  }) async {
    await logEvent('aplicar_filtro', {
      'categoria': categoria,
      if (temporada != null) 'temporada': temporada,
      if (distanciaMaxKm != null) 'distancia_max_km': distanciaMaxKm,
    });
  }

  static Future<void> logRealizarBusqueda(
    String termino,
    int resultados,
  ) async {
    await logEvent('realizar_busqueda', {
      'termino': termino,
      'resultados': resultados,
    });
  }
  // --- ERRORES ---
  /// Registra un error con contexto (ruta, POI, etc.)
  static Future<void> logError(
    dynamic error,
    StackTrace stack, {
    String? contexto, // ej: "Ruta Lago Colbún" o "POI Mirador X"
    Map<String, dynamic>? detalles,
  }) async {
    final contextInfo = {
      if (contexto != null) 'contexto': contexto,
      if (detalles != null) ...detalles,
    };

    // Log para depuración local
    // ignore: avoid_print
    print('🚨 Error capturado: $error\nContexto: $contextInfo');

    // Enviar a Crashlytics con contexto adicional
    await _crashlytics.log('Error en contexto: $contexto');
    await _crashlytics.setCustomKey('contexto', contexto ?? 'sin_contexto');
    detalles?.forEach((key, value) {
      _crashlytics.setCustomKey(key, value.toString());
    });

    await _crashlytics.recordError(error, stack, fatal: false);
  }
}
