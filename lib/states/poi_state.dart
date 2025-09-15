import 'package:consultoria_chat_bot/model/poi_model.dart';

abstract class PoiState {}

class PoiInitial extends PoiState {}


class PoiLoading extends PoiState {}

class PoiLoaded extends PoiState {
  final POI poi;

  PoiLoaded(this.poi);
}
class PoiError extends PoiState {
  final String message;

  PoiError(this.message);
}
