import 'package:latlong2/latlong.dart';

// Clase base abstracta para los eventos relacionados con el mapa.
abstract class MapEvent {}

// Evento para añadir un nuevo marcador en la posición dada.
class AddMarker extends MapEvent {
  final LatLng position;
  AddMarker(this.position);
}

// Evento para actualizar la ubicación actual del usuario en el mapa.
class UpdateUserLocation extends MapEvent {
  final LatLng position;
  UpdateUserLocation(this.position);
}

// Evento para actualizar la orientación o heading del dispositivo.
class UpdateHeading extends MapEvent {
  final double heading;
  UpdateHeading(this.heading);
}

// Evento para cargar rutas y datos relacionados en el mapa.
class LoadRoute extends MapEvent {}
