// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get search => 'Pesquisar';

  @override
  String get otono => 'Outono';

  @override
  String get invierno => 'Inverno';

  @override
  String get primavera => 'Primavera';

  @override
  String get verano => 'Verão';

  @override
  String get vista360 => 'Vista 360°';

  @override
  String get descripcion => 'Descrição';

  @override
  String get recomendados => 'Recomendados';

  @override
  String get cercanos => 'Perto de você';

  @override
  String get ruta => 'Rota';

  @override
  String get rutas_disponibles => 'Rotas disponíveis';

  @override
  String get resultado_busqueda => 'Resultado de busca';

  @override
  String get sin_resultado => 'Nenhum resultado encontrado';

  @override
  String get vistas_modificadas_ia => 'Inclui vistas modificadas com IA';

  @override
  String no_vista360_temporada(Object season) {
    return 'Não há imagem 360 para a temporada \"$season\".';
  }

  @override
  String get no_vista360_disponible =>
      'Não há imagem 360 disponível para a temporada selecionada.';

  @override
  String get ir => 'Ir';

  @override
  String get ruta_en_curso => 'Rota em andamento';

  @override
  String distancia_fmt(Object distance) {
    return 'Distância: $distance';
  }

  @override
  String tiempo_aprox_fmt(Object duration) {
    return 'Tempo aprox.: $duration';
  }

  @override
  String llegada_aprox_fmt(Object eta) {
    return 'Chegada aprox.: $eta';
  }

  @override
  String get cancelar => 'Cancelar';
}
