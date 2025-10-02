import 'package:consultoria_chat_bot/model/route_model.dart';
import 'package:latlong2/latlong.dart';

// Clase base abstracta para representar los diferentes estados del mapa.
abstract class MapState {}

// Estado inicial del mapa, antes de cualquier carga o acción.
class MapInitial extends MapState {}

// Estado que indica que el mapa o los datos se están cargando.
class MapLoading extends MapState {}

// Estado que representa cuando el mapa está cargado con los datos necesarios.
class MapLoaded extends MapState {
  final LatLng center; // Centro actual del mapa.
  final List<LatLng>
  markers; // Lista de marcadores mostrados en el mapa (coordenadas).
  final LatLng? userLocation; // Ubicación actual del usuario (puede ser nula).
  final double heading; // Orientación o heading del dispositivo.
  final List<MapRoute> route; // Lista de rutas cargadas con sus detalles.

  // Constructor con todos los campos requeridos.
  MapLoaded({
    required this.center,
    required this.markers,
    required this.userLocation,
    required this.heading,
    required this.route,
  });

  // Método para copiar el estado con actualizaciones opcionales manteniendo inmutabilidad.
  MapLoaded copyWith({
    LatLng? center,
    List<LatLng>? markers,
    LatLng? userLocation,
    double? heading,
    List<MapRoute>? route,
  }) {
    return MapLoaded(
      center: center ?? this.center,
      markers: markers ?? this.markers,
      userLocation: userLocation ?? this.userLocation,
      heading: heading ?? this.heading,
      route: route ?? this.route,
    );
  }
}

// Estado que representa un error con un mensaje descriptivo al usuario.
class MapError extends MapState {
  final String message;

  MapError(this.message);
}
