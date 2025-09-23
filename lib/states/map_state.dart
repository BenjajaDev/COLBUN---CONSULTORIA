import 'package:consultoria_chat_bot/model/route_model.dart';
import 'package:latlong2/latlong.dart';

abstract class MapState {}

class MapInitial extends MapState {
}
class MapLoading extends MapState {
}
class MapLoaded extends MapState {
  final LatLng center;
  final List<LatLng> markers;
  final LatLng? userLocation;
  final double heading;
  final List<MapRoute> route;

  MapLoaded({
    required this.center,
    required this.markers,
    required this.userLocation,
    required this.heading,
    required this.route,
  });

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
class MapError extends MapState {
  final String message;
  MapError(this.message);
}