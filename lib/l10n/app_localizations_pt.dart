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

  @override
  String get filtros_title => 'Filtros';

  @override
  String get categoria_label => 'Categoria';

  @override
  String get actividad_label => 'Atividade';

  @override
  String get distancia_km_label => 'Distância (km)';

  @override
  String get aplicar_filtros => 'Aplicar filtros';

  @override
  String get todas => 'Todas';

  @override
  String get modo_sin_conexion => 'Modo offline';

  @override
  String temporada_actual_fmt(Object season) {
    return 'Estação atual: $season';
  }

  @override
  String get recomendacion_temporada_otono =>
      'Paisagens coloridas e temperaturas amenas; ideal para fotografia e caminhadas.';

  @override
  String get recomendacion_temporada_invierno =>
      'Clima frio e neblina; use agasalho adequado e tenha cautela nas trilhas.';

  @override
  String get recomendacion_temporada_primavera =>
      'Clima ameno e flores abundantes; ideal para trekking e observação da flora.';

  @override
  String get recomendacion_temporada_verano =>
      'Dias mais quentes; hidrate-se e evite os horários de maior radiação.';

  @override
  String get emergencias_title => 'Emergências';

  @override
  String get telefonos_emergencia_title => 'Telefones de emergência';

  @override
  String get emergency_police_chile => 'Polícia (Carabineros)';

  @override
  String get emergency_firefighters_chile => 'Bombeiros';

  @override
  String get emergency_ambulance_chile => 'Ambulância (SAMU)';

  @override
  String get iniciar_ruta => 'Iniciar rota';

  @override
  String get ver_detalles => 'Ver detalhes';

  @override
  String route_count_chip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# rotas',
      one: '# rota',
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
}
