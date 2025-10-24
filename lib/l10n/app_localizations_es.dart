// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get search => 'Buscar';

  @override
  String get otono => 'Otoño';

  @override
  String get invierno => 'Invierno';

  @override
  String get primavera => 'Primavera';

  @override
  String get verano => 'Verano';

  @override
  String get vista360 => 'Vista 360°';

  @override
  String get descripcion => 'Descripción';

  @override
  String get recomendados => 'Recomendados';

  @override
  String get cercanos => 'Cerca de ti';

  @override
  String get ruta => 'Ruta';

  @override
  String get rutas_disponibles => 'Rutas disponibles';

  @override
  String get resultado_busqueda => 'Resultado de búsqueda';

  @override
  String get sin_resultado => 'No se encontraron resultados';

  @override
  String get vistas_modificadas_ia => 'Incluye vistas modificadas con IA';

  @override
  String no_vista360_temporada(Object season) {
    return 'No hay imagen 360 para la temporada \"$season\".';
  }

  @override
  String get no_vista360_disponible =>
      'No hay imagen 360 disponible para la temporada seleccionada.';

  @override
  String get ir => 'Ir';

  @override
  String get ruta_en_curso => 'Ruta en curso';

  @override
  String distancia_fmt(Object distance) {
    return 'Distancia: $distance';
  }

  @override
  String tiempo_aprox_fmt(Object duration) {
    return 'Tiempo aprox.: $duration';
  }

  @override
  String llegada_aprox_fmt(Object eta) {
    return 'Llegada aprox.: $eta';
  }

  @override
  String get cancelar => 'Cancelar';

  @override
  String get filtros_title => 'Filtros';

  @override
  String get categoria_label => 'Categoría';

  @override
  String get actividad_label => 'Actividad';

  @override
  String get distancia_km_label => 'Distancia (km)';

  @override
  String get aplicar_filtros => 'Aplicar filtros';

  @override
  String get todas => 'Todas';

  @override
  String get modo_sin_conexion => 'Modo sin conexión';

  @override
  String temporada_actual_fmt(Object season) {
    return 'Temporada actual: $season';
  }

  @override
  String get recomendacion_temporada_otono =>
      'Paisajes coloridos y temperaturas moderadas; ideal para fotografía y caminatas.';

  @override
  String get recomendacion_temporada_invierno =>
      'Clima frío y con neblina; usa abrigo adecuado y precaución en senderos.';

  @override
  String get recomendacion_temporada_primavera =>
      'Clima templado y flora abundante; ideal para trekking y observación de flora.';

  @override
  String get recomendacion_temporada_verano =>
      'Días más calurosos; hidrátate y evita las horas de mayor radiación.';

  @override
  String get emergencias_title => 'Emergencias';

  @override
  String get telefonos_emergencia_title => 'Teléfonos de emergencia';

  @override
  String get emergency_police_chile => 'Policía (Carabineros)';

  @override
  String get emergency_firefighters_chile => 'Bomberos';

  @override
  String get emergency_ambulance_chile => 'Ambulancia (SAMU)';
}
