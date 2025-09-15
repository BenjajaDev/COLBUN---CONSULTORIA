import 'package:latlong2/latlong.dart';
import 'package:consultoria_chat_bot/models/route360.dart';

abstract class MapState {}

const _unset = Object();

class MapInitial extends MapState {
  final LatLng center;
  final List<LatLng> markers;
  final double heading;
  final LatLng? userLocation;
  final List<Route360> routes;
  final String? selectedRouteId;

  MapInitial({
    required this.center,
    this.markers = const [],
    this.heading = 0.0,
    this.userLocation,
    this.routes = const [],
    this.selectedRouteId,
  });

  MapInitial copyWith({
    LatLng? center,
    List<LatLng>? markers,
    double? heading,
    Object? userLocation = _unset,     
    List<Route360>? routes,
    Object? selectedRouteId = _unset,
  }) {
    return MapInitial(
      center: center ?? this.center,
      markers: markers ?? this.markers,
      heading: heading ?? this.heading,
      userLocation: identical(userLocation, _unset)
          ? this.userLocation
          : userLocation as LatLng?,
      routes: routes ?? this.routes,
      selectedRouteId: identical(selectedRouteId, _unset)
          ? this.selectedRouteId
          : selectedRouteId as String?,
    );
  }
}

class MapFailure extends MapState {
  final String message;
  MapFailure(this.message);
}
