import 'package:consultoria_chat_bot/model/poi_model.dart';

abstract class PoiState {}

class PoiInitial extends PoiState {}


class PoiLoading extends PoiState {}

class PoiLoaded extends PoiState {
  final POI current;
  final List<POI> recommended;
  final List<POI> nearby;
  final Map<String, double> distancesKm;

  PoiLoaded ({
    required this.current,
    required this.recommended,
    required this.nearby,
    required this.distancesKm,
  });
}
class PoiError extends PoiState {
  final String message;
  PoiError(this.message);
}


