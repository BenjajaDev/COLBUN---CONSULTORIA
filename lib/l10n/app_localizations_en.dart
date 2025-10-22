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
}
