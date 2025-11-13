// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get search => 'Search';

  @override
  String get otono => 'Autumn';

  @override
  String get invierno => 'Winter';

  @override
  String get primavera => 'Spring';

  @override
  String get verano => 'Summer';

  @override
  String get vista360 => '360° View';

  @override
  String get descripcion => 'Description';

  @override
  String get recomendados => 'Recommended';

  @override
  String get cercanos => 'Near you';

  @override
  String get ruta => 'Route';

  @override
  String get rutas_disponibles => 'Available routes';

  @override
  String get resultado_busqueda => 'Search result';

  @override
  String get sin_resultado => 'No results found';

  @override
  String get vistas_modificadas_ia => 'Includes views modified with AI';

  @override
  String no_vista360_temporada(Object season) {
    return 'No 360 image available for the \"$season\" season.';
  }

  @override
  String get no_vista360_disponible =>
      'No 360 image available for the selected season.';

  @override
  String get ir => 'Go';

  @override
  String get ruta_en_curso => 'Route in progress';

  @override
  String distancia_fmt(Object distance) {
    return 'Distance: $distance';
  }

  @override
  String tiempo_aprox_fmt(Object duration) {
    return 'Approx. time: $duration';
  }

  @override
  String llegada_aprox_fmt(Object eta) {
    return 'Approx. arrival: $eta';
  }

  @override
  String get cancelar => 'Cancel';

  @override
  String get filtros_title => 'Filters';

  @override
  String get categoria_label => 'Category';

  @override
  String get actividad_label => 'Activity';

  @override
  String get distancia_km_label => 'Distance (km)';

  @override
  String get aplicar_filtros => 'Apply filters';

  @override
  String get todas => 'All';

  @override
  String get modo_sin_conexion => 'Offline mode';

  @override
  String temporada_actual_fmt(Object season) {
    return 'Current season: $season';
  }

  @override
  String get recomendacion_temporada_otono =>
      'Colorful landscapes and mild temperatures; great for photography and hikes.';

  @override
  String get recomendacion_temporada_invierno =>
      'Cold weather and mist; wear warm clothing and use caution on trails.';

  @override
  String get recomendacion_temporada_primavera =>
      'Mild weather and abundant blooms; ideal for trekking and wildflower viewing.';

  @override
  String get recomendacion_temporada_verano =>
      'Hotter days; stay hydrated and avoid peak sun hours.';

  @override
  String get emergencias_title => 'Emergencies';

  @override
  String get telefonos_emergencia_title => 'Emergency phone numbers';

  @override
  String get emergency_police_chile => 'Police (Carabineros)';

  @override
  String get emergency_firefighters_chile => 'Firefighters';

  @override
  String get emergency_ambulance_chile => 'Ambulance (SAMU)';

  @override
  String get iniciar_ruta => 'Start route';

  @override
  String get ver_detalles => 'View details';

  @override
  String route_count_chip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# routes',
      one: '# route',
    );
    return '$_temp0';
  }

  @override
  String poi_count_chip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# POIs',
      one: '# POI',
    );
    return '$_temp0';
  }

  @override
  String get error_cargar_imagen => 'Failed to load image';

  @override
  String get error_cargar_mapa => 'Failed to load map';

  @override
  String get reintentar => 'Retry';

  @override
  String get intentando_reconectar => 'Trying to reconnect...';

  @override
  String get conexion_recuperada => 'Connection restored';
}
