

abstract class PoiState {}

class PoiInitial extends PoiState {}


class PoiLoading extends PoiState {}

class PoiLoaded extends PoiState {
}
class PoiError extends PoiState {
  final String message;

  PoiError(this.message);
}
