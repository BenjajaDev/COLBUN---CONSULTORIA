// Clase base abstracta para representar los diferentes estados relacionados con POIs.
abstract class PoiState {}

// Estado inicial antes de cargar cualquier dato de POIs.
class PoiInitial extends PoiState {}

// Estado que indica que los datos de POIs se están cargando.
class PoiLoading extends PoiState {}

// Estado que indica que los datos de POIs se han cargado correctamente.
class PoiLoaded extends PoiState {}

// Estado que indica un error con un mensaje descriptivo al usuario.
class PoiError extends PoiState {
  final String message; // Mensaje de error para mostrar.

  PoiError(this.message);
}
