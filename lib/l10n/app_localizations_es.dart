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
}
